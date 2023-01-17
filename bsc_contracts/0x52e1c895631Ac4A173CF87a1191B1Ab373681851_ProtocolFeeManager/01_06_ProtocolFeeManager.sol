// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IProtocolFeeManager} from "./interfaces/IProtocolFeeManager.sol";

error ProtocolFeeManager__InvalidProtocolFee();

/**
 * @title ProtocolFeeManager
 * @notice Tracks and manages protocol fees for collections in the Joepeg Exchange
 */
contract ProtocolFeeManager is
    IProtocolFeeManager,
    Initializable,
    OwnableUpgradeable
{
    struct ProtocolFeeOverride {
        bool isOverridden;
        uint256 protocolFee;
    }

    /// @notice Default protocol fee, with precision 100 (e.g. 200 -> 2%)
    uint256 public override defaultProtocolFee;

    /// @notice Mapping of collections to custom protocol fee overrides
    mapping(address => ProtocolFeeOverride)
        public collectionProtocolFeeOverrides;

    event UpdateDefaultProtocolFee(
        address indexed user,
        uint256 defaultProtocolFee
    );
    event SetProtocolFeeForCollection(
        address indexed user,
        address indexed collection,
        uint256 protocolFee
    );
    event UnsetProtocolFeeForCollection(
        address indexed user,
        address indexed collection
    );

    modifier isValidProtocolFee(uint256 _protocolFee) {
        if (_protocolFee > 10000) {
            revert ProtocolFeeManager__InvalidProtocolFee();
        }
        _;
    }

    /**
     * @notice Initializer
     * @param _defaultProtocolFee default protocol fee
     */
    function initialize(uint256 _defaultProtocolFee)
        public
        initializer
        isValidProtocolFee(_defaultProtocolFee)
    {
        __Ownable_init();

        defaultProtocolFee = _defaultProtocolFee;
    }

    /**
     * @notice Updates `defaultProtocolFee`
     * @param _defaultProtocolFee new default protocol fee
     */
    function setDefaultProtocolFee(uint256 _defaultProtocolFee)
        external
        override
        onlyOwner
        isValidProtocolFee(_defaultProtocolFee)
    {
        defaultProtocolFee = _defaultProtocolFee;
        emit UpdateDefaultProtocolFee(msg.sender, _defaultProtocolFee);
    }

    /**
     * @notice Sets custom protocol fee for `_collection`
     * @param _collection address of collection to set custom protocol fee for
     * @param _protocolFee custom protocol fee
     */
    function setProtocolFeeForCollection(
        address _collection,
        uint256 _protocolFee
    ) external override onlyOwner isValidProtocolFee(_protocolFee) {
        collectionProtocolFeeOverrides[_collection] = ProtocolFeeOverride({
            isOverridden: true,
            protocolFee: _protocolFee
        });
        emit SetProtocolFeeForCollection(msg.sender, _collection, _protocolFee);
    }

    /**
     * @notice Unsets custom protocol fee for `_collection`
     * @param _collection address of collection to unset custom protocol fee for
     */
    function unsetProtocolFeeForCollection(address _collection)
        external
        override
        onlyOwner
    {
        collectionProtocolFeeOverrides[_collection] = ProtocolFeeOverride({
            isOverridden: false,
            protocolFee: 0
        });
        emit UnsetProtocolFeeForCollection(msg.sender, _collection);
    }

    /**
     * @notice Get protocol fee for a given `_collection`, falling back to
     * `defaultProtocolFee` if there is no custom protocol fee set
     * @param _collection address of collection to look up protocol fee for
     * @return protocol fee for `_collection`
     */
    function protocolFeeForCollection(address _collection)
        external
        view
        override
        returns (uint256)
    {
        ProtocolFeeOverride
            memory protocolFeeOverride = collectionProtocolFeeOverrides[
                _collection
            ];
        return
            protocolFeeOverride.isOverridden
                ? protocolFeeOverride.protocolFee
                : defaultProtocolFee;
    }
}