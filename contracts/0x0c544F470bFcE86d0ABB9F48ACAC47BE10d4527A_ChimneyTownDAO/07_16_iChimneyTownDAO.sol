// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

interface iChimneyTownDAO {

    //******************************
    // view functions
    //******************************
    function remainingForSale() external view returns (uint256);

    function remainingReserved() external view returns (uint256);

    function mintedSalesTokenIdList(
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory);

    function priceInWei() external view returns (uint256);

    function isOnSale() external view returns (bool);

    function merkleRoot() external view returns (bytes32);

    function isClaimed(address account) external view returns (bool);

    //******************************
    // public functions
    //******************************
    function mint(uint256 tokenId) external payable;

    function mintBatch(uint256[] memory tokenIdList) external payable;

    function claim(uint256 tokenId, bytes32[] calldata merkleProof) external payable;

    //******************************
    // admin functions
    //******************************
    function updateBaseURI(string memory url) external;

    function freezeMetadata() external;

    function mintReserve(uint256 quantity, address to) external;

    function setMerkleRoot(bytes32 merkleRoot) external;

    function setPrice(uint256 priceInWei) external;

    function setSaleStatus(bool isOnSale) external;

    function withdraw(address payable to, uint256 amountInWei) external;
}