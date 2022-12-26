pragma solidity ^0.8.4;

interface IWhiteList {
    function addAddress(address whiteListAddress) external returns (bool);

    function deleteAddress(address addressToDelete) external returns (bool);

    function getAddressesInWhiteList() external view returns (address[] memory);

    function getAddressesInWhiteListPaginated(
        uint256 offset,
        uint256 itemsAmount
    ) external returns (address[] memory);

    function isAddressWhiteListed(address addressToFind)
        external
        view
        returns (bool);

    function getWhiteListSize() external view returns (uint256);
}