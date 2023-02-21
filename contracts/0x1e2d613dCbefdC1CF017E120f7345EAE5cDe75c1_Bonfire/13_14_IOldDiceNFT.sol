// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IOldDiceNFT {
    error ApprovalCallerNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error ApprovalToCurrentOwner();
    error ApproveToCaller();
    error BalanceQueryForZeroAddress();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error OwnerQueryForNonexistentToken();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
    error URIQueryForNonexistentToken();
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event ContractURIUpdated(string prevURI, string newURI);
    event DefaultRoyalty(
        address indexed newRoyaltyRecipient,
        uint256 newRoyaltyBps
    );
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
    event RoyaltyForToken(
        uint256 indexed tokenId,
        address indexed royaltyRecipient,
        uint256 royaltyBps
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function airdrop(address[] memory _addresses, uint256[] memory _amounts)
        external;

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function burn(uint256 _tokenId) external;

    function contractURI() external view returns (string memory);

    function getApproved(uint256 tokenId) external view returns (address);

    function getDefaultRoyaltyInfo() external view returns (address, uint16);

    function getRoyaltyInfoForToken(uint256 _tokenId)
        external
        view
        returns (address, uint16);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function multicall(bytes[] memory data)
        external
        returns (bytes[] memory results);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

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

    function setApprovalForAll(address operator, bool approved) external;

    function setBaseURI(string memory _uri) external;

    function setContractURI(string memory _uri) external;

    function setDefaultRoyaltyInfo(
        address _royaltyRecipient,
        uint256 _royaltyBps
    ) external;

    function setOwner(address _newOwner) external;

    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}