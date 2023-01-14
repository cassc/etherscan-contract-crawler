//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Staking} from "./Staking.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract IDStaking is Staking, EIP712, AccessControl {
    uint256 public latestRound;

    // 0x7ba1e5E9d013EaE624D274bfbAC886459F291081
    address public trustedSigner;

    struct Round {
        string meta;
        uint256 tvl;
        uint256 start;
        uint256 duration;
    }

    mapping(uint256 => mapping(bytes32 => uint256)) public xStakes;
    mapping(uint256 => Round) rounds;
    mapping(bytes32 => bool) usedDigest;

    event roundCreated(uint256 id);
    event selfStake(
        uint256 roundId,
        address staker,
        uint256 amount,
        bool staked
    );
    event xStake(
        uint256 roundId,
        address staker,
        address user,
        uint256 amount,
        bool staked
    );
    event tokenMigrated(
        address staker,
        uint256 amount,
        uint256 fromRound,
        uint256 toRound
    );

    modifier roundExists(uint256 roundId) {
        require(roundId > 0 && roundId <= latestRound, "Round does not exist");
        _;
    }

    modifier canStakeRound(uint256 roundId) {
        require(roundId > 0 && roundId <= latestRound, "Round does not exist");
        require(
            rounds[roundId].start + rounds[roundId].duration > block.timestamp,
            "Can't stake on this round"
        );
        _;
    }

    modifier canUnstakeRound(uint256 roundId) {
        require(roundId > 0 && roundId <= latestRound, "Round does not exist");
        require(
            rounds[roundId].start + rounds[roundId].duration < block.timestamp,
            "Can't unstake an active round"
        );
        _;
    }

    constructor(IERC20 _token)
        EIP712("IDStaking", "1.0")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        token = _token;
    }

    function addAdmin(address admin) public {
        grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function removeAdmin(address admin) public {
        revokeRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function createRound(
        uint256 start,
        uint256 duration,
        string calldata meta
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (latestRound > 0) {
            require(
                start >
                    rounds[latestRound].start + rounds[latestRound].duration,
                "new rounds have to start after old rounds"
            );
        }

        require(start >= block.timestamp, "new rounds should be in the future");

        latestRound++;

        uint256 currentRound = latestRound;

        rounds[currentRound].start = start;
        rounds[currentRound].duration = duration;
        rounds[currentRound].meta = meta;

        emit roundCreated(currentRound);
    }

    // stake
    function stake(uint256 roundId, uint256 amount)
        external
        canStakeRound(roundId)
    {
        _stake(roundId, amount);

        rounds[roundId].tvl += amount;

        emit selfStake(roundId, msg.sender, amount, true);
    }

    // unstake
    function unstake(uint256 roundId, uint256 amount)
        external
        canUnstakeRound(roundId)
    {
        require(
            stakes[roundId][msg.sender] >= amount,
            "Not enough balance to withdraw"
        );

        rounds[roundId].tvl -= amount;

        _unstake(roundId, amount);

        emit selfStake(roundId, msg.sender, amount, false);
    }

    // stakeUser
    function stakeUsers(
        uint256 roundId,
        address[] calldata users,
        uint256[] calldata amounts
    ) external canStakeRound(roundId) {
        require(users.length == amounts.length, "Unequal users and amount");

        uint256 totalAmount;

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 amount = amounts[i];
            require(
                amount > 0,
                "You can't stake nothing on a selected address"
            );
            require(address(0) != user, "can't stake the zero address");
            require(user != msg.sender, "You can't stake on your address here");

            xStakes[roundId][getStakeId(msg.sender, user)] += amount;
            totalAmount += amount;

            emit xStake(roundId, msg.sender, user, amount, true);
        }

        require(
            token.transferFrom(msg.sender, address(this), totalAmount),
            "unable to stake users"
        );

        rounds[roundId].tvl += totalAmount;
    }

    // unstakeUser
    function unstakeUsers(uint256 roundId, address[] calldata users)
        external
        canUnstakeRound(roundId)
    {
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < users.length; i++) {
            require(address(0) != users[i], "can't unstake the zero address");
            require(
                users[i] != msg.sender,
                "You can't unstake on your address here"
            );

            bytes32 stakeId = getStakeId(msg.sender, users[i]);
            uint256 unstakeBalance = xStakes[roundId][stakeId];

            if (unstakeBalance > 0) {
                xStakes[roundId][stakeId] -= unstakeBalance;

                totalAmount += unstakeBalance;

                emit xStake(
                    roundId,
                    msg.sender,
                    users[i],
                    unstakeBalance,
                    false
                );
            }
        }

        rounds[roundId].tvl -= totalAmount;
        require(
            token.transfer(msg.sender, totalAmount),
            "unable to unstake users"
        );
    }

    // migrateStake
    function migrateStake(uint256 fromRound)
        external
        canUnstakeRound(fromRound)
    {
        uint256 toRound = latestRound;

        require(fromRound < toRound, "Can't migrate from an active round");

        uint256 balance = stakes[fromRound][msg.sender];

        require(balance > 0, "Not enough balance to migrate");

        rounds[fromRound].tvl -= balance;
        stakes[fromRound][msg.sender] = 0;
        rounds[toRound].tvl += balance;
        stakes[toRound][msg.sender] = balance;

        emit selfStake(fromRound, msg.sender, balance, false);
        emit selfStake(toRound, msg.sender, balance, true);
        emit tokenMigrated(msg.sender, balance, fromRound, toRound);
    }

    // VIEW
    function fetchRoundMeta(uint256 roundId)
        public
        view
        roundExists(roundId)
        returns (
            uint256 start,
            uint256 duration,
            uint256 tvl,
            string memory meta
        )
    {
        return (
            rounds[roundId].start,
            rounds[roundId].duration,
            rounds[roundId].tvl,
            rounds[roundId].meta
        );
    }

    function isActiveRound(uint256 roundId)
        public
        view
        returns (bool isActive)
    {
        (uint256 start, uint256 duration, , ) = fetchRoundMeta(roundId);
        isActive =
            start < block.timestamp &&
            start + duration > block.timestamp;
    }

    function getUserStakeForRound(uint256 roundId, address user)
        public
        view
        roundExists(roundId)
        returns (uint256)
    {
        return _getUserStakeForRound(roundId, user);
    }

    function getUserXStakeForRound(
        uint256 roundId,
        address staker,
        address user
    ) external view returns (uint256) {
        return xStakes[roundId][getStakeId(staker, user)];
    }

    function getStakeId(address staker, address user)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(staker, user));
    }
}