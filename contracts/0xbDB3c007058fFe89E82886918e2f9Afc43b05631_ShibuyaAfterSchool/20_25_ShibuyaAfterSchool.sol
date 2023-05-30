// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC721A} from 'erc721a/contracts/ERC721A.sol';
import {SBYASData, ISBYASStaticData} from './extensions/SBYASData.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import './interface/IShibuyaAfterSchool.sol';

contract ShibuyaAfterSchool is
    IShibuyaAfterSchool,
    ERC721A('Shibuya_AS', 'SBYAS'),
    DefaultOperatorFilterer,
    SBYASData,
    ReentrancyGuard
{
    address payable public constant override withdrawAddress = payable(0x77133988dEE3561255be08211a1862B224101754);
    ISBYASStaticData public immutable override staticData;

    bytes32 public merkleRoot;
    mapping(address => uint256) public override minted;

    ISBYASStaticData.Phase public override phase = ISBYASStaticData.Phase.BeforeMint;

    uint16 public override maxMintSupply = 1;
    uint256 public override maxSupply = 111;

    constructor(ISBYASStaticData _staticData) SBYASData() {
        staticData = _staticData;
    }

    function mint(uint256 amount, bytes32[] calldata _merkleProof) external payable override nonReentrant {
        require(phase == ISBYASStaticData.Phase.WLMint, 'WLMint is not active');
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');
        require(currentIndex() + amount <= maxSupply, 'Total supply cannot exceed maxSupply');
        require(minted[_msgSender()] + amount <= maxMintSupply, 'Address already claimed max amount');
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            require(msg.value >= etherPrice * amount, 'Not enough funds provided for mint');
        }

        minted[_msgSender()] += amount;
        _safeMint(_msgSender(), amount);
    }

    function minterMint(uint256 amount, address to) external override onlyRole(MINTER_ROLE) {
        _safeMint(to, amount);
    }

    function burnerBurn(address _address, uint256[] calldata tokenIds) public override onlyRole(BURNER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_address == ownerOf(tokenId));

            _burn(tokenId);
        }
    }

    function withdraw() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool os, ) = withdrawAddress.call{value: address(this).balance}('');
        require(os);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot = _merkleRoot;
    }

    function setPhase(ISBYASStaticData.Phase _newPhase) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        phase = _newPhase;
    }

    function setMaxSupply(uint256 _newMaxSupply) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = _newMaxSupply;
    }

    function setMaxMintSupply(uint16 _maxMintSupply) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        maxMintSupply = _maxMintSupply;
    }

    function currentIndex() public view returns (uint256) {
        return _nextTokenId();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return staticData.createMetadata(characters[tokenId - 1], images[characters[tokenId - 1].imageId]);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, SBYASData) returns (bool) {
        return
            interfaceId == type(IShibuyaAfterSchool).interfaceId ||
            ERC721A.supportsInterface(interfaceId) ||
            SBYASData.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
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
}