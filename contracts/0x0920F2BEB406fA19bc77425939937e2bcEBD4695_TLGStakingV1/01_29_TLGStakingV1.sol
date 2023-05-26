// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./TheLostGlitches.sol";
import "./LOSTToken.sol";
import "./TheLostGlitchesComic.sol";

/*
    Minter contract for the $LOST token.
    Holds the rights for minting and all the logic for who can mint how much.

    LOST token address must be passed during deployment
    DEFAULT_ADMIN_ROLE and PAUSER_ROLE is sender by default
*/
contract TLGStakingV1 is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    LOSTToken public LOST;
    TheLostGlitches public TLG;
    TheLostGlitchesComic public LCOM;
    uint256 public lostPerDay = 1;
    uint256 public ROUNDING_PRECISION = 1000;

    // the total accumulated pending reward
    mapping(address => uint256) public pendingReward;
    mapping(uint256 => address) public userStakedGlitch;
    mapping(address => uint256) public lastClaimed;
    mapping(address => uint256) public stakedComic;
    mapping(address => uint256[]) public stakedGlitches;
    mapping(address => mapping(uint256 => uint256)) public stakedGlitchIndex;

    constructor(
        address _lost,
        address _tlg,
        address _comic
    ) {
        TLG = TheLostGlitches(_tlg);
        LOST = LOSTToken(_lost);
        LCOM = TheLostGlitchesComic(_comic);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        // start paused
        _pause();
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721A: balance query for the zero address");
        return stakedGlitches[owner].length;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return userStakedGlitch[tokenId];
    }

    function numberOfDepositedGlitches(address staker) public view returns (uint256 amount) {
        return stakedGlitches[staker].length;
    }

    function depositComic(uint256 _comic) external whenNotPaused {
        require(stakedComic[msg.sender] == 0, "Already staked one comic");
        pendingReward[msg.sender] += calculateRewards();
        stakedComic[msg.sender] = _comic;
        LCOM.transferFrom(msg.sender, address(this), _comic);
        lastClaimed[msg.sender] = block.timestamp;
    }

    function withdrawComic(uint256 _comic) external whenNotPaused {
        require(stakedComic[msg.sender] == _comic, "Comic not staked");
        pendingReward[msg.sender] += calculateRewards();
        delete stakedComic[msg.sender];
        LCOM.transferFrom(address(this), msg.sender, _comic);
        lastClaimed[msg.sender] = block.timestamp;
    }

    function depositGlitches(uint256[] calldata _glitches) external whenNotPaused {
        // store the accumulated reward
        pendingReward[msg.sender] += calculateRewards();

        // TODO check if approval is set
        for (uint256 i = 0; i < _glitches.length; i++) {
            // add glitch to the list and update staking info
            stakedGlitches[msg.sender].push(_glitches[i]);
            stakedGlitchIndex[msg.sender][_glitches[i]] = stakedGlitches[msg.sender].length - 1;
            userStakedGlitch[_glitches[i]] = msg.sender;
            TLG.transferFrom(msg.sender, address(this), _glitches[i]);
        }

        lastClaimed[msg.sender] = block.timestamp;
    }

    function withdrawGlitches(uint256[] calldata _glitches) external whenNotPaused {
        require(stakedGlitches[msg.sender].length > 0, "No glitches staked");
        // store the accumulated reward
        pendingReward[msg.sender] += calculateRewards();
        for (uint256 i = 0; i < _glitches.length; i++) {
            // if there's no entry on deposit time, the glitch isn't staked by the sender
            require(userStakedGlitch[_glitches[i]] == msg.sender, "You do not own this glitch");
            // remove glitch from stakedGlitches
            uint256 index = stakedGlitchIndex[msg.sender][_glitches[i]];
            if (stakedGlitches[msg.sender].length - 1 == index) {
                stakedGlitches[msg.sender].pop();
            } else {
                stakedGlitches[msg.sender][index] = stakedGlitches[msg.sender][stakedGlitches[msg.sender].length - 1];
                stakedGlitchIndex[msg.sender][stakedGlitches[msg.sender][index]] = index;
                stakedGlitches[msg.sender].pop();
            }
            // remove the staking info and the index
            delete stakedGlitchIndex[msg.sender][_glitches[i]];
            delete userStakedGlitch[_glitches[i]];

            TLG.transferFrom(address(this), msg.sender, _glitches[i]);
        }

        lastClaimed[msg.sender] = block.timestamp;
    }

    function currentMultiplier(address staker) public view returns (uint256 amount) {
        if (stakedGlitches[staker].length == 1) {
            return 1 * ROUNDING_PRECISION;
        }

        uint256 multi = (stakedGlitches[staker].length * ROUNDING_PRECISION) / 10 + ROUNDING_PRECISION;
        if (multi > 2 * ROUNDING_PRECISION) {
            multi = 2 * ROUNDING_PRECISION;
        }
        return multi;
    }

    function calculateRewardsOf(address staker) public view returns (uint256) {
        uint256 totalReward = 0;
        uint256 diff = block.timestamp - lastClaimed[staker];
        uint256 daysDiff = diff / 1 days;
        uint256 dailyReward = daysDiff * lostPerDay * stakedGlitches[staker].length;

        // multiplier
        if (stakedGlitches[staker].length > 1) {
            uint256 multi = currentMultiplier(staker);
            dailyReward = dailyReward * multi;
            totalReward += (dailyReward * 1e18) / ROUNDING_PRECISION;
        } else {
            totalReward += dailyReward * 1e18;
        }

        if (stakedComic[staker] != 0) {
            totalReward = (totalReward * 12) / 10;
        }

        totalReward += pendingReward[staker];
        return totalReward;
    }

    function calculateRewards() public view returns (uint256) {
        return calculateRewardsOf(msg.sender);
    }

    function claimRewards() external whenNotPaused {
        uint256 reward = calculateRewards();

        LOST.mint(msg.sender, reward);

        pendingReward[msg.sender] = 0;
        lastClaimed[msg.sender] = block.timestamp;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}