// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import 'erc721a/contracts/ERC721A.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import './TMAs.sol';

contract TMAsSaler is Ownable {
    enum Phase {
        BeforeMint,
        PreMint1
    }
    address public constant withdrawAddress = 0x843F854d0d0074F16B92B748089E3892d71fffd3;
    TMAs public immutable tmas;

    uint256 public maxSupply = 10000;

    Phase public phase = Phase.BeforeMint;

    mapping(Phase => mapping(address => uint256)) public minted;
    mapping(Phase => uint256) public limitedPerWL;
    mapping(Phase => bytes32) public merkleRoot;
    mapping(Phase => uint256) public costs;

    constructor(TMAs _tmas) {
        tmas = _tmas;
        limitedPerWL[Phase.PreMint1] = 1;
        costs[Phase.PreMint1] = 0.07 ether;
    }

    // internal
    function _mintCheck(uint256 _mintAmount, uint256 cost) internal view {
        require(_mintAmount > 0, 'Mint amount cannot be zero');
        require(tmas.totalSupply() + _mintAmount <= maxSupply, 'Total supply cannot exceed maxSupply');
        require(msg.value >= cost, 'Not enough funds provided for mint');
    }

    // public
    function preMint(
        uint256 _mintAmount,
        uint256 _wlCount,
        bytes32[] calldata _merkleProof
    ) public payable {
        require(phase == Phase.PreMint1, 'PreMint is not active.');
        uint256 cost = costs[Phase.PreMint1] * _mintAmount;
        _mintCheck(_mintAmount, cost);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _wlCount));
        require(MerkleProof.verify(_merkleProof, merkleRoot[phase], leaf), 'Invalid Merkle Proof');

        require(
            minted[phase][msg.sender] + _mintAmount <= _wlCount * limitedPerWL[phase],
            'Address already claimed max amount'
        );

        minted[phase][msg.sender] += _mintAmount;
        tmas.minterMint(msg.sender, _mintAmount);
    }

    // external (only owner)
    function setCost(Phase _phase, uint256 _cost) external onlyOwner {
        costs[_phase] = _cost;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPhase(Phase _newPhase) external onlyOwner {
        phase = _newPhase;
    }

    function setLimitedPerWL(Phase _phase, uint256 _number) external onlyOwner {
        limitedPerWL[_phase] = _number;
    }

    function setMerkleRoot(Phase _phase, bytes32 _merkleRoot) external onlyOwner {
        merkleRoot[_phase] = _merkleRoot;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }
}