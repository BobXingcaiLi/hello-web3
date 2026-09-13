// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Ledger} from "../src/Ledger.sol";

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
}