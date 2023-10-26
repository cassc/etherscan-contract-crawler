pragma solidity 0.8.7;

interface IAccess {
    function isMinter(address _manager) external view returns (bool);

    function isOwner(address _manager) external view returns (bool);

    function isSender(address _manager) external view returns (bool);

    function isSigner(address _manager) external view returns (bool);

    function isTradeDesk(address _manager) external view returns (bool);

    function updateTradeDeskUsers(address _user, bool _isTradeDesk) external;

    function preAuthValidations(
        bytes32 message,
        bytes32 token,
        bytes memory signature
    ) external returns (address);
}