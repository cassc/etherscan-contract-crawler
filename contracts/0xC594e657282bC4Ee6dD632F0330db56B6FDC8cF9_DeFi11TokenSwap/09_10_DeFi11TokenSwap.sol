// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../utils/AccessProtected-0.8.sol";
import "@openzeppelin/contracts-0.8/utils/Address.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-0.8/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";

/// @title DeFi11TokenSwap
/// @author NonceBlox
/// @notice A Simple token swap contract for DeFi11 between D11 token and Partner token, contract should hold the partner token to be distributed
contract DeFi11TokenSwap is Ownable, ReentrancyGuard, AccessProtected {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* 
        STATE VARIABLES 
    */

    IERC20 private d11TokenAddress;
    IERC20 private partnerTokenAddress;
    uint256 private swapRatio;

    // this address is used for superficial burning of tokens, we'll transfer D11 token here
    address public constant deadAddr = 0x000000000000000000000000000000000000dEaD;

    /*
        EVENTS
    */

    event TokenSwapped(address indexed user, uint256 indexed offeredTokenAmount, uint256 indexed swappedTokenAmount);

    /* 
        CONSTRUCTOR
    */

    constructor(IERC20 _d11TokenAddress, IERC20 _partnerTokenAddress, uint256 _swapRatio) {
        require(address(_d11TokenAddress) != address(0), "d11TokenAddress = 0x00");
        require(_d11TokenAddress != _partnerTokenAddress, "can't be same address");
        require(address(_d11TokenAddress).isContract(), "d11TokenAddress != contract");
        require(address(_partnerTokenAddress) != address(0), "partnerTokenAddress = 0x00");
        require(address(_partnerTokenAddress).isContract(), "partnerTokenAddress != contract");
        require(_swapRatio > 0, "swapRatio = zero || -ve");
        d11TokenAddress = _d11TokenAddress;
        partnerTokenAddress = _partnerTokenAddress;
        swapRatio = _swapRatio;
    }

    /* 
        SETTER FUNCTIONS
    */

    /// @notice to set D11 token address
    /// @dev to set/modify D11 token address if decided to change for a reason, can only be called by admins
    /// @param _d11TokenAddress address of the ERC20 D11 token smart contract
    function setD11TokenAddress(IERC20 _d11TokenAddress) external onlyAdmin {
        require(address(_d11TokenAddress) != address(0), "d11TokenAddress = 0x00");
        require(address(_d11TokenAddress).isContract(), "d11TokenAddress != contract");
        d11TokenAddress = _d11TokenAddress;
    }

    /// @notice to set partner token address
    /// @dev to set/modify partner token address if decided to change for a reason, can only be called by admins
    /// @param _partnerTokenAddress address of the ERC20 partner token smart contract
    function setPartnerTokenAddress(IERC20 _partnerTokenAddress) external onlyAdmin {
        require(address(_partnerTokenAddress) != address(0), "partnerTokenAddress = 0x00");
        require(address(_partnerTokenAddress).isContract(), "partnerTokenAddress != contract");
        partnerTokenAddress = _partnerTokenAddress;
    }

    /// @notice to set swap ratio
    /// @dev to set/modify swap ratio if decided to change for a reason, can only be called by admins
    /// @param _swapRatio integer value defining the swap ratio eg 1:100 = 100 swap ratio
    function setSwapRatio(uint256 _swapRatio) external onlyAdmin {
        require(_swapRatio > 0, "swapRatio = zero || -ve");
        swapRatio = _swapRatio;
    }

    /* 
        MUTATIVE FUNCTIONS
    */

    /// @notice to swap D11 token with partner token, approve before call
    /// @dev to swap D11 token with partner token with the swapped ratio, can be called by anyone
    /// @param d11TokenAmount amount of D11 token to be swapped with partner token
    /// @return bool true if swap is successful otherwise false
    function swapD11Token(uint256 d11TokenAmount) external whenNotPaused nonReentrant returns (bool) {
        require(d11TokenAmount > 0, "d11TokenAmount < 0");
        require(IERC20(d11TokenAddress).balanceOf(_msgSender()) >= d11TokenAmount, "insufficient D11 token");

        uint256 swapAmount = d11TokenAmount.div(swapRatio);
        require(swapAmount > 0, "swapAmount = zero || -ve");
        require(IERC20(partnerTokenAddress).balanceOf(address(this)) >= swapAmount, "insufficient partner token");

        // Transfer D11 token to smart contract
        bool successTransferD11Token = IERC20(d11TokenAddress).transferFrom(
            _msgSender(),
            address(this),
            d11TokenAmount
        );
        require(successTransferD11Token, "D11 token swap failed");

        // Burn D11 token
        bool successBurnD11Token = IERC20(d11TokenAddress).transfer(deadAddr, d11TokenAmount);
        require(successBurnD11Token, "D11 token burn failed");

        // Transfer partner token to user
        bool successTransferPartnerToken = IERC20(partnerTokenAddress).transfer(_msgSender(), swapAmount);
        require(successTransferPartnerToken, "partner token transfer failed");

        emit TokenSwapped(_msgSender(), d11TokenAmount, swapAmount);
        return true;
    }

    /* 
        Withdraw any IERC20 tokens accumulated in this contract
    */

    /// @notice to withdraw any ERC20 tokens accumulated in this contract
    /// @dev can only be called by the owner
    /// @param tokenAddress address of any ERC20 token that is accumulated in this contract
    function withdrawTokens(IERC20 tokenAddress) external onlyOwner {
        bool success = tokenAddress.transfer(owner(), tokenAddress.balanceOf(address(this)));
        require(success, "ERC20 token transfer failed");
    }
}