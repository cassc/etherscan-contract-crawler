//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INftSales {
    function assignNftType(
        uint32[] calldata nftIDs,
        uint32[] calldata nftTypes
    ) external;

    function batchBuy(uint16 amount) external payable returns (uint32[] memory);

    function batchBuyNative(
        uint16 amount
    ) external payable returns (uint32[] memory);

    function batchMint(address receiver, uint32[] calldata nftTypes) external;

    function burn(uint32 tokenId) external;

    function buy() external returns (uint32);

    function buyNative() external payable returns (uint32);

    function evolve(
        uint32[] calldata nftIDs,
        uint32[] calldata nftTypes
    ) external;

    function mint(address receiver, uint32 nftType) external;

    function setIsNativePaymentActive(bool value) external;

    function setMaxSupply(uint256 value) external;

    function setNativePaymentAmount(uint256 value) external;

    function setPrice(uint256 value) external;

    function setSaleActive(bool value) external;

    function setTokenPayment(
        address _paymentToken,
        uint256 _paymentAmount
    ) external;

    function setTreasury(address _treasury) external;

    function withdrawNativeToTreasury() external;

    function withdrawTokensToTreasury(address tokenAddress) external;

    function batchSafeTransferFromSmallInt(
        address from,
        address to,
        uint32[] memory tokenIds,
        bytes memory data
    ) external;

    function batchTransferFromSmallInt(
        address from,
        address to,
        uint32[] memory tokenIds
    ) external;

    function isApprovedForAll(
        address _owner,
        address operator
    ) external view returns (bool);

    function airdrop(
        address[] calldata receivers,
        uint32[] calldata nftTypes
    ) external;

    function getNftTypeCount(
        address account,
        uint32 nftType
    ) external view returns (uint256);

    function getNftTypeCounts(
        address account,
        uint32[] calldata nftTypes
    ) external view returns (uint256 result);

    function getNftTypeForTokenID(
        uint32 tokenId
    ) external view returns (uint32);

    function getNftTypesForTokenIDs(
        uint32[] calldata tokenIds
    ) external view returns (uint32[] memory);

    function setNftTypeURI(uint32 nftTypeID, string calldata uri) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function setProxyState(address proxyAddress, bool value) external;

    function proxyToApproved(address _address) external view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function setBaseURI(string calldata uri) external;

    function setContractURI(string calldata uri) external;

    function setTokenURI(uint32 tokenId, string calldata uri) external;

    function contractURI() external view returns (string memory);

    function isOwnerOf(
        address account,
        uint32[] calldata tokenIds
    ) external view returns (bool);

    function getOwnerCount() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function approve(address to, uint256 tokenId) external;
}