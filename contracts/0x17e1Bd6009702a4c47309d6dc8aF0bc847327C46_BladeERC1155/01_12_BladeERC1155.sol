// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BladeERC1155 is ERC1155, ERC1155Burnable, Ownable {
    address private _signer;
    string private _baseURI = "https://nifty-island-sword-drop-public.s3.us-east-2.amazonaws.com/";
    string private _contractMetadataURI = "bladeContract.json";
    mapping(uint256 => string) public tokenMetadata;
    mapping(uint256 => bool) private usedNonces;

    uint256[] private ids = [0, 1];
    uint256[] private initialMintAmount = [50, 50];

    event TicketRedeemed(address redeemer);

    constructor(address signer, address initialBatchTo) ERC1155("https://nifty-island-sword-drop-public.s3.us-east-2.amazonaws.com/") {
        _signer = signer;
        tokenMetadata[0] = "blade.json";
        tokenMetadata[1] = "ticket.json";
        _mintBatch(initialBatchTo, ids, initialMintAmount, "");
    }

    function updateSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }

    function mint(address to, uint256 nonce, bytes calldata signature)
        external {
        require(usedNonces[nonce] == false, "can't use the same signature twice");
        usedNonces[nonce] = true;

        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(to, nonce)));
        require(ECDSA.recover(hash, signature) == _signer, "Signature failed to recover");

        _mint(to, 0, 1, "");
        _mint(to, 1, 1, "");
    }

    function burnTicket() external {
        require(balanceOf(msg.sender, 1) >= 1, "Caller has no ticket");
        _burn(msg.sender, 1, 1);
        emit TicketRedeemed(msg.sender);
    }

    function updateMetadata(uint256 tokenId, string memory metadata)
        external
        onlyOwner {
        tokenMetadata[tokenId] = metadata;
    }

    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    function updateBaseURI(string memory newURI) external onlyOwner {
        _baseURI = newURI;
    }

    function uri(uint256 id) public view override returns (string memory) {
        string memory base = baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenMetadata[id])) : ""; 
    }

    function contractURI() public view returns (string memory) {
        string memory base = baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, _contractMetadataURI)) : ""; 
    }

    function updateContractURI(string memory newURI) external onlyOwner {
        _contractMetadataURI = newURI;
    }
}