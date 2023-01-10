// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

pragma experimental ABIEncoderV2;


import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {Address} from "openzeppelin/utils/Address.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ILevelMaster} from "../interfaces/ILevelMaster.sol";
import {Babylonian} from "../lib/Babylonian.sol";

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract LevelZap is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct ZapInfo {
        uint256 pid;
        IERC20 token;
        bool inactive;
    }

    ZapInfo[] public zaps;
    ILevelMaster public levelMaster;
    IUniswapV2Router02 public uniRouter;

    address public wethAddress; // WETH

    constructor(
        address _levelMaster,
        address _uniRouter,
        address _weth
    ) {
        require(_levelMaster != address(0), "Zap::constructor: Invalid address");
        require(_uniRouter != address(0), "Zap::constructor: Invalid address");
        require(_weth != address(0), "Zap::constructor: Invalid address");
        levelMaster = ILevelMaster(_levelMaster);
        uniRouter = IUniswapV2Router02(_uniRouter);
        wethAddress = _weth;
    }

    function zap(
        uint256 _zapId,
        uint256 _minLiquidity,
        bool _transferResidual
    ) external payable nonReentrant {
        ZapInfo memory _info = zaps[_zapId];
        require(!_info.inactive, "Zap::zap: Zap configuration is inactive");
        uint256 _ethIn = msg.value;

        address _lp = levelMaster.lpToken(_info.pid);
        require(_lp != address(0), "Zap::zap: Invalid LP");

        // STEP 1: Swap or Mint token
        (uint256 _ethAmtToSwap, uint256 _tokenAmtToAddLP) = swap(_lp, _ethIn, address(_info.token));

        // STEP 2: Add liquditiy
        uint256 _ethAmtToAddLP = _ethIn - _ethAmtToSwap;
        approveToken(address(_info.token), address(uniRouter), _tokenAmtToAddLP);
        (uint256 _tokenAmtUsedInLp, uint256 _ethAmtUsedInLp, uint256 _liquidity) = uniRouter
            .addLiquidityETH{value: _ethAmtToAddLP}(
            address(_info.token),
            _tokenAmtToAddLP,
            1,
            1,
            address(this),
            block.timestamp
        );
        require(_liquidity >= _minLiquidity, "Zap::zap: Slippage. < minLiquidity");

        // STEP 3: Deposit LP to Farm
        approveToken(_lp, address(levelMaster), _liquidity);
        levelMaster.deposit(_info.pid, _liquidity, msg.sender);

        // STEP 4: Clean up dust
        if (_transferResidual) {
            if (_tokenAmtToAddLP > _tokenAmtUsedInLp) {
                _info.token.safeTransfer(msg.sender, _tokenAmtToAddLP - _tokenAmtUsedInLp);
            }
            if (_ethAmtToAddLP > _ethAmtUsedInLp) {
                Address.sendValue(payable(msg.sender), _ethAmtToAddLP - _ethAmtUsedInLp);
            }
        }

        emit Zapped(_zapId, _ethIn, _liquidity);
    }

    /// @notice fallback for payable -> required to receive ETH
    receive() external payable {}

    function swap(
        address _lp,
        uint256 _ethIn,
        address _token
    ) internal returns (uint256 _ethAmtToSwap, uint256 _tokenAmtReceived) {
        address _token0 = IUniswapV2Pair(_lp).token0();
        (uint256 _res0, uint256 _res1, ) = IUniswapV2Pair(_lp).getReserves();

        if (_token == _token0) {
            _ethAmtToSwap = calculateSwapInAmount(_res1, _ethIn);
        } else {
            _ethAmtToSwap = calculateSwapInAmount(_res0, _ethIn);
        }

        if (_ethAmtToSwap <= 0) _ethAmtToSwap = _ethIn / 2;
        _tokenAmtReceived = doSwapETH(_token, _ethAmtToSwap);
    }

    function doSwapETH(address _toToken, uint256 _ethAmt)
        internal
        returns (uint256 _tokenReceived)
    {
        address[] memory _path = new address[](2);
        _path[0] = wethAddress;
        _path[1] = _toToken;

        _tokenReceived = uniRouter.swapExactETHForTokens{value: _ethAmt}(
            1,
            _path,
            address(this),
            block.timestamp
        )[_path.length - 1];

        require(_tokenReceived > 0, "Zap::doSwapETH: Error Swapping Tokens 2");
    }

    function approveToken(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        IERC20 _erc20Token = IERC20(_token);
        _erc20Token.safeApprove(_spender, 0);
        _erc20Token.safeApprove(_spender, _amount);
    }

    function calculateSwapInAmount(uint256 _reserveIn, uint256 _tokenIn)
        internal
        pure
        returns (uint256)
    {
        uint256 swapFee = 25;
        uint256 D = 10000; // denominator
        uint256 R = D - swapFee; // r number

        return
            (Babylonian.sqrt(
                _reserveIn * ((_tokenIn * 4 * D * R) + (_reserveIn * (D + R) * (D + R)))
            ) - (_reserveIn * (R + D))) / (R * 2);
    }

    // ========= RESTRICTIVE FUNCTIONS ==============

    function addZap(address _token, uint256 _pid) external onlyOwner returns (uint256 _zapId) {
        require(_token != address(0), "Zap::addZap: Invalid address");
        zaps.push(ZapInfo({token: IERC20(_token), pid: _pid, inactive: false}));
        _zapId = zaps.length - 1;

        emit ZapAdded(_zapId, _token, _pid);
    }

    function removeZap(uint256 _zapId) external onlyOwner {
        require(zaps.length > _zapId, "Zap::removeZap: Invalid zapId");
        ZapInfo storage info = zaps[_zapId];
        info.inactive = true;

        emit ZapRemoved(_zapId);
    }

    // ========= EVENTS ==============
    event ZapAdded(uint256 _id, address _token, uint256 _pid);
    event ZapRemoved(uint256 _id);
    event Zapped(uint256 _zapId, uint256 _amount, uint256 _liquidity);
}