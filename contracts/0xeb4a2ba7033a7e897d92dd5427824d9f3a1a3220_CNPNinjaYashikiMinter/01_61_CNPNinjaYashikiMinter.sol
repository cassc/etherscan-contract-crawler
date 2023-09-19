// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CNPMakimono} from './CNPMakimono.sol';
import {CNPNinjaYashiki} from './CNPNinjaYashiki.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {CNPYRegistry} from './CNPYRegistry.sol';

contract CNPNinjaYashikiMinter is Ownable {
    enum Phase {
        BeforeMint,
        PreMint
    }
    CNPYRegistry public immutable registory;
    CNPMakimono public immutable makimono;
    CNPNinjaYashiki public immutable ninjaYashiki;

    uint256 public targetTokenId = 1;
    uint256 public maxSupply = 1200;
    Phase public phase = Phase.BeforeMint;

    uint256 public maxMint = 1;
    mapping(address => uint256) public minted;

    constructor(CNPMakimono _makimono, CNPNinjaYashiki _ninjaYashiki, CNPYRegistry _registory) {
        makimono = _makimono;
        ninjaYashiki = _ninjaYashiki;
        registory = _registory;
    }

    function _mintCheck(uint256 _mintAmount) internal view {
        require(_mintAmount > 0, 'Mint amount cannot be zero');
        require((minted[msg.sender] + _mintAmount) <= maxMint, 'Max Minted');
        require(ninjaYashiki.totalSupply() + _mintAmount <= maxSupply, 'Total supply cannot exceed maxSupply');
    }

    function preMint(uint256 _mintAmount) external {
        require(phase == Phase.PreMint, 'PreMint is not active.');
        _mintCheck(_mintAmount);

        minted[msg.sender] += _mintAmount;

        makimono.burn(msg.sender, targetTokenId, _mintAmount);
        uint256 current = ninjaYashiki.totalSupply();
        ninjaYashiki.minterMint(msg.sender, _mintAmount);

        for (uint256 i = 1; i <= _mintAmount; ) {
            address accountAddress = registory.account(current + i);
            makimono.mint(accountAddress, targetTokenId, 1, '');
            unchecked {
                ++i;
            }
        }
    }

    function totalSupply() external view returns (uint256) {
        return makimono.totalSupply(targetTokenId);
    }

    function setPhase(Phase _newPhase) external onlyOwner {
        phase = _newPhase;
    }

    function setTargetTokenId(uint256 _targetTokenId) external onlyOwner {
        targetTokenId = _targetTokenId;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }
}