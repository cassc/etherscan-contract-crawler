pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

struct VestingWallet {
    address wallet;
    uint256 totalAmount;
    uint256 dayAmount;
    uint256 startDay;
    uint256 afterDays;
    bool nonlinear;
    bool advisory;
}

/**
 * dailyRate:       the daily amount of tokens to give access to,
 *                  this is a percentage * 1000000000000000000
 *                  this value is ignored if nonlinear is true
 * afterDays:       vesting cliff, dont allow any withdrawal before these days expired
 * nonlinear:       non linear vesting, used for PRIVATE/FOUNDATION/STRATEGIC sales
 **/

struct VestingType {
    uint256 dailyRate;
    uint256 afterDays;
    bool nonlinear;
    bool advisory;
}
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PNLToken is Ownable, ERC20Burnable {
    using SafeMath for uint256;

    mapping(address => VestingWallet) public vestingWallets;
    VestingType[] public vestingTypes;

    mapping(address => bool) public freezeList;

    uint256 public constant PRECISION = 1e18;
    uint256 public constant ONE_HUNDRED_PERCENT = PRECISION * 100;

    // Non linear unlocks [i,j] j% per day for i days
    uint256[][] public nonLinearUnlock = [
        [10000000000000000000, 1], //10% during the first day
        [1000000000000000000, 40], //1% for the next 40 days
        [250000000000000000, 200] // then 0.25% per 200 days
    ];

    uint256[][] public advisoryNonLinearUnlock = [
        [uint256(20000000000000000000), 1], //20% during the first day
        [uint256(666666666666666666), 121] //0,66% daily after
    ];

    /**
     * Setup the initial supply and types of vesting schemas
     **/

    constructor() ERC20("PNLToken", "PNL") {
        // 0: TEAM, 2.7% monthly (0.09% daily) 1 year after TGE.
        vestingTypes.push(
            VestingType(92592592000000000, 360 days, false, false)
        );

        // 1: MARKETING, 3% monthly (0.1% daily) after TGE.
        vestingTypes.push(VestingType(100000000000000000, 0, false, false));

        // 2: SEED/PRIVATE/STRATEGIC NONLINEAR 10% at TGE, then 1% daily over 40 days, then 0.25% for 200 days.
        vestingTypes.push(VestingType(0, 0, true, false));

        // 3: ADVISORY. 20% at TGE, then 0,67% daily over 120 days
        vestingTypes.push(VestingType(0, 0, true, true));

        // 4: Immediate unlock
        vestingTypes.push(VestingType(100000000000000000000, 0, false, false));

        // 5: FOUNDATION. 5% monthly (0.166% daily) 1 year after TGE.
        vestingTypes.push(
            VestingType(166666666666666666, 360 days, false, false)
        );

        // 6: STACKING. 4.17% monthly (0.139% daily) after TGE
        vestingTypes.push(VestingType(138888888888888888, 0, false, false));

        // Release BEFORE token start, tokens for liquidity
        _mint(address(0xB1537209C77C42d5fe33B56FD2bA3a7434c5Acb8), 1500000e18);

        // and public sale
        _mint(address(0xB1537209C77C42d5fe33B56FD2bA3a7434c5Acb8), 3400000e18);
    }

    // Vested tokens wont be available before the listing time
    function getListingTime() public pure returns (uint256) {
        return 1621357200;
    }

    function getMaxTotalSupply() public pure returns (uint256) {
        return PRECISION * 1e8; // 100 million tokens with 18 decimals
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) private pure returns (uint256) {
        return x.mul(y).div(z);
    }

    function freeze(address user) external onlyOwner {
        freezeList[user] = true;
    }

    function unfreeze(address user) external onlyOwner {
        freezeList[user] = false;
    }

    function addAllocations(
        address[] memory addresses,
        uint256[] memory totalAmounts,
        uint256 vestingTypeIndex
    ) external onlyOwner returns (bool) {
        require(
            addresses.length == totalAmounts.length,
            "Address and totalAmounts length must be same"
        );
        require(
            vestingTypeIndex < vestingTypes.length,
            "Vesting type isnt found"
        );

        VestingType memory vestingType = vestingTypes[vestingTypeIndex];
        uint256 addressesLength = addresses.length;

        for (uint256 i = 0; i < addressesLength; i++) {
            address _address = addresses[i];
            uint256 totalAmount = totalAmounts[i];
            // We add 1 to round up, this prevents small amounts from never vesting
            uint256 dayAmount =
                mulDiv(
                    totalAmounts[i],
                    vestingType.dailyRate,
                    ONE_HUNDRED_PERCENT
                );
            uint256 afterDay = vestingType.afterDays;
            bool nonlinear = vestingType.nonlinear;
            bool advisory = vestingType.advisory;

            addVestingWallet(
                _address,
                totalAmount,
                dayAmount,
                afterDay,
                nonlinear,
                advisory
            );
        }

        return true;
    }

    function _mint(address account, uint256 amount) internal override {
        uint256 totalSupply = super.totalSupply();
        require(
            getMaxTotalSupply() >= totalSupply.add(amount),
            "Maximum supply exceeded!"
        );
        super._mint(account, amount);
    }

    function addVestingWallet(
        address wallet,
        uint256 totalAmount,
        uint256 dayAmount,
        uint256 afterDays,
        bool nonlinear,
        bool advisory
    ) internal {
        require(
            vestingWallets[wallet].totalAmount == 0,
            "Vesting wallet already created for this address"
        );

        uint256 releaseTime = getListingTime();

        // Create vesting wallets
        VestingWallet memory vestingWallet =
            VestingWallet(
                wallet,
                totalAmount,
                dayAmount,
                releaseTime.add(afterDays),
                afterDays,
                nonlinear,
                advisory
            );

        vestingWallets[wallet] = vestingWallet;
        _mint(wallet, totalAmount);
    }

    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /**
     * Returns the amount of days passed with vesting
     */

    function getDays(uint256 afterDays) public view returns (uint256) {
        uint256 releaseTime = getListingTime();
        uint256 time = releaseTime.add(afterDays);

        if (block.timestamp < time) {
            return 0;
        }

        uint256 diff = block.timestamp.sub(time);
        uint256 ds = diff.div(1 days).add(1);

        return ds;
    }

    function isStarted(uint256 startDay) public view returns (bool) {
        uint256 releaseTime = getListingTime();

        if (block.timestamp < releaseTime || block.timestamp < startDay) {
            return false;
        }

        return true;
    }

    // Calculate the amount of unlocked tokens after X days for a given amount, nonlinear
    function calculateNonLinear(uint256 _days, uint256 amount)
        public
        view
        returns (uint256)
    {
        if (_days > 360) {
            return amount;
        }

        uint256 unlocked = 0;
        uint256 _days_remainder = 0;

        for (uint256 i = 0; i < nonLinearUnlock.length; i++) {
            if (_days <= _days_remainder) break;

            if (_days.sub(_days_remainder) >= nonLinearUnlock[i][1]) {
                unlocked = unlocked.add(
                    mulDiv(amount, nonLinearUnlock[i][0], ONE_HUNDRED_PERCENT)
                        .mul(nonLinearUnlock[i][1])
                );
            }

            if (_days.sub(_days_remainder) < nonLinearUnlock[i][1]) {
                unlocked = unlocked.add(
                    mulDiv(amount, nonLinearUnlock[i][0], ONE_HUNDRED_PERCENT)
                        .mul(_days.sub(_days_remainder))
                );
            }

            _days_remainder += nonLinearUnlock[i][1];
        }

        if (unlocked > amount) {
            unlocked = amount;
        }

        return unlocked;
    }

    function calculateNonLinearAdvisory(uint256 _days, uint256 amount)
        public
        view
        returns (uint256)
    {
        if (_days > 360) {
            return amount;
        }

        uint256 unlocked = 0;
        uint256 _days_remainder = 0;

        for (uint256 i = 0; i < advisoryNonLinearUnlock.length; i++) {
            if (_days <= _days_remainder) break;

            if (_days.sub(_days_remainder) >= advisoryNonLinearUnlock[i][1]) {
                unlocked = unlocked.add(
                    mulDiv(
                        amount,
                        advisoryNonLinearUnlock[i][0],
                        ONE_HUNDRED_PERCENT
                    )
                        .mul(advisoryNonLinearUnlock[i][1])
                );
            }

            if (_days.sub(_days_remainder) < advisoryNonLinearUnlock[i][1]) {
                unlocked = unlocked.add(
                    mulDiv(
                        amount,
                        advisoryNonLinearUnlock[i][0],
                        ONE_HUNDRED_PERCENT
                    )
                        .mul(_days.sub(_days_remainder))
                );
            }

            _days_remainder += advisoryNonLinearUnlock[i][1];
        }

        if (unlocked > amount) {
            unlocked = amount;
        }

        return unlocked;
    }

    // Returns the amount of tokens unlocked by vesting so far
    function getUnlockedVestingAmount(address sender)
        public
        view
        returns (uint256)
    {
        if (vestingWallets[sender].totalAmount == 0) {
            return 0;
        }

        if (!isStarted(0)) {
            return 0;
        }

        uint256 dailyTransferableAmount = 0;
        uint256 trueDays = getDays(vestingWallets[sender].afterDays);

        if (vestingWallets[sender].nonlinear == true) {
            if (vestingWallets[sender].advisory == false) {
                dailyTransferableAmount = calculateNonLinear(
                    trueDays,
                    vestingWallets[sender].totalAmount
                );
            } else {
                dailyTransferableAmount = calculateNonLinearAdvisory(
                    trueDays,
                    vestingWallets[sender].totalAmount
                );
            }
        } else {
            dailyTransferableAmount = vestingWallets[sender].dayAmount.mul(
                trueDays
            );
        }

        if (dailyTransferableAmount > vestingWallets[sender].totalAmount) {
            return vestingWallets[sender].totalAmount;
        }

        return dailyTransferableAmount;
    }

    // Returns the amount of vesting tokens still locked
    function getRestAmount(address sender) public view returns (uint256) {
        uint256 transferableAmount = getUnlockedVestingAmount(sender);
        uint256 restAmount =
            vestingWallets[sender].totalAmount.sub(transferableAmount);

        return restAmount;
    }

    function isFrozen(address sender) public view returns (bool) {
        if (freezeList[sender] == true) return false;
        return true;
    }

    // Transfer control
    function canTransfer(address sender, uint256 amount)
        public
        view
        returns (bool)
    {
        // Treat as a normal coin if this is not a vested wallet
        if (vestingWallets[sender].totalAmount == 0) {
            return true;
        }

        uint256 balance = balanceOf(sender);
        uint256 restAmount = getRestAmount(sender);

        // Account for sending received tokens outside of the vesting schedule
        if (
            balance > vestingWallets[sender].totalAmount &&
            balance.sub(vestingWallets[sender].totalAmount) >= amount
        ) {
            return true;
        }

        // Don't allow vesting if the period has not started yet or if you are below allowance
        if (
            !isStarted(vestingWallets[sender].startDay) ||
            balance.sub(amount) < restAmount
        ) {
            return false;
        }

        return true;
    }

    // @override
    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override(ERC20) {
        // Reject any transfers that are not allowed
        require(isFrozen(sender), "The account is frozen");
        require(
            canTransfer(sender, amount),
            "Unable to transfer, not unlocked yet."
        );
        super._beforeTokenTransfer(sender, recipient, amount);
    }
}