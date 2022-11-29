// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ProxyUtils.sol";

abstract contract ProxyWithdrawal is Ownable {
    
    event BalanceEvent(uint amount, address tokenAddress);
    event TransferEvent(address to, uint amount, address tokenAddress);

    /**
     * Return coins balance
     */
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    /**
     * Return tokens balance
     */
    function getTokenBalance(address tokenAddress) public returns(uint) {
        (bool success, bytes memory result) = tokenAddress.call(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        require(success, "Withdrawal: balanceOf request failed");

        uint amount = abi.decode(result, (uint));
        emit BalanceEvent(amount, tokenAddress);

        return amount;
    }

    /**
     * Transfer coins
     */
    function transfer(address payable to, uint amount) external onlyOwner {
        require(!ProxyUtils.isContract(to), "Withdrawal: target address is contract");

        require(getBalance() >= amount, "Withdrawal: balance not enough");
        to.transfer(amount);

        emit TransferEvent(to, amount, address(0));
    }

    /**
     * Transfer tokens
     */
    function transferToken(address to, uint amount, address tokenAddress) external onlyOwner {
        require(!ProxyUtils.isContract(to), "Withdrawal: target address is contract");

        uint _balance = getTokenBalance(tokenAddress);
        require(_balance >= amount, "Withdrawal: not enough tokens");

        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "Withdrawal: approve request failed");

        (success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "Withdrawal: transfer request failed");

        emit TransferEvent(to, amount, tokenAddress);
    }
}