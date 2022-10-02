// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IGymMLM.sol";
import "./interfaces/IERC20Burnable.sol";
/**
 * @notice Turnover pool contract:
 * Stores information about
 */
contract TurnoverPool is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event DistributeRewards(address indexed user, uint256 amount, uint256 _type);

    event Whitelisted(address indexed wallet, bool whitelist);

    /**
     * @notice User distribution info
     * @param userAddress: user address
     * @param gymnetAmount: amount in GYMNET to distribute
     * @param bnbAmount: amount in BNB to distribute
     * @param busdAmount: amount in BUSD to distribute
     */
    struct UserDistributionInfo {
        address userAddress;
        uint256 gymnetAmount;
        uint256 bnbAmount;
        uint256 busdAmount;
    }

    /**
     * @notice User rewards info
     * @param gymnetAmount: amount in GYMNET to distribute
     * @param bnbAmount: amount in BNB to distribute
     * @param busdAmount: amount in BUSD to distribute
     * @param gymnetClaimedAmount: claimed amount in GYMNET
     * @param bnbClaimedAmount: claimed amount in BNB
     * @param busdClaimedAmount: claimed amount in BUSD
     */
    struct UserRewards {
        uint256 gymnetAmount;
        uint256 bnbAmount;
        uint256 busdAmount;
        uint256 gymnetClaimedAmount;
        uint256 bnbClaimedAmount;
        uint256 busdClaimedAmount;
    }

    address public gymnetAddress;
    address public busdAddress;

    mapping(address => UserRewards) public userRewardInfo;

    mapping(address => bool) private whitelist;

    modifier onlyWhitelisted() {
        require(
            whitelist[msg.sender] || msg.sender == owner(),
            "GymTurnoverPool: not whitelisted or owner"
        );
        _;
    }

    function initialize(address _gymnetAddress, address _busdAddress) external initializer {
        gymnetAddress = _gymnetAddress;
        busdAddress = _busdAddress;

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    receive() external payable {}

    fallback() external payable {}

    function setGYMNETAddress(address _address) external onlyOwner {
        gymnetAddress = _address;
    }

    function setBUSDAddress(address _address) external onlyOwner {
        busdAddress = _address;
    }

    /**
     * @notice Add or remove wallet to/from whitelist, callable only by contract owner
     *         whitelisted wallet will be able to call functions
     *         marked with onlyWhitelisted modifier
     * @param _wallet wallet to whitelist
     * @param _whitelist boolean flag, add or remove to/from whitelist
     */
    function whitelistWallet(address _wallet, bool _whitelist) external onlyOwner {
        whitelist[_wallet] = _whitelist;

        emit Whitelisted(_wallet, _whitelist);
    }

    /**
     * @notice Function to distribute rewards
     * @param _userDistributionInfo: array of UserDistributionInfo
     */
    function distributeRewards(UserDistributionInfo[] calldata _userDistributionInfo)
        external
        onlyWhitelisted
    {
        for (uint256 i; i < _userDistributionInfo.length; i++) {
            UserRewards memory _user = userRewardInfo[_userDistributionInfo[i].userAddress];
            userRewardInfo[_userDistributionInfo[i].userAddress] = UserRewards({
                gymnetAmount: _user.gymnetAmount + _userDistributionInfo[i].gymnetAmount,
                bnbAmount: _user.bnbAmount + _userDistributionInfo[i].bnbAmount,
                busdAmount: _user.busdAmount + _userDistributionInfo[i].busdAmount,
                gymnetClaimedAmount: _user.gymnetClaimedAmount,
                bnbClaimedAmount: _user.bnbClaimedAmount,
                busdClaimedAmount: _user.busdClaimedAmount
            });
        }
    }

    /**
     * @notice Function to claim rewards by type
     * @param _type: type of rewards (0- GYMNET, 1- BNB, 2- BUSD)
     */
    function claim(uint256 _type) external nonReentrant {
        if (_type == 0) {
            _claimGYMNETRewards();
        } else if (_type == 1) {
            _claimBNBRewards();
        } else if (_type == 2) {
            _claimBUSDRewards();
        }
    }

    /**
     * @notice Function to claim all rewards
     */
    function claimAll() external nonReentrant {
        _claimGYMNETRewards();
        _claimBNBRewards();
        _claimBUSDRewards();
    }

    /**
     * @notice Function to claim GYMNET rewards
     */
    function _claimGYMNETRewards() private {
        UserRewards storage _user = userRewardInfo[msg.sender];
        if (_user.gymnetAmount > 0) {
            require(
                IERC20Upgradeable(gymnetAddress).transfer(msg.sender, _user.gymnetAmount),
                "GymTurnoverPool:: Transfer failed"
            );

            _user.gymnetClaimedAmount += _user.gymnetAmount;
            _user.gymnetAmount = 0;
        }
    }

    /**
     * @notice Function to claim BNB rewards
     */
    function _claimBNBRewards() private {
        UserRewards storage _user = userRewardInfo[msg.sender];

        if (_user.bnbAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: _user.bnbAmount}("");
            require(success, "GymTurnoverPool:: Transfer failed");

            _user.bnbClaimedAmount += _user.bnbAmount;
            _user.bnbAmount = 0;
        }
    }

    /**
     * @notice Function to claim BUSD rewards
     */
    function _claimBUSDRewards() private {
        UserRewards storage _user = userRewardInfo[msg.sender];
        if (_user.busdAmount > 0) {
            require(
                IERC20Upgradeable(busdAddress).transfer(msg.sender, _user.busdAmount),
                "GymTurnoverPool:: Transfer failed"
            );

            _user.busdClaimedAmount += _user.busdAmount;
            _user.busdAmount = 0;
        }
    }

    function burnRestTokens(uint256 _wantAmt) external onlyWhitelisted {
        IERC20Burnable(gymnetAddress).burn(_wantAmt);
    }
}