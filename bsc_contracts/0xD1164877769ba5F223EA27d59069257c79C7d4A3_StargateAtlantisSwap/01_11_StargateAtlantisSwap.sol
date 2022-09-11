// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;
pragma abicoder v2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStargateRouter.sol";
import "./interfaces/IStargateRouterETH.sol";
import "./interfaces/IStargateFactory.sol";
import "./interfaces/IStargateAtlantisSwap.sol";

contract StargateAtlantisSwap is ReentrancyGuard, IStargateAtlantisSwap {
    using SafeERC20 for IERC20;

    IStargateRouter public immutable stargateRouter;
    IStargateRouterETH public immutable stargateRouterETH;
    IStargateFactory public immutable stargateFactory;
    uint256 public constant TENTH_BPS_DENOMINATOR = 100000;
    uint256 public constant MAX_UINT = 2**256 - 1;
    bytes2 public constant PARTNER_ID = 0x0003;

    mapping(address => bool) public tokenApproved;

    constructor(address _stargateRouter, address _stargateRouterETH, address _stargateFactory) {
        stargateRouter = IStargateRouter(_stargateRouter);
        stargateRouterETH = IStargateRouterETH(_stargateRouterETH);
        stargateFactory = IStargateFactory(_stargateFactory);
    }

    // allow anyone to emit this msg alongside their stargate tx so they can get credited for their referral
    // to get credit this event must be emitted in the same tx as a stargate swap event
    function partnerSwap(bytes2 _partnerId) external override {
        emit PartnerSwap(_partnerId);
    }

    function swapTokens(
        uint16 _dstChainId,
        uint16 _srcPoolId,
        uint16 _dstPoolId,
        uint256 _amountLD,
        uint256 _minAmountLD,
        IStargateRouter.lzTxObj calldata _lzTxParams,
        bytes calldata _to,
        FeeObj calldata _feeObj
    ) external override nonReentrant payable {
        uint256 atlantisFee = _getAndPayAtlantisFee(_srcPoolId, _amountLD, _feeObj);

        stargateRouter.swap{value:msg.value}(
            _dstChainId,
            _srcPoolId,
            _dstPoolId,
            payable(msg.sender),
            _amountLD - atlantisFee,
            _minAmountLD,
            _lzTxParams,
            _to,
            "0x"
        );

        emit StargateAtlantisSwapped(PARTNER_ID, _feeObj.tenthBps, atlantisFee);
    }

    function swapETH(
        uint16 _dstChainId,
        uint256 _amountLD,
        uint256 _minAmountLD,
        bytes calldata _to,
        FeeObj calldata _feeObj
    ) external override nonReentrant payable {
        // allows us to deploy same contract on non eth chains
        require(address(stargateRouterETH) != address(0x0), "StargateAtlantisSwap: func not available");

        uint256 atlantisFee = _getAndPayAtlantisFeeETH(_amountLD, _feeObj);

        // "value:" contains the amount of eth to swap and the stargate/layerZero fees, minus the atlantis fee
        stargateRouterETH.swapETH{value:msg.value - atlantisFee}(
            _dstChainId,
            payable(msg.sender),
            _to,
            _amountLD - atlantisFee,
            _minAmountLD
        );

        emit StargateAtlantisSwapped(PARTNER_ID, _feeObj.tenthBps, atlantisFee);
    }

    function _getAndPayAtlantisFee(
        uint16 _srcPoolId,
        uint256 _amountLD,
        FeeObj calldata _feeObj
    ) internal returns (uint256 atlantisFee) {
        // corresponding token to the poolId
        address token = stargateFactory.getPool(_srcPoolId).token();

        // move all the tokens to this contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amountLD);

        // calculate the atlantisFee
        atlantisFee = _amountLD * _feeObj.tenthBps / TENTH_BPS_DENOMINATOR;

        // pay the atlantis fee
        IERC20(token).safeTransfer(_feeObj.feeCollector, atlantisFee);

        // only call max approval once
        if (!tokenApproved[token]) {
            tokenApproved[token] = true;
            // allow stargateRouter to spend the tokens to be transferred
            IERC20(token).safeApprove(address(stargateRouter), MAX_UINT);
        }
    }

    function _getAndPayAtlantisFeeETH(
        uint256 _amountLD,
        FeeObj calldata _feeObj
    ) internal returns (uint256 atlantisFee) {
        // calculate the atlantisFee
        atlantisFee = _amountLD * _feeObj.tenthBps / TENTH_BPS_DENOMINATOR;
        require(msg.value > atlantisFee, "StargateAtlantisSwap: not enough eth for atlantisFee");

        // verify theres enough eth to cover the amount to swap
        require(msg.value - atlantisFee > _amountLD, "StargateAtlantisSwap: not enough eth for swap");

        // pay the widget fee
        (bool success, ) = _feeObj.feeCollector.call{value: atlantisFee}("");
        require(success, "StargateAtlantisSwap: failed to transfer atlantisFee");

        return atlantisFee;
    }
}