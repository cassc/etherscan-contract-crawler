// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Crowdsale is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private _token;

    // How many token units a buyer gets per wei
    // The rate is the conversion between wei and the smallest and indivisible token unit
    uint256 private _rate;
    uint256 private _weiRaised;

    address payable private _wallet;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor(IERC20 tokenToSell, uint256 tokenRate, address payable account) {
        require(address(tokenToSell) != address(0), "Crowdsale: token is the zero address");
        require(tokenRate > 0, "Crowdsale: rate is 0");
        require(account != address(0), "Crowdsale: wallet is the zero address");

        _token = tokenToSell;
        _rate = tokenRate;
        _wallet = account;
    }

    function token() external view returns (IERC20) {
        return _token;
    }

    function rate() public view returns (uint256) {
        return _rate;
    }

    function weiRaised() external view returns (uint256) {
        return _weiRaised;
    }

    function wallet() external view returns (address payable) {
        return _wallet;
    }

    function setWallet(address payable account) external onlyOwner {
        require(account != address(0), "Crowdsale: wallet is the zero address");
        _wallet = account;
    }

    receive() external payable {
        buyTokens(_msgSender());
    }

    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);

        _weiRaised = _weiRaised.add(weiAmount);
        _token.safeTransfer(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _wallet.transfer(weiAmount);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal virtual view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
    }

    function _getTokenAmount(uint256 weiAmount) internal virtual view returns (uint256) {
        return weiAmount.mul(_rate);
    }
}