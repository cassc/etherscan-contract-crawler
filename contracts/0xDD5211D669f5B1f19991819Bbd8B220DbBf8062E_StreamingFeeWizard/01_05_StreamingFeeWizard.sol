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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IChamber} from "./interfaces/IChamber.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {IStreamingFeeWizard} from "./interfaces/IStreamingFeeWizard.sol";

contract StreamingFeeWizard is IStreamingFeeWizard, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 private constant ONE_YEAR_IN_SECONDS = 365.25 days;
    uint256 private constant SCALE_UNIT = 1 ether;
    mapping(IChamber => FeeState) public feeStates;

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the initial _feeState to the chamber. The chamber needs to exist beforehand.
     * Will revert if msg.sender is not a a manager from the _chamber. The feeState
     * is structured as:
     *
     * {
     *   feeRecipient:              address; [mandatory]
     *   maxStreamingFeePercentage: uint256; [mandatory] < 100%
     *   streamingFeePercentage:    address; [mandatory] <= maxStreamingFeePercentage
     *   lastCollectTimestamp:      address; [optional]  any value
     * }
     *
     * Consider [1 % = 10e18] for the fees
     *
     * @param _chamber  Chamber to enable
     * @param _feeState     First feeState of the Chamber
     */
    function enableChamber(IChamber _chamber, FeeState memory _feeState) external nonReentrant {
        require(IChamber(_chamber).isManager(msg.sender), "msg.sender is not chamber's manager");
        require(_feeState.feeRecipient != address(0), "Recipient cannot be null address");
        require(_feeState.maxStreamingFeePercentage <= 100 * SCALE_UNIT, "Max fee must be <= 100%");
        require(
            _feeState.streamingFeePercentage <= _feeState.maxStreamingFeePercentage,
            "Fee must be <= Max fee"
        );
        require(feeStates[_chamber].lastCollectTimestamp < 1, "Chamber already exists");

        _feeState.lastCollectTimestamp = block.timestamp;
        feeStates[_chamber] = _feeState;
    }

    /**
     * Calculates total inflation percentage. Mints new tokens in the Chamber for the
     * streaming fee recipient. Then calls the chamber to update its quantities.
     *
     * @param _chamber Chamber to acquire streaming fees from
     */
    function collectStreamingFee(IChamber _chamber) external nonReentrant {
        uint256 previousCollectTimestamp = feeStates[_chamber].lastCollectTimestamp;
        require(previousCollectTimestamp > 0, "Chamber does not exist");
        require(previousCollectTimestamp < block.timestamp, "Cannot collect twice");
        uint256 currentStreamingFeePercentage = feeStates[_chamber].streamingFeePercentage;
        require(currentStreamingFeePercentage > 0, "Chamber fee is zero");

        feeStates[_chamber].lastCollectTimestamp = block.timestamp;

        uint256 inflationQuantity =
            _collectStreamingFee(_chamber, previousCollectTimestamp, currentStreamingFeePercentage);

        emit FeeCollected(address(_chamber), currentStreamingFeePercentage, inflationQuantity);
    }

    /**
     * Will collect pending fees, and then update the streaming fee percentage for the Chamber
     * specified. Cannot be larger than the maximum fee. Will revert if msg.sender is not a
     * manager from the _chamber. To disable a chamber, set the streaming fee to zero.
     *
     * @param _chamber          Chamber to update streaming fee percentage
     * @param _newFeePercentage     New streaming fee in percentage [1 % = 10e18]
     */
    function updateStreamingFee(IChamber _chamber, uint256 _newFeePercentage)
        external
        nonReentrant
    {
        uint256 previousCollectTimestamp = feeStates[_chamber].lastCollectTimestamp;
        require(previousCollectTimestamp > 0, "Chamber does not exist");
        require(previousCollectTimestamp < block.timestamp, "Cannot update fee after collecting");
        require(IChamber(_chamber).isManager(msg.sender), "msg.sender is not chamber's manager");
        require(
            _newFeePercentage <= feeStates[_chamber].maxStreamingFeePercentage,
            "New fee is above maximum"
        );
        uint256 currentStreamingFeePercentage = feeStates[_chamber].streamingFeePercentage;

        feeStates[_chamber].lastCollectTimestamp = block.timestamp;
        feeStates[_chamber].streamingFeePercentage = _newFeePercentage;

        if (currentStreamingFeePercentage > 0) {
            uint256 inflationQuantity = _collectStreamingFee(
                _chamber, previousCollectTimestamp, currentStreamingFeePercentage
            );
            emit FeeCollected(address(_chamber), currentStreamingFeePercentage, inflationQuantity);
        }

        emit StreamingFeeUpdated(address(_chamber), _newFeePercentage);
    }

    /**
     * Will update the maximum streaming fee of a chamber. The _newMaxFeePercentage
     * can only be lower than the current maximum streaming fee, and cannot be greater
     * than the current streaming fee. Will revert if msg.sender is not a manager from
     * the _chamber.
     *
     * @param _chamber          Chamber to update max. streaming fee percentage
     * @param _newMaxFeePercentage  New max. streaming fee in percentage [1 % = 10e18]
     */
    function updateMaxStreamingFee(IChamber _chamber, uint256 _newMaxFeePercentage)
        external
        nonReentrant
    {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");
        require(IChamber(_chamber).isManager(msg.sender), "msg.sender is not chamber's manager");
        require(
            _newMaxFeePercentage <= feeStates[_chamber].maxStreamingFeePercentage,
            "New max fee is above maximum"
        );
        require(
            _newMaxFeePercentage >= feeStates[_chamber].streamingFeePercentage,
            "New max fee is below current fee"
        );

        feeStates[_chamber].maxStreamingFeePercentage = _newMaxFeePercentage;

        emit MaxStreamingFeeUpdated(address(_chamber), _newMaxFeePercentage);
    }

    /**
     * Update the streaming fee recipient for the Chamber specified. Will revert if msg.sender
     * is not a manager from the _chamber.
     *
     * @param _chamber          Chamber to update streaming fee recipient
     * @param _newFeeRecipient      New fee recipient address
     */
    function updateFeeRecipient(IChamber _chamber, address _newFeeRecipient)
        external
        nonReentrant
    {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");
        require(IChamber(_chamber).isManager(msg.sender), "msg.sender is not chamber's manager");
        require(_newFeeRecipient != address(0), "Recipient cannot be null address");
        feeStates[_chamber].feeRecipient = _newFeeRecipient;

        emit FeeRecipientUpdated(address(_chamber), _newFeeRecipient);
    }

    /**
     * Returns the streaming fee recipient of the AcrhChamber specified.
     *
     * @param _chamber Chamber to consult
     */
    function getStreamingFeeRecipient(IChamber _chamber) external view returns (address) {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");
        return feeStates[_chamber].feeRecipient;
    }

    /**
     * Returns the maximum streaming fee percetage of the AcrhChamber specified.
     * Consider [1 % = 10e18]
     *
     * @param _chamber Chamber to consult
     */
    function getMaxStreamingFeePercentage(IChamber _chamber) external view returns (uint256) {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");
        return feeStates[_chamber].maxStreamingFeePercentage;
    }

    /**
     * Returns the streaming fee percetage of the AcrhChamber specified.
     * Consider [1 % = 10e18]
     *
     * @param _chamber Chamber to consult
     */
    function getStreamingFeePercentage(IChamber _chamber) external view returns (uint256) {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");
        return feeStates[_chamber].streamingFeePercentage;
    }

    /**
     * Returns the last streaming fee timestamp of the AcrhChamber specified.
     *
     * @param _chamber Chamber to consult
     */
    function getLastCollectTimestamp(IChamber _chamber) external view returns (uint256) {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");
        return feeStates[_chamber].lastCollectTimestamp;
    }

    /**
     * Returns the fee state of a chamber as a tuple.
     *
     * @param _chamber Chamber to consult
     */
    function getFeeState(IChamber _chamber)
        external
        view
        returns (
            address feeRecipient,
            uint256 maxStreamingFeePercentage,
            uint256 streamingFeePercentage,
            uint256 lastCollectTimestamp
        )
    {
        require(feeStates[_chamber].lastCollectTimestamp > 0, "Chamber does not exist");

        feeRecipient = feeStates[_chamber].feeRecipient;
        maxStreamingFeePercentage = feeStates[_chamber].maxStreamingFeePercentage;
        streamingFeePercentage = feeStates[_chamber].streamingFeePercentage;
        lastCollectTimestamp = feeStates[_chamber].lastCollectTimestamp;
        return
            (feeRecipient, maxStreamingFeePercentage, streamingFeePercentage, lastCollectTimestamp);
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * Given the current supply of an Chamber, the last timestamp and the current streaming fee,
     * this function returns the inflation quantity to mint. The formula to calculate inflation quantity
     * is this:
     *
     * currentSupply * (streamingFee [10e18] / 100 [10e18]) * ((now [s] - last [s]) / one_year [s])
     *
     * @param _currentSupply            Chamber current supply
     * @param _lastCollectTimestamp     Last timestamp of collect
     * @param _streamingFeePercentage   Current streaming fee
     */
    function _calculateInflationQuantity(
        uint256 _currentSupply,
        uint256 _lastCollectTimestamp,
        uint256 _streamingFeePercentage
    ) internal view returns (uint256 inflationQuantity) {
        uint256 blockWindow = block.timestamp - _lastCollectTimestamp;
        uint256 inflation = _streamingFeePercentage * blockWindow;
        uint256 a = _currentSupply * inflation;
        uint256 b = ONE_YEAR_IN_SECONDS * (100 * SCALE_UNIT);
        return a / b;
    }

    /**
     * Performs the collect fee on the Chamber, considering the Chamber current supply,
     * the last collect timestamp and the streaming fee percentage provided. It calls the Chamber
     * to mint the inflation amount, and then calls it again so the Chamber can update its quantities.
     *
     * @param _chamber              Chamber to collect fees from
     * @param _lastCollectTimestamp     Last collect timestamp to consider
     * @param _streamingFeePercentage   Streaming fee percentage to consider
     */
    function _collectStreamingFee(
        IChamber _chamber,
        uint256 _lastCollectTimestamp,
        uint256 _streamingFeePercentage
    ) internal returns (uint256 inflationQuantity) {
        // Get chamber supply
        uint256 currentSupply = IERC20(address(_chamber)).totalSupply();

        // Calculate inflation quantity
        inflationQuantity = _calculateInflationQuantity(
            currentSupply, _lastCollectTimestamp, _streamingFeePercentage
        );

        // Mint the inlation quantity
        IChamber(_chamber).mint(feeStates[_chamber].feeRecipient, inflationQuantity);

        // Calculate chamber new quantities
        IChamber(_chamber).updateQuantities();

        // Return inflation quantity
        return inflationQuantity;
    }
}