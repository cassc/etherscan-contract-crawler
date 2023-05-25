/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: MIT
// Creator: Debox Labs

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DeBoxGuardiansPenguin is ERC721, ERC721Enumerable, Ownable {

    bool public saleIsActive = false;
    string private _baseURIextended;

    uint8 public constant MAX_PUBLIC_MINT = 3;
    uint256 public constant MAX_SUPPLY = 2048;
    uint256 public constant PRICE_PER_TOKEN = 0.05 ether;

    bytes32 public root;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;  
    }
    constructor(bytes32 _root) ERC721("DeBox Guardians Penguin", "DeBox") {
        root = _root;
    }

    function setRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) private view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < n; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mintAllowList(bytes32[] memory proof, uint8 numberOfTokens) external payable callerIsUser {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");
        require(balanceOf(msg.sender) == 0, "Allowlist just for once");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function mint(uint numberOfTokens) public payable callerIsUser {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}