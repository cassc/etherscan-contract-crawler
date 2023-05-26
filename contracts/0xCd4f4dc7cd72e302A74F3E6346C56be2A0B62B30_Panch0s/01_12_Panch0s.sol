// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol';
import 'https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol';

contract Panch0s is
    ERC721A,
    DefaultOperatorFilterer,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    mapping(address => uint256) public ClaimedAllowlist;
    mapping(address => uint256) public ClaimedPublic;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_MINTS_WALLET_ALLOWLIST = 4;
    uint256 public constant MAX_MINTS_WALLET_PUBLIC = 2;
    uint256 public constant MAX_MINTS_TEAM = 250;
    uint256 public constant PRICE_ALLOWLIST = 0.0045 ether;
    uint256 public constant PRICE_PUBLIC = 0.006 ether;

    string private baseURI;
    uint256 private _mintedTeam = 0;
    bool public TeamMinted = false;
    bytes32 public root;

    enum Stages {
        PreAllowlist,
        Allowlist,
        Public,
        SoldOut
    }

    Stages public stages;

    constructor() ERC721A('Panch0s', 'PANCH0S') {
        stages = Stages.PreAllowlist;
        _safeMint(msg.sender, 1);
    }

    function AllowlistMint(
        uint256 amount,
        bytes32[] memory proof
    ) public payable nonReentrant {
        require(stages == Stages.Allowlist, 'Allowlist not started yet.');
        require(
            isValid(proof, keccak256(abi.encodePacked(msg.sender))),
            'Not a part of Allowlist'
        );
        require(
            msg.value == amount * PRICE_ALLOWLIST,
            'Invalid funds provided'
        );
        require(
            amount > 0 && amount <= MAX_MINTS_WALLET_ALLOWLIST,
            'Must mint between the min and max.'
        );
        require(totalSupply() + amount <= MAX_SUPPLY, 'Exceed max supply');
        require(
            ClaimedAllowlist[msg.sender] + amount <= MAX_MINTS_WALLET_ALLOWLIST,
            'Already minted Max Mints Allowlist'
        );
        ClaimedAllowlist[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function PublicMint(uint256 amount) public payable nonReentrant {
        require(stages == Stages.Public, 'Public has not started yet.');
        require(msg.value == amount * PRICE_PUBLIC, 'Invalid funds provided');
        require(
            amount > 0 && amount <= MAX_MINTS_WALLET_PUBLIC,
            'Must mint between the min and max.'
        );
        require(totalSupply() + amount <= MAX_SUPPLY, 'Exceed max supply');
        require(
            ClaimedPublic[msg.sender] + amount <= MAX_MINTS_WALLET_PUBLIC,
            'Already minted Max Mints Public'
        );
        if (totalSupply() + amount == MAX_SUPPLY) {
            stages = Stages.SoldOut;
        }
        ClaimedPublic[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function TeamMint(
        uint256 amount,
        address _address
    ) public nonReentrant {
        require(!TeamMinted, 'Team Minted Already');
        require(
            amount > 0 && amount <= MAX_MINTS_TEAM,
            'Must mint between the min and max.'
        );
        require(totalSupply() + amount <= MAX_SUPPLY, 'Exceed max supply');
        if (_mintedTeam + amount == MAX_MINTS_TEAM) {
            TeamMinted = true;
        }
        _mintedTeam += amount;
        _safeMint(_address, amount);
    }

    function setAllowlistMint() external onlyOwner {
        stages = Stages.Allowlist;
    }

    function setPublicMint() external onlyOwner {
        stages = Stages.Public;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        '.json'
                    )
                )
                : '';
    }

    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

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

    function isValid(
        bytes32[] memory proof,
        bytes32 leaf
    ) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function withdrawMoneyToDeployer() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, 'WITHDRAW FAILED!');
    }

    function withdrawMoney(address payoutAddress) external onlyOwner {
        (bool success, ) = payoutAddress.call{value: address(this).balance}('');
        require(success, 'WITHDRAW FAILED!');
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}