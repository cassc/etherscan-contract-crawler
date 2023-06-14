// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ICryptoPirates {
    function types(uint256) external view returns (uint256);
    function TYPE_COMMON() external view returns (uint256);
    function TYPE_RARE() external view returns (uint256);
    function TYPE_EPIC() external view returns (uint256);
    function TYPE_LEGENDARY() external view returns (uint256);
}

contract ThePirateBay is Ownable, IERC721Receiver, Pausable, ReentrancyGuard {
    // whether or not rescue is enabled
    bool public rescueEnabled = false;
    // address of the NFT contract
    IERC721 public nftAddress;
    // address of the ERC20 token
    IERC20 public tokenAddress;

    uint256 public constant amountPerNFT = 10_000_000 ether; // amount of tokens per NFT
    uint256 public constant totalLockTime = 10 days; // how long the lock is
    uint256 public constant totalReward = 2_000_000_000 ether; // total reward for the pool (2 billion tokens)

    uint256 public constant COMMON_MULTIPLIER = 100; // 1
    uint256 public constant RARE_MULTIPLIER = 125; // 1.25
    uint256 public constant EPIC_MULTIPLIER = 200; // 2
    uint256 public constant LEGENDARY_MULTIPLIER = 500; // 5
    
    bool public depositStarted = true; // whether or not depositing has started
    uint256 public lockStartTime = 1686650400; // Tuesday, June 13, 2023 10:00:00 AM

    uint256 public totalStaked; // total amount of tokens staked
    uint256 public totalNFTsStaked; // total amount of NFTs staked
    uint256 public totalMultipliers; // total amount of multipliers

    struct Stake {
        uint256 amount; // amount of tokens staked
        uint256[] nftIds; // array of NFTs staked
        bool claimed; // whether the user has claimed their reward
    }

    mapping(uint256 => bool) private nftIdsStaked; // whether or not an NFT has been staked

    mapping(address => Stake) public stakes; // stake of an account

    event Staked(address indexed user, uint256 amount, uint256[] nftIds);
    event Claimed(address indexed user, uint256 amount);

    constructor(address _nftAddress, address _tokenAddress) {
        nftAddress = IERC721(_nftAddress);
        tokenAddress = IERC20(_tokenAddress);
    }

    modifier whenDepositOn() {
        require(depositStarted, "Cannot stake before deposit started");
        require(lockStartTime > block.timestamp, "Cannot stake after lock started");
        _;
    }

    modifier whenLockOver() {
        require(lockStartTime + totalLockTime < block.timestamp, "Cannot claim during lock time");
        _;
    }

    modifier whenRescueEnabled() {
        require(rescueEnabled, "Rescue is not enabled");
        _;
    }

    /// @dev allows user to stake tokens and NFTs
    /// @param _nftIds ids of the NFTs to stake
    function stake(uint256[] calldata _nftIds) external whenNotPaused whenDepositOn nonReentrant {
        require(_nftIds.length > 0, "Cannot stake 0 NFTs");
        
        uint256 totalAmount = amountPerNFT * _nftIds.length;

        Stake storage _stake = stakes[_msgSender()];

        // transfer tokens to contract
        tokenAddress.transferFrom(_msgSender(), address(this), totalAmount);
        // transfer NFTs to contract
        for (uint256 i = 0; i < _nftIds.length; i++) {
            require(!nftIdsStaked[_nftIds[i]], "Cannot stake the same NFT twice");
            nftAddress.transferFrom(_msgSender(), address(this), _nftIds[i]);
            _stake.nftIds.push(_nftIds[i]);
            nftIdsStaked[_nftIds[i]] = true;
            totalMultipliers += nftMultiplier(_nftIds[i]);
        }

        // update stake
        _stake.amount += totalAmount;

        // update totals
        totalStaked += totalAmount;
        totalNFTsStaked += _nftIds.length;

        emit Staked(_msgSender(), totalAmount, _nftIds);
    }

    /// @dev allows user to claim tokens and NFTs
    function claim() external whenNotPaused whenLockOver nonReentrant {
        Stake memory _stake = stakes[_msgSender()];
        require(_stake.amount > 0, "Cannot claim before staking");
        require(!_stake.claimed, "Cannot claim twice");

        _stake.claimed = true;

        // transfer NFTs to user
        for (uint256 i = 0; i < _stake.nftIds.length; i++) {
            nftAddress.transferFrom(address(this), _msgSender(), _stake.nftIds[i]);
        }

        uint256 totalAmount = _stake.amount + earned(_msgSender());

        // transfer tokens to user
        require(IERC20(tokenAddress).transfer(_msgSender(), totalAmount), "Cannot transfer tokens to user");

        emit Claimed(_msgSender(), totalAmount);
    }

    /// @dev returns the amount of tokens earned
    /// @param account address of the account
    function earned(address account) public view returns (uint256 _earned) {
        uint256 multiplier = totalMultiplier(account);
        return multiplier * totalReward / totalMultipliers;
    }

    /// @dev returns the multiplier for an NFT
    /// @param nftId id of the NFT
    function nftMultiplier(uint256 nftId) public view returns (uint256 multiplier) {
        ICryptoPirates cryptoPirates = ICryptoPirates(address(nftAddress));
        uint256 nftType = cryptoPirates.types(nftId);
        if (nftType == cryptoPirates.TYPE_COMMON()) {
            return COMMON_MULTIPLIER;
        } else if (nftType == cryptoPirates.TYPE_RARE()) {
            return RARE_MULTIPLIER;
        } else if (nftType == cryptoPirates.TYPE_EPIC()) {
            return EPIC_MULTIPLIER;
        } else if (nftType == cryptoPirates.TYPE_LEGENDARY()) {
            return LEGENDARY_MULTIPLIER;
        }
        return COMMON_MULTIPLIER;
    }

    /// @dev returns the total multiplier for an account
    /// @param account address of the account
    function totalMultiplier(address account) public view returns (uint256 multiplier) {
        Stake memory _stake = stakes[account];
        for (uint256 i = 0; i < _stake.nftIds.length; i++) {
            multiplier += nftMultiplier(_stake.nftIds[i]);
        }
        return multiplier;
    }

    /// @dev returns the NFTs staked by an account
    /// @param account address of the account
    function userNFTs(address account) public view returns (uint256[] memory nftIds) {
        Stake memory _stake = stakes[account];
        return _stake.nftIds;
    }

    /// @dev returns the stats of an account
    /// @param account address of the account
    function userStats(address account) public view 
        returns (uint256 nfts, uint256 staked, uint256 multiplier, uint256 share, uint256 reward, bool claimed)
    {
        Stake memory _stake = stakes[account];
        nfts = _stake.nftIds.length;
        staked = _stake.amount;
        multiplier = totalMultiplier(account);
        share = multiplier * 10000 / totalMultipliers;
        uint256 stakeTime = 0;
        if (lockStartTime > block.timestamp) stakeTime = 0;
        else if (lockStartTime + totalLockTime < block.timestamp) stakeTime = totalLockTime;
        else stakeTime = block.timestamp - lockStartTime;
        reward = earned(account) * stakeTime / totalLockTime;
        claimed = _stake.claimed;
    }

    /// @dev allows owner to set the lock start time
    /// @param _lockStartTime timestamp of when locking starts
    function setLockStartTime(uint256 _lockStartTime) external whenDepositOn onlyOwner {
        require(_lockStartTime > block.timestamp, "Cannot set time before current time");
        lockStartTime = _lockStartTime;
    }

    /// @dev allows owner to set wether or not depositing has started
    /// @param _depositStarted boolean
    function setDepositStarted(bool _depositStarted) external onlyOwner {
        depositStarted = _depositStarted;
    }

    /// @dev allows owner to enable "rescue mode"
    /// @param _enabled boolean
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    /// @dev enables owner to pause / unpause minting
    /// @param _paused boolean
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /// @dev allows user to rescue tokens and NFTs
    /// @param account address of the account
    /// @param index index of the first NFT to rescue
    /// @param amount amount of NFTs to rescue
    function emergencyRescue(address account, uint256 index, uint256 amount) external whenNotPaused whenRescueEnabled nonReentrant {
        Stake memory _stake = stakes[account];

        // transfer NFTs to user
        for (uint256 i = index; i < (index + amount); i++) {
            nftAddress.transferFrom(address(this), account, _stake.nftIds[i]);
        }
    }

    /// @dev allows user to rescue tokens
    /// @param account address of the account
    function emergencyRescueTokens(address account) external whenNotPaused whenRescueEnabled nonReentrant {
        Stake memory _stake = stakes[account];
        require(!_stake.claimed, "Cannot rescue tokens after claiming");
        _stake.claimed = true;
        // transfer tokens to user
        require(IERC20(tokenAddress).transfer(account, _stake.amount), "Cannot transfer tokens to user");
    }


    /// @dev allows owner to rescue tokens
    /// @param amount amount of tokens to rescue
    function emergencyRewardRescue(uint256 amount) external onlyOwner whenRescueEnabled {
        require(IERC20(tokenAddress).transfer(_msgSender(), amount), "Cannot transfer tokens to user");
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens directly to the bay");
      return IERC721Receiver.onERC721Received.selector;
    }
}