// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Ledger} from "../src/Ledger.sol";
import {Attacker} from "./Attacker.sol";

contract LedgerTest is Test {
    Ledger public ledger;
    address public alice = address(0x1);

    function setUp() public {
        ledger = new Ledger();
        // 给 alice 这个测试地址一些初始 ETH，方便她后面调用 deposit
        vm.deal(alice, 10 ether);
    }

    function test_DepositUpdatesBalance() public {
        vm.prank(alice);
        ledger.deposit{value: 1 ether}();

        assertEq(ledger.balances(alice), 1 ether);
    }

    function test_WithdrawReducesBalance() public {
        vm.prank(alice);
        ledger.deposit{value: 1 ether}();

        vm.prank(alice);
        ledger.withdraw(0.4 ether);

        assertEq(ledger.balances(alice), 0.6 ether);
    }

    function test_WithdrawFailsIfInsufficientBalance() public {
        vm.prank(alice);
        ledger.deposit{value: 1 ether}();

        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        ledger.withdraw(2 ether);
    }

    function test_DepositEmitsEvent() public {
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Ledger.Deposit(alice, 1 ether);

        ledger.deposit{value: 1 ether}();
    }

    function testFuzz_DepositUpdatesBalance(uint256 amount) public {
        // 1. 这里需要限制 amount 的范围，为什么？
        //    提示：alice 只有 vm.deal 给的 10 ether，如果 amount 比这个还大会怎样？
        //    用 vm.assume(...) 来过滤掉不合理的输入
        vm.assume(amount > 0 && amount <= alice.balance);
        vm.prank(alice);
        ledger.deposit{value: amount}();

        assertEq(ledger.balances(alice), amount);
    }

    function testFuzz_WithdrawReducesBalance(uint256 amount) public {
        uint256 depositAmount = 10 ether;
        vm.prank(alice);
        ledger.deposit{value: depositAmount}();
        vm.assume(amount > 0 && amount <= depositAmount);
        
        vm.prank(alice);
        ledger.withdraw(amount);

        assertEq(ledger.balances(alice), depositAmount - amount);
    }

    function test_ReentrancyAttackFails() public {
        // get someone putting some ETH into the Ledger contract first
        address bob = address(0x2);
        vm.deal(bob, 5 ether);
        vm.prank(bob);
        ledger.deposit{value: 5 ether}();
        
        // 1. 部署攻击合约
        Attacker attacker = new Attacker(ledger);

        // 2. 给攻击合约一些初始 ETH，方便它调用 deposit
        vm.deal(address(attacker), 1 ether);

        // 3. 调用攻击函数，尝试发起重入攻击
        vm.expectRevert(); // 预期攻击会失败，因为 Ledger 合约已经防御了重入攻击
        attacker.attack{value: 1 ether}();
    }
}