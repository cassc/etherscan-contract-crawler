// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./Types.sol";

contract Asset1155 is
    ERC1155("https://io.8mint.io/media-batch-items/metadata/{id}"),
    ERC1155Burnable,
    ERC1155Supply
{
    using ECDSA for bytes32;

    address public mintManager;
    address public admin;
    uint256 public deployBlockNumber;
    string public name;
    string public symbol;
    bool public isInitialized;

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

    function initialize(
        string calldata _name,
        string calldata _symbol,
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

        symbol = _symbol;

        name = _name;

        isInitialized = true;

        emit Initialized(
            Types.AssetKind.ERC1155,
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
        _mint(asset.to, tokenId, asset.mintAmount, "");
        emit Minted(asset.to, tokenId, asset.uri, asset.mintAmount);
    }

    function setURI(string memory _uri) external onlyAdmin {
        _setURI(_uri);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}