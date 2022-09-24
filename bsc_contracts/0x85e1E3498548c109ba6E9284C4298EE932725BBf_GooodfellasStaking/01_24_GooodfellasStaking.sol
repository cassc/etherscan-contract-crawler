// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./StakingState.sol";
import "./tiers/StakingTiers.sol";
import "./erc721/StakedToken.sol";
import "./erc20/IGooodToken.sol";
import "./utils/TokenWeights.sol";
import "./utils/EmergencyWithdrawable.sol";

// import "hardhat/console.sol";

contract GooodfellasStaking is EmergencyWithdrawable, StakingState, StakingTiers, TokenWeights, Pausable, ReentrancyGuard {

    // The GOOOD token
    IGooodToken public immutable goood;
    // GOOOD token created per block
    uint256 public gooodPerBlock;
    // The block number when GOOOD minting starts
    uint256 public immutable startBlock;
    // Last block number that GOOODs distribution occured.
    uint256 public lastRewardBlock; 
    // Accumulated GOOOD per share, times 1e12. See below.
    mapping(uint256 => uint256) public accGooodPerShare; 

    // Stakeable collections
    address[] private _stakeableCollections;
    // Reverse indices of collections
    mapping(address => uint256) public collectionIndex;
    // Staked token receipt for stakeable NFTs
    mapping(address => StakedToken) public stakedTokens;
    

    event EmissionRateChanged(uint256 oldGooodPerBlock, uint256 newGooodPerBlock);

    constructor(
        IGooodToken _goood,
        uint256 _gooodPerBlock,
        uint256 _startBlock) 
    {
        goood = _goood;
        gooodPerBlock = _gooodPerBlock;
        startBlock = _startBlock;

        lastRewardBlock = _startBlock;
    }


    // --- user interface ---

    // update reward variables to be up-to-date
    function update() public whenNotPaused {
        GlobalState memory global = globalState();
        Config memory config = collectionConfig(global.pid);
        uint256 totalAmount = getTotalWeight(global, config);

        if (block.number <= lastRewardBlock) {
            return;
        }
        if (totalAmount == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 gooodReward = multiplier * gooodPerBlock;
        goood.mint(address(this), gooodReward);
        accGooodPerShare[global.pid] += gooodReward * 1e12 / totalAmount;
        lastRewardBlock = block.number; 
    }

    // claim rewards and stake tokens
    function stake(address[] calldata _collections, uint256[][] calldata _tokenIds) external whenNotPaused nonReentrant {
        require(_collections.length == _tokenIds.length, "Invalid lengths");
        
        update();

        UserState memory user = userState(msg.sender);
        GlobalState memory global = globalState();
        Config memory config;
        uint256 pending;

        for (uint256 _pid = user.pid; _pid <= global.pid; ++_pid) {
            config = collectionConfig(_pid);
            pending += _pendingGoood(user, config);
        }
        if (pending > 0) {
            _safeGooodTransfer(msg.sender, pending);
        }
        if (_collections.length > 0) {
            for(uint256 i = 0; i < _collections.length; ++i) {
                StakedToken stakedToken = stakedTokens[_collections[i]];
                require(address(stakedToken) != address(0), "Unknown collection");
                uint256 _collectionIndex = collectionIndex[_collections[i]];

                uint256 weight = _stakeTokens(msg.sender, _collections[i], stakedToken, _tokenIds[i]);

                user.weightCollection[_collectionIndex] += weight;
                global.totalWeightCollection[_collectionIndex] += weight;
            }

            global.totalBonusWeight -= getBonusWeight(user, config);
        }
        
        if (_collections.length > 0 || user.pid != global.pid) {
            user.bonusWeight = calculateTierBonus(msg.sender, getCollectionsWeight(user, config));
            user.pid = global.pid;
            global.totalBonusWeight += user.bonusWeight; 
        }

        setRewardDebt(global.pid, msg.sender, getWeight(user, config) * accGooodPerShare[global.pid] / 1e12);
        setUserWeight(user);
        setGlobalState(global);
    }


    // claim rewards and unstake tokens
    function unstake(address[] calldata _collections, uint256[][] calldata _tokenIds) external whenNotPaused nonReentrant {
        require(_collections.length == _tokenIds.length, "Invalid lengths");
        
        update();

        UserState memory user = userState(msg.sender);
        GlobalState memory global = globalState();
        Config memory config;
        uint256 pending;

        for (uint256 _pid = user.pid; _pid <= global.pid; ++_pid) {
            config = collectionConfig(_pid);
            pending += _pendingGoood(user, config);
        }
        if (pending > 0) {
            _safeGooodTransfer(msg.sender, pending);
        }
        if (_collections.length > 0) {
            for(uint256 i = 0; i < _collections.length; ++i) {
                StakedToken stakedToken = stakedTokens[_collections[i]];
                require(address(stakedToken) != address(0), "Unknown collection");
                uint256 _collectionIndex = collectionIndex[_collections[i]];

                uint256 weight = _unstakeTokens(msg.sender, _collections[i], stakedToken, _tokenIds[i]);

                user.weightCollection[_collectionIndex] -= weight;
                global.totalWeightCollection[_collectionIndex] -= weight;
            }

            global.totalBonusWeight -= getBonusWeight(user, config);
        }
        
        if (_collections.length > 0 || user.pid != global.pid) {
            user.bonusWeight = calculateTierBonus(msg.sender, getCollectionsWeight(user, config));
            user.pid = global.pid;
            global.totalBonusWeight += user.bonusWeight; 
        }

        setRewardDebt(global.pid, msg.sender, getWeight(user, config) * accGooodPerShare[global.pid] / 1e12);
        setUserWeight(user);
        setGlobalState(global);
    }

    function activateTierBonus() external whenNotPaused nonReentrant {
        update();

        UserState memory user = userState(msg.sender);
        GlobalState memory global = globalState();
        Config memory config = collectionConfig(global.pid);

        require(user.pid != global.pid, "Already up to date");

        user.bonusWeight = calculateTierBonus(msg.sender, getCollectionsWeight(user, config));
        user.pid = global.pid;
        global.totalBonusWeight += user.bonusWeight; 

        setUserWeight(user);
        setGlobalState(global);
    }


    // --- admin interface ---

    function addStakeableCollection(address _collection) external onlyOwner {
        require(address(stakedTokens[_collection]) == address(0), "Already added");

        collectionIndex[_collection] = _stakeableCollections.length;
        _stakeableCollections.push(_collection);
        stakedTokens[_collection] = new StakedToken(_collection);
    }
    
    function setCollectionFactors(uint256[6] calldata factors) external onlyOwner {
        update();

        GlobalState memory global = nextPid();
        Config memory config = collectionConfig(global.pid);
        for (uint256 i = 0; i < factors.length; ++i) {
            require(factors[i] <= 100, "Factor > 100");
            config.factor[i] = factors[i];
        }
        setCollectionConfig(config);
    }

    function setTierBonusLogic(address _logic) external onlyOwner {
        update();

        _upgradeTierLogic(_logic);

        Config memory config = collectionConfig(globalState().pid);
        config.pid = nextPid().pid;
        setCollectionConfig(config);
    }

    function setEmissionRate(uint256 _gooodPerBlock) external onlyOwner {
        update();

        emit EmissionRateChanged(gooodPerBlock, _gooodPerBlock);
        gooodPerBlock = _gooodPerBlock;
    }

    function setBaseURI(address _collection, string memory _uri) external onlyOwner {
        StakedToken stakedToken = stakedTokens[_collection];
        require(address(stakedToken) != address(0));
        stakedToken.setBaseURI(_uri);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function emergencyTransferIGooodTokenOwnership(address _newOwner) external onlyOwner {
        goood.transferOwnership(_newOwner);
    }


    // --- read methods ---
    function _pendingGoood(UserState memory user, Config memory config) internal view returns (uint256) {
        return (getWeight(user, config) * accGooodPerShare[config.pid] / 1e12) - rewardDebt(config.pid, user.user);
    }

    function pendingGoood(address _user) external view returns (uint256 pending) {
        UserState memory user = userState(_user);
        GlobalState memory global = globalState();
        Config memory config;

        for (uint256 _pid = user.pid; _pid < global.pid; ++_pid) {
            config = collectionConfig(_pid);
            pending += _pendingGoood(user, config);
        }

        config = collectionConfig(global.pid);
        uint256 totalAmount = getTotalWeight(global, config);
        uint256 userAmount = getWeight(user, config);

        uint256 _accGooodPerShare = accGooodPerShare[global.pid];
        if (block.number > lastRewardBlock && totalAmount != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
            uint256 gooodReward = multiplier * gooodPerBlock;
            _accGooodPerShare += gooodReward * 1e12 / totalAmount;
        }

        pending += (userAmount * _accGooodPerShare / 1e12) - rewardDebt(global.pid, user.user);
    }

    function canActivateTierBonus(address _user) external view returns (bool) {
        UserState memory user = userState(_user);
        GlobalState memory global = globalState();
        Config memory config = collectionConfig(global.pid);

        return (user.pid != global.pid) && (calculateTierBonus(_user,  getCollectionsWeight(user, config)) != 0);
    }

    function stakeableCollections() external view returns (address[] memory) {
        return _stakeableCollections;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to - _from;
    }


    function _stakeTokens(address _user, address _collection, StakedToken _stakedToken, uint256[] calldata _tokenIds) internal returns (uint256 weight) {
        require(_tokenIds.length != 0, "Empty array");
        for (uint256 i = 0; i < _tokenIds.length; ) {
            weight += _stakeToken(_user, _stakedToken, _collection, _tokenIds[i]);
            unchecked {++i;}
        }
        return weight;
    }

    function _unstakeTokens(address _user, address _collection, StakedToken _stakedToken, uint256[] calldata _tokenIds) internal returns (uint256 weight) {
        require(_tokenIds.length != 0, "Empty array");
        for (uint256 i = 0; i < _tokenIds.length; ) {
            weight += _unstakeToken(_user, _stakedToken, _collection, _tokenIds[i]);
            unchecked {++i;}
        }
        return weight;
    }

    function _stakeToken(address _user, StakedToken _stakedToken, address _collection, uint256 _tokenId) internal returns (uint256) {
        require(IERC721(_collection).ownerOf(_tokenId) == _user, "Not owner");
        IERC721(_collection).transferFrom(_user, address(this), _tokenId);
        _stakedToken.mint(_user, _tokenId);
        return _weightOfToken(_collection, _tokenId);
    }

    function _unstakeToken(address _user, StakedToken _stakedToken, address _collection, uint256 _tokenId) internal returns (uint256) {
        require(_stakedToken.ownerOf(_tokenId) == _user, "Not owner");
        IERC721(_collection).transferFrom(address(this), _user, _tokenId);
        _stakedToken.burn( _tokenId);
        return _weightOfToken(_collection, _tokenId);
    }

    // Safe Goood transfer function, just in case if rounding error causes _pid to not have enough Goood.
    function _safeGooodTransfer(address _to, uint256 _amount) internal {
        uint256 gooodBal = goood.balanceOf(address(this));
        if (_amount > gooodBal) {
            goood.transfer(_to, gooodBal);
        } else {
            goood.transfer(_to, _amount);
        }
    }
}