// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import 'erc721a/contracts/ERC721A.sol';

contract VeryLongCNP is ERC721A('Very long CNP', 'VLCNP'), Ownable {
    enum Phase {
        BeforeMint,
        WLMint,
        PublicMint
    }

    address public constant withdrawAddress = 0x194A919bc6B7Eac730a0df44372296Bdc93e5D1E;
    uint256 public constant maxSupply = 11111;
    uint256 public constant publicMaxPerTx = 1;
    string public constant baseExtension = '.json';

    string public baseURI = 'ipfs://QmXPFsQtWc96AmsMDpUiuZSPkLRzupeAsWnR9yHrXzJLmu/';
    uint256 public preCost = 0.001 ether;
    uint256 public publicCost = 0.001 ether;

    bytes32 public merkleRoot;
    Phase public phase = Phase.BeforeMint;

    mapping(address => uint256) public whitelistMinted;

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // public mint
    function mint(uint256 _mintAmount) public payable {
        require(phase == Phase.PublicMint, 'Public mint is not active.');
        uint256 cost = publicCost * _mintAmount;
        _mintCheck(_mintAmount, cost);
        require(_mintAmount <= publicMaxPerTx, 'Mint amount cannot exceed 10 per Tx.');

        _safeMint(msg.sender, _mintAmount);
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _presaleMax,
        bytes32[] calldata _merkleProof
    ) public payable {
        require(phase == Phase.WLMint, 'Presale is not active.');
        uint256 cost = preCost * _mintAmount;
        _mintCheck(_mintAmount, cost);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');

        require(whitelistMinted[msg.sender] + _mintAmount <= _presaleMax, 'Address already claimed max amount');

        whitelistMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function _mintCheck(uint256 _mintAmount, uint256 cost) internal view {
        require(_mintAmount > 0, 'Mint amount cannot be zero');
        require(totalSupply() + _mintAmount <= maxSupply, 'Total supply cannot exceed maxSupply');
        require(msg.value >= cost, 'Not enough funds provided for mint');
    }

    function ownerMint(address to, uint256 count) public onlyOwner {
        _safeMint(to, count);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function setPhase(Phase _newPhase) public onlyOwner {
        phase = _newPhase;
    }

    function setPreCost(uint256 _preCost) public onlyOwner {
        preCost = _preCost;
    }

    function setPublicCost(uint256 _publicCost) public onlyOwner {
        publicCost = _publicCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}