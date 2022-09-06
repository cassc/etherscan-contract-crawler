// contracts/UnsIco.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IUnsIcoVestingWallet.sol";

contract UnsIcoEth is AccessControl {
    using SafeERC20 for IERC20;
    AggregatorV3Interface internal priceFeed;

    bytes32 public constant ICO_ADMIN_ROLE = keccak256("ICO_ADMIN_ROLE");

    address private _unsAddress;
    address private _icoVestingWallet;
    uint256 private _unsPrice = 300;
    uint256 private _totalSold = 0;

    mapping(address => bool) private _icoTokens;
    mapping(address => uint256) private _icoTokenDecimals;

    event UnsIcoWithEth(address indexed src, uint256 ethAmount, uint256 unsAmount);
    event UnsIcoWithToken(address indexed src, address indexed token, uint256 tokenAmount, uint256 unsAmount);
    event WithdrawToken(address indexed dest, uint256 amount, address indexed token);
    event WithdrawEth(address indexed dest, uint256 amount);
    event IcoTokenAdded(address indexed token);
    event IcoTokenRemoved(address indexed token);
    event PriceUpdated(uint256 amount);
    event SetIcoVestingWallet(address amount);

    constructor(address unsTokenAddress, address priceFeedAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ICO_ADMIN_ROLE, _msgSender());
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        _unsAddress = unsTokenAddress;
    }

    receive() external payable {
        require(msg.value > 0, "!zero");
        uint256 unsAmount = _usnForEth(msg.value);
        require(unsAmount > 0, "!unsAmount");
        require (IERC20(_unsAddress).transfer(_icoVestingWallet, unsAmount * 2), "!transfer");
        require (IUnsIcoVestingWallet(_icoVestingWallet).createVesting(_msgSender(), unsAmount * 2), "!createVesting");
        _totalSold += unsAmount;
        emit UnsIcoWithEth(_msgSender(), msg.value, unsAmount);
    }

    /**
     * @notice Function to buy UNS With Stable Token
     * @param token Address of stable token
     * @param amount Amount of tokens
     *
     */
    function buyUnsWithStableToken(
        IERC20 token,
        uint256 amount
    ) external {
        require(amount > 0, "!zero");
        require(_icoTokens[address(token)], "!icoToken");
        token.safeTransferFrom(_msgSender(), address(this), amount);
        uint256 unsAmount = _usnForStable(address(token), amount);
        require(unsAmount > 0, "!unsAmount");
        require (IERC20(_unsAddress).transfer(_icoVestingWallet, unsAmount * 2), "!transfer");
        require (IUnsIcoVestingWallet(_icoVestingWallet).createVesting(_msgSender(), unsAmount * 2), "!createVesting");
        _totalSold += unsAmount;
        emit UnsIcoWithToken(_msgSender(), address(token), amount, unsAmount);
    }

    /**
     * @notice Function to withdraw Token
     * Caller is assumed to be governance
     * @param token Address of token to be rescued
     * @param amount Amount of tokens
     *
     * Requirements:
     *
     * - the caller must have the `ICO_ADMIN_ROLE`.
     */
    function withdrawToken(
        IERC20 token,
        uint256 amount
    ) external onlyRole(ICO_ADMIN_ROLE) {
        require(amount > 0, "!zero");
        token.safeTransfer(_msgSender(), amount);
        emit WithdrawToken(_msgSender(), amount, address(token));
    }

    /**
     * @notice Function to withdraw Eth
     * Caller is assumed to be governance
     *
     * Requirements:
     *
     * - the caller must have the `ICO_ADMIN_ROLE`.
     */
    function withdrawEth() external onlyRole(ICO_ADMIN_ROLE) {
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            require(payable(_msgSender()).send(ethBalance), "!withdrawEth");
            emit WithdrawEth(_msgSender(), ethBalance);
        }
    }


    /**
     * @param token Address of token
     * @param decimals of token
     */
    function addIcoToken(address token, uint256 decimals) external onlyRole(ICO_ADMIN_ROLE) {
        require (!_icoTokens[token], "exists");
        _icoTokens[token] = true;
        _icoTokenDecimals[token] = decimals;
        emit IcoTokenAdded(token);
    }

    /**
     * @param token Address of token
     */
    function removeIcoToken(address token) external onlyRole(ICO_ADMIN_ROLE) {
        require (_icoTokens[token], "!exists");
        _icoTokens[token] = false;
        emit IcoTokenRemoved(token);
    }

    /**
     * @param icoVestingWalletAddress Address
     */
    function setIcoVesting(address icoVestingWalletAddress) external onlyRole(ICO_ADMIN_ROLE) {
        _icoVestingWallet = icoVestingWalletAddress;
        emit SetIcoVestingWallet(icoVestingWalletAddress);
    }

    /**
     * @param unsPriceAmount price of uns
     */
    function setUnsPrice(uint256 unsPriceAmount) external onlyRole(ICO_ADMIN_ROLE) {
        _unsPrice = unsPriceAmount;
        emit PriceUpdated(unsPriceAmount);
    }

    /**
     * @dev Returns `true` if `token` is `isIcoToken`.
     * @param token Address of token
     */
    function isIcoToken(address token) public view returns (bool) {
        return _icoTokens[token];
    }

    function usnForStable(address token, uint256 amount) public view returns (uint256 unsAmount) {
        return _usnForStable(token, amount);
    }

    function usnForEth(uint256 amount) public view returns(uint256 unsAmount){
        return _usnForEth(amount);
    }

    /**
     * @dev Returns the unsAddress.
     */
    function unsAddress() public view virtual returns (address) {
        return _unsAddress;
    }

    /**
     * @dev Returns the unsPrice.
     */
    function unsPrice() public view virtual returns (uint256) {
        return _unsPrice;
    }
    
    /**
     * @dev Returns the totalSold.
     */
    function totalSold() public view virtual returns (uint256) {
        return _totalSold;
    }

    /**
     * @dev Returns the icoVestingWallet.
     */
    function icoVestingWallet() public view virtual returns (address) {
        return _icoVestingWallet;
    }

    function _usnForStable(address token, uint256 amount) internal view returns (uint256) {
        require(_icoTokens[token], "!icoToken");
        uint256 _decimals = _icoTokenDecimals[token];
        require(_decimals <= 18);
        if (_decimals < 18) {
            _decimals = 18 - _decimals;
            amount = amount  * 10 ** _decimals;
        }
        return _usnForUsd(amount);
    }

    function _usnForEth(uint256 amount) internal view returns(uint256){
        (,int256 price,,,) = priceFeed.latestRoundData();
        price = price * 1e18;
        uint256 usdAmount = (uint256(price) * amount) / 1e18;
        return _usnForUsd(usdAmount / 1e8);
    }

    function _usnForUsd(uint256 usdAmount) internal view returns (uint256) {
        return (usdAmount * (10000)) / _unsPrice;
    }
}