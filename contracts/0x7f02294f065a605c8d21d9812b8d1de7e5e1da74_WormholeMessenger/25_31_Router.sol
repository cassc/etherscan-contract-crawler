// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {MessengerProtocol} from "./interfaces/IBridge.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pool} from "./Pool.sol";

abstract contract Router is Ownable, IRouter {
    using SafeERC20 for ERC20;
    uint private immutable chainPrecision;
    uint internal constant ORACLE_PRECISION = 18;

    mapping(bytes32 tokenId => Pool) public pools;
    // precomputed values to divide by to change the precision from the Gas Oracle precision to the token precision
    mapping(address tokenAddress => uint scalingFactor) internal fromGasOracleScalingFactor;
    // precomputed values of the scaling factor required for paying the bridging fee with stable tokens
    mapping(address tokenAddress => uint scalingFactor) internal bridgingFeeConversionScalingFactor;

    // can restrict swap operations
    address private stopAuthority;

    /**
     * @dev The rebalancer is an account responsible for balancing the liquidity pools. It ensures that the pool is
     * balanced by executing zero-fee swaps when the pool is imbalanced.
     *
     * Gas optimization: both the 'rebalancer' and 'canSwap' fields are used in the 'swap' and 'swapAndBridge'
     * functions and can occupy the same slot.
     */
    address private rebalancer;
    uint8 public override canSwap = 1;

    /**
     * @dev Emitted during the on-chain swap of tokens.
     */
    event Swapped(
        address sender,
        address recipient,
        bytes32 sendToken,
        bytes32 receiveToken,
        uint sendAmount,
        uint receiveAmount
    );

    constructor(uint chainPrecision_) {
        chainPrecision = chainPrecision_;
        stopAuthority = owner();
    }

    /**
     * @dev Modifier to make a function callable only when the swap is allowed.
     */
    modifier whenCanSwap() {
        require(canSwap == 1, "Router: swap prohibited");
        _;
    }

    /**
     * @dev Throws if called by any account other than the stopAuthority.
     */
    modifier onlyStopAuthority() {
        require(stopAuthority == msg.sender, "Router: is not stopAuthority");
        _;
    }

    /**
     * @notice Swaps a given pair of tokens on the same blockchain.
     * @param amount The amount of tokens to be swapped.
     * @param token The token to be swapped.
     * @param receiveToken The token to receive in exchange for the swapped token.
     * @param recipient The address to receive the tokens.
     * @param receiveAmountMin The minimum amount of tokens required to receive during the swap.
     */
    function swap(
        uint amount,
        bytes32 token,
        bytes32 receiveToken,
        address recipient,
        uint receiveAmountMin
    ) external override whenCanSwap {
        uint vUsdAmount = _sendAndSwapToVUsd(token, msg.sender, amount);
        uint receivedAmount = _receiveAndSwapFromVUsd(receiveToken, recipient, vUsdAmount, receiveAmountMin);
        emit Swapped(msg.sender, recipient, token, receiveToken, amount, receivedAmount);
    }

    /**
     * @notice Allows the admin to add new supported liquidity pools.
     * @dev Adds the address of the `Pool` contract to the list of supported liquidity pools.
     * @param pool The address of the `Pool` contract.
     * @param token The address of the token in the liquidity pool.
     */
    function addPool(Pool pool, bytes32 token) external onlyOwner {
        pools[token] = pool;
        address tokenAddress = address(uint160(uint(token)));
        uint tokenDecimals = ERC20(tokenAddress).decimals();
        bridgingFeeConversionScalingFactor[tokenAddress] = 10 ** (ORACLE_PRECISION - tokenDecimals + chainPrecision);
        fromGasOracleScalingFactor[tokenAddress] = 10 ** (ORACLE_PRECISION - tokenDecimals);
    }

    /**
     * @dev Switches off the possibility to make swaps.
     */
    function stopSwap() external onlyStopAuthority {
        canSwap = 0;
    }

    /**
     * @dev Switches on the possibility to make swaps.
     */
    function startSwap() external onlyOwner {
        canSwap = 1;
    }

    /**
     * @dev Allows the admin to set the address of the stopAuthority.
     */
    function setStopAuthority(address stopAuthority_) external onlyOwner {
        stopAuthority = stopAuthority_;
    }

    /**
     * @dev Allows the admin to set the address of the rebalancer.
     */
    function setRebalancer(address rebalancer_) external onlyOwner {
        rebalancer = rebalancer_;
    }

    function _receiveAndSwapFromVUsd(
        bytes32 token,
        address recipient,
        uint vUsdAmount,
        uint receiveAmountMin
    ) internal returns (uint) {
        Pool tokenPool = pools[token];
        require(address(tokenPool) != address(0), "Router: no receive pool");
        return tokenPool.swapFromVUsd(recipient, vUsdAmount, receiveAmountMin, recipient == rebalancer);
    }

    function _sendAndSwapToVUsd(bytes32 token, address user, uint amount) internal virtual returns (uint) {
        Pool pool = pools[token];
        require(address(pool) != address(0), "Router: no pool");
        ERC20(address(uint160(uint(token)))).safeTransferFrom(user, address(pool), amount);
        return pool.swapToVUsd(user, amount, user == rebalancer);
    }
}