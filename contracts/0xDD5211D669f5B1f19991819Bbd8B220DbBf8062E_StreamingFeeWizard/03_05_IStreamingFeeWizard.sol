/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

import {IChamber} from "./IChamber.sol";

interface IStreamingFeeWizard {
    /*//////////////////////////////////////////////////////////////
                              STRUCT
    //////////////////////////////////////////////////////////////*/

    struct FeeState {
        address feeRecipient;
        uint256 maxStreamingFeePercentage;
        uint256 streamingFeePercentage;
        uint256 lastCollectTimestamp;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event FeeCollected(
        address indexed _chamber, uint256 _streamingFeePercentage, uint256 _inflationQuantity
    );
    event StreamingFeeUpdated(address indexed _chamber, uint256 _newStreamingFee);
    event MaxStreamingFeeUpdated(address indexed _chamber, uint256 _newMaxStreamingFee);
    event FeeRecipientUpdated(address indexed _chamber, address _newFeeRecipient);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function enableChamber(IChamber _chamber, FeeState memory _feeState) external;
    function collectStreamingFee(IChamber _chamber) external;
    function updateStreamingFee(IChamber _chamber, uint256 _newFeePercentage) external;
    function updateMaxStreamingFee(IChamber _chamber, uint256 _newMaxFeePercentage) external;
    function updateFeeRecipient(IChamber _chamber, address _newFeeRecipient) external;
    function getStreamingFeeRecipient(IChamber _chamber) external view returns (address);
    function getMaxStreamingFeePercentage(IChamber _chamber) external view returns (uint256);
    function getStreamingFeePercentage(IChamber _chamber) external view returns (uint256);
    function getLastCollectTimestamp(IChamber _chamber) external view returns (uint256);
    function getFeeState(IChamber _chamber)
        external
        view
        returns (
            address feeRecipient,
            uint256 maxStreamingFeePercentage,
            uint256 streamingFeePercentage,
            uint256 lastCollectTimestamp
        );
}