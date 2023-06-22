// SPDX-License-Identifier: MIT
// REF: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.3.0/contracts/crowdsale/Crowdsale.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 private _acceptToken;

    // Address where funds are collected
    address private _wallet;

    // 1 unit of payment token gives you this much sale token
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 indexed amount
    );

    /**
     * @param pRate 1 unit of payment token gives you this much sale token
     * @param pWallet Address where collected funds will be forwarded to
     * @param pAcceptToken Address of the token to accept in payment
     */
    constructor(
        uint256 pRate,
        address pWallet,
        IERC20 pAcceptToken
    ) {
        require(pRate > 0);
        require(pWallet != address(0));
        require(address(pAcceptToken) != address(0));

        _rate = pRate;
        _wallet = pWallet;
        _acceptToken = pAcceptToken;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address) {
        return _wallet;
    }

    /** @dev Sets the wallet that will receive funds from token sale
     */
    function setWallet(address pWallet) external onlyOwner {
        require(pWallet != address(0));
        _wallet = pWallet;
    }

    /**
     * @return the number of token wei equal to 1 token.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     @ @param amount wei amount of tokens to purchase
     */
    function buyTokens(address beneficiary, uint256 amount) public nonReentrant {
        require(beneficiary != address(0));
        require(amount >= _rate, "amount must be greater than or equal to rate");
        uint256 totalWeiCost = amount.div(_rate);

        // update state
        _weiRaised = _weiRaised.add(totalWeiCost);

        emit TokensPurchased(msg.sender, beneficiary, totalWeiCost, amount);

        _acceptToken.transferFrom(msg.sender, _wallet, totalWeiCost);
    }

    function withdrawTokens(address token, address beneficiary, uint256 tokenAmount) external onlyOwner nonReentrant {
        IERC20(token).transfer(beneficiary, tokenAmount);
    }
}