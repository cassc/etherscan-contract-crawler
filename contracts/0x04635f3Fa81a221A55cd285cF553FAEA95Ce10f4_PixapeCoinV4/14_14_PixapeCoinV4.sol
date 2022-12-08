// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface StakingContract {
    function getTokensStakedForMoreThanAWeek(
        address _user
    ) external returns (uint256[] memory);
}

interface MaterialsContract {
    function balanceOf(address account, uint256 id) external returns (uint256);
}

contract PixapeCoinV4 is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    uint256 public constant MAX_SUPPLY = 10000000 * 10 ** 18;
    uint256 public COMMUNITY_CLAIMED;
    uint256 public COMMUNITY_CLAIMABLE;
    uint256 public COMMUNITY_CLAIMABLE_PER_MONTH;
    // keep track of daily claimed amount for community
    mapping(uint256 => uint256) public maonthlyClaimed;

    mapping(address => bool) public minters;

    // mal user to last claimed day
    mapping(address => uint256) public lastClaim;

    bool public tokensClaimable;
    address public pixapeStakeToken;
    address public awakenStake;
    address public materialsContract;

    uint256 pixApeRewads;
    uint256 awakenRewards;

    function initialize(
        string memory name,
        string memory symbol,
        address _pixapeStakeToken,
        address _awakenStake,
        uint256 _communityClaimablePercentage,
        uint256 communityClaimed
    ) external initializer {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        pixapeStakeToken = _pixapeStakeToken;
        awakenStake = _awakenStake;
        // calculate community claimable per month
        COMMUNITY_CLAIMABLE_PER_MONTH =
            (MAX_SUPPLY * _communityClaimablePercentage) /
            100 /
            (12 * 5);
        COMMUNITY_CLAIMABLE =
            (MAX_SUPPLY * _communityClaimablePercentage) /
            100;
        COMMUNITY_CLAIMED = communityClaimed;
    }

    event ClaimableStatusUpdated(bool status);

    function setTokensClaimable(bool _enabled) public onlyOwner {
        //needs access control
        tokensClaimable = _enabled;
        emit ClaimableStatusUpdated(_enabled);
    }

    // set materials contract address
    function setMaterialsContract(address _materialsContract) public onlyOwner {
        materialsContract = _materialsContract;
    }

    // set pixape rewards
    function setPixApeRewards(uint256 _pixApeRewards) public onlyOwner {
        pixApeRewads = _pixApeRewards;
    }

    // set awaken rewards
    function setAwakenRewards(uint256 _awakenRewards) public onlyOwner {
        awakenRewards = _awakenRewards;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // mint tokens to vesting contract
    function mintToVesting(address _to) public onlyOwner {
        // mint 60% of total supply to vesting contract
        _mint(_to, (((MAX_SUPPLY * 60) / 100) - ((MAX_SUPPLY * 6) / 100)));
    }

    function mint(address to, uint256 amount) external {
        require(minters[msg.sender], "Not a minter");
        _mint(to, amount);
    }

    function getCurrentMonth() public view returns (uint256) {
        return (block.timestamp / 30 days);
    }

    function canClaim(address user) public view returns (bool) {
        // chack that max claimable amount is not reached
        // check that user has staked tokens

        if (COMMUNITY_CLAIMED >= COMMUNITY_CLAIMABLE) {
            return false;
        }
        // get the current month from the timestamp
        uint256 currentMonth = getCurrentMonth();

        // check that limit for current month is not reached
        if (maonthlyClaimed[currentMonth] >= COMMUNITY_CLAIMABLE_PER_MONTH) {
            return false;
        }

        // check that user has not claimed in the last 7 days
        uint256 lastClaimed = getLastClaimed(user);
        if (lastClaimed > 0) {
            if (block.timestamp - lastClaimed < 7 days) {
                return false;
            }
        }
        return true;
    }

    function getLastClaimed(address user) public view returns (uint256) {
        return lastClaim[user];
    }

    // change awakener stake contract address
    function setAwakenStake(address _awakenStake) public onlyOwner {
        awakenStake = _awakenStake;
    }

    // change pixape stake contract address
    function setPixapeStakeToken(address _pixapeStakeToken) public onlyOwner {
        pixapeStakeToken = _pixapeStakeToken;
    }

    // claim tokens
    function claimTokens() public {
        require(canClaim(msg.sender), "You can't claim yet");

        uint256[] memory claimable = StakingContract(pixapeStakeToken)
            .getTokensStakedForMoreThanAWeek(msg.sender);
        uint256[] memory claimableAwaken = StakingContract(awakenStake)
            .getTokensStakedForMoreThanAWeek(msg.sender);
        // check that length of claimable array is not 0

        // banace of materials 9
        uint256 materialsBalance = MaterialsContract(materialsContract)
            .balanceOf(msg.sender, 9);
        uint256 lastClaimed_ = getLastClaimed(msg.sender);
        // check that user has not claimed in the last 1 week
        require(
            block.timestamp - lastClaimed_ >= 1 weeks,
            "You can't claim yet"
        );
        require(
            claimable.length > 0 || claimableAwaken.length > 0,
            "You have no tokens to claim"
        );
        uint256 totalClaimable = 0 * 10 ** 18;
        for (uint256 i = 0; i < claimable.length; i++) {
            totalClaimable += pixApeRewads * 10 ** 18;
        }
        for (uint256 i = 0; i < claimableAwaken.length; i++) {
            totalClaimable += awakenRewards * 10 ** 18;
        }

        // check that current claimable tokens are less than max 7.5% of total supply
        require(
            COMMUNITY_CLAIMED + totalClaimable <= COMMUNITY_CLAIMABLE,
            "Max supply reached"
        );

        if (materialsBalance > 0) {
            // if stake awaken earn +2 tokens else if staked both pixape and awaken earn +4 tokens
            if (claimableAwaken.length > 0 && claimable.length > 0) {
                totalClaimable += 4 * 10 ** 18;
            } else if (claimableAwaken.length > 0) {
                totalClaimable += 2 * 10 ** 18;
            }
        }

        require(totalClaimable > 0, "Nothing to claim");
        COMMUNITY_CLAIMED += totalClaimable;
        // update daily claimed amount
        uint256 month = getCurrentMonth();
        maonthlyClaimed[month] += totalClaimable;
        // set last claimed timestamp
        lastClaim[msg.sender] = block.timestamp;
        _mint(msg.sender, totalClaimable);
    }

    // get last claimed timestamp for user

    function burnFrom(address account, uint256 amount) public virtual override {
        if (minters[msg.sender]) {
            _burn(account, amount);
        } else {
            super.burnFrom(account, amount);
        }
    }

    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }
}