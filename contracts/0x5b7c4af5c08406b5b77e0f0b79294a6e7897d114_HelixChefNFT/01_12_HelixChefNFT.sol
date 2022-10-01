// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "../interfaces/IHelixNFT.sol";
import "../interfaces/IFeeMinter.sol";
import "../interfaces/IHelixToken.sol";
import "../interfaces/ISynthReactor.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/// Enable users to stake NFTs and earn rewards
contract HelixChefNFT is 
    Initializable, 
    OwnableUpgradeable, 
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    // Info on each user who has NFTs staked in this contract
    struct UserInfo {
        uint256[] stakedNftIds; // Ids of the NFTs this user has staked
        uint256 accruedReward;  // Amount of directly accrued helixToken
        uint256 rewardDebt;     // Used in reward calculations
        uint256 stakedNfts;     // Total (wrapped and unwrapped) nfts
    }

    /// Owner approved contracts which can accrue user rewards
    EnumerableSetUpgradeable.AddressSet private _accruers;

    /// Instance of HelixNFT
    IHelixNFT public helixNFT;

    /// Token that rewards are earned in
    IHelixToken public helixToken;

    /// Called to get helixToken to mint per block
    IFeeMinter public feeMinter;

    /// Maps a user's address to their info struct
    mapping(address => UserInfo) public users;

    /// Used in reward calculations
    uint256 public accTokenPerShare;

    /// Last block number when rewards were reward
    uint256 public lastUpdateBlock;
    
    /// Total (wrapped and unwrapped) nfts staked in this contract
    uint256 public totalStakedNfts;

    // Used in reward calculations
    uint256 private constant REWARDS_PRECISION = 1e12;

    // Tracks staked nfts and mints synth token to stakers
    ISynthReactor public synthReactor;

    // Emitted when an NFTs are staked
    event Stake(address indexed user, uint256[] tokenIds);

    // Emitted when an NFTs are unstaked
    event Unstake(address indexed user, uint256[] tokenIds);

    // Emitted when a user's transaction results in accrued reward
    event AccrueReward(address indexed user, uint256 accruedReward);

    // Emitted when an accruer is added
    event AddAccruer(address indexed adder, address indexed added);

    // Emitted when an accruer is removed
    event RemoveAccruer(address indexed remover, address indexed removed);

    // Emitted when a new helixNFT address is set
    event SetHelixNFT(address indexed setter, address indexed helixNFT);

    // Emitted when a new helixToken address is set
    event SetHelixToken(address indexed setter, address indexed helixToken);

    // Emitted when a new feeMinter is set
    event SetFeeMinter(address indexed setter, address indexed feeMinter);

    // Emitted when the pool is updated
    event UpdatePool(
        uint256 indexed accTokenPerShare, 
        uint256 indexed lastUpdateBlock, 
        uint256 indexed toMint
    );

    // Emitted when a user harvests their rewards
    event HarvestRewards(address harvester, uint256 rewards);

    // Emitted when a new synthReactor address is set
    event SetSynthReactor(address indexed setter, address indexed synthReactor);

    modifier onlyAccruer {
        require(isAccruer(msg.sender), "caller is not an accruer");
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "zero address");
        _;
    }

    function initialize(
        address _helixNFT, 
        address _helixToken,
        address _feeMinter
    ) 
        external 
        initializer 
        onlyValidAddress(_helixNFT)
        onlyValidAddress(_helixToken)
        onlyValidAddress(_feeMinter)
    {
        __Ownable_init();
        __ReentrancyGuard_init();
        helixNFT = IHelixNFT(_helixNFT);
        helixToken = IHelixToken(_helixToken);
        feeMinter = IFeeMinter(_feeMinter);
        lastUpdateBlock = block.number;
    }

    /// Stake the tokens with _tokenIds in the pool
    function stake(uint256[] memory _tokenIds) external whenNotPaused nonReentrant {
        uint256 tokenIdsLength = _tokenIds.length; 
        require(tokenIdsLength > 0, "tokenIds length can not be zero");
        
        UserInfo storage user = users[msg.sender];

        harvestRewards();
  
        uint256 stakedNfts = 0;
        for (uint256 i = 0; i < tokenIdsLength; i++){
            (address tokenOwner, bool isStaked, uint256 wrappedNfts) = helixNFT.getInfoForStaking(
                _tokenIds[i]
            );

            require(msg.sender == tokenOwner, "caller is not token owner");
            require(!isStaked, "token is already staked");

            helixNFT.setIsStaked(_tokenIds[i], true);
            user.stakedNftIds.push(_tokenIds[i]);

            stakedNfts += (wrappedNfts > 0) ? wrappedNfts : 1;
        }
        user.stakedNfts += stakedNfts;
        totalStakedNfts += stakedNfts;

        _notifySynthReactor(msg.sender, user.stakedNfts);

        emit Stake(msg.sender, _tokenIds);
    }

    /// Unstake the tokens with _tokenIds in the pool
    function unstake(uint256[] memory _tokenIds) external whenNotPaused nonReentrant {
        uint256 tokenIdsLength = _tokenIds.length;
        require(tokenIdsLength > 0, "tokenIds length can not be zero");

        UserInfo storage user = users[msg.sender];
        uint256 stakedNfts = user.stakedNfts;
        require(stakedNfts > 0, "caller has not staked any nfts");

        harvestRewards();
        
        uint256 unstakedNfts = 0;
        for (uint256 i = 0; i < tokenIdsLength; i++){
            (address tokenOwner, bool isStaked, uint256 wrappedNfts) = 
                helixNFT.getInfoForStaking(_tokenIds[i]);

            require(msg.sender == tokenOwner, "caller is not token owner");
            require(isStaked, "token is already unstaked");

            helixNFT.setIsStaked(_tokenIds[i], false);
            _removeTokenIdFromUser(msg.sender, _tokenIds[i]);

            unstakedNfts += (wrappedNfts > 0) ? wrappedNfts : 1;
        }
        user.stakedNfts -= unstakedNfts;
        totalStakedNfts -= unstakedNfts;

        _notifySynthReactor(msg.sender, user.stakedNfts);

        emit Unstake(msg.sender, _tokenIds);
    }

    /// Accrue reward to the _user's account based on the transaction _fee
    function accrueReward(address _user, uint256 _fee) external onlyAccruer {
        uint256 reward = getAccruedReward(_user, _fee);
        users[_user].accruedReward += reward;
        emit AccrueReward(_user, reward);
    }

    /// Called by the owner to add an accruer
    function addAccruer(address _address) external onlyOwner onlyValidAddress(_address) {
        bool success = EnumerableSetUpgradeable.add(_accruers, _address);
        require(success, "add accruer failed");
        emit AddAccruer(msg.sender, _address);
    }

    /// Called by the owner to remove an accruer
    function removeAccruer(address _address) external onlyOwner {
        require(isAccruer(_address), "caller not an accruer");
        bool success = EnumerableSetUpgradeable.remove(_accruers, _address);
        require(success, "remove accruer failed");
        emit RemoveAccruer(msg.sender, _address);
    }   
    
    /// Called by the owner to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// Called by the owner to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// Called by the owner to set the _helixNFT address
    function setHelixNFT(address _helixNFT) external onlyOwner onlyValidAddress(_helixNFT) {
        helixNFT = IHelixNFT(_helixNFT);
        emit SetHelixNFT(msg.sender, _helixNFT);
    }

    /// Called by the owner to set the _helixToken address
    function setHelixToken(address _helixToken) external onlyOwner onlyValidAddress(_helixToken) {
        helixToken = IHelixToken(_helixToken);
        emit SetHelixToken(msg.sender, _helixToken);
    }

    /// Called by the owner to set the _feeMinter address
    function setFeeMinter(address _feeMinter) external onlyOwner onlyValidAddress(_feeMinter) {
        feeMinter = IFeeMinter(_feeMinter);
        emit SetFeeMinter(msg.sender, _feeMinter);
    }

    /// Called by the owner to set the _synthReactor address
    function setSynthReactor(address _synthReactor) external onlyOwner onlyValidAddress(_synthReactor) {
        synthReactor = ISynthReactor(_synthReactor);
        emit SetSynthReactor(msg.sender, _synthReactor);
    }

    /// Return the _user's pending reward
    function getPendingReward(address _user) external view returns (uint256) {
        UserInfo memory user = users[_user];
   
        uint256 _accTokenPerShare = accTokenPerShare;
        if (block.number > lastUpdateBlock) {
            uint256 blockDelta = block.number - lastUpdateBlock;
            uint256 rewards = blockDelta * getRewardsPerBlock();
            _accTokenPerShare += rewards * REWARDS_PRECISION / totalStakedNfts;
        }
  
        uint256 toMint = users[_user].stakedNfts * _accTokenPerShare / REWARDS_PRECISION;
        toMint += user.accruedReward;
        if (toMint > user.rewardDebt) {
            return toMint - user.rewardDebt;
        } else {
            return 0;
        }
    }

    /// Return the accruer at _index
    function getAccruer(uint256 _index) external view returns (address) {
        require(_index <= getNumAccruers() - 1, "index out of bounds");
        return EnumerableSetUpgradeable.at(_accruers, _index);
    }

    /// Return the list of nft ids staked by the user
    function getStakedNftIds(address _user) external view returns (uint256[] memory) {
        return users[_user].stakedNftIds;
    }

    // Return the number of nfts staked by user
    function getUserStakedNfts(address _user) external view returns (uint256) {
        return users[_user].stakedNfts;
    }

    /// Mint the caller's rewards to their address
    function harvestRewards() public {
        updatePool();
        UserInfo storage user = users[msg.sender];

        uint256 rewards = _getRewards(msg.sender) + user.accruedReward;
        uint256 toMint = rewards > user.rewardDebt ? rewards - user.rewardDebt : 0;
        user.rewardDebt = rewards;
        user.accruedReward = 0;

        if (toMint <= 0) {
            return;
        }

        emit HarvestRewards(msg.sender, toMint);
        bool success = helixToken.mint(msg.sender, toMint);
        require(success, "harvest rewards failed");
    }

    /// Update the pool's accTokenPerShare and lastUpdateBlock
    function updatePool() public {
        if (block.number <= lastUpdateBlock) {
            return;
        }

        if (totalStakedNfts == 0) {
            lastUpdateBlock = block.number;
            emit UpdatePool(accTokenPerShare, lastUpdateBlock, 0);
            return;
        } 

        uint256 blockDelta = block.number - lastUpdateBlock;
        uint256 rewards = blockDelta * getRewardsPerBlock();
        accTokenPerShare = accTokenPerShare + (rewards * REWARDS_PRECISION / totalStakedNfts);
        lastUpdateBlock = block.number;

        emit UpdatePool(accTokenPerShare, lastUpdateBlock, rewards);
    }

    /// Return the number of added _accruers
    function getNumAccruers() public view returns (uint256) {
        return EnumerableSetUpgradeable.length(_accruers);
    }

    /// Return the reward accrued to _user based on the transaction _fee
    function getAccruedReward(address _user, uint256 _fee) public view returns (uint256) {
        if (totalStakedNfts == 0) {
            return 0;
        }
        return users[_user].stakedNfts * _fee / totalStakedNfts;
    }

    /// Return true if the _address is a registered accruer and false otherwise
    function isAccruer(address _address) public view returns (bool) {
        return EnumerableSetUpgradeable.contains(_accruers, _address);
    }

    // Return the toMintPerBlockRate assigned to this contract by the feeMinter
    function getRewardsPerBlock() public view returns (uint256) {
        return feeMinter.getToMintPerBlock(address(this));
    }

    // Remove _tokenId from _user's account
    function _removeTokenIdFromUser(address _user, uint256 _tokenId) private {
        uint256[] storage tokenIds = users[_user].stakedNftIds;
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (_tokenId == tokenIds[i]) {
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                return;
            }
        }
    }

    // Return the _user's rewards
    function _getRewards(address _user) private view returns (uint256) {
        return users[_user].stakedNfts * accTokenPerShare / REWARDS_PRECISION;
    }

    // Register the change in _user's _stakedNfts with the synthReactor
    function _notifySynthReactor(address _user, uint256 _stakedNfts) private {
        if (address(synthReactor) != address(0)) {
            synthReactor.updateUserStakedNfts(_user, _stakedNfts);
        }
    }
}