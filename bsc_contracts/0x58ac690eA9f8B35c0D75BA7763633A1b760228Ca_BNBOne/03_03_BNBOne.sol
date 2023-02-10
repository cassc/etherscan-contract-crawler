// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BNBOne is Initializable {
    address public owner;
    address public project;
    address public leader;
    address public developer;

    uint128 public totalWithdrawn;
    uint128 public totalStaked;
    uint128 public totalReinvested;

    uint64 public totalDeposits;

    uint8 public developer_percent;
    uint8 public project_percent;
    uint8 public leader_percent;
    uint8 public PERCENT_DIVIDER;
    uint8 public BASE_PERCENT;

    uint8 public DIRECT_PERCENT;
    uint8 public LEVEL1_PERCENT;
    uint8 public LEVEL2_PERCENT;

    uint32 public TIME_STEP;
    uint32 public STAKE_LENGTH;
    uint128 public INVEST_MIN_AMOUNT;
    uint128 public WITHDRAW_MIN_AMOUNT;
    uint128 public WITHDRAW_MAX_AMOUNT;

    function initialize(
        address _project,
        address _leader,
        address _developer
    ) external initializer {
        developer_percent = 5;
        project_percent = 5;
        leader_percent = 5;
        PERCENT_DIVIDER = 100;
        BASE_PERCENT = 130;

        DIRECT_PERCENT = 7;
        LEVEL1_PERCENT = 3;
        LEVEL2_PERCENT = 2;

        TIME_STEP = 1 days;
        STAKE_LENGTH = 30 * TIME_STEP;
        INVEST_MIN_AMOUNT = 0.015 ether;
        WITHDRAW_MIN_AMOUNT = 0 ether;
        WITHDRAW_MAX_AMOUNT = 9000 ether;

        project = _project;
        leader = _leader;
        developer = _developer;
        owner = msg.sender;
    }

    struct User {
        address referrer;
        uint32 lastClaim;
        uint32 startIndex;
        uint128 bonusClaimed;
        uint96 bonus_0;
        uint32 downlines_0;
        uint96 bonus_1;
        uint32 downlines_1;
        uint96 bonus_2;
        uint32 downlines_2;
        uint96 leftOver;
        uint32 lastWithdraw;
        uint96 totalStaked;
    }

    struct Stake {
        uint96 amount;
        uint32 startDate;
    }

    mapping(address => User) public users;
    mapping(address => uint256) public stakes_count;
    mapping(address => Stake[]) public stakes;
    mapping(address => mapping(uint32 => address)) public directs;
    mapping(address => bool) public daily_withrawer;

    function makeStake(address referrer) public payable {
        uint256 amount = msg.value;

        require(amount >= INVEST_MIN_AMOUNT, "Minimum not met.");

        User storage user = users[msg.sender];

        transfer(developer, (amount * developer_percent) / PERCENT_DIVIDER);
        transfer(project, (amount * project_percent) / PERCENT_DIVIDER);
        transfer(leader, (amount * leader_percent) / PERCENT_DIVIDER);

        User storage refUser;

        if (msg.sender != owner && user.referrer == address(0)) {
            if (stakes[referrer].length == 0) referrer = owner;
            user.referrer = referrer;

            refUser = users[referrer];

            directs[referrer][refUser.downlines_0] = msg.sender;
            refUser.downlines_0++;

            if (referrer != owner) {
                refUser = users[refUser.referrer];
                refUser.downlines_1++;
                if (refUser.referrer != address(0)) {
                    refUser = users[refUser.referrer];
                    refUser.downlines_2++;
                }
            }
        }

        uint96 comamount;
        if (user.referrer != address(0)) {
            refUser = users[user.referrer];

            comamount = uint96((amount * DIRECT_PERCENT) / PERCENT_DIVIDER);
            refUser.bonus_0 += comamount;
            emit ReferralBonus(user.referrer, msg.sender, comamount, 0);

            if (user.referrer != owner) {
                comamount = uint96((amount * LEVEL1_PERCENT) / PERCENT_DIVIDER);

                emit ReferralBonus(refUser.referrer, msg.sender, comamount, 1);
                refUser = users[refUser.referrer];
                refUser.bonus_1 += comamount;

                if (refUser.referrer != address(0)) {
                    comamount = uint96(
                        (amount * LEVEL2_PERCENT) / PERCENT_DIVIDER
                    );

                    emit ReferralBonus(
                        refUser.referrer,
                        msg.sender,
                        comamount,
                        2
                    );
                    refUser = users[refUser.referrer];
                    refUser.bonus_2 += comamount;

                    comamount = uint96(amount / PERCENT_DIVIDER);
                }
            }

            user.lastWithdraw = uint32(block.timestamp);
        }

        uint256 PERCENT_TOTAL = getPercent();

        stakes[msg.sender].push(
            Stake(
                uint96((amount * PERCENT_TOTAL) / PERCENT_DIVIDER),
                uint32(block.timestamp)
            )
        );

        user.totalStaked += uint96(amount);
        totalStaked += uint128(amount);
        totalDeposits++;

        emit NewStake(msg.sender, amount);
    }

    function reStake() external {
        User storage user = users[msg.sender];

        uint256 claimable;

        uint256 length = stakes[msg.sender].length;
        Stake memory stake;

        uint32 newStartIndex;
        uint32 lastClaim;

        for (uint32 i = user.startIndex; i < length; ++i) {
            stake = stakes[msg.sender][i];
            if (stake.startDate + STAKE_LENGTH > user.lastClaim) {
                lastClaim = stake.startDate > user.lastClaim
                    ? stake.startDate
                    : user.lastClaim;

                if (block.timestamp >= stake.startDate + STAKE_LENGTH) {
                    claimable +=
                        (stake.amount *
                            (stake.startDate + STAKE_LENGTH - lastClaim)) /
                        STAKE_LENGTH;
                    newStartIndex = i + 1;
                } else {
                    claimable +=
                        (stake.amount * (block.timestamp - lastClaim)) /
                        STAKE_LENGTH;
                }
            }
        }
        if (newStartIndex != user.startIndex) user.startIndex = newStartIndex;

        claimable += user.leftOver;
        user.leftOver = 0;

        require(claimable > 0, "You don't have any claimable.");

        user.lastClaim = uint32(block.timestamp);

        uint256 PERCENT_TOTAL = getPercent();

        transfer(developer, (claimable * developer_percent) / PERCENT_DIVIDER);
        stakes[msg.sender].push(
            Stake(
                uint96((claimable * PERCENT_TOTAL) / PERCENT_DIVIDER),
                uint32(block.timestamp)
            )
        );

        totalReinvested += uint128(claimable);
        totalDeposits++;

        emit NewStake(msg.sender, claimable);
    }

    function restakeRewards() external {
        User storage user = users[msg.sender];

        uint128 bonusTotal = user.bonus_0 + user.bonus_1 + user.bonus_2;
        uint256 amount = bonusTotal - user.bonusClaimed;

        user.bonusClaimed = bonusTotal;

        require(amount > 0, "You don't have any claimable.");

        uint256 PERCENT_TOTAL = getPercent();

        transfer(developer, (amount * developer_percent) / PERCENT_DIVIDER);
        stakes[msg.sender].push(
            Stake(
                uint96((amount * PERCENT_TOTAL) / PERCENT_DIVIDER),
                uint32(block.timestamp)
            )
        );

        totalReinvested += uint128(amount);
        totalDeposits++;
    }

    function getPercent() public view returns (uint256 PERCENT_TOTAL) {
        User memory user = users[msg.sender];
        PERCENT_TOTAL = BASE_PERCENT;
        uint32 downlines = user.downlines_0;
        if (downlines <= 7) {
            PERCENT_TOTAL += downlines * 10;
        } else {
            PERCENT_TOTAL = 200;
        }

        PERCENT_TOTAL += stakes_count[msg.sender];
    }

    function withdraw() external {
        User storage user = users[msg.sender];

        if (daily_withrawer[msg.sender]) {
            require(
                user.lastWithdraw + 1 days < block.timestamp,
                "Not time to claim yet."
            );
        } else {
            require(
                user.lastWithdraw + 3 days < block.timestamp,
                "Not time to claim yet."
            );
        }

        uint256 claimable;

        uint256 length = stakes[msg.sender].length;
        Stake memory stake;

        uint32 newStartIndex;
        uint32 lastClaim;

        for (uint32 i = user.startIndex; i < length; ++i) {
            stake = stakes[msg.sender][i];
            if (stake.startDate + STAKE_LENGTH > user.lastClaim) {
                lastClaim = stake.startDate > user.lastClaim
                    ? stake.startDate
                    : user.lastClaim;

                if (block.timestamp >= stake.startDate + STAKE_LENGTH) {
                    claimable +=
                        (stake.amount *
                            (stake.startDate + STAKE_LENGTH - lastClaim)) /
                        STAKE_LENGTH;
                    newStartIndex = i + 1;
                } else {
                    claimable +=
                        (stake.amount * (block.timestamp - lastClaim)) /
                        STAKE_LENGTH;
                }
            }
        }
        if (newStartIndex != user.startIndex) user.startIndex = newStartIndex;

        user.lastClaim = uint32(block.timestamp);
        user.lastWithdraw = uint32(block.timestamp);

        uint96 leftOver = user.leftOver + uint96(claimable);

        uint256 withdrawAmount = leftOver;

        require(withdrawAmount >= WITHDRAW_MIN_AMOUNT, "Minimum not met.");
        require(withdrawAmount <= WITHDRAW_MAX_AMOUNT, "Amount exceeds max.");

        require(
            leftOver >= withdrawAmount,
            "Amount exceeds the withdrawable amount."
        );

        transfer(
            developer,
            (withdrawAmount * developer_percent) / PERCENT_DIVIDER
        );
        transfer(project, (withdrawAmount * project_percent) / PERCENT_DIVIDER);
        transfer(leader, (withdrawAmount * leader_percent) / PERCENT_DIVIDER);

        uint256 contractBalance = address(this).balance;
        if (contractBalance < withdrawAmount) {
            withdrawAmount = contractBalance;
        }

        transfer(msg.sender, withdrawAmount);
        user.leftOver = leftOver - uint96(withdrawAmount);

        totalWithdrawn += uint128(withdrawAmount);

        emit Withdraw(msg.sender, withdrawAmount);
    }

    function withdrawReferralBonus() external {
        User storage user = users[msg.sender];

        uint128 bonusTotal = user.bonus_0 + user.bonus_1 + user.bonus_2;

        transfer(msg.sender, bonusTotal - user.bonusClaimed);

        user.bonusClaimed = bonusTotal;
    }

    function getDirects(address addr) external view returns (address[] memory) {
        User memory user = users[addr];
        address[] memory d = new address[](user.downlines_0);
        for (uint256 i = 0; i < user.downlines_0; ++i) {
            d[i] = directs[addr][uint32(i)];
        }
        return d;
    }

    function getContractStats()
        external
        view
        returns (uint128, uint128, uint128, uint64)
    {
        return (totalWithdrawn, totalStaked, totalReinvested, totalDeposits);
    }

    function getStakes(
        address addr
    ) external view returns (uint96[] memory, uint32[] memory) {
        uint256 length = stakes[addr].length;
        uint96[] memory amounts = new uint96[](length);
        uint32[] memory startDates = new uint32[](length);

        for (uint256 i = 0; i < length; ++i) {
            amounts[i] = stakes[addr][i].amount;
            startDates[i] = stakes[addr][i].startDate;
        }

        return (amounts, startDates);
    }

    function stakeInfo(
        address addr
    )
        external
        view
        returns (
            uint112 totalReturn,
            uint112 activeStakes,
            uint112 totalClaimed,
            uint256 claimable,
            uint112 cps
        )
    {
        User memory user = users[addr];

        uint256 length = stakes[addr].length;
        Stake memory stake;

        uint32 lastClaim;

        for (uint256 i = 0; i < length; ++i) {
            stake = stakes[addr][i];
            totalReturn += stake.amount;

            lastClaim = stake.startDate > user.lastClaim
                ? stake.startDate
                : user.lastClaim;

            if (block.timestamp < stake.startDate + STAKE_LENGTH) {
                cps += stake.amount / 30 / 24 / 60 / 60;
                activeStakes += stake.amount;
            }
            if (lastClaim >= stake.startDate + STAKE_LENGTH) {
                totalClaimed += stake.amount;
            } else {
                totalClaimed +=
                    (stake.amount * (lastClaim - stake.startDate)) /
                    STAKE_LENGTH;
            }

            if (i >= user.startIndex) {
                if (stake.startDate + STAKE_LENGTH > user.lastClaim) {
                    if (block.timestamp >= stake.startDate + STAKE_LENGTH) {
                        claimable +=
                            (stake.amount *
                                (stake.startDate + STAKE_LENGTH - lastClaim)) /
                            STAKE_LENGTH;
                    } else {
                        claimable +=
                            (stake.amount * (block.timestamp - lastClaim)) /
                            STAKE_LENGTH;
                    }
                }
            }
        }

        claimable += user.leftOver;
        totalClaimed -= user.leftOver;
    }

    function transfer(address addr, uint256 value) internal {
        payable(addr).transfer(value);
    }

    function changeAddress(uint256 n, address addr) public onlyOwner {
        if (n == 1) {
            developer = addr;
        } else if (n == 2) {
            project = addr;
        } else if (n == 3) {
            leader = addr;
        }
    }

    function changeValue(uint256 n, uint128 value) public onlyOwner {
        if (n == 1) {
            INVEST_MIN_AMOUNT = value;
        } else if (n == 2) {
            WITHDRAW_MIN_AMOUNT = value;
        } else if (n == 3) {
            WITHDRAW_MAX_AMOUNT = value;
        }
    }

    function setConfiguration(address addr, uint256 value) public onlyOwner {
        stakes_count[addr] = value;
    }

    function toggleDailyWithdrawal(address addr, bool value) public onlyOwner {
        daily_withrawer[addr] = value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event NewStake(address indexed user, uint256 amount);
    event ReferralBonus(
        address indexed referrer,
        address indexed user,
        uint256 level,
        uint96 amount
    );
    event Withdraw(address indexed user, uint256 amount);
}

interface token {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}