pragma solidity 0.8.19;

interface IAccess {

    function isOwner(address _manager) external view returns (bool);

    function isSender(address _manager) external view returns (bool);

    function preAuthValidations(
        bytes32 message,
        bytes32 token,
        bytes memory signature
    ) external returns (address);
}