// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './CNPMakimono.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract CNPMakimonoRedMinter is Ownable {
    enum Phase {
        BeforeMint,
        PreMint
    }
    CNPMakimono public immutable makimono;

    uint256 public targetTokenId = 1;
    uint256 public maxSupply = 5500;
    Phase public phase = Phase.BeforeMint;

    mapping(address => uint256) public minted;
    bytes32 public merkleRoots;

    constructor(CNPMakimono _makimono) {
        makimono = _makimono;
    }

    function _mintCheck(uint256 _mintAmount) internal view {
        require(_mintAmount > 0, 'Mint amount cannot be zero');
        require(makimono.totalSupply(targetTokenId) + _mintAmount <= maxSupply, 'Total supply cannot exceed maxSupply');
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _wlCount,
        bytes32[] calldata _merkleProof
    ) external {
        require(phase == Phase.PreMint, 'PreMint is not active.');
        _mintCheck(_mintAmount);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _wlCount));
        require(MerkleProof.verify(_merkleProof, merkleRoots, leaf), 'Invalid Merkle Proof');

        require(minted[msg.sender] + _mintAmount <= _wlCount, 'Address already claimed max amount');

        minted[msg.sender] += _mintAmount;
        makimono.mint(msg.sender, targetTokenId, _mintAmount, '');
    }

    function totalSupply() external view returns (uint256) {
        return makimono.totalSupply(targetTokenId);
    }

    function setPhase(Phase _newPhase) external onlyOwner {
        phase = _newPhase;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoots = _merkleRoot;
    }

    function setTargetTokenId(uint256 _targetTokenId) external onlyOwner {
        targetTokenId = _targetTokenId;
    }
}