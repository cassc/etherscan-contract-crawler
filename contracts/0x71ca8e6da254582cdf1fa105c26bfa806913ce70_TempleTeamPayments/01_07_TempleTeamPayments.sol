//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TempleTeamPayments is Ownable {
    uint256 public immutable roundStartDate;
    uint256 public immutable roundEndDate;
    IERC20 public immutable TEMPLE;

    mapping(address => uint256) public allocation;
    mapping(address => uint256) public claimed;

    event Claimed(address indexed member, uint256 amount);

    constructor(IERC20 _TEMPLE, uint256 paymentPeriodInSeconds, uint256 startTimestamp) {
        roundStartDate = startTimestamp;
        roundEndDate = startTimestamp + paymentPeriodInSeconds;
        TEMPLE = _TEMPLE;
    }

    modifier addressExists(address _address) {
        require(allocation[_address] > 0, "TempleTeamPayments: Member not found");
        _;
    }

    function setAllocations(
        address[] memory _addresses,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(
            _addresses.length == _amounts.length,
            "TempleTeamPayments: addresses and amounts must be the same length"
        );
        address addressZero = address(0);
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != addressZero, "TempleTeamPayments: Address cannot be 0x0");
            allocation[_addresses[i]] = _amounts[i];
        }
    }

    function setAllocation(address _address, uint256 _amount) external onlyOwner {
        require(_address != address(0), "TempleTeamPayments: Address cannot be 0x0");
        allocation[_address] = _amount;
    }

    function pauseMember(address _address)
        external
        onlyOwner
        addressExists(_address)
    {
        allocation[_address] = claimed[_address];
    }

    function calculateClaimable(address _address)
        public
        view
        addressExists(_address)
        returns (uint256)
    {
        // allocation * portion_of_round_elapsed - total_claimed
        uint256 claimableAmount = (allocation[_address] *
            (block.timestamp - roundStartDate)) /
            (roundEndDate - roundStartDate) -
            claimed[_address];
        if (claimableAmount + claimed[_address] > allocation[_address]) {
            claimableAmount = allocation[_address] - claimed[_address];
        }
        return claimableAmount;
    }

    function claim() external addressExists(msg.sender) {
        uint256 claimable = calculateClaimable(msg.sender);
        require(claimable > 0, "TempleTeamPayments: Member has no TEMPLE to claim");

        claimed[msg.sender] += claimable;
        SafeERC20.safeTransfer(TEMPLE, msg.sender, claimable);
        emit Claimed(msg.sender, claimable);
    }

    function adhocPayment(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "TempleTeamPayments: Amount must be greater than 0");
        claimed[_to] += _amount;
        SafeERC20.safeTransfer(TEMPLE, _to, _amount);
        emit Claimed(_to, _amount);
    }

    function withdrawTempleBalance(address _to, uint256 _amount)
        external
        onlyOwner
    {
        require(_amount > 0, "TempleTeamPayments: Amount must be greater than 0");
        SafeERC20.safeTransfer(TEMPLE, _to, _amount);
    }
}