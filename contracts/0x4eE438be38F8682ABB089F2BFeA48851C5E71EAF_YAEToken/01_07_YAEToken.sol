pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

struct VestingWallet {
    address wallet;
    uint256 totalAmount;
    uint256 dayAmount;
    uint256 startDay;
    uint256 afterDays;
    bool nonlinear;
}

/**
 * dailyRate:       the daily amount of tokens to give access to,
 *                  this is a percentage * 1000000000000000000
 *                  this value is ignored if nonlinear is true
 * afterDays:       vesting cliff, dont allow any withdrawal before these days expired
 * nonlinear:       non linear vesting, more vesting at the start, less at the end
**/

struct VestingType {
    uint256 dailyRate;
    uint256 afterDays;
    bool nonlinear;
}

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract YAEToken is Ownable, ERC20Burnable {
    
    using SafeMath for uint256;
    
    mapping (address => VestingWallet) public vestingWallets;
    VestingType[] public vestingTypes;

    uint256 public constant PRECISION = 1e18;
    uint256 public constant ONE_HUNDRED_PERCENT = PRECISION * 100;
        
    // Non linear unlocks per year per day, year 1 = index 0
    uint256[] public nonLinearUnlockYears = [
        58333333333333333, // 21%
        41666666666666667, // 15%
        33333333333333333, // 12%
        27777777777777778, // 10%
        25000000000000000, // 9%
        22222222222222222, // 8%
        19444444444444444, // 7%
        18055555555555556, // 6.5%
        16666666666666667, // 6%
        15277777777777778  // 5.5%
    ];
    
    /**
     * Setup the initial supply and types of vesting schemas
    **/
    
    constructor() ERC20("Cryptonovae", "YAE") {

		// 0: 90 Days 0.277% per day (360 days), pre-seed
        vestingTypes.push(VestingType(277777777777777778, 90 days, false));

        // 1: Immediate release for 360 days, seed, advisor
        vestingTypes.push(VestingType(277777777777777778, 0, false));

        // 2: Immediate release for 150 days, p1
        vestingTypes.push(VestingType(666666666666666667, 0, false));

        // 3: Immediate release for 120 days, p2
        vestingTypes.push(VestingType(833333333333333333, 0, false));

        // 4: IDO, release all first day
        vestingTypes.push(VestingType(100000000000000000000, 0, false)); 

        // 5: Immediate release for 1080 days, reserve
        vestingTypes.push(VestingType(92592592592592592, 0, false));

        // 6: Release for 360 days, after 360 days, team
        vestingTypes.push(VestingType(277777777777777778, 360 days, false));

        // 7: Release immediately, for 3600 days using nonlinear function, rewards
        vestingTypes.push(VestingType(1337, 0, true));
        
        // Release before token start, tokens for liquidity
        _mint(address(0x285F56c5Fdb0FF311db0Fb6ab95BF5f0D7C31D85), 2000000e18);
    }
	
    // Vested tokens wont be available before the listing time
    function getListingTime() public pure returns (uint256) {
        return 1617984000; // 2021/4/9 16:00 UTC
    }

    function getMaxTotalSupply() public pure returns (uint256) {
        return PRECISION * 1e8; // 100 million tokens with 18 decimals
    }

    function mulDiv(uint256 x, uint256 y, uint256 z) private pure returns (uint256) {
        return x.mul(y).div(z);
    }
    
    function addAllocations(address[] memory addresses, uint256[] memory totalAmounts, uint256 vestingTypeIndex) external onlyOwner returns (bool) {
        require(addresses.length == totalAmounts.length, "Address and totalAmounts length must be same");
        require(vestingTypeIndex < vestingTypes.length, "Vesting type isnt found");

        VestingType memory vestingType = vestingTypes[vestingTypeIndex];
        uint256 addressesLength = addresses.length;

        for(uint256 i = 0; i < addressesLength; i++) {
            address _address = addresses[i];
            uint256 totalAmount = totalAmounts[i];
            // We add 1 to round up, this prevents small amounts from never vesting
            uint256 dayAmount = mulDiv(totalAmounts[i], vestingType.dailyRate, ONE_HUNDRED_PERCENT);
            uint256 afterDay = vestingType.afterDays;
            bool nonlinear = vestingType.nonlinear;

            addVestingWallet(_address, totalAmount, dayAmount, afterDay, nonlinear);
        }

        return true;
    }

    function _mint(address account, uint256 amount) internal override {
        uint256 totalSupply = super.totalSupply();
        require(getMaxTotalSupply() >= totalSupply.add(amount), "Maximum supply exceeded!");
        super._mint(account, amount);
    }

    function addVestingWallet(address wallet, uint256 totalAmount, uint256 dayAmount, uint256 afterDays, bool nonlinear) internal {

        require(vestingWallets[wallet].totalAmount == 0, "Vesting wallet already created for this address");

        uint256 releaseTime = getListingTime();

        // Create vesting wallets
        VestingWallet memory vestingWallet = VestingWallet(
            wallet,
            totalAmount,
            dayAmount,
            releaseTime.add(afterDays),
            afterDays,
            nonlinear
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
    
    // Calculate the amount of unlocked tokens after X days for a given amount, nonlinear over 10 years
    // 21.0%	15.0%	12.0%	10.0%	9.0%	8.0%	7.0%	6.5%	6.0%	5.5%
    function calculateNonLinear(uint256 _days, uint256 amount) public view returns (uint256) {

        uint256 _years = _days.div(360);
    
        if (_years > 9) {
            return amount;
        }

        uint256 unlocked = 0;
        uint256 _days_remainder = _days.mod(360);

        for(uint256 i = 0; i < _years; i++) {
            // Add 360x the amount unlocked per day counting for this year
            unlocked = unlocked.add(mulDiv(amount, nonLinearUnlockYears[i], ONE_HUNDRED_PERCENT).mul(360));
        }
        
        uint256 _rem = mulDiv(amount, nonLinearUnlockYears[_years], ONE_HUNDRED_PERCENT);
        unlocked = unlocked.add(_rem.mul(_days_remainder));

		if (unlocked > amount){
			unlocked = amount;
		} 

        return unlocked;
    }
    
    // Returns the amount of tokens unlocked by vesting so far
    function getUnlockedVestingAmount(address sender) public view returns (uint256) {
        
        if (vestingWallets[sender].totalAmount == 0) {
			return 0;
        }

        if (!isStarted(0)) {
            return 0;
        }

        uint256 dailyTransferableAmount = 0;
        uint256 trueDays = getDays(vestingWallets[sender].afterDays);
        
        // Unlock the first month right away on the first day of vesting;
        // But only start the real vesting after the first month (0, 30, 30, .., 31)
        if (trueDays > 0 && trueDays < 30) {
            trueDays = 30; 
        }
        
        if (vestingWallets[sender].nonlinear == true) {
            dailyTransferableAmount = calculateNonLinear(trueDays, vestingWallets[sender].totalAmount);
        } else {
            dailyTransferableAmount = vestingWallets[sender].dayAmount.mul(trueDays);
        }

        if (dailyTransferableAmount > vestingWallets[sender].totalAmount) {
            return vestingWallets[sender].totalAmount;
        }

        return dailyTransferableAmount;
    }
    
    // Returns the amount of vesting tokens still locked
    function getRestAmount(address sender) public view returns (uint256) {
        uint256 transferableAmount = getUnlockedVestingAmount(sender);
        uint256 restAmount = vestingWallets[sender].totalAmount.sub(transferableAmount);

        return restAmount;
    }

    // Transfer control 
    function canTransfer(address sender, uint256 amount) public view returns (bool) {

        // Treat as a normal coin if this is not a vested wallet
        if (vestingWallets[sender].totalAmount == 0) {
            return true;
        }

        uint256 balance = balanceOf(sender);
        uint256 restAmount = getRestAmount(sender);
        
        // Account for sending received tokens outside of the vesting schedule
        if (balance > vestingWallets[sender].totalAmount && balance.sub(vestingWallets[sender].totalAmount) >= amount) {
            return true;
        }

        // Don't allow vesting if the period has not started yet or if you are below allowance
        if (!isStarted(vestingWallets[sender].startDay) || balance.sub(amount) < restAmount) {
            return false;
        }

        return true;
    }
    
    // @override
    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal virtual override(ERC20) {
        // Reject any transfers that are not allowed
        require(canTransfer(sender, amount), "Unable to transfer, not unlocked yet.");
        super._beforeTokenTransfer(sender, recipient, amount);
    }
}