// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../owner/Operator.sol";

contract Diamonds is ERC20Burnable, Operator {
    using SafeMath for uint256;

    // Distribution for the LP Providers
    uint256 public constant FARMING_POOL_REWARD_ALLOCATION = 7730 ether;
    // Distribution for the TEAM
    uint256 public constant TEAM_FUND_ALLOCATION = 300 ether;
    // Distribution for the Treasury
    uint256 public constant TREASURY_FUND_ALLOCATION = 300 ether;
    // Airdrop for V1 users
    uint256 public constant V1_AIRDROP = 1470 ether;
    // Airdrop for V1 users
    uint256 public constant TEAM_AIRDROP = 199.8 ether;

    uint256 public constant VESTING_DURATION = 365 days;
    uint256 public startTime;
    uint256 public endTime;

    address public teamAddress;
    address public treasuryAddress;

    uint256 public teamFundLastClaimed;
    uint256 public treasuryFundLastClaimed;

    bool public rewardPoolDistributed = false;

    constructor(
        uint256 _startTime,
        address _teamAddress,
        address _treasuryAddress
    ) ERC20("DIAMONDS", "DIA") {
        require(_teamAddress != address(0), "Team Address should be non-zero one");
        teamAddress = _teamAddress;

        require(_treasuryAddress != address(0), "Treasury Address should be non-zero one");
        treasuryAddress = _treasuryAddress;

        // airdrop DIA for V1 users
        _mint(treasuryAddress, V1_AIRDROP);

        // airdrop DIA for Team fund
        _mint(teamAddress, TEAM_AIRDROP);

        // mint 0.2 DIA for initial pools deployment
        _mint(msg.sender, 0.2 ether);

        startTime = _startTime;
        endTime = startTime + VESTING_DURATION;

        teamFundLastClaimed = startTime;
        treasuryFundLastClaimed = startTime;
    }

    function setTeamAddress(address _teamAddress) external onlyOperator() {
        require(_teamAddress != address(0), "Team address should be non-zero one");
        teamAddress = _teamAddress;
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOperator() {
        require(_treasuryAddress != address(0), "Treasury address should be non-zero one");
        treasuryAddress = _treasuryAddress;
    }

    function unclaimedTeamFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (teamFundLastClaimed >= _now) return 0;
        _pending = _now.sub(teamFundLastClaimed).mul(TEAM_FUND_ALLOCATION).div(VESTING_DURATION);
    }

    function unclaimedTreasuryFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (treasuryFundLastClaimed >= _now) return 0;
        _pending = _now.sub(treasuryFundLastClaimed).mul(TREASURY_FUND_ALLOCATION).div(VESTING_DURATION);
    }

    /**
     * @dev Claim pending rewards to community and dev fund
     */
    function claimRewards() external {
        uint256 _pending = unclaimedTeamFund();
        if (_pending > 0 && teamAddress != address(0)) {
            _mint(teamAddress, _pending);
            teamFundLastClaimed = block.timestamp;
        }

        _pending = unclaimedTreasuryFund();
        if (_pending > 0 && treasuryAddress != address(0)) {
            _mint(treasuryAddress, _pending);
            treasuryFundLastClaimed = block.timestamp;
        }
    }

    /**
     * @notice distribute to reward pool (only once)
     */
    function distributeReward(address _poolAddress) external onlyOperator {
        require(!rewardPoolDistributed, "Distribution had already done!");
        require(_poolAddress != address(0), "Pool address should be non-zero one");

        _mint(_poolAddress, FARMING_POOL_REWARD_ALLOCATION);
        rewardPoolDistributed = true;
    }

    function burn(uint256 _amount) public override {
        super.burn(_amount);
    }

    /**
     * @notice recover unsupported tokens
     */
    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        _token.transfer(_to, _amount);
    }
}