pragma solidity ^0.8.13;

interface RegistryController {


    function setRegistryAddress(string memory fn, address value) external ;

    function setRegistryBool(string memory fn, bool value) external ;

    function setRegistryUINT(string memory key) external view returns (uint256) ;

    function setRegistryString(string memory fn, string memory value) external ;

    function setAdmin(address user,bool status ) external;

    function setAppAdmin(address app, address user, bool state) external;

}