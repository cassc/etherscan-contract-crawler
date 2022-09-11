// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import 'erc721a/contracts/ERC721A.sol';

contract AMATO is ERC721A('AMATO', 'AMT'), Ownable {
    enum Phase {
        BeforeMint,
        PreMint1,
        PreMint2,
        PublicMint
    }

    address public constant withdrawAddress = 0xEc64CEEbeF9e790738a1Dec286385331f018a6a2;
    uint256 public constant maxSupply = 5555;
    uint256 public constant publicMaxPerTx = 1;
    string public constant baseExtension = '.json';

    string public baseURI = 'ipfs://QmY4q1pXYJCiKKsFTfe4FQRNc8Ebzy47d5yotsHmJbea1Z/';

    bytes32 public merkleRoot;
    Phase public phase = Phase.BeforeMint;

    mapping(Phase => mapping(address => uint256)) public minted;
    mapping(Phase => uint256) public limitedPerWL;
    mapping(Phase => uint256) public costs;

    constructor() {
        limitedPerWL[Phase.PreMint1] = 3;
        limitedPerWL[Phase.PreMint2] = 5;
        costs[Phase.PreMint1] = 0.001 ether;
        costs[Phase.PreMint2] = 0.003 ether;
        costs[Phase.PublicMint] = 0.005 ether;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _mintCheck(uint256 _mintAmount, uint256 cost) internal view {
        require(_mintAmount > 0, 'Mint amount cannot be zero');
        require(totalSupply() + _mintAmount <= maxSupply, 'Total supply cannot exceed maxSupply');
        require(msg.value >= cost, 'Not enough funds provided for mint');
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(phase == Phase.PublicMint, 'Public mint is not active.');
        uint256 cost = costs[Phase.PublicMint] * _mintAmount;
        _mintCheck(_mintAmount, cost);
        require(_mintAmount <= publicMaxPerTx, 'Mint amount cannot exceed 1 per Tx.');

        _safeMint(msg.sender, _mintAmount);
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _wlCount,
        bytes32[] calldata _merkleProof
    ) public payable {
        require(phase == Phase.PreMint1 || phase == Phase.PreMint2, 'PreMint is not active.');
        uint256 cost = costs[phase] * _mintAmount;
        _mintCheck(_mintAmount, cost);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _wlCount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');

        require(
            minted[phase][msg.sender] + _mintAmount <= _wlCount * limitedPerWL[phase],
            'Address already claimed max amount'
        );

        minted[phase][msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    // public (only owner)
    function ownerMint(address to, uint256 count) public onlyOwner {
        _safeMint(to, count);
    }

    function setPhase(Phase _newPhase) public onlyOwner {
        phase = _newPhase;
    }

    function setLimitedPerWL(Phase _phase, uint256 _number) public onlyOwner {
        limitedPerWL[_phase] = _number;
    }

    function setCost(Phase _phase, uint256 _cost) public onlyOwner {
        costs[_phase] = _cost;
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