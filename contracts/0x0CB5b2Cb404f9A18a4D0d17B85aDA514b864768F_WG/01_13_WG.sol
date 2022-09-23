// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract WG is ERC721A, Ownable {
    enum Status {
        Waiting,
        Started,
        Public,
        Finished
    }

    bytes32 private merkleRoot;
    Status public status;
    string public baseURI;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public maxMintPerAddr;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);
    event RootChanged(bytes32 newRoot);
    event MaxMintPerAddrChanged(uint256 newMaxMintPerAddr);

    constructor() ERC721A("WINGS GENESIS", "WG") {
        maxMintPerAddr = 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function isWhitelisted(address user, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function mint(address user, uint256 quantity, bytes32[] calldata _merkleProof) external payable {
        require(status == Status.Started || status == Status.Public, "WG: Not started yet");
        // require(tx.origin == msg.sender, "WG: Contract call not allowed");
        require(status == Status.Public || isWhitelisted(user, _merkleProof), "WG: Not in allowlist");
        require(
            numberMinted(user) + quantity <= maxMintPerAddr,
            "WG: exceed limit for each address."
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "WG: ran out of supply."
        );

        _safeMint(user, quantity);
        emit Minted(user, quantity);
    }

    function airdrop(address user, uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "WG: ran out of supply."
        );
        _safeMint(user, quantity);
        emit Minted(user, quantity);
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

    function setMaxMintPerAddr(uint256 newMaxMintPerAddr) external onlyOwner {
        maxMintPerAddr = newMaxMintPerAddr;
        emit MaxMintPerAddrChanged(newMaxMintPerAddr);
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "WG: Can't withdraw.");
    }
}