// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Ledger {
    // struct：把多个相关字段打包成一个自定义类型
    struct AccountInfo {
        uint256 lastActionTime;   // 最后一次操作的时间戳
        uint256 actionCount;      // 总共操作次数
    }

    // mapping：地址 -> 余额，类似一个key-value字典
    mapping(address => uint256) public balances;

    // mapping：地址 -> 附加信息(struct)
    mapping(address => AccountInfo) public accountInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);


    function deposit() public payable {
        balances[msg.sender] += msg.value;

        accountInfo[msg.sender].lastActionTime = block.timestamp;
        accountInfo[msg.sender].actionCount += 1;

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        // 1. 先检查：调用者的余额够不够取这么多
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // 2. 先改状态：在真正转账之前，先把余额扣掉
        balances[msg.sender] -= amount;
        accountInfo[msg.sender].lastActionTime = block.timestamp;
        accountInfo[msg.sender].actionCount += 1;

        emit Withdraw(msg.sender, amount);

        // 3. 最后才转账:把 ETH 发给调用者
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}