pragma solidity ^0.8.0;

interface IMarketCreator {
    function creatorOnwer() external view returns (address);

    function getBeneficiary(uint256 partnerId) external view returns (address);

    function hasControllerRole(address user) external view returns (bool);

    function grantController(address user) external;

    function revokeController(address user) external;
}