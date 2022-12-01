// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IBridgeFactory {
    function getProjectNumber() external view returns (uint256);

    function getProjectAddress(uint256 id) external view returns (address);

    function _isAdmin(address _address) external view returns (bool);

    function addCompanyNFTsSold(
        address _buyer,
        uint256 _tokenId,
        uint256 _companyID,
        uint256 _quantity,
        uint256 _price,
        uint256 _projectId
    ) external;

    function addTotalRevueToCompany(
        uint256 _companyID,
        uint256 _price,
        uint256 _projectId
    ) external;

    function isOwner(address _projectAddress, address _sender) external view returns (bool);
}