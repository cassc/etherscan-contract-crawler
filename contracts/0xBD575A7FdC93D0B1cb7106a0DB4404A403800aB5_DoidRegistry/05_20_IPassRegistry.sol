pragma solidity ^0.8.0;

interface IPassRegistry {
    struct PassInfo {
        uint passId;
        bytes32 passClass;
        bytes32 passHash;
    }

    function getUserInvitedNumber(address _user) external view returns (uint, uint);

    function getUserByName(string memory _name) external view returns (address);

    function getNameByHash(bytes32 _hash) external view returns (string memory);

    function getPassByHash(bytes32 _hash) external view returns (uint);

    function getUserByHash(bytes32 _hash) external view returns (address);

    function getUserPassInfo(uint _passId) external view returns (PassInfo memory);

    function nameExists(string memory _name) external view returns (bool);

    function nameReserves(string memory _name) external view returns (bool);

    function exists(uint _passId) external view returns (bool);
}