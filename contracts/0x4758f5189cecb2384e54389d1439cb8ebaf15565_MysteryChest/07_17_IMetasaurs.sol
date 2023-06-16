// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IMetasaurs {
    function adminMint(uint256 qty, address to) external;

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function burn(uint256 tokenId) external;

    function changeMaxPresale(uint256 _newMaxPresale) external;

    function changePrice(uint256 newPrice) external;

    function contractURI() external view returns (string memory);

    function customThing(
        uint256 nftID,
        uint256 id,
        string memory what
    ) external;

    function decreaseMaxSupply(uint256 newMaxSupply) external;

    function exists(uint256 _tokenId) external view returns (bool);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool);

    function lockMetadata() external;

    function locked() external view returns (bool);

    function maxPresale() external view returns (uint256);

    function maxSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function presaleBuy(
        bytes32 hash,
        bytes memory sig,
        uint256 qty,
        string memory nonce
    ) external;

    function presaleLive() external view returns (bool);

    function pricePerToken() external view returns (uint256);

    function publicBuy(
        bytes32 hash,
        bytes memory sig,
        string memory nonce
    ) external;

    function publicBuyX2(uint256 qty) external;

    function reclaimERC20(address erc20Token) external;

    function renounceOwnership() external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function saleLive() external view returns (bool);

    function saleLiveX2() external view returns (bool);

    function setApprovalForAll(address operator, bool approved) external;

    function setBaseURI(string memory newBaseURI) external;

    function setContractURI(string memory newuri) external;

    function setIPFSProvenance(string memory _ipfsProvenance) external;

    function setSignerAddress(address addr) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function togglePresaleStatus() external;

    function toggleSaleStatus() external;

    function toggleSaleStatusX2() external;

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferOwnership(address newOwner) external;

    function withdrawEarnings() external;
}