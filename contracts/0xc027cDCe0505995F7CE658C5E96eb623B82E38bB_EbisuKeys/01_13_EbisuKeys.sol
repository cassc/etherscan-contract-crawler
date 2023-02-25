// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract EbisuKeys is ERC721A, Ownable {
    string  public baseURI = "ipfs://QmZ7brLTnUGdt5X7FGSYnZa1ojfZpVptCcKkqEDL7P5bj4/";

    uint32 public immutable maxSupply = 100;

    bytes32 public root = 0x3acc8d3c35b85a468a8502360b1e9bc590bfac3eeea8adcb3bfc281fa9030d94;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("EbisuKeys", "EK") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function mint(bytes32[] calldata proof) public callerIsUser {
        require(canMint(msg.sender,root, proof), "not white");
        require(totalSupply() + 5 <= maxSupply,"sold out");
        _safeMint(msg.sender, 5);
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