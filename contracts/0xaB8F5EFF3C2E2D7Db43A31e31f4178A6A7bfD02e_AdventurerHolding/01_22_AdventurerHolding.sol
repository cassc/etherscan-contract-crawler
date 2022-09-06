// SPDX-License-Identifier: MIT
/**

 ________  ___    ___ ________  ___  ___  _______   ________  _________   
|\   __  \|\  \  /  /|\   __  \|\  \|\  \|\  ___ \ |\   ____\|\___   ___\ 
\ \  \|\  \ \  \/  / | \  \|\  \ \  \\\  \ \   __/|\ \  \___|\|___ \  \_| 
 \ \   ____\ \    / / \ \  \\\  \ \  \\\  \ \  \_|/_\ \_____  \   \ \  \  
  \ \  \___|/     \/   \ \  \\\  \ \  \\\  \ \  \_|\ \|____|\  \   \ \  \ 
   \ \__\  /  /\   \    \ \_____  \ \_______\ \_______\____\_\  \   \ \__\
    \|__| /__/ /\ __\    \|___| \__\|_______|\|_______|\_________\   \|__|
          |__|/ \|__|          \|__|                  \|_________|        
                                                                                                                                                    


 * @title AdventurerHolding
 * AdventurerHolding - a multi-purpose contract for staked PX Quest Adventurers
 */

pragma solidity ^0.8.11;

