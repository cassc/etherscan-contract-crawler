// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {SecurePool} from "./SecurePool.sol";
import {ISBT721} from "./interface/ISBT721.sol";

struct QuoteParameters {
    string quoteId;
    address fromAsset;
    address toAsset;
    uint256 fromAmount;
    uint256 toAmount;
    address lpIn;
    address user;
    uint256 tradeCompleteDeadline;
    uint256 quoteConfirmDeadline;
    address compensateToken;
    uint256 compensateAmount;
    uint256 mode;  // 0 fast mode, 1 normal mode
    uint256 chainid;
}

enum OrderStatus{
    PENDING,
    FINISH,
    DECLINE
}

enum CompensateStatus{
    NO,
    YES
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

struct QuoteInfoV2 {
    bytes32 quoteHash;
    OrderStatus status;
    CompensateStatus compensateStatus;
}

contract DexBase {
    /**
     * @notice
     * This emits when ownership transferred
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice
     * This emits when new owner accepted the ownership 
     */
    event OwnershipAccepted(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice
     * This emits when bab limit switch changed
     *
     * @param value True: bab token is required for swap
     */
    event BabTokenSet(address indexed babToken, bool value);

    /**
     * @notice
     * This emits when circuit breaker changed
     *
     * @param value True: break the new swap reuqests
     */
    event CircuitBreakerSet(bool value);

    /**
     * @notice
     * This emits when a pair added to whitelist 
     */
    event PairWhiteListAdded(address indexed lp, address token0, address token1);

    /**
     * @notice
     * This emits when pair removed from whitelist 
     */
    event PairWhiteListDeleted(address indexed lp, address token0, address token1);

    /**
     * @notice
     * This emits when a pair added to eligible liquidity provider list
     *
     * @param lpIn The lp deposit wallet address
     * @param lpOut The lp withdraw wallet address
     * @param signer The lp signer address which used to sign the quotation
     */
    event LiquidityProviderAdded(address indexed lpIn, address indexed lpOut, address indexed signer);

    /**
     * @notice
     * This emits when a pair removed from liquidity provider list
     *
     * @param lpIn The lp deposit wallet address
     * @param lpOut The lp withdraw wallet address
     * @param signer The lp signer address which used to sign the quotation
     */
    event LiquidityProviderDeleted(address indexed lpIn, address indexed lpOut, address indexed signer);

    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Native token address
    address constant BNB = address(0);

    // Owner of the contract
    address internal _owner;

    // Pending owner
    address internal _pendingOwner;
    
    // The token of Binance Account Bound Token(https://developers.binance.com/docs/babt/introduction)
    ISBT721 public babToken;

    // The switch of babt
    bool public babSwitch;

    // The switch of swap circuit breaker
    bool public circuitBreaker;

    // The secure pool which used to manage lp collaterals
    SecurePool public secure; 

    // The pair whiltelist map
    // out address => token pair
    mapping(address => mapping(address => mapping(address => uint256))) public whitelistPairToIndex;

    // The liquidityprovider map
    // out address 
    mapping(address => uint256) public liquidityProviders;
    
    // The liquidityprovider map
    // in address => out address
    mapping(address => address) public liquidityProviderMap;
    
    // The liquidityprovider signer map
    // out address => signer address
    mapping(address => address) public liquidityProviderSigner;

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

    /**
     * @notice
     * Query eligible trading pairs by liquidity provider
     *
     * @param lpOut Withdraw wallet of liquidity provider
     * @param tokenA Base token of pair
     * @param tokenB Quote token if pair
     */
    function queryWhitelist(address lpOut, address tokenA, address tokenB) external view returns(uint256) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == BNB) {
            return whitelistPairToIndex[lpOut][BNB][token1];
        } else {
            return (whitelistPairToIndex[lpOut][BNB][token0] & whitelistPairToIndex[lpOut][BNB][token1]);
        }
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

    /**
     * @notice
     * Setup address of BABT
     * 
     * @param newBabToken The BABT address, can't be zero address.
     */
    function setBabTokenAddress(address newBabToken) external onlyOwner {
        require(newBabToken != address(0), "DexBase: new BAB token is the zero address");
        babToken = ISBT721(newBabToken);

        emit BabTokenSet(newBabToken, babSwitch);
    }

    /**
     * @notice
     * Toggle the BABT switch limit
     *
     * @param value True: BABT is required to swap.
     */
    function setBabTokenSwitch(bool value) external onlyOwner {
        babSwitch = value;

        emit BabTokenSet(address(babToken), babSwitch);
    }

    /**
     * @notice
     * Toggle the circuit breaker switch
     * 
     * @param value True: break the new swap reuqests.
     */
    function setCircuitBreaker(bool value) external onlyOwner {
        circuitBreaker = value;

        emit CircuitBreakerSet(value);
    }

    /**
     * @notice
     * 
     * Add trading pair to liquidity provider
     *
     * @param lpOut Withdraw wallet of liquidity provider
     * @param tokenA Base token of pair
     * @param tokenB Quote token if pair
     */
    function addPairWhitelist(address lpOut, address tokenA, address tokenB) external onlyOwner {
        if (tokenA != BNB) {
            _addPairWhitelist(lpOut, tokenA, BNB);
        }
        if (tokenB != BNB) {
            _addPairWhitelist(lpOut, tokenB, BNB);
        }
    }

    /**
     * @notice
     * Batch add trading pair to liquidity provider
     *
     * @param lpOut Withdraw wallet of liquidity provider
     * @param tokenList Base token of pair
     */
    function addBatchPairWhitelist(address lpOut, address[] calldata tokenList) external onlyOwner {
        require(tokenList.length >= 1, "DexBase: at least one tokens");
        for (uint256 i; i < tokenList.length; i++) {
            _addPairWhitelist(lpOut, tokenList[i], BNB);
        }
    }

    /**
     * @notice
     * 
     * Remove trading pair from liquidity provider
     *
     * @param lpOut Withdraw wallet of liquidity provider
     * @param tokenA Base token of pair
     * @param tokenB Quote token if pair
     */
    function removePairWhitelist(address lpOut, address tokenA, address tokenB) external onlyOwner {
        if (tokenA != BNB) {
            _removePairWhitelist(lpOut, tokenA, BNB);
        }
        if (tokenB != BNB) {
            _removePairWhitelist(lpOut, tokenB, BNB);
        }
    }

    /**
     * @notice
     * Batch remove trading pair from liquidity provider
     *
     * @param lpOut Withdraw wallet of liquidity provider
     * @param tokenList Base token of pair
     */
    function removeBatchPairWhitelist(address lpOut, address[] calldata tokenList) external onlyOwner {
        require(tokenList.length >= 1, "DexBase: at least one tokens");
        for (uint256 i; i < tokenList.length; i++) {
            _removePairWhitelist(lpOut, tokenList[i], BNB);
        }
    }

    /**
     * @notice
     * Verify the eligibility of trading pair
     *
     * @param lpOut Withdraw wallet of liquidity provider
     * @param from Base token of pair
     * @param to Quote token of pair
     */
    function verifyPairWhitelist(address lpOut, address from, address to) internal view {
        (address token0, address token1) = from < to ? (from, to) : (to, from);
        if (token0 == BNB) {
            require(whitelistPairToIndex[lpOut][token0][token1] > 0, "DexBase: cannot swap non-whitelisted pair");
        } else {
            require(whitelistPairToIndex[lpOut][BNB][token0] > 0, "DexBase: cannot swap non-whitelisted pair");
            require(whitelistPairToIndex[lpOut][BNB][token1] > 0, "DexBase: cannot swap non-whitelisted pair");
        }
    }

    /**
     * @notice
     * Query the lock collaterals balance by lp address
     *
     * @param lpOut Withdraw wallet of liquidity provider
     */
    function liquidityProviderPending(address lpOut) public view returns(uint256) {
        return secure.queryPending(lpOut);
    }

    /**
     * @notice
     * Query the free collaterals balance by lp address
     *
     * @param lpOut Withdraw wallet of liquidity provider
     */
    function liquidityProviderSecure(address lpOut) public view returns(uint256) {
        return secure.querySecure(lpOut);
    }

    /**
     * @notice
     * Add a liduidity provider
     * 
     * @param lpIn The lp deposit wallet address
     * @param lpOut The lp withdraw wallet address
     * @param signer The lp signer address which used to sign the quotation
     */
    function addLiquidityProvider(address lpIn, address lpOut, address signer) external onlyOwner {
        require(lpIn != address(0) && lpOut != address(0), "DexBase: address is the zero address");

        // uint256 index2 = liquidityProviders[lpOut];
        // require(index2 == 0, "DexBase: addressOut is already liquidity provider");

        liquidityProviders[lpOut] = 1;
        liquidityProviderMap[lpIn] = lpOut;
        liquidityProviderSigner[lpOut] = signer;
        
        emit LiquidityProviderAdded(lpIn, lpOut, signer);
    }

    /**
     * @notice
     * Delete a liquidity provider

     * @param lpIn The lp deposit wallet address
     * @param lpOut The lp withdraw wallet address
     */
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

    /**
     * @notice
     * Lp add secure collaterals
     *
     * @param token_  The secure token address
     * @param amount_ The add amount
     */
    function addSecureFund(address token_, uint256 amount_) external payable onlyLiquidityProvider {
        _transferInSecureFund(msg.sender, token_, amount_);
    }

    /**
     * @notice Lp remove secure collaterals

     * @param token_  The secure token address
     * @param amount_ The remove amount
     */
    function removeSecureFund(address token_, uint256 amount_) external onlyLiquidityProvider {
        _transferOutSecureFund(msg.sender, token_, amount_);
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

    function _removePairWhitelist(address lpOut, address tokenA, address tokenB) internal {
        require(tokenA != tokenB, 'DexBase: identical token addresses');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (whitelistPairToIndex[lpOut][token0][token1] > 0) {
            delete whitelistPairToIndex[lpOut][token0][token1];
            emit PairWhiteListDeleted(lpOut, token0, token1);
        }
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