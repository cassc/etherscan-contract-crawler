// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ASPlatform is Initializable {
    // Addresses
    address public owner;
    ERC20 public aznt;
    ERC20 public busd;

    // Constants
    uint16 public divider;

    // Staking Mechanics
    uint16[] public commissions;

    uint16 public basePercent;
    uint16 public percentPerDownline;
    uint16 public percentDownlineMax;
    uint32 public stakeLength;

    uint32 public azntPerBusd;

    uint96 public minimumDeposit;
    uint96 public maximumDeposit;

    uint96 public minimumWithdraw;
    uint96 public maximumWithdraw;

    // Staker Properties

    address[] public addressById;

    mapping(address => Staker) public stakers;
    mapping(address => address[]) public downlines;
    mapping(address => Stake[]) public stakes;
    mapping(address => mapping(uint256 => uint96)) public stakerCommissions;

    // Structs
    struct Staker {
        address referrer;
        uint96 totalDeposit;
        uint24 id;
        uint32 lastClaim;
        uint96 leftOver;
        uint96 commissionClaimed;
        uint32 stakesOffset;
    }

    struct Stake {
        uint96 amount;
        uint32 dateStaked;
        uint128 heldAznt;
    }

    struct Deductor {
        address wallet;
        uint16 commission;
    }

    // Contract functions

    function initialize() external initializer {
        owner = msg.sender;

        divider = 100_0;

        commissions = [7_0, 3_0, 2_0];
        basePercent = 150_0;
        percentPerDownline = 1_5;
        percentDownlineMax = 10;
        stakeLength = 150 days;
        azntPerBusd = 54;

        addressById.push(address(this));
        registerStaker();
    }

    Deductor[] public deductors;

    // Staker Methods

    function getPercent(address wallet) public view returns (uint16 percent) {
        percent = basePercent;
        uint256 length = downlines[wallet].length;
        if (length <= percentDownlineMax) {
            percent += uint16(length) * percentPerDownline;
        } else {
            percent += percentPerDownline * percentDownlineMax;
        }
    }

    function createStake(uint256 amount, uint24 referrer) public {
        // Rules
        require(amount >= minimumDeposit, "Minimum amount required.");
        busd.transferFrom(msg.sender, address(this), amount);
        aznt.governanceTransfer(
            msg.sender,
            address(this),
            amount * azntPerBusd
        );

        if (referrer == 0 || addressById[referrer] == address(0)) {
            referrer = stakers[owner].id;
        }

        Staker storage staker = stakers[msg.sender];

        if (staker.id == 0) {
            registerStaker();
            staker.referrer = addressById[referrer];
            downlines[addressById[referrer]].push(msg.sender);
            staker.lastClaim = uint32(block.timestamp);
        }

        stakes[msg.sender].push(
            Stake(
                (uint96(amount) * getPercent(msg.sender)) / divider,
                uint32(block.timestamp),
                uint128(amount)
            )
        );
        staker.totalDeposit += uint96(amount);

        // Commission loop
        Staker storage uplineStaker = staker;
        uint256 length = commissions.length;
        for (uint256 i = 0; i < length; ++i) {
            if (uplineStaker.referrer == address(0)) break;
            uplineStaker = stakers[staker.referrer];

            stakerCommissions[staker.referrer][i] +=
                (uint96(amount) * commissions[i]) /
                divider;
        }
    }

    function withdraw() public {
        Staker storage staker = stakers[msg.sender];

        // Rules
        require(
            block.timestamp >= staker.lastClaim + 1 days,
            "Can only claim once daily."
        );

        uint256 claimable;
        uint32 lastClaim;
        uint256 length = stakes[msg.sender].length;
        uint32 newStakesOffset = staker.stakesOffset;

        Stake memory stake;
        for (uint32 i = staker.stakesOffset; i < length; ++i) {
            stake = stakes[msg.sender][i];
            if (stake.dateStaked + stakeLength <= staker.lastClaim) continue;

            lastClaim = stake.dateStaked > staker.lastClaim
                ? stake.dateStaked
                : staker.lastClaim;

            if (block.timestamp >= stake.dateStaked + stakeLength) {
                claimable +=
                    (stake.amount *
                        (stake.dateStaked + stakeLength - lastClaim)) /
                    stakeLength;
                aznt.transfer(msg.sender, stake.heldAznt);
                newStakesOffset = i + 1;
            } else {
                claimable +=
                    (stake.amount * (block.timestamp - lastClaim)) /
                    stakeLength;
            }
        }
        if (newStakesOffset != staker.stakesOffset)
            staker.stakesOffset = newStakesOffset;

        claimable += staker.leftOver;
        staker.leftOver = 0;
        require(claimable >= minimumWithdraw, "minimum not met");

        if (claimable > maximumWithdraw) {
            staker.leftOver += uint96(claimable - maximumWithdraw);
            claimable = maximumWithdraw;
        }

        deduct(claimable);

        uint256 contractBalance = busd.balanceOf(address(this));
        if (contractBalance < claimable) {
            staker.leftOver += uint96(claimable - contractBalance);
            claimable = contractBalance;
        }

        busd.transfer(msg.sender, claimable);

        staker.lastClaim = uint32(block.timestamp);
    }

    function withdrawCommission() external {
        Staker storage staker = stakers[msg.sender];

        uint96 bonusTotal;
        uint256 length = commissions.length;
        for (uint256 i = 0; i < length; ++i) {
            bonusTotal += stakerCommissions[msg.sender][i];
        }

        busd.transfer(msg.sender, bonusTotal - staker.commissionClaimed);

        staker.commissionClaimed = bonusTotal;
    }

    // Staker views

    function stakeInfo(
        address wallet
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
        Staker memory staker = stakers[wallet];

        uint256 length = stakes[wallet].length;
        Stake memory stake;

        uint32 lastClaim;

        for (uint256 i = 0; i < length; ++i) {
            stake = stakes[wallet][i];
            totalReturn += stake.amount;

            lastClaim = stake.dateStaked > staker.lastClaim
                ? stake.dateStaked
                : staker.lastClaim;

            if (block.timestamp < stake.dateStaked + stakeLength) {
                cps += stake.amount / 30 / 24 / 60 / 60;
                activeStakes += stake.amount;
            }
            if (lastClaim >= stake.dateStaked + stakeLength) {
                totalClaimed += stake.amount;
            } else {
                totalClaimed +=
                    (stake.amount * (lastClaim - stake.dateStaked)) /
                    stakeLength;
            }

            if (i >= staker.stakesOffset) {
                if (stake.dateStaked + stakeLength > staker.lastClaim) {
                    if (block.timestamp >= stake.dateStaked + stakeLength) {
                        claimable +=
                            (stake.amount *
                                (stake.dateStaked + stakeLength - lastClaim)) /
                            stakeLength;
                    } else {
                        claimable +=
                            (stake.amount * (block.timestamp - lastClaim)) /
                            stakeLength;
                    }
                }
            }
        }

        claimable += staker.leftOver;
        totalClaimed -= staker.leftOver;
    }

    function getStakes(
        address wallet
    ) external view returns (uint96[] memory, uint32[] memory) {
        uint256 length = stakes[wallet].length;
        uint96[] memory amounts = new uint96[](length);
        uint32[] memory dateStaked = new uint32[](length);

        for (uint256 i = 0; i < length; ++i) {
            amounts[i] = stakes[wallet][i].amount;
            dateStaked[i] = stakes[wallet][i].dateStaked;
        }

        return (amounts, dateStaked);
    }

    // Internals

    function registerStaker() internal {
        if (stakers[msg.sender].id == 0) {
            addressById.push(msg.sender);
            stakers[msg.sender].id = uint24(addressById.length) - 1;
        }
    }

    function deduct(uint256 amount) internal {
        uint256 length = deductors.length;
        for (uint256 i = 0; i < length; ++i) {
            if (deductors[i].wallet == address(0)) continue;
            busd.transfer(
                deductors[i].wallet,
                (amount * deductors[i].commission) / divider
            );
        }
    }

    function getDeductorIndex(address wallet) internal view returns (uint256) {
        uint256 length = deductors.length;
        for (uint256 i = 0; i < length; ++i) {
            if (wallet == deductors[i].wallet) return i;
        }
        revert("Address is not found");
    }

    // Owner functions

    function addDeductor(address wallet, uint16 commission) external onlyOwner {
        deductors.push(Deductor(wallet, commission));
    }

    function removeDeductor(address wallet) external onlyOwner {
        uint256 index = getDeductorIndex(wallet);
        require(index < deductors.length);
        deductors[index] = deductors[deductors.length - 1];
        deductors.pop();
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

interface ERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function governanceTransfer(
        address,
        address,
        uint256
    ) external returns (bool);
}