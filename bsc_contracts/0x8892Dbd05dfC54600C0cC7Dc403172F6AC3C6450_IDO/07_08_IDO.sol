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
    uint256 public price = 100 * 1e18;
    uint256 public quantity = 1000 * 1e18;

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

        releaseTime = block.timestamp;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setQuantity(uint256 _quantity) external onlyOwner {
        quantity = _quantity;
    }

    function buy(uint256 num) external {
        if (block.timestamp < 1668493800 || block.timestamp > releaseTime) revert();
        if (referral.registered(msg.sender) == false) revert Unregistered();

        uint256 amount = num * price;
        usdt.safeTransferFrom(msg.sender, address(this), amount);

        uint256 tokenAmount = num * quantity;
        lock[msg.sender] += tokenAmount;
        release[msg.sender] += (tokenAmount * 6000) / 10000;
        token.safeTransferFrom(recipient, msg.sender, (tokenAmount * 6000) / 10000);

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
        if (month > 2) {
            month = 2;
        }
        uint256 amount = (lock[user] * (6000 + 2000 * month)) / 10000;
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
        reward += (amount * 1000) / 10000;
        usdt.safeTransfer(parent2, (amount * 1000) / 10000);
        emit Reward(parent2, msg.sender, (amount * 1000) / 10000, 1000);

        return reward;
    }

    function claim(
        address _token,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        if (_token == address(0)) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).transfer(_to, _amount);
        }
    }
}