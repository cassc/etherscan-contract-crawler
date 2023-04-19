// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../../ext-contracts/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../access/MerkleVerifier.sol";
import "../util/TimeRangeLib.sol";
import "../util/Errors.sol";

abstract contract PhasedSales is MerkleVerifier {
    SalesPhase[] public _salesPhases;
    mapping(uint8 => mapping(address => uint256)) public _usages;
    // mapping(bytes32 => mapping(address => uint256)) public _usages;
    IERC20 public _salesToken;

    constructor(IERC20 salesToken) {
        _salesToken = salesToken;
    }

    function _setSalesPhases(SalesPhase[] memory salesPhases) internal {
        while (_salesPhases.length > salesPhases.length) _salesPhases.pop();

        if (_salesPhases.length >= salesPhases.length) {
            for (uint i = 0; i < salesPhases.length; i++)
                _salesPhases[i] = salesPhases[i];
        }

        uint256 ind = _salesPhases.length;
        for (uint i = ind; i < salesPhases.length; i++)
            _salesPhases.push(salesPhases[i]);
    }

    function getSalesPhases() public view returns (SalesPhase[] memory) {
        return _salesPhases;
    }

    function _updateSalesPhase(
        uint8 phaseIndex,
        SalesPhase memory salesPhase
    ) internal {
        if (_salesPhases.length <= phaseIndex) revert InvalidValue();

        _salesPhases[phaseIndex] = salesPhase;
    }

    /* 
      don't forget the withdraw function implementation 
      in the contract that derives from this contract
    */
    function _buy(
        uint8 phaseIndex, // starts from zero
        uint256 amount,
        uint256 requestedAmount
    ) internal {
        if (phaseIndex + 1 > _salesPhases.length) revert InvalidValue();

        SalesPhase memory salesPhase = _salesPhases[phaseIndex];
        // if merkle hash is set. this _buy method cannot be called.
        // must be call buy method with merkle params for merkle verification
        if (salesPhase.merkleRootHash != bytes32(0x0)) revert InvalidCall();

        uint256 price = salesPhase.price;

        // check period
        TimeRangeLib.check(salesPhase.timeRange);

        if (
            salesPhase.amountLimiting &&
            _usages[phaseIndex][msg.sender] >= amount
        ) revert MaxAmountReached();

        _receivePayment(
            amount,
            requestedAmount,
            salesPhase.amountLimiting,
            price,
            phaseIndex
        );
    }

    function _buy(
        uint8 phaseIndex, // starts from zero
        uint256 amount,
        uint256 requestedAmount,
        bytes32[] calldata merkleProof
    ) internal {
        if (phaseIndex + 1 > _salesPhases.length) revert InvalidValue();

        SalesPhase memory salesPhase = _salesPhases[phaseIndex];
        uint256 price = salesPhase.price;

        if (price == 0 && salesPhase.merkleRootHash == bytes32(0x0))
            revert InvalidValue();

        // check period
        TimeRangeLib.check(salesPhase.timeRange);

        if (
            salesPhase.amountLimiting &&
            _usages[phaseIndex][msg.sender] >= amount
        ) revert MaxAmountReached();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));

        bool valid = isMerkleValid(
            leaf,
            merkleProof,
            salesPhase.merkleRootHash
        );
        if (!valid && phaseIndex > 0) {
            // check old phases
            for (uint8 i = phaseIndex; i > 0; i--) {
                salesPhase = _salesPhases[i - 1];

                // is there a price for current phase in the old phase
                // if not, continue with previous phase
                uint256[] memory prices = salesPhase.phasePrices;
                if (phaseIndex + 1 > prices.length) continue;

                price = prices[phaseIndex]; // current phase price for old phase
                bool amountOK = !salesPhase.amountLimiting;
                if (salesPhase.amountLimiting) {
                    uint256 usedAmount = _usages[i - 1][msg.sender];
                    uint256 remainingAmount = amount - usedAmount;
                    if (requestedAmount <= remainingAmount) amountOK = true;
                }

                // if the merkleRootHash is not already used in the old phase
                if (amountOK) {
                    valid = isMerkleValid(
                        leaf,
                        merkleProof,
                        salesPhase.merkleRootHash
                    );
                    if (valid) break;
                }
            }
        }

        if (!valid) revert MerkleVerificationEror();

        _receivePayment(
            amount,
            requestedAmount,
            salesPhase.amountLimiting,
            price,
            phaseIndex
        );
    }

    function _receivePayment(
        uint256 amount,
        uint256 requestedAmount,
        bool amountLimiting,
        uint256 price,
        uint8 phaseIndex
    ) private {
        if (amountLimiting) {
            uint256 usedAmount = _usages[phaseIndex][msg.sender];
            uint256 remainingAmount = amount - usedAmount;
            if (requestedAmount > remainingAmount) revert InvalidAmount();
        }

        _usages[phaseIndex][msg.sender] += requestedAmount;

        uint256 totalAmount = requestedAmount * price;
        if (totalAmount == 0) return;

        if (address(_salesToken) != address(0)) {
            bool transferOK = _salesToken.transferFrom(
                msg.sender,
                address(this),
                totalAmount
            );

            if (!transferOK) revert TransferFailed("");
        } else if (msg.value < totalAmount) {
            revert InsufficientAmount();
        }
    }
}

struct SalesPhase {
    bytes32 merkleRootHash;
    uint256 price;
    uint256[] phasePrices; //if can be bought at different phases
    StartEndTime timeRange;
    bool amountLimiting;
}