import "./IAdventurer.sol";
import "./IChronos.sol";
import "./IAdventurerHolding.sol";
import "./IAdventurerStaking.sol";
import "./utils/BitMap.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AdventurerHolding is
    Initializable,
    IAdventurerHolding,
    AccessControlUpgradeable,
    ERC721HolderUpgradeable
{
    using SafeERC20 for IChronos;
    IAdventurer public adventurerContract;
    IChronos public chronosContract;

    bytes32 public constant LOCK_IN_ROLE = keccak256("LOCK_IN_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // NFT tokenId to time staked and owner's address
    mapping(uint256 => StakedToken) public stakes;

    // Address to number of tokens they have staked
    mapping(address => uint256) public _userStakes;

    // Last update for claimed chronos
    mapping(address => uint256) public lastUpdated;

    // Add store of current claimable chronos
    mapping(address => uint256) public _chronosReward;

    // Store of BitMap representing token statuses
    mapping(uint256 => uint256) public _status;

    // Store of timestamp for token lock-in expiry.
    mapping(uint256 => uint256) _lockIn;

    uint256 public SHARED_SUMMON_REWARD = 150 ether; // 150 CHRONOS
    uint256 public constant SINGLE_SUMMON_COST = 750 ether; // 750 CHRONOS

    uint8 private constant SUMMON_BIT = 1;

    address private constant DEAD_ADDRESS = address(0xdead);
    uint256 public LOCK_IN = 0;
    bool grantChronos = true;

    uint256 private MAX_GEN_COUNT;

    function initialize(
        IAdventurer _adventurerContract,
        IChronos _chronosContract,
        address _adminAddress
    ) external payable initializer {
        if (
            (_adventurerContract == IAdventurer(address(0))) ||
            (_chronosContract == IChronos(address(0))) ||
            (_adminAddress == address(0))
        ) revert CannotBeZeroAddress();
        _grantRole(ADMIN_ROLE, _adminAddress);
        chronosContract = _chronosContract;
        adventurerContract = _adventurerContract;
        MAX_GEN_COUNT = adventurerContract.maxGenCount();
    }

    // VIEW FUNCTIONS

    // Considering an individual array of tokens staked per user/status isn't stored,
    // when we want to access this information externally, we are forced to use these
    // extremely gas expensive view functions which are made free by them being simply
    // calculated by the RPC instead of being an actual gas-ful transaction.

    function viewStakes(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokens = new uint256[](7500);
        uint256 tookCount = 0;
        for (uint64 i = 0; i < 7500; i++) {
            if (stakes[i].user == _address) {
                _tokens[tookCount] = i;
                tookCount++;
            }
        }
        uint256[] memory trimmedResult = new uint256[](tookCount);
        for (uint256 j = 0; j < trimmedResult.length; j++) {
            trimmedResult[j] = _tokens[j];
        }
        return trimmedResult;
    }

    function viewStakesByStatus(uint8[] memory status)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokens = new uint256[](7500);
        uint256 bitmap = BitMap.setBits(0, status);
        uint256 tookCount = 0;
        for (uint64 i = 0; i < 7500; i++) {
            if (_status[i] & bitmap == bitmap) {
                _tokens[tookCount] = i;
                tookCount++;
            }
        }
        uint256[] memory trimmedResult = new uint256[](tookCount);
        for (uint256 j = 0; j < trimmedResult.length; j++) {
            trimmedResult[j] = _tokens[j];
        }
        return trimmedResult;
    }

    function viewSharedSummoners() public view returns (uint256[] memory) {
        uint256[] memory _tokens = new uint256[](MAX_GEN_COUNT);
        uint256 tookCount = 0;
        for (uint64 i = 0; i <= MAX_GEN_COUNT; i++) {
            if (BitMap.checkBit(_status[i], SUMMON_BIT)) {
                _tokens[tookCount] = i;
                tookCount++;
            }
        }
        uint256[] memory trimmedResult = new uint256[](tookCount);
        for (uint256 j = 0; j < trimmedResult.length; j++) {
            trimmedResult[j] = _tokens[j];
        }
        return trimmedResult;
    }

    function getAccruedChronos(address _address)
        public
        view
        returns (uint256 amount)
    {
        amount =
            (_userStakes[_address] *
                5 ether *
                (block.timestamp - lastUpdated[_address])) /
            86400;
    }

    function updateRewardAndTimestamp(address _address) internal {
        _chronosReward[_address] += getAccruedChronos(_address);
        lastUpdated[_address] = block.timestamp;
    }

    function getSummonCost(bool _shared) public view returns (uint256 cost) {
        cost = SINGLE_SUMMON_COST + (_shared ? SHARED_SUMMON_REWARD : 0);
    }

    function claimChronos() public {
        uint256 unclaimed = chronosContract.getTotalUnclaimed(msg.sender);
        uint256 accrued = unclaimed;
        updateRewardAndTimestamp(msg.sender);
        if (grantChronos == true) {
            accrued += _chronosReward[msg.sender];
            _chronosReward[msg.sender] = 0;
        }
        chronosContract.burnUnclaimed(msg.sender, unclaimed);
        chronosContract.grantChronos(msg.sender, accrued);
    }

    function _stake(uint256 token) internal {
        stakes[token] = StakedToken(
            msg.sender,
            uint64(block.timestamp),
            uint64(_userStakes[msg.sender]) + 1
        );
        _userStakes[msg.sender] += 1;
        emit StartStake(msg.sender, token);
        adventurerContract.safeTransferFrom(
            msg.sender,
            address(this),
            uint256(token)
        );
    }

    function stake(uint256 token) public override {
        updateRewardAndTimestamp(msg.sender);
        _stake(token);
    }

    function groupStake(uint256[] memory tokens) external override {
        updateRewardAndTimestamp(msg.sender);
        for (uint64 i = 0; i < tokens.length; ++i) {
            _stake(tokens[i]);
        }
    }

    function _unstake(uint256 token, uint256 stakeLength) private {
        emit Unstake(msg.sender, token, stakeLength > 90 days, stakeLength);
        delete stakes[token];
        delete _status[token];
        _userStakes[msg.sender] -= 1;
        adventurerContract.safeTransferFrom(
            address(this),
            msg.sender,
            uint256(token)
        );
    }

    function unstake(uint256 token) public override {
        if (stakes[token].user != msg.sender) revert UserNotStaker();
        if (block.timestamp < _lockIn[token]) revert TokenLocked();
        uint64 stakeLength = uint64(block.timestamp) - stakes[token].timeStaked;
        if (stakeLength < LOCK_IN) revert TokenLocked();
        updateRewardAndTimestamp(msg.sender);
        _unstake(token, stakeLength);
    }

    function groupUnstake(uint256[] memory tokens) external override {
        updateRewardAndTimestamp(msg.sender);
        for (uint256 i = 0; i < tokens.length; ++i) {
            if (stakes[tokens[i]].user != msg.sender) revert UserNotStaker();
            if (block.timestamp < _lockIn[tokens[i]]) revert TokenLocked();
            uint64 stakeLength = uint64(block.timestamp) -
                stakes[tokens[i]].timeStaked;
            if (stakeLength < LOCK_IN) revert TokenLocked();
            _unstake(tokens[i], stakeLength);
        }
    }

    function burnToken(uint256 token) public onlyRole(BURNER_ROLE) {
        if (stakes[token].user == address(0)) revert TokenNotStaked();
        emit Burn(stakes[token].user, token);
        delete stakes[token];
        adventurerContract.safeTransferFrom(address(this), DEAD_ADDRESS, token);
    }

    function batchBurnTokens(uint256[] memory tokens)
        external
        onlyRole(BURNER_ROLE)
    {
        for (uint256 i = 0; i < tokens.length; ++i) {
            burnToken(tokens[i]);
        }
    }

    function lockToken(uint256 token, uint256 period)
        public
        onlyRole(LOCK_IN_ROLE)
    {
        if (stakes[token].user == address(0)) revert TokenNotStaked();
        _lockIn[token] = block.timestamp + period;
    }

    function groupLockTokens(uint256[] memory tokens, uint256 period)
        external
        onlyRole(LOCK_IN_ROLE)
    {
        for (uint256 i = 0; i < tokens.length; ++i) {
            lockToken(tokens[i], period);
        }
    }

    function _summon(
        uint256 _token1,
        uint256 _token2,
        uint8 option,
        bool shared,
        bool swapped
    ) private {
        if (option > uint8(type(SummonOption).max))
            revert InvalidSummonOption();
        if (
            (SummonOption(option) == SummonOption.HoldingUnclaimed) &&
            (getAccruedChronos(msg.sender) + _chronosReward[msg.sender] <
                getSummonCost(shared))
        ) revert InsufficientChronos();
        uint256 cost = getSummonCost(shared);
        SummonOption selectedOption = SummonOption(option);
        uint256 advId = MAX_GEN_COUNT + adventurerContract.gen2Count() + 1;
        if (shared) {
            _chronosReward[stakes[_token2].user] += SHARED_SUMMON_REWARD;
        }

        uint256 token1;
        uint256 token2;

        (token1, token2) = swapped ? (_token2, _token1) : (_token1, _token2);

        if (selectedOption == SummonOption.HoldingUnclaimed) {
            updateRewardAndTimestamp(msg.sender);
            _chronosReward[msg.sender] -= cost;
            chronosContract.grantChronos(address(this), cost);
            adventurerContract.summon(token1, token2, true);
        } else if (selectedOption == SummonOption.NFTUnclaimed) {
            chronosContract.burnUnclaimed(msg.sender, cost);
            chronosContract.grantChronos(address(this), cost);
            adventurerContract.summon(token1, token2, true);
        } else {
            chronosContract.safeTransferFrom(
                msg.sender,
                address(this),
                SHARED_SUMMON_REWARD + SINGLE_SUMMON_COST
            );
            adventurerContract.summon(token1, token2, true);
        }

        adventurerContract.safeTransferFrom(address(this), msg.sender, advId);
    }

    function sharedSummon(
        uint256 token,
        uint256 summoner,
        uint8 option,
        bool swapped
    ) external {
        if (stakes[token].user != msg.sender) revert UserNotStaker();
        if (!(BitMap.checkBit(_status[summoner], SUMMON_BIT)))
            revert TokenCannotBeUsedToSummon();
        _summon(token, summoner, option, true, swapped);
    }

    function summon(
        uint256 token1,
        uint256 token2,
        uint8 option
    ) external {
        if (
            stakes[token1].user != msg.sender ||
            stakes[token2].user != msg.sender
        ) revert UserNotStaker();
        _summon(token1, token2, option, false, false);
    }

    function setSummoning(uint256 token, bool status) public {
        if (stakes[token].user != msg.sender) revert UserNotStaker();
        if (status && token > MAX_GEN_COUNT) revert TokenCannotBeUsedToSummon();
        _status[token] = BitMap.setBit(_status[token], SUMMON_BIT, status);
    }

    function batchSetSummoning(uint256[] memory tokens, bool status) external {
        for (uint256 i = 0; i < tokens.length; ++i) {
            setSummoning(tokens[i], status);
        }
    }

    function setStatus(uint256 token, uint8[] memory bits) public {
        if (stakes[token].user != msg.sender) revert UserNotStaker();
        _status[token] = BitMap.setBits(0, bits);
    }

    function batchSetStatus(uint256[] memory tokens, uint8[] memory bits)
        external
    {
        uint256 bitmap = BitMap.setBits(0, bits);
        for (uint256 i = 0; i < tokens.length; ++i) {
            if (stakes[tokens[i]].user != msg.sender) revert UserNotStaker();
            _status[tokens[i]] = bitmap;
        }
    }

    function setGrantChronos(bool _grant) external onlyRole(ADMIN_ROLE) {
        grantChronos = _grant;
    }

    function setLockIn(uint256 lockin) external onlyRole(ADMIN_ROLE) {
        LOCK_IN = lockin;
    }

    function updateSummonReward(uint256 amount) external onlyRole(ADMIN_ROLE) {
        SHARED_SUMMON_REWARD = amount;
    }

    function addLockInRole(address user) external onlyRole(ADMIN_ROLE) {
        if (user == address(0)) revert CannotBeZeroAddress();
        _grantRole(LOCK_IN_ROLE, user);
    }

    function addBurnerRole(address user) external onlyRole(ADMIN_ROLE) {
        if (user == address(0)) revert CannotBeZeroAddress();
        _grantRole(BURNER_ROLE, user);
    }
}