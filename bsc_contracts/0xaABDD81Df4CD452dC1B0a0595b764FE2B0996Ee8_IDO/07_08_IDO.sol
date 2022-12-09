// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Referral.sol";

contract IDO is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdt;
    IERC20 public immutable token;

    Referral public immutable referral;

    address public recipient;
    uint256 public price = 0.1 * 1e18;

    uint256 public releaseTime;

    uint256 public total;
    mapping(address => uint256) public lock;
    mapping(address => uint256) public release;

    event Reward(address indexed parent, address indexed child, uint256 amount, uint256 rate);
    event Buy(address indexed account, uint256 indexed amount);

    error Unregistered();

    constructor(
        address _usdt,
        address _token,
        address _recipient,
        address _referral
    ) {
        usdt = IERC20(_usdt);
        token = IERC20(_token);
        recipient = _recipient;
        referral = Referral(_referral);
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function buy(uint256 amount) external {
        if (referral.registered(msg.sender) == false) revert Unregistered();

        usdt.safeTransferFrom(msg.sender, address(this), amount);

        uint256 tokenAmount = (amount / price) * 1e18;
        lock[msg.sender] += tokenAmount;
        release[msg.sender] += (tokenAmount * 4000) / 10000;
        token.safeTransferFrom(recipient, msg.sender, (tokenAmount * 4000) / 10000);

        uint256 reward = _reward(amount);
        usdt.safeTransfer(recipient, amount - reward);
        total += amount;
        emit Buy(msg.sender, amount);
    }

    function balance(address user) public view returns (uint256) {
        if (releaseTime == 0 || block.timestamp <= releaseTime) {
            return 0;
        }
        uint256 month = (block.timestamp - releaseTime) / 30 days;
        if (month > 3) {
            month = 3;
        }
        uint256 amount = (lock[user] * (4000 + 2000 * month)) / 10000;
        return amount - release[user];
    }

    function withdraw() external {
        uint256 amount = balance(msg.sender);
        if (amount == 0) revert();
        release[msg.sender] += amount;
        token.safeTransferFrom(recipient, msg.sender, amount);
    }

    function _reward(uint256 amount) internal returns (uint256) {
        uint256 reward;

        address parent1 = referral.parent(msg.sender);
        if (parent1 == address(0)) return reward;
        reward += (amount * 1500) / 10000;
        usdt.safeTransfer(parent1, (amount * 1500) / 10000);
        emit Reward(parent1, msg.sender, (amount * 1500) / 10000, 1500);

        address parent2 = referral.parent(parent1);
        if (parent2 == address(0)) return reward;
        reward += (amount * 500) / 10000;
        usdt.safeTransfer(parent2, (amount * 500) / 10000);
        emit Reward(parent2, msg.sender, (amount * 500) / 10000, 500);

        address parent3 = referral.parent(parent2);
        if (parent3 == address(0)) return reward;
        reward += (amount * 1000) / 10000;
        usdt.safeTransfer(parent3, (amount * 1000) / 10000);
        emit Reward(parent3, msg.sender, (amount * 1000) / 10000, 1000);

        return reward;
    }
}