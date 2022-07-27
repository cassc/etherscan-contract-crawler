// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import './IWizMagic.sol';
import './Elixir.sol';
import './FullSkull.sol';

contract SkullAlchemy is Ownable, ReentrancyGuard, Pausable {
    event SkullAlchemyStarted(address owner, uint256 tokenId, uint256 numElixirs);
    event SkullUpgradeSuccess(address owner, uint256 originalTokenId, uint256 upgradedTokenId);
    event SkullUpgradeFail(address owner, uint256 tokenId);

    struct SkullInWaiting {
        address owner;
        uint256 tokenId;
        uint256 start;
        uint256 index;
        uint256 numElixirs;
    }

    event WizMinted(uint256 quantity, address to);

    IWizMagic private _wizMagicContract;
    Elixir private _elixirContract;
    FullSkull private _fullSkullContract;

    mapping(address => SkullInWaiting) private _skullInWaitingMap;
    address private _materialBank;
    uint256 private _uncommonProbability = 4;
    uint256 private _rareProbability = 6;
    uint256 private _epicProbability = 16;
    uint256 private _legendaryProbability = 156;

    uint256 private _maxLegendaries = 10;
    uint256 private _numLegendaries = 0;

    constructor(address fullSkullAddress, address elixirAddress, address wizMagicAddress) {
        _pause();
        _wizMagicContract = IWizMagic(wizMagicAddress);
        _elixirContract = Elixir(elixirAddress);
        _fullSkullContract = FullSkull(fullSkullAddress);
        _materialBank = _msgSender();
    }

    function startSkullAlchemy(uint256 skullId, uint256 numElixirs) external nonReentrant whenNotPaused {
        require(_skullInWaitingMap[_msgSender()].start == 0, 'Already have skull pending alchemy');
        require(_elixirContract.balanceOf(_msgSender()) >= numElixirs*(10**18), 'Not enough elixirs');
        require(_fullSkullContract.balanceOf(_msgSender(), skullId) > 0, 'Does not have skull to alchemy');
        require(skullId < 4, 'Already maximum level reached');
        if (skullId == 3) {
            require(_numLegendaries < _maxLegendaries, 'Max number of legendaries reached');
        }
        uint256 index = _wizMagicContract.getIndex();
        _skullInWaitingMap[_msgSender()] = SkullInWaiting({
            owner: _msgSender(),
            tokenId: skullId,
            start: block.timestamp,
            index: index,
            numElixirs: numElixirs
        });
        _elixirContract.transferFrom(_msgSender(), _materialBank, numElixirs*(10**18));
        _fullSkullContract.burn(_msgSender(), skullId, 1);
        emit SkullAlchemyStarted(_msgSender(), skullId, numElixirs);
    }

    function checkAlchemy() external nonReentrant whenNotPaused {
        SkullInWaiting memory skullInWaiting = _skullInWaitingMap[_msgSender()];
        require(skullInWaiting.owner == _msgSender(), 'Owner does not own SkullInWaiting object');
        uint256 rand = _wizMagicContract.getRand(skullInWaiting.index);
        uint256 numElixirs = skullInWaiting.numElixirs;
        uint256 currSkullId = skullInWaiting.tokenId;
        uint256 elixirsUsed = 0;

        for (uint i = 0; i < numElixirs; i++) {
            uint256 newRand = _wizMagicContract.getAnotherRand(rand + i);
            if (currSkullId == 0) {
                if (newRand % _uncommonProbability == 0) {
                    emit SkullUpgradeSuccess(_msgSender(), 0, 1);
                    currSkullId = 1;
                } else {
                    emit SkullUpgradeFail(_msgSender(), 0);
                }
            } else if (currSkullId == 1) {
                if (newRand % _rareProbability == 0) {
                    emit SkullUpgradeSuccess(_msgSender(), 1, 2);
                    currSkullId = 2;
                } else {
                    emit SkullUpgradeFail(_msgSender(), 1);
                }
            } else if (currSkullId == 2) {
                if (newRand % _epicProbability == 0) {
                    emit SkullUpgradeSuccess(_msgSender(), 2, 3);
                    currSkullId = 3;
                } else {
                    emit SkullUpgradeFail(_msgSender(), 2);
                }
            } else if (currSkullId == 3) {
                if (_numLegendaries >= _maxLegendaries) {
                    break;
                }
                if (newRand % _legendaryProbability == 0) {
                    emit SkullUpgradeSuccess(_msgSender(), 3, 4);
                    currSkullId = 4;
                    _numLegendaries += 1;
                } else {
                    emit SkullUpgradeFail(_msgSender(), 3);
                }
            } else if (currSkullId == 4) {
                break;
            }
            elixirsUsed += 1;
        }

        uint256 elixirLeft = numElixirs - elixirsUsed;
        if (elixirLeft > 0) {
            _elixirContract.transferFrom(_materialBank, _msgSender(), elixirLeft*(10**18));
        }
        _fullSkullContract.mint(_msgSender(), currSkullId, 1, "0x0");
        delete _skullInWaitingMap[_msgSender()];
    }

    function getSkullInWaiting(address owner) public view returns (SkullInWaiting memory) {
        return _skullInWaitingMap[owner];
    }

    function setBank(address bankAddress) public onlyOwner {
        _materialBank = bankAddress;
    }

    function setUncommonProbability(uint256 newProbability) public onlyOwner {
        _uncommonProbability = newProbability;
    }

    function setRareProbability(uint256 newProbability) public onlyOwner {
        _rareProbability = newProbability;
    }

    function setEpicProbability(uint256 newProbability) public onlyOwner {
        _epicProbability = newProbability;
    }

    function setLegendaryProbability(uint256 newProbability) public onlyOwner {
        _legendaryProbability = newProbability;
    }

    function setMaxLegendaries(uint256 newMax) public onlyOwner {
        _maxLegendaries = newMax;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}