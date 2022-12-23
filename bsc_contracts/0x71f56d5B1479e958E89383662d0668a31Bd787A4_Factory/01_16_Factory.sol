//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IManagement.sol";
import "./interfaces/IProperty.sol";

contract Factory is IFactory, OwnableUpgradeable {
    bytes32 public constant VERSION = keccak256("BOOKING_V2");

    // linked management instance
    IManagement public management;

    // the upgrade beacon address of property contracts
    address private propertyBeacon;

    // returns the deployed property address for a given ID
    mapping(uint256 => address) public property;

    function init(address _management, address _beacon) external initializer {
        require(_management != address(0), "ZeroAddress");
        require(_beacon != address(0), "ZeroAddress");

        __Ownable_init();
        management = IManagement(_management);
        propertyBeacon = _beacon;
    }

    /**
       @notice Create a new property for host
       @dev    Caller must be Operator
       @param _propertyId The given property ID
       @param _host Address of property's host
       @param _delegate Address of delegate contract
     */
    function createProperty(
        uint256 _propertyId,
        address _host,
        address _delegate
    ) external returns (address _property) {
        require(_msgSender() == management.operator(), "OnlyOperator");
        require(_host != address(0) && _delegate != address(0), "ZeroAddress");
        require(property[_propertyId] == address(0), "PropertyExisted");

        bytes32 salt = keccak256(abi.encodePacked(_propertyId, VERSION));

        bytes memory bytecode = abi.encodePacked(
            type(BeaconProxy).creationCode,
            abi.encode(
                propertyBeacon,
                abi.encodeWithSelector(
                    IProperty.init.selector,
                    _propertyId,
                    _host,
                    address(management),
                    _delegate
                )
            )
        );

        _property = Create2Upgradeable.deploy(0, salt, bytecode);
        property[_propertyId] = _property;

        emit NewProperty(_propertyId, _property, _host);
    }
}