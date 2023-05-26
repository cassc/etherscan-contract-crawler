// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './StakableTokenWrapper.sol';
import '../ERC1155/CryptoKombatCollection.sol';

contract LaunchPool is Context, StakableTokenWrapper, AccessControl {
    CryptoKombatCollection public collection;

    uint256 public maxStake;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public vombats;
    mapping(uint256 => uint256) public heroes;

    event MaxStakeChanged(uint256 maxStake);
    event HeroAdded(uint256 hero, uint256 price);
    event HeroesAdded(uint256[] heroes, uint256[] prices);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);

    modifier updateReward(address account) {
        if (account != address(0)) {
            vombats[account] = earned(account);
            lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    constructor(
        CryptoKombatCollection _collectionAddress,
        IERC20 _tokenAddress,
        uint256 _maxStake
    ) public StakableTokenWrapper(_tokenAddress) {
        collection = _collectionAddress;
        _setMaxStake(_maxStake);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function addHero(uint256 heroId, uint256 price) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'LaunchPool: Must have admin role to add hero');
        require(price >= 1e18, 'LaunchPool: Price too low');
        heroes[heroId] = price;
        emit HeroAdded(heroId, price);
    }

    function addHeroes(uint256[] memory _heroes, uint256[] memory _prices) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'LaunchPool: Must have admin role to add heroes');
        require(_heroes.length == _prices.length, 'LaunchPool: Heroes and prices length mismatch');
        for (uint256 i = 0; i < _heroes.length; i++) {
            uint256 heroId = _heroes[i];
            uint256 price = _prices[i];
            require(price >= 1e18, 'LaunchPool: Price too low');
            heroes[heroId] = price;
        }
        emit HeroesAdded(_heroes, _prices);
    }

    function setMaxStake(uint256 _maxStake) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'LaunchPool: Must have admin role to set max stake');
        require(_maxStake > 0, 'LaunchPool: Cannot set zero max stake');
        _setMaxStake(_maxStake);
    }

    function _setMaxStake(uint256 _maxStake) internal {
        maxStake = _maxStake;
        emit MaxStakeChanged(_maxStake);
    }

    function earned(address account) public view returns (uint256) {
        uint256 blockTime = block.timestamp;
        return
            vombats[account].add(
                blockTime.sub(lastUpdateTime[account]).mul(1e18).div(86400).mul(balanceOf(account).div(1e8))
            );
    }

    function stake(uint256 amount) public override updateReward(_msgSender()) {
        require(amount > 0, 'LaunchPool: Cannot stake zero amount');
        require(amount.add(balanceOf(_msgSender())) <= maxStake, 'LaunchPool: Cannot stake more than max stake');

        super.stake(amount);
        emit Staked(_msgSender(), amount);
    }

    function withdraw(uint256 amount) public override updateReward(_msgSender()) {
        require(amount > 0, 'LaunchPool: Cannot withdraw zero amount');

        super.withdraw(amount);
        emit Withdrawn(_msgSender(), amount);
    }

    function exit() external {
        withdraw(balanceOf(_msgSender()));
    }

    function redeem(uint256 hero) public updateReward(_msgSender()) {
        require(heroes[hero] != 0, 'LaunchPool: Hero not found');
        require(vombats[_msgSender()] >= heroes[hero], 'LaunchPool: Not enough Vombats to redeem for hero');
        require(collection.totalSupply(hero) < collection.maxSupply(hero), 'LaunchPool: Max heroes minted');

        vombats[_msgSender()] = vombats[_msgSender()].sub(heroes[hero]);
        collection.mint(_msgSender(), hero, 1, '');
        emit Redeemed(_msgSender(), heroes[hero]);
    }
}