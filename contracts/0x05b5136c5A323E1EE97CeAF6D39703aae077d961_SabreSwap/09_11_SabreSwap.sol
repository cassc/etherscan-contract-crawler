/*
Crafted with love by
Fueled on Bacon
https://fueledonbacon.com
*/
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './SabreSwapSellOffer.sol';
import './SabreSwapBuyOffer.sol';

/** @title SabreSwap */
contract SabreSwap is Ownable, SabreSwapSellOffer, SabreSwapBuyOffer {
    using EnumerableSet for EnumerableSet.AddressSet;

    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event SetTransferFee(uint256 transferFee);

    error TokenAlreadyAdded();
    error TokenNotYetAdded();
    error TokenAddressIsZero();
    error WrongTransferFee();
    error FailedToRetrieveFees();

    uint256 public transferFee;
    uint256 public balanceFees;

    EnumerableSet.AddressSet private _tokens;

    /** @param _transferFee must be between 1 and 10000 which represents 100% */
    constructor(uint256 _transferFee) {
        setTransferFee(_transferFee);
    }

    /** @notice sets a Sell Offer, should have allowance and balance in order call the function
     *  @param token address of whitelisted token
     *  @param amount amount of erc20 token to sell
     *  @param pricePerToken price in ETH for each token
     */
    function setSellOffer(
        address token,
        uint256 amount,
        uint256 pricePerToken
    ) external {
        if (!_tokens.contains(token)) revert TokenNotYetAdded();
        _setSellOffer(token, amount, pricePerToken);
    }

    /** @notice fulfills a Sell Offer, must be a payable function with the exact value
     * @param sellOfferPosition position of the Sell Offer stored in _sellOfferByPosition
     */
    function fulfillSellOffer(uint256 sellOfferPosition) external payable {
        uint256 takenFee = _fulfillSellOffer(sellOfferPosition, transferFee);
        balanceFees += takenFee;
    }

    /** @notice sets Buy Offer, must be a payable function with the exact value
     *  @param token address of whitelisted token
     *  @param amount amount of erc20 token to sell
     *  @param pricePerToken price in ETH for each token
     */
    function setBuyOffer(
        address token,
        uint256 amount,
        uint256 pricePerToken
    ) external payable {
        if (!_tokens.contains(token)) revert TokenNotYetAdded();
        _setBuyOffer(token, amount, pricePerToken);
    }

    /** @notice fulfills a Buy Offer, must have ERC20 token approval set
     *  @param buyOfferPosition position of the Buy Offer stored in _buyOfferByPosition
     */
    function fulfillBuyOffer(uint256 buyOfferPosition) external {
        uint256 takenFee = _fulfillBuyOffer(buyOfferPosition, transferFee);
        balanceFees += takenFee;
    }

    /** @notice Sets new transfer fee
     * @param _transferFee must be between 1 and 10000 which represents 100% 
     */
    function setTransferFee(uint256 _transferFee) public onlyOwner {
        if (_transferFee == 0 || _transferFee > 10000) revert WrongTransferFee();
        transferFee = _transferFee;
        emit SetTransferFee(_transferFee);
    }

    function withdrawFees(address receiver) external onlyOwner nonReentrant {
        (bool sent, ) = receiver.call{value: balanceFees}('');
        balanceFees = 0;
        if (!sent) revert FailedToRetrieveFees();
    }

    function addToken(address token) external onlyOwner {
        if (token == address(0)) revert TokenAddressIsZero();
        if (_tokens.contains(token)) revert TokenAlreadyAdded();
        _tokens.add(token);
        emit TokenAdded(token);
    }

    function removeToken(address token) external onlyOwner {
        if (token == address(0)) revert TokenAddressIsZero();
        if (!_tokens.contains(token)) revert TokenNotYetAdded();
        _tokens.remove(token);
        emit TokenRemoved(token);
    }

    function getTokens() external view returns (address[] memory) {
        return _tokens.values();
    }

    function isTokenAdded(address token) external view returns (bool) {
        return _tokens.contains(token);
    }
}