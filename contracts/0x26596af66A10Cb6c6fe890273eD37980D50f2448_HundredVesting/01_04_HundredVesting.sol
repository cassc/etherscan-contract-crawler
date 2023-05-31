// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HundredVesting {
    using SafeERC20 for IERC20;
    IERC20 public immutable Hundred;
    uint256 numberOfEpochs;
    uint256 epochLength;
    struct UserInfo {
        uint256 totalAmount;
        uint256 timestamp;
        uint256 claimedAmount;
    }
    mapping(address => UserInfo) addresses; 

    constructor(IERC20 hundred, uint256 _epochLength, uint256 totalVestingTime) {
        Hundred = hundred;
        epochLength = _epochLength;
        numberOfEpochs = totalVestingTime / _epochLength;
    }

    function beginVesting(address beneficiary, uint256 amount) external {
        require(amount != 0, "Amount should bigger than 0");

        Hundred.safeTransferFrom(msg.sender, address(this), amount);
        UserInfo memory user = addresses[beneficiary];
        if (user.totalAmount != 0) {
            user.totalAmount = user.totalAmount - user.claimedAmount + amount;
            user.timestamp = block.timestamp;
            user.claimedAmount = 0;
        } else {
            user = UserInfo({ totalAmount: amount, timestamp: block.timestamp, claimedAmount: 0 });
        }
        addresses[beneficiary] = user;
    }

    function claimVested() public {
        uint256 amount = getClaimableVest(msg.sender);
        require(amount != 0, "No claimable hundred token");

        Hundred.safeTransfer(msg.sender, amount);
        addresses[msg.sender].claimedAmount = addresses[msg.sender].claimedAmount + amount;
    }

    function getClaimableVest(address beneficiary) public view returns(uint) {
        UserInfo memory user = addresses[beneficiary];
        require(user.timestamp != 0, "Invalid address");
        uint256 amount = (block.timestamp - user.timestamp) / epochLength * user.totalAmount / numberOfEpochs;
        return amount < user.claimedAmount ? 0 : amount - user.claimedAmount;
    }

    function getClaimedVest(address beneficiary) public view returns(uint) {
        return addresses[beneficiary].claimedAmount;
    }

    function getRemainingVest(address beneficiary) public view returns(uint) {
        return getTotalVest(beneficiary) - getClaimedVest(beneficiary);
    }

    function getTotalVest(address beneficiary) public view returns(uint) {
        return addresses[beneficiary].totalAmount;
    }
}