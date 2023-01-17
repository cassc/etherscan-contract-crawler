// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Errors.sol";
import {IRoyaltyFeeRegistryV2} from "./interfaces/IRoyaltyFeeRegistryV2.sol";
import {RoyaltyFeeTypes} from "./libraries/RoyaltyFeeTypes.sol";

/**
 * @title RoyaltyFeeRegistryV2
 * @notice It is a royalty fee registry for the Joepeg exchange and auction house.
 */
contract RoyaltyFeeRegistryV2 is
    IRoyaltyFeeRegistryV2,
    Initializable,
    OwnableUpgradeable
{
    using RoyaltyFeeTypes for RoyaltyFeeTypes.FeeInfoPart;

    /// @notice Max royalty fee bp allowed (10,000 = 100%)
    uint256 public royaltyFeeLimit;

    /// @notice Max number of royalty fee recipients allowed
    uint8 public maxNumRecipients;

    /// @notice Stores royalty fee information for collections
    mapping(address => RoyaltyFeeTypes.FeeInfoPart[])
        public royaltyFeeInfoPartsCollection;

    /// @notice Stores setter address for collections whose royalty fee information
    /// are overridden
    mapping(address => address) public royaltyFeeInfoPartsCollectionSetter;

    event RoyaltyFeeLimitSet(
        uint256 oldRoyaltyFeeLimit,
        uint256 newRoyaltyFeeLimit
    );
    event MaxNumRecipientsSet(
        uint256 oldMaxNumRecipients,
        uint256 newMaxNumRecipients
    );
    event RoyaltyFeeInfoSet(
        address indexed collection,
        address indexed setter,
        RoyaltyFeeTypes.FeeInfoPart[] feeInfoParts
    );

    modifier isValidRoyaltyFeeLimit(uint256 _royaltyFeeLimit) {
        if (_royaltyFeeLimit > 9500) {
            revert RoyaltyFeeRegistryV2__RoyaltyFeeLimitTooHigh();
        }
        _;
    }

    modifier isValidMaxNumRecipients(uint256 _maxNumRecipients) {
        if (_maxNumRecipients == 0) {
            revert RoyaltyFeeRegistryV2__InvalidMaxNumRecipients();
        }
        _;
    }

    /**
     * @notice Initializer
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     * @param _maxNumRecipients new maximum number of royalty fee recipients allowed
     */
    function initialize(uint256 _royaltyFeeLimit, uint8 _maxNumRecipients)
        public
        initializer
    {
        __Ownable_init();

        _updateRoyaltyFeeLimit(_royaltyFeeLimit);
        _updateMaxNumRecipients(_maxNumRecipients);
    }

    /**
     * @notice Update royalty fee limit
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit)
        external
        override
        onlyOwner
    {
        _updateRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    /**
     * @notice Update royalty fee limit
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function _updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit)
        internal
        isValidRoyaltyFeeLimit(_royaltyFeeLimit)
    {
        uint256 oldRoyaltyFeeLimit = royaltyFeeLimit;
        royaltyFeeLimit = _royaltyFeeLimit;

        emit RoyaltyFeeLimitSet(oldRoyaltyFeeLimit, _royaltyFeeLimit);
    }

    /**
     * @notice Update `maxNumRecipients`
     * @param _maxNumRecipients new max number of recipients allowed
     */
    function updateMaxNumRecipients(uint8 _maxNumRecipients)
        external
        override
        onlyOwner
    {
        _updateMaxNumRecipients(_maxNumRecipients);
    }

    /**
     * @notice Update `maxNumRecipients`
     * @param _maxNumRecipients new max number of recipients allowed
     */
    function _updateMaxNumRecipients(uint8 _maxNumRecipients)
        internal
        isValidMaxNumRecipients(_maxNumRecipients)
        onlyOwner
    {
        uint8 oldMaxNumRecipients = maxNumRecipients;
        maxNumRecipients = _maxNumRecipients;

        emit MaxNumRecipientsSet(oldMaxNumRecipients, _maxNumRecipients);
    }

    /**
     * @notice Update royalty info for collection
     * @param _collection address of the NFT contract
     * @param _setter address that sets the receivers
     * @param _feeInfoParts contains receiver and fee information
     */
    function updateRoyaltyInfoPartsForCollection(
        address _collection,
        address _setter,
        RoyaltyFeeTypes.FeeInfoPart[] memory _feeInfoParts
    ) external override onlyOwner {
        uint256 numFeeInfoParts = _feeInfoParts.length;
        if (numFeeInfoParts > maxNumRecipients) {
            revert RoyaltyFeeRegistryV2__TooManyFeeRecipients();
        }
        if (_setter == address(0)) {
            revert RoyaltyFeeRegistryV2__RoyaltyFeeSetterCannotBeNullAddr();
        }

        delete royaltyFeeInfoPartsCollection[_collection];
        RoyaltyFeeTypes.FeeInfoPart[]
            storage feeInfoPartsForCollection = royaltyFeeInfoPartsCollection[
                _collection
            ];

        uint256 totalFees;

        for (uint256 i; i < numFeeInfoParts; i++) {
            RoyaltyFeeTypes.FeeInfoPart memory feeInfoPart = _feeInfoParts[i];
            if (feeInfoPart.receiver == address(0)) {
                revert RoyaltyFeeRegistryV2__RoyaltyFeeRecipientCannotBeNullAddr();
            }
            if (feeInfoPart.fee == 0) {
                revert RoyaltyFeeRegistryV2__RoyaltyFeeCannotBeZero();
            }
            totalFees += feeInfoPart.fee;
            feeInfoPartsForCollection.push(feeInfoPart);
        }

        if (totalFees > royaltyFeeLimit) {
            revert RoyaltyFeeRegistryV2__RoyaltyFeeTooHigh();
        }

        royaltyFeeInfoPartsCollectionSetter[_collection] = _setter;

        emit RoyaltyFeeInfoSet(_collection, _setter, _feeInfoParts);
    }

    /**
     * @notice Get royalty info for collection
     * @param _collection address of the NFT contract
     * @param _amount contains receiver and fee information
     */
    function royaltyAmountParts(address _collection, uint256 _amount)
        external
        view
        override
        returns (RoyaltyFeeTypes.FeeAmountPart[] memory)
    {
        RoyaltyFeeTypes.FeeInfoPart[]
            memory feeInfoParts = royaltyFeeInfoPartsCollection[_collection];
        uint256 numFeeInfoParts = feeInfoParts.length;
        RoyaltyFeeTypes.FeeAmountPart[]
            memory feeAmountParts = new RoyaltyFeeTypes.FeeAmountPart[](
                numFeeInfoParts
            );
        for (uint256 i; i < numFeeInfoParts; i++) {
            RoyaltyFeeTypes.FeeInfoPart memory feeInfoPart = feeInfoParts[i];
            feeAmountParts[i] = RoyaltyFeeTypes.FeeAmountPart({
                receiver: feeInfoPart.receiver,
                amount: (_amount * feeInfoPart.fee) / 10_000
            });
        }
        return feeAmountParts;
    }
}