//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract SeedSaleVesting is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event VestingAppliedToken(
        address indexed vestingToken,
        uint256 indexed vestingAmount
    );
    event ClaimedSeedSale(address vestingAddress, uint256 claimAmountXOX);

    struct VestingInfo {
        uint256 amountTokenAllocation;
        uint256 amountTGE;
        uint256 numberOfClaims;
    }

    struct VestingSchedule {
        uint256 amountOfGrant;
        uint256 amountClaimed;
        uint256 numberOfClaimed;
        bool isClaimedTGE;
    }

    address public xox;

    uint256 public TIME_TOKEN_LAUNCH; //August 20 - at 12:00PM UTC ~ 1692532800

    uint256 private constant _amountVestingSeedSale = 2_880_000 ether;

    uint256 private _amountVestedSeedSale;

    // seed sale
    mapping(address => VestingInfo) public vestingInfoSeedSale;
    mapping(address => VestingSchedule) public vestingScheduleSeedSale;

    uint256 public _ONE_MONTH; // 2592000
    uint256 private _FIVE_MINUTES;

    /**
     * @dev constructor the contract
     * @param _xoxTokenAddress Address XOX
     * @param _investors List address investor of SeedSale
     * @param _amountXOXArr List amount invested of SeedSale
     * @notice Each parameters should be set carefully since it's not modifiable for each round
     */
    //
    function initialize(
        address _xoxTokenAddress,
        address[] calldata _investors,
        uint256[] memory _amountXOXArr
    ) public initializer {
        __Ownable_init_unchained();

        require(
            _investors.length == _amountXOXArr.length,
            "not match array investor & amountXOX"
        );
        for (uint256 i; i < _investors.length; i++) {
            require(
                vestingInfoSeedSale[_investors[i]].amountTokenAllocation == 0,
                "wrong list investor or already set up for this investor"
            );
            VestingInfo storage investor = vestingInfoSeedSale[_investors[i]];
            investor.amountTokenAllocation = _amountXOXArr[i];
            investor.amountTGE = _amountXOXArr[i].mul(10).div(100);
            investor.numberOfClaims = 5;
            vestingScheduleSeedSale[_investors[i]]
                .amountOfGrant = _amountXOXArr[i];
            _amountVestedSeedSale = _amountVestedSeedSale.add(_amountXOXArr[i]);
        }
        require(
            _amountVestedSeedSale <= _amountVestingSeedSale,
            "exceed amountVesting for seedsale"
        );

        xox = _xoxTokenAddress;
        TIME_TOKEN_LAUNCH = 1700913600;
        _ONE_MONTH = 2592000; // 2592000
        _FIVE_MINUTES = 300;
        _transferOwnership(0x9A29b081E91471302dD7522B211775d90a1622C1);
    }

    function claimSeedSale() external {
        require(
            block.timestamp >= getPendingTimeLaunch(),
            "Not Launchtime yet"
        );
        VestingInfo storage seedSaleInfo = vestingInfoSeedSale[msg.sender];
        VestingSchedule storage seedSaleSchedule = vestingScheduleSeedSale[
            msg.sender
        ];
        uint256 amountClaim = 0;
        uint256 numberClaimCurrent = _getNumberofClaims();
        if (numberClaimCurrent > seedSaleInfo.numberOfClaims)
            numberClaimCurrent = seedSaleInfo.numberOfClaims;
        if (!seedSaleSchedule.isClaimedTGE && numberClaimCurrent == 0) {
            amountClaim = seedSaleInfo.amountTGE;
        }
        if (numberClaimCurrent > seedSaleSchedule.numberOfClaimed) {
            if (numberClaimCurrent == seedSaleInfo.numberOfClaims) {
                amountClaim = seedSaleSchedule.amountOfGrant.sub(
                    seedSaleSchedule.amountClaimed
                );
            } else {
                amountClaim = _calculatorAmountSeedSaleClaim(
                    numberClaimCurrent.sub(seedSaleSchedule.numberOfClaimed),
                    seedSaleSchedule.amountOfGrant
                );
                if (!seedSaleSchedule.isClaimedTGE) {
                    amountClaim = amountClaim.add(seedSaleInfo.amountTGE);
                }
            }
        }
        require(amountClaim > 0, "nothing to claim");
        IERC20Upgradeable(xox).transfer(msg.sender, amountClaim);
        if (!seedSaleSchedule.isClaimedTGE) {
            seedSaleSchedule.isClaimedTGE = true;
        }
        seedSaleSchedule.amountClaimed = seedSaleSchedule.amountClaimed.add(
            amountClaim
        );
        seedSaleSchedule.numberOfClaimed = numberClaimCurrent;
        emit ClaimedSeedSale(msg.sender, amountClaim);
    }

    /**
     * @dev View function to see pending amount SeedSale on frontend
     */
    function getPendingAmountSeedSale(
        address account
    ) external view returns (uint256) {
        if (block.timestamp < getPendingTimeLaunch()) return 0;
        return _getPendingAmountSeedSale(account);
    }

    function _getPendingAmountSeedSale(
        address account
    ) private view returns (uint256) {
        VestingInfo storage info = vestingInfoSeedSale[account];
        VestingSchedule storage schedule = vestingScheduleSeedSale[account];
        uint256 numberClaimCurrent = _getNumberofClaims();
        if (numberClaimCurrent >= info.numberOfClaims)
            return schedule.amountOfGrant.sub(schedule.amountClaimed);
        if (!schedule.isClaimedTGE && numberClaimCurrent == 0)
            return info.amountTGE;
        if (numberClaimCurrent > schedule.numberOfClaimed) {
            return
                schedule.isClaimedTGE
                    ? _calculatorAmountSeedSaleClaim(
                        numberClaimCurrent.sub(schedule.numberOfClaimed),
                        schedule.amountOfGrant
                    )
                    : _calculatorAmountSeedSaleClaim(
                        numberClaimCurrent.sub(schedule.numberOfClaimed),
                        schedule.amountOfGrant
                    ).add(info.amountTGE);
        }
        return 0;
    }

    /**
     * @dev Return claimable amount
     */
    function _calculatorAmountSeedSaleClaim(
        uint256 _part,
        uint256 _amountVesting
    ) public pure returns (uint256) {
        return _amountVesting.mul(_part).div(5); // 20% per month & 10% the last month
    }

    /**
     * @dev Pre function to calculate What far it's been
     */
    function _getNumberofClaims() public view returns (uint256) {
        return (block.timestamp.sub(getPendingTimeLaunch())).div(_ONE_MONTH);
    }

    /**
     * @dev Pre function to pending 5 minutes after launch
     */
    function getPendingTimeLaunch() private view returns (uint256) {
        return TIME_TOKEN_LAUNCH.add(_FIVE_MINUTES); // pending 5 minutes
    }

    function changeTimeLaunch(uint256 _time) external onlyOwner {
        TIME_TOKEN_LAUNCH = _time;
    }
}