//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import './ShurikenNFT.sol';
import './ShurikenStakedNFT.sol';
import './PassportNFT.sol';

contract CALMinterV2 is ReentrancyGuard, Ownable {
    enum Phase {
        BeforeMint,
        WLMint
    }

    ShurikenNFT public immutable shurikenNFT;
    PassportNFT public immutable passportNFT;

    Phase public phase = Phase.WLMint;
    bytes32 public merkleRoot;
    mapping(address => uint256) public shurikenMinted;

    uint256 public cardCost = 0.02 ether;
    uint256 public shurikenCost = 0.008 ether;
    uint256 public cardSupply = 3000;
    uint256 public shurikenSupply = 20000;
    uint256 public shurikenMaxMint = 3;

    constructor(
        ShurikenNFT _shurikenNFT,
        PassportNFT _passportNFT
    ) {
        shurikenNFT = _shurikenNFT;
        passportNFT = _passportNFT;
    }

    function mint(
        bool _card,
        uint256 _shurikenAmount,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        require(phase == Phase.WLMint, 'WLMint is not active.');
        require(_card || passportNFT.balanceOf(_msgSender()) == 1, 'Passport required.');
        uint256 card = _card ? cardCost : 0;
        uint256 shuriken = shurikenCost * _shurikenAmount;
        require(_card || _shurikenAmount > 0, 'Mint amount cannot be zero');
        if (_shurikenAmount != 0) {
            require(
                shurikenNFT.currentIndex() + _shurikenAmount - 1 <= shurikenSupply,
                'Total supply cannot exceed shurikenSupply'
            );
            require(
                shurikenMinted[_msgSender()] + _shurikenAmount <= shurikenMaxMint,
                'Address already claimed max amount'
            );
        }
        require(msg.value >= (card + shuriken), 'Not enough funds provided for mint');

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');

        if (_card) {
            require(passportNFT.currentIndex() + 1 <= cardSupply, 'Total supply cannot exceed cardSupply');
            require(passportNFT.balanceOf(_msgSender()) == 0, 'Address already claimed max amount');
            passportNFT.minterMint(_msgSender(), 1);
        }

        if (_shurikenAmount != 0) {
            shurikenMinted[_msgSender()] += _shurikenAmount;
            shurikenNFT.minterMint(_msgSender(), _shurikenAmount);
        }
    }

    function setPhase(Phase _newPhase) external onlyOwner {
        phase = _newPhase;
    }

    function setCardCost(uint256 _cardCost) external onlyOwner {
        cardCost = _cardCost;
    }

    function setShurikenCost(uint256 _shurikenCost) external onlyOwner {
        shurikenCost = _shurikenCost;
    }

    function setCardSupply(uint256 _cardSupply) external onlyOwner {
        cardSupply = _cardSupply;
    }

    function setShurikenSupply(uint256 _shurikenSupply) external onlyOwner {
        shurikenSupply = _shurikenSupply;
    }

    function setShurikenMaxMint(uint256 _shurikenMaxMint) external onlyOwner {
        shurikenMaxMint = _shurikenMaxMint;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw(address payable withdrawAddress) external onlyOwner {
        (bool os, ) = withdrawAddress.call{value: address(this).balance}('');
        require(os);
    }
}