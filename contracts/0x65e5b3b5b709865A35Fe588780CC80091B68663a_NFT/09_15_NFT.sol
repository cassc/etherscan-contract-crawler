// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract NFT is ERC721AQueryable, ERC721ABurnable, OperatorFilterer, Ownable, ERC2981 {
    bool public operatorFilteringEnabled;

    bytes32 private _merkleRootInRound = 0x0;
    uint private _price = 40000000000000000;
    uint private _round = 0;
    uint private _maxTotal = 10000;
    uint private _maxInRound = 0;

    mapping(uint => mapping(address => bool)) private _roundMinted;

    string private _baseTokenURI;

    constructor() ERC721A("anonkin", "ANONKIN") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 750);

        setBaseURI("https://metadata.kinance.io/");

        _mint(owner(), 100);
    }

    function mintFree(bytes32[] calldata proof) public {
        require(_round > 0, "Minting hasn't started yet");
        require(totalSupply() + _maxInRound <= _maxTotal, "The quantity exceeds max total amount");

        if (_round < 4) { // round 1, 2, 3
            require(!_roundMinted[_round][msg.sender], "You already minted this round");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(proof, _merkleRootInRound, leaf), "You are not whitelisted for this round");
            _mint(msg.sender, _maxInRound);
            _roundMinted[_round][msg.sender] = true;
        } else {
            revert("Public mint started");
        }
    }

    function mint(uint256 quantity) public payable {
        require(totalSupply() + quantity <= _maxTotal, "The quantity exceeds max total amount");
        require(quantity > 0, "You need to mint at least 1");
        require(_round == 4, "Public minting hasn't started yet");
        require(msg.value >= _price * quantity, "The quantity you sent does not satisfy the needed price");
        _mint(msg.sender, quantity);
    }

    function startRound(uint round, bytes32 merkleRoot, uint maxInRound) public onlyOwner {
        _round = round;
        _merkleRootInRound = merkleRoot;
        _maxInRound = maxInRound;
    }

    function getRound() public view returns (uint256) {
        return _round;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setApprovalForAll(address operator, bool approved) public override (ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override (ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override (ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}