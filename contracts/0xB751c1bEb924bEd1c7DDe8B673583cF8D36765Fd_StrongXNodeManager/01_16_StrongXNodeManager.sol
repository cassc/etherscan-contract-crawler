// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IStrongXNodeManager.sol";
import "./interfaces/IStrongXNFT.sol";
import "./interfaces/IStrongX.sol";

contract StrongXNodeManager is AccessControl, ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    struct User {
        bool exists;
        uint quantity;
        uint lastClaim;
        uint totalClaimed;
        uint totalUsedSlots;
    }

    struct UserBoost {
        uint bronzeNftAmount;
        uint bronzeSlotsUsed;
        uint silverNftAmount;
        uint silverSlotsUsed;
        uint goldNftAmount;
        uint goldSlotsUsed;
        uint platinumNftAmount;
        uint platinumSlotsUsed;
    }

    struct Boost {
        uint boostPerSecond;
        uint slots;
        uint tokenId;
    }

    mapping (address => User) public users;
    mapping (address => UserBoost) public userBoosts;
    IStrongX public immutable token;
    IStrongXNFT public immutable nft;
    Boost public bronzeBoost = Boost(145000000000, 1, 1);
    Boost public silverBoost = Boost(347000000000, 2, 2);
    Boost public goldBoost = Boost(463000000000, 5, 3);
    Boost public platinumBoost = Boost(579000000000, 10, 4);
    uint public costPerNode = 10 * 1e18;
    uint public rewardPerSecond = 1100000000000; // 0.095 / 86400
    uint public totalNodes;
    uint public totalParticipants;
    uint public totalRewarded;

    mapping (address => uint) private claimableRewards;
    address private immutable admin;

    event Created(
        address indexed account,
        uint quantity
    );

    event Withdrawn(
        address indexed account,
        uint amount
    );

    event Attached(
        address indexed account,
        uint id,
        uint amount
    );

    event Detached(
        address indexed account,
        uint id,
        uint amount
    );

    constructor(
        address _token,
        address _nft
    ) {
        token = IStrongX(_token);
        nft = IStrongXNFT(_nft);

        admin = _msgSender();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    function create(uint quantity) external nonReentrant {
        require(quantity > 0, "Quantity must be more than zero");

        User storage user = users[_msgSender()];
        if (!user.exists) {
            user.exists = true;
            totalParticipants++;
        }

        _claimPendingRewards(_msgSender());
        user.quantity = user.quantity.add(quantity);
        totalNodes = totalNodes.add(quantity);

        uint amount = quantity.mul(costPerNode);
        token.transferFrom(_msgSender(), address(this), amount);
        token.burn(amount);

        emit Created(_msgSender(), quantity);
    }

    function withdraw() external nonReentrant {
        User storage user = users[_msgSender()];
        require(user.exists, "User does not exist");

        uint rewards = getRewards(_msgSender());
        require(rewards > 0, "No rewards to claim");

        user.totalClaimed = user.totalClaimed.add(rewards);
        totalRewarded = totalRewarded.add(rewards);
        claimableRewards[_msgSender()] = 0;
        user.lastClaim = block.timestamp;

        token.mint(_msgSender(), rewards);

        emit Withdrawn(_msgSender(), rewards);
    }

    function claim(address beneficiary, uint quantity) external nonReentrant onlyRole(MANAGER_ROLE) {
        require(quantity > 0, "Quantity must be more than zero");

        User storage user = users[beneficiary];
        if (!user.exists) {
            user.exists = true;
            totalParticipants++;
        }

        _claimPendingRewards(beneficiary);
        user.quantity = user.quantity.add(quantity);
        totalNodes = totalNodes.add(quantity);

        emit Created(beneficiary, quantity);
    }

    function attach(uint id, uint amount) external nonReentrant {
        require(id > 0 && id <= 4, "Invalid token id");
        require(amount > 0, "Amount must be more than zero");

        User storage user = users[_msgSender()];
        require(user.exists, "User does not exist");

        uint neededSlots;
        if (id == 1) neededSlots = 1;
        else if (id == 2) neededSlots = 2;
        else if (id == 3) neededSlots = 5;
        else neededSlots = 10;
        
        neededSlots = neededSlots.mul(amount);

        require(
            user.totalUsedSlots.add(neededSlots) <= user.quantity, 
            "You do not have enough nodes for this boost"
        );

        _claimPendingRewards(_msgSender());
        _applyBoost(_msgSender(), id, amount, neededSlots);
        user.totalUsedSlots = user.totalUsedSlots.add(neededSlots);

        nft.burn(_msgSender(), id, amount);

        emit Attached(_msgSender(), id, amount);
    }

    function detach(uint id, uint amount) external nonReentrant {
        require(id > 0 && id <= 4, "Invalid token id");
        require(amount > 0, "Amount must be more than zero");

        User storage user = users[_msgSender()];
        require(user.exists, "User does not exist");

        uint freedSlots;
        if (id == 1) freedSlots = 1;
        else if (id == 2) freedSlots = 2;
        else if (id == 3) freedSlots = 5;
        else freedSlots = 10;
        
        freedSlots = freedSlots.mul(amount);

        require(
            user.totalUsedSlots >= freedSlots,
            "Not enough used slots to detach"
        );

        _claimPendingRewards(_msgSender());
        _detachBoost(_msgSender(), id, amount, freedSlots);
        user.totalUsedSlots = user.totalUsedSlots.sub(freedSlots);

        nft.mint(_msgSender(), id, amount, "");

        emit Detached(_msgSender(), id, amount);
    }

    /** VIEW FUNCTIONS */

    function getRewards(address account) public view returns (uint rewards) {
        return claimableRewards[account].add(_getPendingRewards(account));
    }

    function getRewardRatePerDay(address account) public view returns (uint rewardRatePerDay) {
        rewardRatePerDay = _getRewardRate(account).mul(1 days);
    }

    /** INTERNAL FUNCTIONS */

    function _claimPendingRewards(address account) internal returns (bool) {
        User storage user = users[account];
        require(user.exists, "User does not exist");

        claimableRewards[account] = claimableRewards[account].add(_getPendingRewards(account));
        user.lastClaim = block.timestamp;
        return true;
    }

    function _getPendingRewards(address account) internal view returns (uint pendingRewards) {
        User memory user = users[account];
        uint rewardPeriod = block.timestamp.sub(user.lastClaim);

        pendingRewards = _getRewardRate(account).mul(rewardPeriod);
    }

    function _getRewardRate(address account) internal view returns (uint rewardRate) {
        User memory user = users[account];

        uint baseRate = user.quantity.mul(rewardPerSecond);
        uint additionalRate;

        for (uint i = 1; i <= 4; i++) {
            additionalRate = additionalRate.add(_getBoostRewardRate(account, i));
        }

        rewardRate = baseRate.add(additionalRate);
    }

    function _getBoostRewardRate(address account, uint tokenId) internal view returns (uint) {
        UserBoost memory userBoost = userBoosts[account];

        uint slots;
        uint boostPerSecond;

        if (tokenId == 1) {
            // bronze boost
            slots = userBoost.bronzeSlotsUsed;
            boostPerSecond = bronzeBoost.boostPerSecond;
        } else if (tokenId == 2) {
            // silver boost
            slots = userBoost.silverSlotsUsed;
            boostPerSecond = silverBoost.boostPerSecond;
        } else if (tokenId == 3) {
            // gold boost
            slots = userBoost.goldSlotsUsed;
            boostPerSecond = goldBoost.boostPerSecond;
        } else {
            // platinum boost
            slots = userBoost.platinumSlotsUsed;
            boostPerSecond = platinumBoost.boostPerSecond;
        }

        return slots.mul(boostPerSecond);
    }

    function _applyBoost(address account, uint tokenId, uint amount, uint slots) internal {
        UserBoost storage userBoost = userBoosts[account];

        if (tokenId == 1) {
            userBoost.bronzeNftAmount = userBoost.bronzeNftAmount.add(amount);
            userBoost.bronzeSlotsUsed = userBoost.bronzeSlotsUsed.add(slots);
        } else if (tokenId == 2) {
            userBoost.silverNftAmount = userBoost.silverNftAmount.add(amount);
            userBoost.silverSlotsUsed = userBoost.silverSlotsUsed.add(slots);
        } else if (tokenId == 3) {
            userBoost.goldNftAmount = userBoost.goldNftAmount.add(amount);
            userBoost.goldSlotsUsed = userBoost.goldSlotsUsed.add(slots);
        } else {
            userBoost.platinumNftAmount = userBoost.platinumNftAmount.add(amount);
            userBoost.platinumSlotsUsed = userBoost.platinumSlotsUsed.add(slots);
        }
    }

    function _detachBoost(address account, uint tokenId, uint amount, uint slots) internal {
        UserBoost storage userBoost = userBoosts[account];

        if (tokenId == 1) {
            require(
                userBoost.bronzeNftAmount >= amount &&
                userBoost.bronzeSlotsUsed >= slots,
                "Can not detach more slots than used"
            );
            userBoost.bronzeNftAmount = userBoost.bronzeNftAmount.sub(amount);
            userBoost.bronzeSlotsUsed = userBoost.bronzeSlotsUsed.sub(slots);
        } else if (tokenId == 2) {
            require(
                userBoost.silverNftAmount >= amount &&
                userBoost.silverSlotsUsed >= slots,
                "Can not detach more slots than used"
            );
            userBoost.silverNftAmount = userBoost.silverNftAmount.sub(amount);
            userBoost.silverSlotsUsed = userBoost.silverSlotsUsed.sub(slots);
        } else if (tokenId == 3) {
            require(
                userBoost.goldNftAmount >= amount &&
                userBoost.goldSlotsUsed >= slots,
                "Can not detach more slots than used"
            );
            userBoost.goldNftAmount = userBoost.goldNftAmount.sub(amount);
            userBoost.goldSlotsUsed = userBoost.goldSlotsUsed.sub(slots);
        } else {
            require(
                userBoost.platinumNftAmount >= amount &&
                userBoost.platinumSlotsUsed >= slots,
                "Can not detach more slots than used"
            );
            userBoost.platinumNftAmount = userBoost.platinumNftAmount.sub(amount);
            userBoost.platinumSlotsUsed = userBoost.platinumSlotsUsed.sub(slots);
        }
    }

    /** RESTRICTED FUNCTIONS */

    function setRewardPerSecond(uint _rewardPerSecond) external onlyRole(MANAGER_ROLE) {
        require(
            _rewardPerSecond > 0 && _rewardPerSecond < 1 ether,
            "Reward per second not within bounds"
        );

        rewardPerSecond = _rewardPerSecond;
    }

    function setBoostProperties(uint id, uint boostRewardPerSecond, uint boostSlots) external onlyRole(MANAGER_ROLE) {
        require(id > 0 && id <= 4, "Invalid token id");

        if (id == 1) bronzeBoost = Boost(boostRewardPerSecond, boostSlots, bronzeBoost.tokenId);
        if (id == 2) silverBoost = Boost(boostRewardPerSecond, boostSlots, silverBoost.tokenId);
        if (id == 3) goldBoost = Boost(boostRewardPerSecond, boostSlots, goldBoost.tokenId);
        else platinumBoost = Boost(boostRewardPerSecond, boostSlots, platinumBoost.tokenId);
    }

    function recoverTokens(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_token).transfer(admin, IERC20(_token).balanceOf(address(this)));
    }
}