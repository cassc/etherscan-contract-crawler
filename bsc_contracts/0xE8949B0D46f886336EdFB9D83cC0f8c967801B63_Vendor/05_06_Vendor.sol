// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Learn more about the ERC20 implementation
// on OpenZeppelin docs: https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Vendor is Ownable, ReentrancyGuard {
    // Event that log buy operation
    uint256 tokenprice = 0.0086 ether;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

    /**
     * @notice Allow users to buy token for ETH
     */
    function buyTokenswtet(uint256 amountToBuy) public nonReentrant {
        IERC20 tether = IERC20(0x55d398326f99059fF775485246999027B3197955);
        IERC20 sps = IERC20(0x8033064Fe1df862271d4546c281AfB581ee25C4A);
        uint256 comision = (amountToBuy * 1) / 100;
        uint256 amtblesscom = amountToBuy - comision;
        uint256 tokenamount = (amtblesscom / tokenprice);
        require(
            tether.allowance(msg.sender, address(this)) >= amountToBuy,
            "Insuficient Allowance"
        );
        require(
            tether.balanceOf(msg.sender) >= amountToBuy,
            "No tiene saldo suficiente"
        );

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = sps.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        // Transfer token to the msg.sender
        require(tether.transferFrom(msg.sender, address(this), amountToBuy));
        require(sps.transferFrom(address(this), msg.sender, tokenamount));
        // emit the event
        emit BuyTokens(msg.sender, tokenamount, amountToBuy);
    }

    function buyTokenswbusd(uint256 amountToBuy) public nonReentrant {
        IERC20 busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        IERC20 sps = IERC20(0x8033064Fe1df862271d4546c281AfB581ee25C4A);
        uint256 comision = (amountToBuy * 1) / 100;
        uint256 amtblesscom = amountToBuy - comision;
        uint256 tokenamount = (amtblesscom / tokenprice);
        require(
            busd.allowance(msg.sender, address(this)) >= amountToBuy,
            "Insuficient Allowance"
        );
        require(
            busd.balanceOf(msg.sender) >= amountToBuy,
            "No tiene saldo suficiente"
        );

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = sps.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        // Transfer token to the msg.sender
        require(busd.transferFrom(msg.sender, address(this), amountToBuy));
        require(sps.transferFrom(address(this), msg.sender, tokenamount));
        // emit the event
        emit BuyTokens(msg.sender, tokenamount, amountToBuy);
    }

    /**
     * @notice Allow the owner of the contract to withdraw ETH
     */
    function withdraw(address _tokenContract) public onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 ownerBalance = tokenContract.balanceOf(address(this));
        require(ownerBalance > 0, "Owner has not balance to withdraw");
        require(tokenContract.transfer(msg.sender, ownerBalance));
    }
}