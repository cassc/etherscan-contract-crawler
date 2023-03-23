// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BaseController} from "./BaseController.sol";
import {ISocketRequest} from "../interfaces/ISocketRequest.sol";

/**
 * @title FeesTaker-Controller Implementation
 * @notice Controller with composed actions to deduct-fees followed by Refuel, Swap and Bridge
 *          to be executed Sequentially and this is atomic
 * @author Socket dot tech.
 */
contract FeesTakerController is BaseController {
    using SafeTransferLib for ERC20;

    /// @notice event emitted upon fee-deduction to fees-taker address
    event SocketFeesDeducted(
        uint256 fees,
        address feesToken,
        address feesTaker
    );

    /// @notice Function-selector to invoke deduct-fees and swap token
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_SWAP_FUNCTION_SELECTOR =
        bytes4(
            keccak256("takeFeesAndSwap((address,address,uint256,uint32,bytes))")
        );

    /// @notice Function-selector to invoke deduct-fees and bridge token
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "takeFeesAndBridge((address,address,uint256,uint32,bytes))"
            )
        );

    /// @notice Function-selector to invoke deduct-fees and bridge multiple tokens
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_MULTI_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "takeFeesAndMultiBridge((address,address,uint256,uint32[],bytes[]))"
            )
        );

    /// @notice Function-selector to invoke deduct-fees followed by swapping of a token and bridging the swapped bridge
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_SWAP_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "takeFeeAndSwapAndBridge((address,address,uint256,uint32,bytes,uint32,bytes))"
            )
        );

    /// @notice Function-selector to invoke deduct-fees refuel
    /// @notice followed by swapping of a token and bridging the swapped bridge
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_REFUEL_SWAP_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "takeFeeAndRefuelAndSwapAndBridge((address,address,uint256,uint32,bytes,uint32,bytes,uint32,bytes))"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BaseController
    constructor(
        address _socketGatewayAddress
    ) BaseController(_socketGatewayAddress) {}

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain and swap token
     * @dev ensure correct function selector is used to generate transaction-data for bridgeRequest
     * @param ftsRequest feesTakerSwapRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_SWAP_FUNCTION_SELECTOR
     * @return output bytes from the swap operation (last operation in the composed actions)
     */
    function takeFeesAndSwap(
        ISocketRequest.FeesTakerSwapRequest calldata ftsRequest
    ) external payable returns (bytes memory) {
        if (ftsRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(ftsRequest.feesTakerAddress).transfer(
                ftsRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(ftsRequest.feesToken).safeTransferFrom(
                msg.sender,
                ftsRequest.feesTakerAddress,
                ftsRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            ftsRequest.feesAmount,
            ftsRequest.feesTakerAddress,
            ftsRequest.feesToken
        );

        //call bridge function (executeRoute for the swapRequestData)
        return _executeRoute(ftsRequest.routeId, ftsRequest.swapRequestData);
    }

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain and bridge amount to destinationChain
     * @dev ensure correct function selector is used to generate transaction-data for bridgeRequest
     * @param ftbRequest feesTakerBridgeRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_BRIDGE_FUNCTION_SELECTOR
     * @return output bytes from the bridge operation (last operation in the composed actions)
     */
    function takeFeesAndBridge(
        ISocketRequest.FeesTakerBridgeRequest calldata ftbRequest
    ) external payable returns (bytes memory) {
        if (ftbRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(ftbRequest.feesTakerAddress).transfer(
                ftbRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(ftbRequest.feesToken).safeTransferFrom(
                msg.sender,
                ftbRequest.feesTakerAddress,
                ftbRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            ftbRequest.feesAmount,
            ftbRequest.feesTakerAddress,
            ftbRequest.feesToken
        );

        //call bridge function (executeRoute for the bridgeData)
        return _executeRoute(ftbRequest.routeId, ftbRequest.bridgeRequestData);
    }

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain and bridge amount to destinationChain
     * @notice multiple bridge-requests are to be generated and sequence and number of routeIds should match with the bridgeData array
     * @dev ensure correct function selector is used to generate transaction-data for bridgeRequest
     * @param ftmbRequest feesTakerMultiBridgeRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_MULTI_BRIDGE_FUNCTION_SELECTOR
     */
    function takeFeesAndMultiBridge(
        ISocketRequest.FeesTakerMultiBridgeRequest calldata ftmbRequest
    ) external payable {
        if (ftmbRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(ftmbRequest.feesTakerAddress).transfer(
                ftmbRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(ftmbRequest.feesToken).safeTransferFrom(
                msg.sender,
                ftmbRequest.feesTakerAddress,
                ftmbRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            ftmbRequest.feesAmount,
            ftmbRequest.feesTakerAddress,
            ftmbRequest.feesToken
        );

        // multiple bridge-requests are to be generated and sequence and number of routeIds should match with the bridgeData array
        for (
            uint256 index = 0;
            index < ftmbRequest.bridgeRouteIds.length;
            ++index
        ) {
            //call bridge function (executeRoute for the bridgeData)
            _executeRoute(
                ftmbRequest.bridgeRouteIds[index],
                ftmbRequest.bridgeRequestDataItems[index]
            );
        }
    }

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain followed by swap the amount on sourceChain followed by
     *         bridging the swapped amount to destinationChain
     * @dev while generating implData for swap and bridgeRequests, ensure correct function selector is used
     *      bridge action corresponds to the bridgeAfterSwap function of the bridgeImplementation
     * @param fsbRequest feesTakerSwapBridgeRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_SWAP_BRIDGE_FUNCTION_SELECTOR
     */
    function takeFeeAndSwapAndBridge(
        ISocketRequest.FeesTakerSwapBridgeRequest calldata fsbRequest
    ) external payable returns (bytes memory) {
        if (fsbRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(fsbRequest.feesTakerAddress).transfer(
                fsbRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(fsbRequest.feesToken).safeTransferFrom(
                msg.sender,
                fsbRequest.feesTakerAddress,
                fsbRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            fsbRequest.feesAmount,
            fsbRequest.feesTakerAddress,
            fsbRequest.feesToken
        );

        // execute swap operation
        bytes memory swapResponseData = _executeRoute(
            fsbRequest.swapRouteId,
            fsbRequest.swapData
        );

        uint256 swapAmount = abi.decode(swapResponseData, (uint256));

        // swapped amount is to be bridged to the recipient on destinationChain
        bytes memory bridgeImpldata = abi.encodeWithSelector(
            BRIDGE_AFTER_SWAP_SELECTOR,
            swapAmount,
            fsbRequest.bridgeData
        );

        // execute bridge operation and return the byte-data from response of bridge operation
        return _executeRoute(fsbRequest.bridgeRouteId, bridgeImpldata);
    }

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain followed by refuel followed by
     *          swap the amount on sourceChain followed by bridging the swapped amount to destinationChain
     * @dev while generating implData for refuel, swap and bridge Requests, ensure correct function selector is used
     *      bridge action corresponds to the bridgeAfterSwap function of the bridgeImplementation
     * @param frsbRequest feesTakerRefuelSwapBridgeRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_REFUEL_SWAP_BRIDGE_FUNCTION_SELECTOR
     */
    function takeFeeAndRefuelAndSwapAndBridge(
        ISocketRequest.FeesTakerRefuelSwapBridgeRequest calldata frsbRequest
    ) external payable returns (bytes memory) {
        if (frsbRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(frsbRequest.feesTakerAddress).transfer(
                frsbRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(frsbRequest.feesToken).safeTransferFrom(
                msg.sender,
                frsbRequest.feesTakerAddress,
                frsbRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            frsbRequest.feesAmount,
            frsbRequest.feesTakerAddress,
            frsbRequest.feesToken
        );

        // refuel is also done via bridge execution via refuelRouteImplementation identified by refuelRouteId
        _executeRoute(frsbRequest.refuelRouteId, frsbRequest.refuelData);

        // execute swap operation
        bytes memory swapResponseData = _executeRoute(
            frsbRequest.swapRouteId,
            frsbRequest.swapData
        );

        uint256 swapAmount = abi.decode(swapResponseData, (uint256));

        // swapped amount is to be bridged to the recipient on destinationChain
        bytes memory bridgeImpldata = abi.encodeWithSelector(
            BRIDGE_AFTER_SWAP_SELECTOR,
            swapAmount,
            frsbRequest.bridgeData
        );

        // execute bridge operation and return the byte-data from response of bridge operation
        return _executeRoute(frsbRequest.bridgeRouteId, bridgeImpldata);
    }
}