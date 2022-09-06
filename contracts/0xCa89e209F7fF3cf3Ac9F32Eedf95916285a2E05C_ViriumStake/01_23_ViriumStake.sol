// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./IViriumId.sol";
import "../util/IERC721Lockable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./IJIVA.sol";

contract ViriumStake is Initializable, UUPSUpgradeable, AccessControlUpgradeable {
    IJIVA public rewardToken;

    uint256 private constant ONE_YEAR = 365 days;
    uint256 private constant FOUR_YEARS = 4 * ONE_YEAR;
    uint256 private constant FIFTY_YEARS = 50 * ONE_YEAR;

    mapping(address => uint256) private _rewards;
    uint256 public totalShare;
    mapping(address => uint256) private _userShare;
    uint256 private _deployTime;
    uint256 public pausedTime;
    bytes32 public constant MAINTAIN_ROLE = keccak256("MAINTAIN_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    address public constant PROJECT_MANAGER = 0x1540602fA43D9b4237aa67c640DC8Bb8C4693dCD;
    uint private _rewardPerShareStored;
    mapping(address => uint) private _userRewardPerShareStored;
    uint256 private _lastUpdateTime;

    //model params
    uint256 private constant W = 373652500;
    uint256 private constant B1 = 106579090;

    enum Status {
        Paused,
        Running
    }
    Status public currentStatus;

    struct Pledge {
        IERC721Lockable token;
        uint256 rate;
    }

    Pledge[] private pledges;

    struct PledgeRequest {
        address token;
        uint256 rate;
    }

    function initialize() initializer public {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(MAINTAIN_ROLE, msg.sender);

        _grantRole(DEFAULT_ADMIN_ROLE, PROJECT_MANAGER);
        _grantRole(UPGRADER_ROLE, PROJECT_MANAGER);
        _grantRole(MAINTAIN_ROLE, PROJECT_MANAGER);

        _deployTime = block.timestamp;
        currentStatus = Status.Running;
    }

    function setDeployTime() external onlyRole(MAINTAIN_ROLE){
        _deployTime = block.timestamp;
    }

    function initializeRewardTokenContract(address rewardTokenContractAddress) external onlyRole(MAINTAIN_ROLE) {
        rewardToken = IJIVA(rewardTokenContractAddress);
    }

    function addPledge(PledgeRequest[] calldata requests) external onlyRole(MAINTAIN_ROLE) {
        delete pledges;
        for (uint256 i = 0; i < requests.length; i++) {
            PledgeRequest calldata request = requests[i];
            pledges.push(Pledge(IERC721Lockable(request.token), request.rate));
        }
    }

    function getPledge(uint256 index) external view returns (Pledge memory){
        return pledges[index];
    }

    function earned() public view returns (uint256) {
        return _userShare[msg.sender] * (rewardPerShare() - _userRewardPerShareStored[msg.sender]) + _rewards[msg.sender];
    }

    function earnedPerDay() external view returns (uint256){
        if (totalShare == 0) {
            return 0;
        }
        return _userShare[msg.sender] * getReward(block.timestamp + 1 days, block.timestamp) / totalShare;
    }

    function rewardPerShare() public view returns (uint256){
        if (totalShare == 0) {
            return 0;
        }
        if (_lastUpdateTime == 0) {
            return 0;
        }
        return _rewardPerShareStored + getReward(block.timestamp, _lastUpdateTime) / totalShare;
    }

    modifier updateReward() {
        _rewardPerShareStored = rewardPerShare();
        _lastUpdateTime = block.timestamp;

        _rewards[msg.sender] = earned();
        _userRewardPerShareStored[msg.sender] = _rewardPerShareStored;
        _;
    }

    function getReward(uint256 t2, uint256 t1) private view returns (uint256){
        uint256 duration = t2 - _deployTime;
        if (duration / FIFTY_YEARS > 0) {
            return 0;
        }
        return g(duration) - g(t1 - _deployTime);
    }

    function g(uint256 t) private pure returns (uint256){
        return W * t * 1e18 / (B1 + t);
    }

    function setCurrentStatus(Status currentStatus_) external onlyRole(MAINTAIN_ROLE) {
        currentStatus = currentStatus_;
    }

    function getShare() external view returns (uint256){
        return _userShare[msg.sender];
    }

    function stake(uint256[][] calldata tokenIds) external updateReward {
        require(currentStatus == Status.Running, "ViriumStake: Status error");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            Pledge storage pledge = pledges[i];
            stake(tokenIds[i], pledge.token, pledge.rate);
        }
    }

    function stake(uint256[] calldata tokenIds, IERC721Lockable token, uint256 value) private {
        uint256 share = tokenIds.length * value;
        totalShare += share;
        _userShare[msg.sender] += share;
        token.setTokenLockStatus(tokenIds, true);
    }

    function unstake(uint256[][] calldata tokenIds) external updateReward {
        require(currentStatus == Status.Running, "ViriumStake: Status error");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            Pledge storage pledge = pledges[i];
            unstake(tokenIds[i], pledge.token, pledge.rate);
        }
    }

    function unstake(uint256[] calldata tokenIds, IERC721Lockable token, uint256 value) private {
        uint256 share = tokenIds.length * value;
        totalShare -= share;
        _userShare[msg.sender] -= share;
        token.setTokenLockStatus(tokenIds, false);
    }

    function claim() external updateReward {
        uint256 reward = _rewards[msg.sender];
        require(reward > 0, "ViriumStake: Reward must be greater than zero");
        _rewards[msg.sender] = 0;
        rewardToken.mint(msg.sender, reward);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override
    {}

    function name() public pure returns (string memory) {
        return "ViriumStake";
    }

    function symbol() public pure returns (string memory) {
        return "VS";
    }
}