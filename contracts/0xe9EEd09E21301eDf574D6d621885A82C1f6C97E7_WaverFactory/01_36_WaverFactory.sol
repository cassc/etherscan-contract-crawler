// SPDX-License-Identifier: BSL
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./WaverImplementationDiamond.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WaverBeacon.sol";

/// [BSL License]
/// @title Proxy contract factory.
/// @notice A proxy contracts are created through the main contract.
/// @author Ismailov Altynbek <[email protected]>

contract WaverFactory is Ownable {
    WaverBeacon internal immutable thisWaverBeacon; //Beacon that routes to implementation addresses.
    address public WaverContractAddress; //Address of the main contract

    mapping(uint256 => address) public MarriageID; //Mapping of the proxy contract addresses by ID.

    /* Address of the proxy implementation has to be passed to the Factory*/
    constructor(address _implementation) {
        thisWaverBeacon = new WaverBeacon(_implementation);
        WaverContractAddress = msg.sender;
    }

    /**
     * @notice changing the address of the main contract.
     * @param _mainContract the address of the main contract.
     */

    function changeAddress(address _mainContract) public onlyOwner {
        WaverContractAddress = _mainContract;
    }

    /**
     * @notice View function to get the address of the beacon.
     */

    function getBeacon() public view returns (address) {
        return address(thisWaverBeacon);

        /**
         * @notice Getting the current address of the current implementation.
         */
    }

    function getimplementation() public view returns (address) {
        return thisWaverBeacon.implementation();
    }

    /**
     * @notice A method for creating proxy contracts.   
     * @dev Only the main contract address can create proxy contracts. Beacon proxy is created with 
     the current implementation. 
     * @param _addressWaveContract Address of the main contract.   
     * @param id Marriage ID assigned by the main contract.
     * @param _waver Address of the prpoposer.
     * @param _proposed Address of the proposed.
     * @param _cmFee CM fee, as a small percentage of incoming and outgoing transactions.
     * @param _divideShare the share that will be divided among partners upon dissolution.
     */

    function newMarriage(
        address _addressWaveContract,
        uint256 id,
        address _waver,
        address _proposed,
        uint256 _policyDays,
        uint256 _cmFee,
        uint256 _minimumDeadline,
        uint256 _divideShare,
        uint256 _promoDays
    ) public returns (address) {
        require(WaverContractAddress == msg.sender, "ACCESS DENIED");
        bytes memory dataOfnewMarriage = abi.encodeWithSelector(
            WaverIDiamond(payable(address(0))).initialize.selector,
            _addressWaveContract,
            id,
            _waver,
            _proposed,
            _policyDays,
            _cmFee,
            _minimumDeadline,
            _divideShare,
            _promoDays
        );

        BeaconProxy NewMarriageBeaconProxy = new BeaconProxy(
            address(thisWaverBeacon),
            dataOfnewMarriage
        );

        MarriageID[id] = address(NewMarriageBeaconProxy);
        return address(NewMarriageBeaconProxy);
    }
}