// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BenMezrichProject2 is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    bytes32 root;
    string baseURI;
    Counters.Counter nextToken;
    mapping (address => bool) mintedWallets;
    bool mintingClosed;

    constructor(bytes32 _root, string memory _baseURI) ERC721("Ben Mezrich Project 2", "BENFT2") {
        root = _root;
        baseURI = _baseURI;
    }

    // MINTING //

    function openMinting() public onlyOwner {
        mintingClosed = false;
    }

    function closeMinting() public onlyOwner {
        mintingClosed = true;
    }

    function mint(bytes32[] calldata proof) public {
        require(!mintingClosed, "minting closed");
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))), "invalid merkle proof");
        require(!mintedWallets[msg.sender], "already minted"); // one mint per wallet
        require(msg.sender == tx.origin, "dont get seven'd"); // no bots allowed
        mintedWallets[msg.sender] = true; // update first to avoid reentrancy
        _safeMint(msg.sender, nextTokenId());
    }

    // URIs //

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    // HELPERS //

    function nextTokenId() private returns (uint) {
        nextToken.increment();
        return nextToken.current();
    }

    // OWNER EMERGENCY //

    function withdrawToken(address token) external onlyOwner {
        uint balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    function updateRoot(bytes32 newRoot) external onlyOwner {
        root = newRoot;
    }
}