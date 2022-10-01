// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IProperty {
    enum PropertyStatus {
        INCOMPLETE,
        COMPLETE
    }

    struct PackageDetail {
        uint256 nft;
        uint256 xta;
    }

    function getPackages() external view returns (PackageDetail[] memory);

    function isMintedMaster() external view returns (bool);

    function mintMaster() external;

    function burnMaster(uint256 count) external;

    function getTokenIdList(address member) external view returns (uint256[] memory);

    function mintFragment(address to, uint256 amount) external;

    function transferOwnership(address owner) external;

    function propertyStatus() external view returns (PropertyStatus);

    function setPropertyStatus(PropertyStatus status) external;

    function setTokenURI(uint256 tokenId_, string memory tokenURI_) external;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function rerollData(uint256 index) external view returns(string memory);

    function tokenURI(uint256 tokenId_) external returns(string memory);

    function ownerOf(uint256 tokenId) external view returns (address);
}