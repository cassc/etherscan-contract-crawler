// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Rewarder is ReentrancyGuard, Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    struct User {
        uint256 checkpoint;
    }

    mapping(address => User) public users;

    IERC20 public token;
    IERC20 public immutable fundraiser;

    address private adminAddress;
    uint256 public claimableBalance;

    uint256 public snapshot;
    uint256 public distributed;
    uint256 public claimedNftTokens;

    uint256 public version;
    bool private isTokenSet = false;

    event Claim(address indexed user);

    modifier onlyCustomOwner() {
        require(adminAddress == _msgSender() || owner() == _msgSender(), "Caller is not the owner");
        _;
    }

    constructor(uint256 _version, address _adminAddress, address _fundraiser) {
        require(_adminAddress != address(0), "Already set");
        require(_fundraiser != address(0), "Already set");
        adminAddress = _adminAddress;
        fundraiser = IERC20(_fundraiser);
        version = _version;
    }

    function getVersion() external view returns (uint256) {
        return version;
    }

    function setToken(address _token) public onlyOwner {
        if (!isTokenSet) {
            token = IERC20(_token);
            isTokenSet = true;
        }
    }

    function _update() private {
        uint256 balance = token.balanceOf(address(this));
        require(claimableBalance >= 0, "Invalid amount");
        require(balance >= claimableBalance, "Invalid amount");

        if (claimableBalance > snapshot.sub(distributed)) {
            snapshot = snapshot.add(claimableBalance.sub(snapshot.sub(distributed)));
        }
    }

    function deposit(uint256 amount) public onlyOwner {
        require(amount >= 0, "Invalid amount");
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 amountMinusFees = applyFees(amount);
        claimableBalance = claimableBalance + amountMinusFees;
    }

    function withdraw() public onlyCustomOwner {
        uint256 balance = token.balanceOf(address(this));
        require(claimableBalance >= 0, "Invalid amount");
        require(balance >= claimableBalance, "Invalid amount");
        uint256 amountMinusFees = applyFees(claimableBalance);
        token.safeTransfer(msg.sender, amountMinusFees);
        claimableBalance = 0;
    }

    function pendingReward(address user) public view returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        require(claimableBalance >= 0, "Invalid amount");
        require(balance >= claimableBalance, "Invalid amount");

        uint256 localSnapshot = snapshot;
        if (claimableBalance > snapshot.sub(distributed)) {
            localSnapshot = localSnapshot.add(claimableBalance.sub(localSnapshot.sub(distributed)));
        }

        uint256 bank = localSnapshot.sub(users[user].checkpoint);
        uint256 allocation = fundraiser.balanceOf(user).mul(bank).div(fundraiser.totalSupply());

        return allocation;
    }

    function claim() public nonReentrant {
        User storage user = users[msg.sender];

        _update();

        uint256 totalNftSupply = fundraiser.totalSupply();
        uint256 userNftBalance = fundraiser.balanceOf(msg.sender);
        uint256 bank = snapshot.sub(user.checkpoint);
        uint256 allocation = userNftBalance.mul(bank).div(totalNftSupply);

        token.safeTransfer(msg.sender, allocation);
        user.checkpoint = snapshot;

        claimedNftTokens = claimedNftTokens + userNftBalance;
        claimableBalance = claimableBalance.sub(allocation);
        distributed = distributed.add(allocation);

        emit Claim(msg.sender);
    }

    function applyFees(uint256 amount) internal returns (uint256) {
        uint256 fee = amount.mul(5).div(1000);
        token.safeTransfer(adminAddress, fee);
        return amount.sub(fee);
    }

    function getClaimedRewardsPercentage() external view returns (uint256) {
        uint256 totalNftSupply = fundraiser.totalSupply();
        if (totalNftSupply == 0) {
            return 0;
        }
        return claimedNftTokens.mul(10000).div(totalNftSupply);
    }
}