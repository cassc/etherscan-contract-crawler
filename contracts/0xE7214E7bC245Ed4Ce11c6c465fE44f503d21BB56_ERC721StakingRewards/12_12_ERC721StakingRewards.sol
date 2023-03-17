// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ERC721Vault {
    function depositsOf(address _address, address _contract, uint8 _type) public virtual view returns (uint256[] memory);
    function depositTimeOf(address _address, address _contract, uint256 _tokenId, uint8 _type) public virtual  view returns (uint256);
    function clearDepositTimesOf(address _address, address[] memory _contracts, uint8 _type) public virtual;
    function getConfiguration(uint8 _type) public virtual view returns (bool);
    function stakedCount(address _contract, uint8 _type) public virtual returns (uint256);
    function claimRewards(address _address, uint8 _type) public virtual;
    function getStaker(address _contract, uint256 _tokenId, uint8 _type) external virtual view returns (address);
}

contract ERC721StakingRewards is Ownable, ReentrancyGuard {

    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    uint8 SOFT_STAKED = 0;
    uint8 HARD_STAKED = 1;

    struct Collection {
        uint72 softRate;
        uint72 hardRate;
        bool exists;
    }
    
    mapping(address => EnumerableSet.UintSet) private tokenMultipliers;
    mapping(address => mapping(uint256 => uint256)) public tokenMultiples;
    mapping(address => Collection) public collections;
    
    bool public paused;
    address[] public contracts;
    ERC721Vault public vault;

    constructor(
        address _vaultAddress,
        address _owner
    ) {
        vault = ERC721Vault(_vaultAddress);
        transferOwnership(_owner);
    }

    function setVaultAddress(address _address) external onlyOwner {
        vault = ERC721Vault(_address);
    }

    function approvedCollection(address _contract) external view returns (bool) {
        return collections[_contract].exists;
    }

    function getCollections() external view returns (address[] memory) {
        return contracts;
    }

    function addCollections(address[] memory _contracts, uint72[] memory _softRates, uint72[] memory _hardRates) external onlyOwner {
        for (uint256 i = 0; i < _contracts.length; i++) {
            address _contract = _contracts[i];
            require(!collections[_contract].exists, "Bad collection");
            contracts.push(_contract);
            collections[_contract].hardRate = (_hardRates[i] * (10**18)) / (60 * 60 * 24);
            collections[_contract].softRate = (_softRates[i] * (10**18)) / (60 * 60 * 24);
            collections[_contract].exists = true;
        }
    }

    function updateCollection(address _contract, uint72 _softRate, uint72 _hardRate) public onlyOwner {
        require(collections[_contract].exists, "Bad collection");
        collections[_contract].hardRate = (_hardRate * (10**18)) / (60 * 60 * 24);
        collections[_contract].softRate = (_softRate * (10**18)) / (60 * 60 * 24);
    }

    function removeCollection(address _contract) public onlyOwner nonReentrant {
        require(vault.stakedCount(_contract, HARD_STAKED) == 0, "Can't delete");
        require(vault.stakedCount(_contract, SOFT_STAKED) == 0, "Can't delete");
        delete collections[_contract];
        for (uint256 i = 0; i < contracts.length; i++) {
            if (_contract == contracts[i]) {
                contracts[i] = contracts[contracts.length - 1];
                contracts.pop();
            }
        }
    }

    function addMultipliers(address _contract, uint256[] calldata _tokenIds, uint256[] calldata _multiples) public onlyOwner {
        require(_tokenIds.length == _multiples.length, "Invalid parameters");
        require(_tokenIds.length > 0, "Must pass tokenIds");
        for (uint256 i; i < _tokenIds.length; i++) {
            require(!tokenMultipliers[_contract].contains(_tokenIds[i]), "Can't add");
            tokenMultipliers[_contract].add(_tokenIds[i]);
            tokenMultiples[_contract][_tokenIds[i]] = _multiples[i];
        }
    }

    function removeMultipliers(address _contract, uint256[] calldata _tokenIds) public onlyOwner {
        for (uint256 i; i < _tokenIds.length; i++) {
            require(tokenMultipliers[_contract].contains(_tokenIds[i]), "Can't remove");
            tokenMultipliers[_contract].remove(_tokenIds[i]);
            delete tokenMultiples[_contract][_tokenIds[i]];
        }
    }

    function multipliersOf(address _contract)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        EnumerableSet.UintSet storage _multiplierSet = tokenMultipliers[_contract];
        uint256[] memory _tokenIds = new uint256[](_multiplierSet.length());
        uint256[] memory _multiples = new uint256[](_multiplierSet.length());
        for (uint256 i; i < _multiplierSet.length(); i++) {
            _tokenIds[i] = _multiplierSet.at(i);
            _multiples[i] = tokenMultiples[_contract][_tokenIds[i]];
        }
        return (_tokenIds, _multiples);
    }

    function rewardsByTokenId(address _contract, uint256[] memory _tokenIds, uint8 _type)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory _rewards = new uint256[](_tokenIds.length);
        if (!vault.getConfiguration(_type)) return (_tokenIds, _rewards);
        if (paused) return (_tokenIds, _rewards);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            address _owner = vault.getStaker(_contract, _tokenId, _type);
            if(_owner == address(0)) {
                _rewards[i] = 0;
            } else {
                uint256 depositTime = vault.depositTimeOf(_owner, _contract, _tokenId, _type);
                uint256 _rate = _type == SOFT_STAKED ? collections[_contract].softRate : collections[_contract].hardRate;
                if (tokenMultipliers[_contract].contains(_tokenId)) {
                    _rate = _rate * tokenMultiples[_contract][_tokenId];
                }
                uint256 _diff = block.timestamp - depositTime;
                _rewards[i] = _rate * _diff;
            }
        }
        return (_tokenIds, _rewards);
    }

    function calculateDailyRewards(address _address, uint8 _type)
        public 
        view
        returns (uint256)
    {
        if (paused) return 0;
        if (!vault.getConfiguration(_type)) return 0;
        uint256 _rewards;
        uint256 _seconds = 60 * 60 * 24;
        for (uint256 i = 0; i < contracts.length; i++) {
            address _contract = contracts[i];
            uint256 _rate = _type == SOFT_STAKED ? collections[_contract].softRate : collections[_contract].hardRate;
            uint256[] memory _tokenIds = vault.depositsOf(_address, _contract, _type);
            for (uint256 j; j < _tokenIds.length; j++) {
                uint256 _tokenId = _tokenIds[j];
                if (tokenMultipliers[_contract].contains(_tokenId)) {
                    _rewards += _rate * tokenMultiples[_contract][_tokenId] * _seconds;
                } else {
                    _rewards += _rate * _seconds;
                }
            }
        }
        return _rewards;
    }

    function claimRewards(uint8 _type) public nonReentrant {
        require(!paused, "Contract paused");
        vault.claimRewards(msg.sender, _type);
        vault.clearDepositTimesOf(msg.sender, contracts, _type);
    }

    function calculateRewards(address _address, uint8 _type) public view returns (uint256) {
        if (paused) return 0;
        if (!vault.getConfiguration(_type)) return 0;
         uint256 _rewards;
         uint256 depositTime;
         uint256 _diff;
         for (uint256 i = 0; i < contracts.length; i++) {
            address _contract = contracts[i];
            uint256[] memory _tokenIds = vault.depositsOf(_address, _contract, _type);
            for (uint256 j; j < _tokenIds.length; j++) {
                uint256 _tokenId = _tokenIds[j];
                depositTime = vault.depositTimeOf(_address, _contract, _tokenId, _type);
                uint256 _rate = _type == SOFT_STAKED ? collections[_contract].softRate : collections[_contract].hardRate;
                if (tokenMultipliers[_contract].contains(_tokenId)) {
                    _rate = _rate * tokenMultiples[_contract][_tokenId];
                }
                _diff = block.timestamp - depositTime;
                _rewards += _rate * _diff;
            }
        }
        return _rewards;
    }

    function withdraw(uint256 _amount, address _contract) public nonReentrant onlyOwner {
        require(IERC20(_contract).balanceOf(address(this)) >= _amount, "Insufficient balance");
        IERC20(_contract).transfer(msg.sender, _amount);
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }
}