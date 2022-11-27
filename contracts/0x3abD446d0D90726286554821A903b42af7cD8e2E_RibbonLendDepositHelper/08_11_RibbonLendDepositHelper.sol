// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IPoolMaster} from "../interfaces/IPoolMaster.sol";
import {ICurvePool} from "../interfaces/RibbonLendDepositHelper/ICurvePool.sol";
import {ITokenDAI} from "../interfaces/RibbonLendDepositHelper/ITokenDAI.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * Earn Vault Error Codes
 * R1: USDT  exchange address is address(0)
 * R2: DAI   exchange address is address(0)
 * R3: GUSD  exchange address is address(0)
 * R4: SUSD  exchange address is address(0)
 * R5: FRAX  exchange address is address(0)
 * R6: MIM   exchange address is address(0)
 * R7: LUSD  exchange address is address(0)
 * R8: BUSD  exchange address is address(0)
 * R9: ALUSD exchange address is address(0)
 * R10: initial lend pools contain an address(0)
 * R11: invalid pool
 * R12: invalid amount
 * R13: new pool address input is address(0)
 * R14: not active pool
 * R15: invalid asset
 */


contract RibbonLendDepositHelper is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant GUSD = 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd;
    address public constant SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address public constant MIM = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;
    address public constant LUSD = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address public constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address public constant ALUSD = 0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9;

    IERC20 public constant usdc = IERC20(USDC);

    /// @notice Data for executing the swap
    /// @param exchange Address of the Curve exchange pool
    /// @param i Incoming token Curve identifier
    /// @param j Outgoing token Curve identifier
    /// @param underlying Defines if the swap is underlying
    struct SwapData {
        address exchange;
        int128 i;
        int128 j;
        bool underlying;
    }
    mapping(address => SwapData) public swapData;

    mapping(address => bool) public ribbonLendPools;

    /// @notice Contract's constructor
    /// @param initialRLendPools is the array with initial ribbon lending pool addresses
    /// @param _usdt is the struct with swap data related to USDT token
    /// @param _dai is the struct with swap data related to DAI token
    /// @param _gusd is the struct with swap data related to GUSD token
    /// @param _susd is the struct with swap data related to SUSD token
    /// @param _frax is the struct with swap data related to FRAX token
    /// @param _mim is the struct with swap data related to MIM token
    /// @param _lusd is the struct with swap data related to LUSD token
    /// @param _busd is the struct with swap data related to BUSD token
    /// @param _alusd is the struct with swap data related to ALUSD token
    constructor(
        address[] memory initialRLendPools,
        SwapData memory _usdt,
        SwapData memory _dai,
        SwapData memory _gusd,
        SwapData memory _susd,
        SwapData memory _frax,
        SwapData memory _mim,
        SwapData memory _lusd,
        SwapData memory _busd,
        SwapData memory _alusd
    ) {
        require(_usdt.exchange != address(0), "R1");
        require(_dai.exchange != address(0), "R2");
        require(_gusd.exchange != address(0), "R3");
        require(_susd.exchange != address(0), "R4");
        require(_frax.exchange != address(0), "R5");
        require(_mim.exchange != address(0), "R6");
        require(_lusd.exchange != address(0), "R7");
        require(_busd.exchange != address(0), "R8");
        require(_alusd.exchange != address(0), "R9");

        // Ribbon lending pool addresses
        for (uint256 i = 0; i < initialRLendPools.length; i++) {
            require(initialRLendPools[i] != address(0), "R10");
            ribbonLendPools[initialRLendPools[i]] = true;
        }

        // Swap data per token
        swapData[USDT] = _usdt;
        swapData[DAI] = _dai;
        swapData[GUSD] = _gusd;
        swapData[SUSD] = _susd;
        swapData[FRAX] = _frax;
        swapData[MIM] = _mim;
        swapData[LUSD] = _lusd;
        swapData[BUSD] = _busd;
        swapData[ALUSD] = _alusd;
    }

    /// @notice Function that swaps stablecoins to USDC on Curve and deposits into ribbon lend pool
    /// @dev Approval for desired amount of currency token should be given in prior
    /// @param amount Amount of stablecoin to swap
    /// @param asset Address of incoming token
    /// @param minAmountOut Minimum amount required to be received of USDC tokens
    /// @param ribbonLendPool Address of the ribbon lend pool to deposit into
    function deposit(
        uint256 amount,
        address asset,
        uint256 minAmountOut,
        address ribbonLendPool
    ) external {
        _deposit(amount, asset, minAmountOut, ribbonLendPool);
    }

    /// @notice Swaps DAI -> USDC on Curve's TriPool and deposits into ribbon lend pool
    /// @param amount Amount of DAI to swap
    /// @param minAmountOut Minimum amount required to be received of USDC tokens
    /// @param ribbonLendPool Address of the ribbon lend pool to deposit into
    /// @param nonce Nonce component of DAI's permit function
    /// @param expiry Expiry component of DAI's permit function
    /// @param allowed Allowed component of DAI's permit function
    /// @param v V component of permit signature
    /// @param r R component of permit signature
    /// @param s S component of permit signature
    function depositDAIWithPermit(
        uint256 amount,
        uint256 minAmountOut,
        address ribbonLendPool,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(ribbonLendPools[ribbonLendPool], "R11");
        require(amount > 0, "R12");

        ITokenDAI(DAI).permit(
            msg.sender,
            address(this),
            nonce,
            expiry,
            allowed,
            v,
            r,
            s
        );

        _deposit(amount, DAI, minAmountOut, ribbonLendPool);
    }

    /// @notice Function is used to add a new ribbon lending pool
    /// @param ribbonLendPool_ Address of the new pool to add
    function addRibbonLendPool(address ribbonLendPool_) external onlyOwner {
        require(ribbonLendPool_ != address(0), "R13");
        ribbonLendPools[ribbonLendPool_] = true;
    }

    /// @notice Function is used to remove a currently allowed ribbon lending pool
    /// @param ribbonLendPool_ Address of the pool to remove
    function removeRibbonLendPool(address ribbonLendPool_) external onlyOwner {
        require(ribbonLendPools[ribbonLendPool_], "R14");
        ribbonLendPools[ribbonLendPool_] = false;
    }

    /// @notice Function is used for the owner to withdraw tokens from the contract
    /// @param asset Address of the asset to withdraw
    function withdrawERC20(IERC20 asset) external onlyOwner {
        asset.safeTransfer(owner(), asset.balanceOf(address(this)));
    }

    /// @notice Internal function that swaps stablecoins to USDC on Curve and deposits into ribbon lend pool
    /// @param amount Amount of stablecoin to swap
    /// @param asset Address of incoming token
    /// @param minAmountOut Minimum amount required to be received of USDC tokens
    /// @param ribbonLendPool Address of the ribbon lend pool to deposit into
    function _deposit(
        uint256 amount,
        address asset,
        uint256 minAmountOut,
        address ribbonLendPool
    ) internal {
        require(swapData[asset].exchange != address(0), "R15");
        require(ribbonLendPools[ribbonLendPool], "R11");
        require(amount > 0, "R12");

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).safeApprove(swapData[asset].exchange, amount);

        uint256 usdcBalanceBefore = usdc.balanceOf(address(this));

        _swapOnCurve(
            swapData[asset].i,
            swapData[asset].j,
            amount,
            minAmountOut,
            swapData[asset].exchange,
            swapData[asset].underlying
        ); // swap to USDC

        uint256 usdcBalanceAfter = usdc.balanceOf(address(this));
        uint256 amountOut = usdcBalanceAfter.sub(usdcBalanceBefore);

        usdc.safeApprove(ribbonLendPool, amountOut);

        IPoolMaster(ribbonLendPool).provideFor(
            amountOut,
            address(0),
            msg.sender
        ); // deposit USDC amount
    }

    /// @notice Internal function swaps an amount of incoming token with its chosen pair on Curve's plain pools
    /// @param tokenInIndex Curve's pool index for the incoming token
    /// @param tokenOutIndex Curve's pool index for the outgoing token
    /// @param amount Amount of the incoming token to swap
    /// @param minAmountOut Minimum amount required to be received of the outgoing token
    /// @param exchange Address of the Curve exchange pool
    /// @param underlying Defines if the swap is underlying
    function _swapOnCurve(
        int128 tokenInIndex,
        int128 tokenOutIndex,
        uint256 amount,
        uint256 minAmountOut,
        address exchange,
        bool underlying
    ) internal {
        if (underlying) {
            ICurvePool(exchange).exchange_underlying(
                tokenInIndex,
                tokenOutIndex,
                amount,
                minAmountOut
            );
        } else {
            ICurvePool(exchange).exchange(
                tokenInIndex,
                tokenOutIndex,
                amount,
                minAmountOut
            );
        }
    }
}