// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {TypeAndVersion} from "../interfaces/TypeAndVersion.sol";
import {ICelerMessageReceiver} from "../interfaces/ICelerMessageReceiver.sol";
import {ICelerMessageBus} from "../interfaces/ICelerMessageBus.sol";

/// @title CrossChainHub
/// @author kevincharm
/// @notice Either side of a cross-chain-enabled set of contracts should
///     extend this contract to be able to communicate.
/// @notice The operator must call {CrossChainHub-setKnownCrossChainHub} on
///     each side of the bridge to enable communication between contracts.
abstract contract CrossChainHub is
    TypeAndVersion,
    ICelerMessageReceiver,
    Initializable
{
    /// @notice This chain's Celer IM MessageHub
    address public celerMessageBus;

    /// @notice Max fee this contract is willing to pay to send a cross-chain
    ///     message (in wei)
    uint256 public maxCrossChainFee;

    /// @notice Known CrossChainHubs
    /// keccak256(crossChainHub, chainId) => isKnown
    mapping(bytes32 => bool) private crossChainHubs;

    /// @dev RESERVED
    uint256[47] private __CrossChainHub_gap;

    event MaxCrossChainFeeUpdated(uint256 oldMaxFee, uint256 newMaxFee);
    event MessageHubUpdated(address oldMessageHub, address newMessageHub);
    event CrossChainHubUpdated(
        uint256 chainId,
        address crossChainHub,
        bool isKnown
    );

    error UnknownMessageBus(address msgBus);
    error MessageTooShort(bytes message);
    error UnknownCrossChainHub(uint256 chainId, address crossChainHub);
    error CrossChainFeeTooHigh(uint256 fee, uint256 maxFee);
    error OnlySelfCallable();
    error UnknownRequest(uint256 requestId);

    constructor(bytes memory initData) {
        if (initData.length > 0) {
            (address celerMessageBus_, uint256 maxCrossChainFee_) = abi.decode(
                initData,
                (address, uint256)
            );
            __init(celerMessageBus_, maxCrossChainFee_);
        }

        _disableInitializers();
    }

    function __CrossChainHub_init(
        address celerMessageBus_,
        uint256 maxCrossChainFee_
    ) internal onlyInitializing {
        __init(celerMessageBus_, maxCrossChainFee_);
    }

    function __init(
        address celerMessageBus_,
        uint256 maxCrossChainFee_
    ) private {
        _setMessageBus(celerMessageBus_);
        _setMaxCrossChainFee(maxCrossChainFee_);
    }

    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert OnlySelfCallable();
        }
        _;
    }

    function _setMessageBus(address celerMessageBus_) internal {
        address oldMessageHub = celerMessageBus;
        celerMessageBus = celerMessageBus_;
        emit MessageHubUpdated(oldMessageHub, celerMessageBus_);
    }

    function _setMaxCrossChainFee(uint256 newMaxFee) internal {
        uint256 oldMaxFee = maxCrossChainFee;
        maxCrossChainFee = newMaxFee;
        emit MaxCrossChainFeeUpdated(oldMaxFee, newMaxFee);
    }

    /// @notice See {TypeAndVersion-typeAndVersion}
    function typeAndVersion()
        external
        pure
        virtual
        override
        returns (string memory)
    {
        return "CrossChainHub 1.0.0";
    }

    /// @notice Determine whether a CrossChainHub contract address on another
    ///     chain is *known*. A known CrossChainHub contract address may call
    ///     cross-chain-enabled functions on this contract via `executeMessage`
    /// @param chainId Chain ID where CrossChainHub contract lives
    /// @param crossChainHub Address of CrossChainHub on other chain
    function isKnownCrossChainHub(
        uint256 chainId,
        address crossChainHub
    ) public view returns (bool) {
        return crossChainHubs[keccak256(abi.encode(crossChainHub, chainId))];
    }

    /// @notice Record whether a CrossChainHub contract address on another
    ///     chain is *known*. A known CrossChainHub contract address may call
    ///     cross-chain-enabled functions on this contract via `executeMessage`
    /// @param chainId Chain ID where CrossChainHub contract lives
    /// @param crossChainHub Address of CrossChainHub on other chain
    /// @param isKnown whether it should be known or not
    function _setKnownCrossChainHub(
        uint256 chainId,
        address crossChainHub,
        bool isKnown
    ) internal {
        crossChainHubs[keccak256(abi.encode(crossChainHub, chainId))] = isKnown;
        emit CrossChainHubUpdated(chainId, crossChainHub, isKnown);
    }

    function _sendCrossChainMessage(
        uint256 destChainId,
        address destCrossChainHub,
        uint8 action,
        bytes memory data
    ) internal {
        bytes memory message = abi.encode(action, data);
        uint256 fee = ICelerMessageBus(celerMessageBus).calcFee(message);
        if (fee > maxCrossChainFee) {
            revert CrossChainFeeTooHigh(fee, maxCrossChainFee);
        }
        ICelerMessageBus(celerMessageBus).sendMessage{value: fee}(
            destCrossChainHub,
            destChainId,
            message
        );
    }

    /// @notice Receive messages from a CrossChainHub on another chain via
    ///     Celer IM's MessageBus on this chain.
    /// @param sender Address of CrossChainHub on other chain
    /// @param srcChainId Chain ID where this message came from
    /// @param message Message
    /// @param executor Executor that delivered this message on this chain
    function executeMessage(
        address sender,
        uint64 srcChainId,
        bytes calldata message,
        address executor
    ) external virtual override returns (ExecutionStatus) {
        if (msg.sender != celerMessageBus) {
            revert UnknownMessageBus(msg.sender);
        }
        if (!isKnownCrossChainHub(srcChainId, sender)) {
            revert UnknownCrossChainHub(srcChainId, sender);
        }
        // At this point, we know this is a valid message from a known hub

        if (message.length < 1) {
            // Message must contain at least action[1B]
            revert MessageTooShort(message);
        }

        _executeValidatedMessage(sender, srcChainId, message, executor);
        return ExecutionStatus.Success;
    }

    function _executeValidatedMessage(
        address sender,
        uint64 srcChainId,
        bytes calldata message,
        address executor
    ) internal virtual;
}