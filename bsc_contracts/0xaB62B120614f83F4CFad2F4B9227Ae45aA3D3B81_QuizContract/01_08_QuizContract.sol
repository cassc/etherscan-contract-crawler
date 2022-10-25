// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

contract QuizContract is Ownable {
    ERC20 public tokenAddress;

    struct DepositData {
        address owner;
        uint amount;
        uint timeStamp;
    }

    mapping(address=> DepositData) public DepositDatas;
    event CreateDeposit(address owner, uint amount, uint timeStamp);

    uint public amountToken = 10 * 10**18;
    uint public totalFee = 0;

    constructor(ERC20 _token){
        tokenAddress = _token;
    }

    function createDeposit() external {
        SafeERC20.safeTransferFrom(tokenAddress, msg.sender, address(this), amountToken);
        totalFee+=amountToken;
        DepositDatas[msg.sender] = DepositData(msg.sender, amountToken, block.timestamp);
        emit CreateDeposit(msg.sender, amountToken, block.timestamp);
    }

    function withdrawFund(uint _amount) external onlyOwner {
        require(_amount <= totalFee, "Amount must smaller totalFee");
        tokenAddress.transfer(msg.sender, _amount);
    }

    function changeAmountFee(uint _amount) external onlyOwner {
        require(_amount > 0, "Amount must greater 0");
        amountToken = _amount;
    }

    fallback () external {
        revert();
    }
}