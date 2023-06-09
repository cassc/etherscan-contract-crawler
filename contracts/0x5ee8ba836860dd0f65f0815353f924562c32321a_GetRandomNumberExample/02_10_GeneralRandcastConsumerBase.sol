// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {RequestIdBase} from "../utils/RequestIdBase.sol";
import {GasEstimationBase} from "../utils/GasEstimationBase.sol";
import {BasicRandcastConsumerBase, IAdapter} from "./BasicRandcastConsumerBase.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @notice This provides callbackGaslimit auto-calculating and TODO balance checking to save user's effort.
 */
abstract contract GeneralRandcastConsumerBase is
    BasicRandcastConsumerBase,
    RequestIdBase,
    GasEstimationBase,
    Ownable
{
    // Sets user seed as 0 to so that users don't have to pass it.
    uint256 private constant _USER_SEED_PLACEHOLDER = 0;
    // Default blocks the working group to wait before responding to the request.
    uint16 private constant _DEFAULT_REQUEST_CONFIRMATIONS = 6;
    // TODO Gives a fixed buffer so that some logic differ in the callback slightly raising gas used will be supported.
    uint32 private constant _GAS_FOR_CALLBACK_OVERHEAD = 30_000;
    // Dummy randomness for estimating gas of callback.
    uint256 private constant _RANDOMNESS_PLACEHOLDER =
        103921425973949831153159651530394295952228049817797655588722524414385831936256;
    uint32 private constant _MAX_GAS_LIMIT = 2000000;
    // Auto-calculating CallbackGasLimit in the first request call, also user can set it manually.
    uint32 public callbackGasLimit;
    // Auto-estimating CallbackMaxGasFee as 3 times tx.gasprice of the request call, also user can set it manually.
    // notes: tx.gasprice stands for effective_gas_price even post EIP-1559
    // priority_fee_per_gas = min(transaction.max_priority_fee_per_gas, transaction.max_fee_per_gas - block.base_fee_per_gas)
    // effective_gas_price = priority_fee_per_gas + block.base_fee_per_gas
    uint256 public callbackMaxGasFee;

    error GasLimitTooBig(uint256 have, uint32 want);

    function setCallbackGasConfig(uint32 _callbackGasLimit, uint256 _callbackMaxGasFee) external onlyOwner {
        if (_callbackGasLimit > _MAX_GAS_LIMIT) {
            revert GasLimitTooBig(_callbackGasLimit, _MAX_GAS_LIMIT);
        }
        callbackGasLimit = _callbackGasLimit;
        callbackMaxGasFee = _callbackMaxGasFee;
    }

    function _requestRandomness(RequestType requestType, bytes memory params)
        internal
        calculateCallbackGasLimit
        returns (bytes32)
    {
        uint256 rawSeed = _makeRandcastInputSeed(_USER_SEED_PLACEHOLDER, msg.sender, nonce);
        // This should be identical to adapter generated requestId.
        bytes32 requestId = _makeRequestId(rawSeed);
        // Only in the first place we calculate the callbackGasLimit, then next time we directly use it to request randomness.
        if (callbackGasLimit == 0) {
            // Prepares the message call of callback function according to request type
            bytes memory data;
            if (requestType == RequestType.Randomness) {
                data = abi.encodeWithSelector(this.rawFulfillRandomness.selector, requestId, _RANDOMNESS_PLACEHOLDER);
            } else if (requestType == RequestType.RandomWords) {
                uint32 numWords = abi.decode(params, (uint32));
                uint256[] memory randomWords = new uint256[](numWords);
                for (uint256 i = 0; i < numWords; i++) {
                    randomWords[i] = uint256(keccak256(abi.encode(_RANDOMNESS_PLACEHOLDER, i)));
                }
                data = abi.encodeWithSelector(this.rawFulfillRandomWords.selector, requestId, randomWords);
            } else if (requestType == RequestType.Shuffling) {
                uint32 upper = abi.decode(params, (uint32));
                uint256[] memory arr = new uint256[](upper);
                for (uint256 k = 0; k < upper; k++) {
                    arr[k] = k;
                }
                data = abi.encodeWithSelector(this.rawFulfillShuffledArray.selector, requestId, arr);
            }

            // We don't want message call for estimating gas to take effect, therefore success should be false,
            // and result should be the reverted reason, which in fact is gas used we encoded to string.
            (bool success, bytes memory result) =
            // solhint-disable-next-line avoid-low-level-calls
             address(this).call(abi.encodeWithSelector(this.requiredTxGas.selector, address(this), 0, data));

            // This will be 0 if message call for callback fails,
            // we pass this message to tell user that callback implementation need to be checked.
            uint256 gasUsed = _parseGasUsed(result);

            if (gasUsed > _MAX_GAS_LIMIT) {
                revert GasLimitTooBig(gasUsed, _MAX_GAS_LIMIT);
            }

            require(!success && gasUsed != 0, "fulfillRandomness dry-run failed");

            callbackGasLimit = uint32(gasUsed) + _GAS_FOR_CALLBACK_OVERHEAD;
        }
        return _rawRequestRandomness(
            requestType,
            params,
            IAdapter(adapter).getLastSubscription(address(this)),
            _USER_SEED_PLACEHOLDER,
            _DEFAULT_REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            callbackMaxGasFee == 0 ? tx.gasprice * 3 : callbackMaxGasFee
        );
    }
}