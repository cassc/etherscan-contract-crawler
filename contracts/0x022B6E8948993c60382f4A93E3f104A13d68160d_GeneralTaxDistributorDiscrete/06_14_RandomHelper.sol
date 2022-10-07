// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

library RandomHelper {
    uint256 constant GWEI_1 = 1000000000;
    uint256 constant MIN_GAS_X1000 = 20 * 1000;
    bytes32 constant SALT =
        0x2e0bbc5de4d611391441d62c8a6fc9439cc80a3e7ceaf4e6f85575437f187d5d;
    struct RandomState {
        bytes26 roll;
        uint32 gasPriceX1000;
        uint8 off;
    }

    /**
     * @dev Use this basis for guard against psuedo random actions. If the gas price is high, reduce
     * the probability of action taken.
     * gasPriceX1000 is 200 ema of the gas price
     */
    // function ramdomWeightX10000(uint64 gasPriceX1000)
    //     internal
    //     view
    //     returns (uint256 rollWeightX1000, uint16 newGasPriceX1000)
    // {
    //     if (gasPriceX1000 == 0) {
    //         gasPriceX1000 = uint64((1000 * tx.gasprice) / GWEI_1);
    //         if (gasPriceX1000 == 0) {
    //             // In case a custom chain has no gas price
    //             gasPriceX1000 = 1000;
    //         }
    //     }
    //     uint256 txGasP = (tx.gasprice * 1000) / GWEI_1;
    //     if (txGasP == 0) {
    //         // In case a custom chain has no gas price
    //         txGasP = 1000;
    //     }
    //     newGasPriceX1000 = uint16((gasPriceX1000 * 20 + txGasP) / 21);
    //     console.log("TX gp: %s, new %s", txGasP, newGasPriceX1000);
    //     if (txGasP > gasPriceX1000) {
    //         rollWeightX1000 = 0.2 * 1000; // minimum weight is 20%
    //     } else {
    //         if (txGasP < MIN_GAS_X1000) {
    //             rollWeightX1000 = 1000; // max weight is 100%
    //         } else {
    //             rollWeightX1000 =
    //                 1000 -
    //                 (1000 * (txGasP - MIN_GAS_X1000)) /
    //                 (gasPriceX1000);
    //             if (rollWeightX1000 < 100) {
    //                 rollWeightX1000 = 100;
    //             }
    //         }
    //     }
    // }

    /**
     * @dev This random function is 100% insecure. Only use it for non-crytical purposes.
     * For example; if you are trying to run a command periodically and want to trigger it on user transactions.
     */
    function rollingRand(bytes26 past, address current)
        internal
        pure
        returns (bytes26 newRoll, uint256 randX2p32)
    {
        newRoll = bytes26(keccak256(abi.encodePacked(past, SALT, current)));
        randX2p32 = uint32(bytes4(newRoll));
    }

    // function rollingRandBool(
    //     RandomState memory state,
    //     address current,
    //     uint256 lowThresholdX1000
    // ) internal view returns (RandomState memory _state, bool result) {
    //     (uint256 rollWeightX1000, uint16 newGasPriceX1000) =
    //         ramdomWeightX10000(state.gasPriceX1000);
    //     console.log(
    //         "RAND gasPrice: %s, new: %s, roll: %s",
    //         state.gasPriceX1000,
    //         newGasPriceX1000,
    //         rollWeightX1000
    //     );
    //     state.gasPriceX1000 = newGasPriceX1000;

    //     (bytes26 newRoll, uint256 randX2p32) = rollingRand(state.roll, current);
	// 	console.log("Random: %s", randX2p32 * 1000 / 2**32);
    //     state.roll = newRoll;
    //     _state = state;
    //     result = randX2p32 * rollWeightX1000 > (lowThresholdX1000 * 2**32);
    // }

    function rollingRandBool(
        RandomState memory state,
        address current,
        uint256 lowThresholdX1000
    ) internal pure returns (RandomState memory _state, bool result) {
        (bytes26 newRoll, uint256 randX2p32) = rollingRand(state.roll, current);
        state.roll = newRoll;
        _state = state;
        result = randX2p32 * 1000 > (lowThresholdX1000 * 2**32);
    }
}