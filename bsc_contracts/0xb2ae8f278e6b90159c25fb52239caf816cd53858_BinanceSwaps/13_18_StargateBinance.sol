//SPDX-License-Identifier: ISC

pragma solidity 0.8.17;

import {IStargateReceiver} from "../../interfaces/IStargateReceiver.sol";
import {IStargateRouter} from "../../interfaces/IStargateRouter.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBinanceSwaps} from "./interfaces/IBinanceSwaps.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

abstract contract StargateBinance is IStargateReceiver {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ///@notice address of the stargate router
    IStargateRouter public immutable stargateRouter;

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event ReceivedOnDestination(address indexed token, uint256 amountLD, bool failed, bool dustSent);

    error NotStgRouter();
    error NotEnoughGas();
    error MismatchedLengths();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IStargateRouter _stargateRouter) {
        stargateRouter = _stargateRouter;
    }

    ///@notice struct to define parameters needed for the swap.
    struct StargateParams {
        uint16 dstChainId; // stargate dst chain id
        address token; // token getting bridged
        uint256 srcPoolId; // stargate src pool id
        uint256 dstPoolId; // stargate dst pool id
        uint256 amount; // amount to bridge
        uint256 amountMin; // amount to bridge minimum
        uint256 dustAmount; // native token to be received on dst chain
        address receiver; // Mugen contract on dst chain
        address to; // receiver bridge token incase of transaction reverts on dst chain
        uint256 gas; // extra gas to be sent for dst chain operations
        bytes32 srcContext; // random bytes32 as source context
    }

    /*//////////////////////////////////////////////////////////////
                               INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param params parameters for the stargate router defined in StargateParams
    /// @param stepsDst an array of steps to be performed on the dst chain
    /// @param dataDst an array of data to be performed on the dst chain
    function stargateSwap(StargateParams memory params, uint8[] memory stepsDst, bytes[] memory dataDst) internal {
        if (stepsDst.length != dataDst.length) revert MismatchedLengths();
        if (params.gas < 100000) revert NotEnoughGas();
        bytes memory payload = abi.encode(params.to, stepsDst, dataDst);
        params.amount = params.amount != 0 ? params.amount : IERC20(params.token).balanceOf(address(this));
        if (IERC20(params.token).allowance(address(this), address(stargateRouter)) < params.amount) {
            IERC20(params.token).approve(address(stargateRouter), type(uint256).max);
        }
        IStargateRouter(stargateRouter).swap{value: address(this).balance}(
            params.dstChainId,
            params.srcPoolId,
            params.dstPoolId,
            payable(msg.sender),
            params.amount,
            params.amountMin,
            IStargateRouter.lzTxObj(params.gas, params.dustAmount, abi.encodePacked(params.receiver)),
            abi.encodePacked(params.receiver),
            payload
        );
    }

    function getFee(StargateParams memory params, bytes memory payload) external view returns (uint256 _fee) {
        bytes memory toAddress = abi.encodePacked(params.receiver);
        (_fee,) = IStargateRouter(stargateRouter).quoteLayerZeroFee(
            params.dstChainId,
            1,
            toAddress,
            payload,
            IStargateRouter.lzTxObj(params.gas, params.dustAmount, abi.encodePacked(params.receiver))
        );
    }

    /*//////////////////////////////////////////////////////////////
                               STARGATE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @param _token The token contract on the local chain
    /// @param amountLD The qty of local _token contract tokens
    /// @param _payload The bytes containing the toAddress
    function sgReceive(uint16, bytes memory, uint256, address _token, uint256 amountLD, bytes memory _payload)
        external
        override
    {
        if (msg.sender != address(stargateRouter)) revert NotStgRouter();

        bool failed;
        bool dustSent;

        uint256 reserveGas = 100000;
        uint256 limit = gasleft() - reserveGas;

        (address to, uint8[] memory steps, bytes[] memory data) = abi.decode(_payload, (address, uint8[], bytes[]));

        if (gasleft() < reserveGas) {
            IERC20(_token).safeTransfer(to, amountLD);
            /// @dev transfer any native token received as dust to the to address
            if (address(this).balance > 0) {
                SafeTransferLib.safeTransferETH(to, address(this).balance);
            }
        }

        try IBinanceSwaps(payable(address(this))).binanceSwaps{gas: limit}(steps, data) {}
        catch (bytes memory) {
            IERC20(_token).safeTransfer(to, amountLD);
            failed = true;
        }

        if (address(this).balance > 0) {
            SafeTransferLib.safeTransferETH(to, address(this).balance);
        }
        emit ReceivedOnDestination(_token, amountLD, failed, dustSent);
    }
}