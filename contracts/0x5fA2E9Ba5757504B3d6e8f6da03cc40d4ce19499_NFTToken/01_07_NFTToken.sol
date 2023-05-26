pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

struct VestingWallet {
    address wallet;
    uint256 totalAmount;
    uint256 dayAmount;
    uint256 startDay;
    uint256 afterDays;
    uint256 firstMonthAmount;
}

/**
 * dailyRate:               the daily amount of tokens to give access to,
 *                          this is a percentage * 1000000000000000000
 * afterDays:               vesting cliff, dont allow any withdrawal before these days expired
 * firstMonthDailyUnlock:   same as dailyRate but for the first 30 days, which are unlocked all at the same time
**/

struct VestingType {
    uint256 dailyRate;
    uint256 afterDays;
    uint256 firstMonthDailyUnlock;
}

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract NFTToken is Ownable, ERC20Burnable {
    
    using SafeMath for uint256;
    
    mapping (address => VestingWallet[]) public vestingWallets;
    VestingType[] public vestingTypes;

    uint256 public constant PRECISION = 1e18;
    uint256 public constant ONE_HUNDRED_PERCENT = PRECISION * 100;
        
    /**
     * Setup the initial supply and types of vesting schemas
    **/
    
    constructor() ERC20("NFT.TECH", "NFTT") {

		// 0: 360 days, 5% first month, angel, 0.95/11/30, 0.05/30
        vestingTypes.push(VestingType(287878787878787879, 0, 166666666666666667));

        // 1: Immediate release for 9 months, seed
        vestingTypes.push(VestingType(395833333333333333, 0, 166666666666666667));

        // 2: Immediate release for 6 months, p1, p2, up and running
        vestingTypes.push(VestingType(633333333333333333, 0, 166666666666666667));

        // 3: All released after 360 days, vault
        vestingTypes.push(VestingType(100000000000000000000, 360 days, 100000000000000000000)); 

        // 4: Release for 360 days, after 540 days (18 months), team
        vestingTypes.push(VestingType(277777777777777778, 540 days, 277777777777777778));
        
        // 5: Release for 360 days, after 30 days (1 months), advisor
        vestingTypes.push(VestingType(277777777777777778, 30 days, 277777777777777778));

        
        // Release before token start, tokens for liquidity
        _mint(address(0x9aE9127cFDB6Aa1843DD182E8270D24735937485), 60000000e18);
        
        // Release before token start, IDO allocation
        _mint(address(0x9aE9127cFDB6Aa1843DD182E8270D24735937485), 407868975879848000000000);
        
        // Release before token start, NFT Community
        _mint(address(0xB74e94301CbE45A0A79527C12121D2697D9d6223), 5000000e18);
    }
	
    // Vested tokens wont be available before the listing time
    function getListingTime() public pure returns (uint256) {
        return 1634824800; // 2021/10/21 14:00 UTC
    }

    function getMaxTotalSupply() public pure returns (uint256) {
        return PRECISION * 157000000; // 157 million tokens with 18 decimals
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
            uint256 firstMonthAmount = mulDiv(totalAmounts[i], vestingType.firstMonthDailyUnlock, ONE_HUNDRED_PERCENT).mul(30);

            addVestingWallet(_address, totalAmount, dayAmount, afterDay, firstMonthAmount);
        }

        return true;
    }

    function _mint(address account, uint256 amount) internal override {
        uint256 totalSupply = super.totalSupply();
        require(getMaxTotalSupply() >= totalSupply.add(amount), "Maximum supply exceeded!");
        super._mint(account, amount);
    }

    function addVestingWallet(address wallet, uint256 totalAmount, uint256 dayAmount, uint256 afterDays, uint256 firstMonthAmount) internal {

        uint256 releaseTime = getListingTime();

        // Create vesting wallets
        VestingWallet memory vestingWallet = VestingWallet(
            wallet,
            totalAmount,
            dayAmount,
            releaseTime.add(afterDays),
            afterDays,
            firstMonthAmount
        );
            
        vestingWallets[wallet].push(vestingWallet);
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
    
    // Returns the amount of tokens unlocked by vesting so far
    function getUnlockedVestingAmount(address sender) public view returns (uint256) {
        
        if (!isStarted(0)) {
            return 0;
        }
        
        uint256 dailyTransferableAmount = 0;

        for (uint256 i=0; i<vestingWallets[sender].length; i++) {

            if (vestingWallets[sender][i].totalAmount == 0) {
                continue;
            }

            uint256 trueDays = getDays(vestingWallets[sender][i].afterDays);
            uint256 dailyTransferableAmountCurrent = 0;
            
            // Unlock the first month right away on the first day of vesting;
            // But only start the real vesting after the first month (0, 30, 30, .., 31)
            if (trueDays > 0 && trueDays < 30) {
                trueDays = 30; 
                dailyTransferableAmountCurrent = vestingWallets[sender][i].firstMonthAmount;
            } 

            if (trueDays >= 30) {
                dailyTransferableAmountCurrent = vestingWallets[sender][i].firstMonthAmount.add(vestingWallets[sender][i].dayAmount.mul(trueDays.sub(30)));
            }

            if (dailyTransferableAmountCurrent > vestingWallets[sender][i].totalAmount) {
                dailyTransferableAmountCurrent = vestingWallets[sender][i].totalAmount;
            }

            dailyTransferableAmount = dailyTransferableAmount.add(dailyTransferableAmountCurrent);
        }

        return dailyTransferableAmount;
    }
    
    function getTotalVestedAmount(address sender) public view returns (uint256) {
        uint256 totalAmount = 0;

        for (uint256 i=0; i<vestingWallets[sender].length; i++) {
            totalAmount = totalAmount.add(vestingWallets[sender][i].totalAmount);
        }
        return totalAmount;
    }

    // Returns the amount of vesting tokens still locked
    function getRestAmount(address sender) public view returns (uint256) {
        uint256 transferableAmount = getUnlockedVestingAmount(sender);
        uint256 totalAmount = getTotalVestedAmount(sender);
        uint256 restAmount = totalAmount.sub(transferableAmount);
        return restAmount;
    }

    // Transfer control 
    function canTransfer(address sender, uint256 amount) public view returns (bool) {

        // Treat as a normal coin if this is not a vested wallet
        if (vestingWallets[sender].length == 0) {
            return true;
        }

        uint256 balance = balanceOf(sender);
        uint256 restAmount = getRestAmount(sender);
        uint256 totalAmount = getTotalVestedAmount(sender);
        
        // Account for sending received tokens outside of the vesting schedule
        if (balance > totalAmount && balance.sub(totalAmount) >= amount) {
            return true;
        }

        // Don't allow vesting if you are below allowance
        if (balance.sub(amount) < restAmount) {
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