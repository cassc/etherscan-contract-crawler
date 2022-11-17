// SPDX-License-Identifier: MIT

// ,---------.  .---.  .---.      .-''-.           .-------.      .-''-.   .-------.     .-------.     .-./`)     .-'''-.
// \          \ |   |  |_ _|    .'_ _   \          \  _(`)_ \   .'_ _   \  |  _ _   \    |  _ _   \    \ .-.')   / _     \
//  `--.  ,---' |   |  ( ' )   / ( ` )   '         | (_ o._)|  / ( ` )   ' | ( ' )  |    | ( ' )  |    / `-' \  (`' )/`--'
//     |   \    |   '-(_{;}_) . (_ o _)  |         |  (_,_) / . (_ o _)  | |(_ o _) /    |(_ o _) /     `-'`"` (_ o _).
//     :_ _:    |      (_,_)  |  (_,_)___|         |   '-.-'  |  (_,_)___| | (_,_).' __  | (_,_).' __   .---.   (_,_). '.
//     (_I_)    | _ _--.   |  '  \   .---.         |   |      '  \   .---. |  |\ \  |  | |  |\ \  |  |  |   |  .---.  \  :
//    (_(=)_)   |( ' ) |   |   \  `-'    /         |   |       \  `-'    / |  | \ `'   / |  | \ `'   /  |   |  \    `-'  |
//     (_I_)    (_{;}_)|   |    \       /          /   )        \       /  |  |  \    /  |  |  \    /   |   |   \       /
//     '---'    '(_,_) '---'     `'-..-'           `---'         `'-..-'   ''-'   `'-'   ''-'   `'-'    '---'    `-...-'

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./DefaultOperatorFilterer.sol";

contract Perris is ERC721A, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    using ECDSA for bytes32;

    bytes32 public perrisMerkleRoot;
    uint256 public saleStatus;
    uint256 public devMinted;

    // ------ Sale Settings
    uint256 private constant PERRIS_PRICE = 0.111 ether;
    uint256 private constant MAX_PERRIS_SUPPLY = 1111;
    uint256 private constant PERRIS_VAULT_RESERVED = 50;
    uint256 private constant LIMIT_PER_WALLET = 2;

    string private _baseTokenURI;
    string private _preRevealURI;

    bool private revealed;

    constructor() ERC721A("Perris", "PERRIS") {}

    function whitelistMint(bytes32[] memory proof) external payable {
        require(saleStatus > 0, "Sale is not active");
        require(
            MerkleProof.verify(proof, perrisMerkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Not whitelisted"
        );
        require(msg.value >= PERRIS_PRICE, "Not enough ETH sent");
        require(_numberMinted(msg.sender) < 1, "Already claimed");

        processMint(1);
    }

    function publicMint(uint256 amount) public payable {
        require(saleStatus > 1, "Public sale is not active");
        require(msg.value >= PERRIS_PRICE * amount, "Not enough ETH sent");
        processMint(amount);
    }

    function devMint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_PERRIS_SUPPLY, "Exceeds max supply");
        require(devMinted + amount <= PERRIS_VAULT_RESERVED, "Exceeds reserved supply");

        devMinted += amount;

        _safeMint(to, amount);
    }

    function processMint(uint256 amount) internal {
        uint256 ownerRemainingSupply = PERRIS_VAULT_RESERVED - devMinted;
        require(
            totalSupply() + amount + ownerRemainingSupply <= MAX_PERRIS_SUPPLY,
            "Exceeds max supply"
        );
        require(_numberMinted(msg.sender) + amount <= LIMIT_PER_WALLET, "Exceeds limit per wallet");

        _safeMint(msg.sender, amount);
    }

    function setMerkleRoot(bytes32 _perrisMerkleRoot) external onlyOwner {
        perrisMerkleRoot = _perrisMerkleRoot;
    }

    function setSaleStatus(uint256 _saleStatus) external onlyOwner {
        saleStatus = _saleStatus;
    }

    function setReveal(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrerevealURI(string memory preRevealURI) external onlyOwner {
        _preRevealURI = preRevealURI;
    }

    function merkleRoot() public view returns (bytes32) {
        return perrisMerkleRoot;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!revealed) return _preRevealURI;
        return string(abi.encodePacked(_baseTokenURI, _tokenId.toString(), ".json"));
    }

    // Opensea On-Chain royalties enforcement
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}