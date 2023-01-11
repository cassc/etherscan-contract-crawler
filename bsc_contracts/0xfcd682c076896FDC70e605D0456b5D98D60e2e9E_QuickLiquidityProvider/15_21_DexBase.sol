// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interface/ISBT721.sol";
import "./interface/IWETH.sol";
import "./SecurePool.sol";

contract DexBase {

    enum OrderStatus{ PENDING, FINISH, DECLINE }

    using SafeERC20Upgradeable for IERC20Upgradeable;

    address constant BNB = address(0);

    address internal _owner;
    address internal _pendingOwner;
    
    ISBT721 public babToken;
    bool public babSwitch;
    bool public circuitBreaker;

    SecurePool public secure; 

    mapping(address => mapping(address => mapping(address => uint256))) public whitelistPairToIndex;  // out address => token pair

    mapping(address => uint256) public liquidityProviders;          // out address 
    mapping(address => address) public liquidityProviderMap;        // in address => out address
    mapping(address => address) public liquidityProviderSigner;     // out address => signer address

    struct QuoteParameters {
        string quoteId;
        address fromAsset;
        address toAsset;
        uint256 fromAmount;
        uint256 toAmount;
        address lpIn;
        address user;
        uint tradeCompleteDeadline;
        uint quoteConfirmDeadline;
        address compensateToken;
        uint256 compensateAmount;
        uint mode; // 0 fast mode, 1 normal mode
        uint chainid;
    }

    struct QuoteInfo {
        string quoteId;
        address user;
        address lpIn;
        address lpOut;
        address lpSigner;
        address fromAsset;
        address toAsset;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 tradeExpireAt;
        address compensateToken;
        uint256 compensateAmount;
        OrderStatus status; 
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipAccepted(address indexed previousOwner, address indexed newOwner);
    event BabTokenSet(address indexed babToken, bool value);
    event CircuitBreakerSet(bool value);

    event PairWhiteListAdded(address indexed lp, address token0, address token1);
    event PairWhiteListDeleted(address indexed lp, address token0, address token1);

    event LiquidityProviderAdded(address indexed lpIn, address indexed lpOut, address indexed signer);
    event LiquidityProviderDeleted(address indexed lpIn, address indexed lpOut, address indexed signer);

    modifier onlyOwner() {
        require(_owner == msg.sender, "DexBase: caller is not the owner");
        _;
    }

    modifier onlyLiquidityProvider() {
        require(liquidityProviders[msg.sender] > 0, "DexBase: caller is not the liqidity provider");
        _;
    }

    modifier onlyBabtUser() {
        require(!babSwitch || babToken.balanceOf(msg.sender) > 0, "DexBase: caller is not a BABToken holder");
        _;
    }

    modifier isCircuitBreaker() {
        require(!circuitBreaker, "DexBase: circuit breaker is on");
        _;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "DexBase: new owner is the zero address");
        require(newOwner != _owner, "DexBase: new owner is the same as the current owner");

        emit OwnershipTransferred(_owner, newOwner);
        _pendingOwner = newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == _pendingOwner, "DexBase: invalid new owner");
        emit OwnershipAccepted(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }

    function setBabTokenAddress(address newBabToken) external onlyOwner {
        require(newBabToken != address(0), "DexBase: new BAB token is the zero address");
        babToken = ISBT721(newBabToken);
        emit BabTokenSet(address(babToken), babSwitch);
    }

    function setBabTokenSwitch(bool value) external onlyOwner {
        babSwitch = value;
        emit BabTokenSet(address(babToken), babSwitch);
    }

    function setCircuitBreaker(bool value) external onlyOwner {
        circuitBreaker = value;
        emit CircuitBreakerSet(value);
    }

    function queryWhitelist(address lpOut, address tokenA, address tokenB) external view returns(uint256) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return whitelistPairToIndex[lpOut][token0][token1];
    }

    function _addPairWhitelist(address lpOut, address tokenA, address tokenB) internal {
        require(tokenA != tokenB, 'DexBase: identical token addresses');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(lpOut != address(0), 'DexBase: zero address');
        if (whitelistPairToIndex[lpOut][token0][token1] == 0) {
            whitelistPairToIndex[lpOut][token0][token1] = 1;
            emit PairWhiteListAdded(lpOut, token0, token1);
        }
    }

    function addPairWhitelist(address lpOut, address tokenA, address tokenB) external onlyOwner {
        _addPairWhitelist(lpOut, tokenA, tokenB);
    }

    function addBatchPairWhitelist(address lpOut, address[] calldata tokenList) external onlyOwner {
        require(tokenList.length > 1, "DexBase: at least two tokens");
        for (uint i = 0; i < tokenList.length; i++) {
            for (uint j = i + 1; j < tokenList.length; j++) {
                _addPairWhitelist(lpOut, tokenList[i], tokenList[j]);
            }
        }
    } 

    function _removePairWhitelist(address lpOut, address tokenA, address tokenB) internal {
        require(tokenA != tokenB, 'DexBase: identical token addresses');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (whitelistPairToIndex[lpOut][token0][token1] > 0) {
            delete whitelistPairToIndex[lpOut][token0][token1];
            emit PairWhiteListDeleted(lpOut, token0, token1);
        }
    }

    function removePairWhitelist(address lpOut, address tokenA, address tokenB) external onlyOwner {
        _removePairWhitelist(lpOut, tokenA, tokenB);
    }

    function removeBatchPairWhitelist(address lpOut, address[] calldata tokenList) external onlyOwner {
        require(tokenList.length > 1, "DexBase: at least two tokens");
        for (uint i = 0; i < tokenList.length; i++) {
            for (uint j = i + 1; j < tokenList.length; j++) {
                _removePairWhitelist(lpOut, tokenList[i], tokenList[j]);
            }
        }
    }

    function verifyPairWhitelist(address lpOut, address from, address to) internal view {
        (address token0, address token1) = from < to ? (from, to) : (to, from);
        require(whitelistPairToIndex[lpOut][token0][token1] > 0, "DexBase: cannot swap non-whitelisted pair");
    }

    function liquidityProviderPending(address lpOut) public view returns(uint256) {
        return secure.queryPending(lpOut);
    }

    function liquidityProviderSecure(address lpOut) public view returns(uint256) {
        return secure.querySecure(lpOut);
    }

    function addLiquidityProvider(address lpIn, address lpOut, address signer) external onlyOwner {
        require(lpIn != address(0) && lpOut != address(0), "DexBase: address is the zero address");

        // uint256 index2 = liquidityProviders[lpOut];
        // require(index2 == 0, "DexBase: addressOut is already liquidity provider");

        liquidityProviders[lpOut] = 1;
        liquidityProviderMap[lpIn] = lpOut;
        liquidityProviderSigner[lpOut] = signer;
        emit LiquidityProviderAdded(lpIn, lpOut, signer);
    }

    function deleteLiquidityProvider(address lpIn, address lpOut) external onlyOwner {
        require(lpIn != address(0) && lpOut != address(0), "DexBase: address is the zero address");
        require(liquidityProviderPending(lpOut) == 0, "DexBase: there is still pending trasanction.");
        require(liquidityProviderSecure(lpOut) == 0, "DexBase: please remove all the secure fund before delete liquidity provider.");

        address signer = liquidityProviderSigner[lpOut];
        delete liquidityProviders[lpOut];
        delete liquidityProviderMap[lpIn];
        delete liquidityProviderSigner[lpOut];
        emit LiquidityProviderDeleted(lpIn, lpOut, signer);
    }

    function addSecureFund(address token_, uint256 amount_) external payable onlyLiquidityProvider {
        _transferInSecureFund(msg.sender, token_, amount_);
    }

    function removeSecureFund(address token_, uint256 amount_) external onlyLiquidityProvider {
        _transferOutSecureFund(msg.sender, token_, amount_);
    }

    function _transferInSecureFund(address from, address token_, uint256 amount_) internal {
        if (token_ == BNB) {
            require(amount_ == msg.value, "DexBase: msg value is not equal to amount");
            secure.addSecureFund{value: msg.value}(msg.sender, token_, amount_);
        } else {
            IERC20Upgradeable(token_).safeTransferFrom(msg.sender, address(this), amount_); // user -> dex
            IERC20Upgradeable(token_).safeIncreaseAllowance(address(secure), amount_); // dex -> secure approve
            secure.addSecureFund(msg.sender, token_, amount_);
        }
    }

    function _transferOutSecureFund(address to, address token_, uint256 amount_) internal {
        if (token_ == BNB) {
            secure.removeSecureFund(msg.sender, token_, amount_);
            _safeTransferETH(to, amount_);
        } else {
            secure.removeSecureFund(msg.sender, token_, amount_);
            IERC20Upgradeable(token_).safeTransfer(to, amount_);
        }
    }

    function _safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "DexBase: transfer bnb failed");
    }

    function _safeTransferAsset(address asset, address to, uint256 amount) internal {
        if (asset  == BNB) {
            require(address(this).balance >= amount, "DexBase: do not have enough ether");
            _safeTransferETH(to, amount);
        } else {
            require(IERC20Upgradeable(asset).balanceOf(address(this)) >= amount, "DexBase: do not have enough asset");
            IERC20Upgradeable(asset).safeTransfer(to, amount);
        }
    }

    function _safeTransferAssetFrom(address asset, address from, address to, uint256 amount) internal {
        if (asset != BNB) {
            IERC20Upgradeable(asset).safeTransferFrom(from, to, amount);
        }
    }

}