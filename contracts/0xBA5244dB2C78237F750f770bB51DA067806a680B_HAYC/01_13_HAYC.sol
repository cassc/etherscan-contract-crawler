// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract HAYC is ERC721A, Ownable {
    string public baseURI = "ipfs://QmcLoLSc1BfjgxEFLD5yaKEtcPKwkoDDAdPF2Qe6iywZKB/";

    uint256 public immutable mintPrice = 0.003 ether;
    uint32 public immutable maxSupply = 5000;
    uint32 public immutable perTxLimit = 10;

    mapping(address => bool) public whiteMinted;

    bytes32 public root;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("Halloween Ape  Yacht Club", "HAYC") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 0;
    }

    function publicMint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= perTxLimit,"max 10 amount");
        require(msg.value >= amount * mintPrice,"insufficient");
        _safeMint(msg.sender, amount);
    }

    function whiteListMint(bytes32[] calldata proof) public callerIsUser {
        require(canMint(msg.sender,root, proof), "not white");
        require(!whiteMinted[msg.sender], "already minted");
        require(totalSupply() + 3 <= maxSupply,"sold out");
        whiteMinted[msg.sender] = true;
        _safeMint(msg.sender, 3);
    }

    function getWhiteMinted(address addr) public view returns (bool){
        return whiteMinted[addr];
    }

    function canMint(address account, bytes32 merkleRoot, bytes32[] calldata proof) public pure returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(account)));
    }

    function setMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        root = merkleRoot;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}