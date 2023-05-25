// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract JiyukoToken is ERC20, ERC20Burnable, Ownable, ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint256;

    uint256 public tokensPerEth = 10000;
    uint256 public availableAmount;

    event TokensPurchased(address indexed buyer, uint256 amount);
    event AvailableAmountUpdated(uint256 newAvailableAmount);
    event TokensPerEthUpdated(uint256 newTokensPerEth);

    constructor(
        uint256 initialSupply, // 10 000 000
        uint256 initialAvailableAmount // 300 000
    ) ERC20("Jiyuko", "JIY") {
        _mint(msg.sender, initialSupply.mul(10 ** decimals()));
        availableAmount = initialAvailableAmount.mul(10 ** decimals());
    }

    function buyTokens() external payable nonReentrant {
        require(msg.value > 0, "You must send ETH to buy tokens.");
        uint256 tokensToBuy = msg.value.mul(tokensPerEth);
        require(
            balanceOf(owner()) > tokensToBuy,
            "Not enough tokens available for sale."
        );
        require(
            availableAmount > tokensToBuy,
            "Token purchase exceeds the available amount."
        );

        availableAmount = availableAmount.sub(tokensToBuy);
        _transfer(owner(), msg.sender, tokensToBuy);

        emit TokensPurchased(msg.sender, tokensToBuy);
    }

    function setAvailableAmount(uint256 newAvailableAmount) external onlyOwner {
        require(
            newAvailableAmount <= balanceOf(owner()),
            "Available amount exceeds owner's token balance."
        );
        availableAmount = newAvailableAmount.mul(10 ** decimals());
        emit AvailableAmountUpdated(newAvailableAmount);
    }

    function setTokensPerEth(uint256 newTokensPerEth) external onlyOwner {
        tokensPerEth = newTokensPerEth;
        emit TokensPerEthUpdated(newTokensPerEth);
    }

    function withdraw() external onlyOwner {
        uint256 etherBalance = address(this).balance;
        require(etherBalance > 0, "Nothing to withdraw.");
        address payable recipient = payable(msg.sender);
        recipient.sendValue(etherBalance);
    }

    function getTokensAvailable() public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 ownerBalance = balanceOf(owner());

        uint256 soldAmount = totalSupply.sub(ownerBalance);

        return availableAmount.sub(soldAmount);
    }

    receive() external payable {
        this.buyTokens();
    }
}