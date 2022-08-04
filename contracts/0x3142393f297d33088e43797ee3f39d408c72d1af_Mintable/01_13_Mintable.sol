// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract Mintable is ERC721A, Ownable {
    enum Status {
        Waiting,
        Started,
        Public,
        Finished
    }

    bytes32 private merkleRoot;
    Status public status;
    string public baseURI;
    uint256 public constant MAX_MINT_PER_ADDR = 1;
    uint256 public constant MAX_SUPPLY = 10000;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);
    event RootChanged(bytes32 newRoot);

    constructor(
        string memory initBaseURI,
        address reserve_address,
        uint256 reserve_amount
    ) ERC721A("Tribe of STATE", "Sapiens") {
        baseURI = initBaseURI;
        // Reserve 1000 NFTs to team address.
        _safeMint(reserve_address, reserve_amount);
        emit Minted(reserve_address, reserve_amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(address user, bytes32[] calldata _merkleProof) external {
        require(status == Status.Started || status == Status.Public, "MINT: Not started yet");
        require(tx.origin == msg.sender, "MINT: Contract call not allowed");
        require(status == Status.Public || isWhitelisted(user, _merkleProof), "MINT: Not in allow list");
        require(
            numberMinted(user) < MAX_MINT_PER_ADDR,
            "MINT: 1 for each address."
        );
        require(
            totalSupply() < MAX_SUPPLY,
            "MINT: Reach max supply"
        );

        _safeMint(user, 1);

        emit Minted(user, 1);
    }

    function isWhitelisted(address user, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
        emit RootChanged(merkleRoot);
    }
}