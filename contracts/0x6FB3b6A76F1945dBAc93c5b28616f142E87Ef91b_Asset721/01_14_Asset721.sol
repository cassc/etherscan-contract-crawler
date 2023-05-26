// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./Types.sol";

contract Asset721 is ERC721, ERC721Enumerable {
    constructor() ERC721("Asset721", "ASSET721") {}

    using ECDSA for bytes32;

    address public mintManager;
    address public admin;
    uint256 public deployBlockNumber;
    string public assetName;
    string public assetSymbol;
    bool public isInitialized;
    string public baseURI = "https://io.8mint.io/media-batch-items/metadata/";

    event Initialized(
        Types.AssetKind assetKind,
        address deployAddress,
        address admin,
        uint256 blockNumber,
        uint256 chainId
    );

    event Minted(address to, uint256 tokenId, string uri, uint256 amount);
    event MintManagerSet(address mintManager);
    event AdminSet(address admin);

    modifier onlyAdmin() {
        if (admin != msg.sender) {
            revert OnlyAdminCanPerformThisAction();
        }
        _;
    }

    modifier onlyAuthorized() {
        if (admin != msg.sender && mintManager != msg.sender) {
            revert OnlyAuthorizedCanPerformThisAction();
        }
        _;
    }

    function name() public view virtual override returns (string memory) {
        return assetName;
    }

    function symbol() public view virtual override returns (string memory) {
        return assetSymbol;
    }

    function initialize(
        string calldata _assetName,
        string calldata _assetSymbol,
        uint256 _deployBlockNumber,
        Types.Sign calldata _sign
    ) external {
        if (isInitialized) {
            revert AlreadyInitialized();
        }

        if (_sign.timestamp + 3600 < block.timestamp) {
            revert ExpiredSignature();
        }

        bytes32 payload = keccak256(
            abi.encodePacked("Deploy Asset: ", _sign.signer)
        );

        admin = keccak256(abi.encodePacked(payload, _sign.timestamp))
            .toEthSignedMessageHash()
            .recover(_sign.signature);

        if (admin != _sign.signer) {
            revert InvalidSignature();
        }

        deployBlockNumber = _deployBlockNumber;

        assetName = _assetName;

        assetSymbol = _assetSymbol;

        isInitialized = true;

        emit Initialized(
            Types.AssetKind.ERC721,
            address(this),
            admin,
            deployBlockNumber,
            block.chainid
        );
    }

    function setMintManager(address _mintManager) external onlyAdmin {
        mintManager = _mintManager;
        emit MintManagerSet(_mintManager);
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
        emit AdminSet(_admin);
    }

    function safeMint(Types.Asset calldata asset) external onlyAuthorized {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(asset.uri)));
        _mint(asset.to, tokenId);
        emit Minted(asset.to, tokenId, asset.uri, 1);
    }

    function setURI(string memory _uri) external onlyAdmin {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}