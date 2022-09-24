// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IClaimable {
    function claim() external returns (uint amount);

    event Claim(address indexed account, uint amount);
}

contract Vester is Ownable, IClaimable {
    using SafeERC20 for IERC20;

    address public immutable MON = 0x1EA48B9965bb5086F3b468E50ED93888a661fc17; // MON (Ethereum)
    address public distributorContract; // Distributor Contract (LiqBootstrap)

    uint256 public totalVestingAmount; // Initial MON balance of the Contract (global MON amount to be vested)
    uint256 public vestingBegin;
    uint256 public vestingEnd;

    bool public started = false;

    uint256 public previousPoint;
    uint256 public immutable finalPoint = 1e18; // From 0 to 1e18 of precision

    constructor(uint256 _totalVestingAmount) {
        totalVestingAmount = _totalVestingAmount;
    }

    /// @notice that Smart Contract needs to be seed before calling this function
    function startVesting(uint256 _days) public onlyOwner {
        require(!started, "Already started");
        require(_days > 0 && _days < 1000, "Invalid period duration");

        uint256 balance = IERC20(MON).balanceOf(address(this));
        require(balance > 0, "Contract has not been seed");
        if (totalVestingAmount != balance) {
            totalVestingAmount = balance; // Reassign in case the amount is updated after deployment
        }

        vestingBegin = getBlockTimestamp();
        vestingEnd = vestingBegin + _days * 1 days;
        started = true;
    }

    function getUnlockedAmount() public view returns (uint256 amount, uint256 currentPoint) {
        uint256 blockTimestamp = getBlockTimestamp();
        currentPoint = ((blockTimestamp - vestingBegin) * (1e18)) / (vestingEnd - vestingBegin);
        amount = (totalVestingAmount * (currentPoint - previousPoint)) / finalPoint;
    }

    function _getUnlockedAmount() internal returns (uint256) {
        (uint256 amount, uint256 currentPoint) = getUnlockedAmount();
        previousPoint = currentPoint;
        return amount;
    }

    function claim() public override returns (uint256 amount) {
        if (vestingBegin == 0 || vestingEnd == 0) return 0; // Has not been initialized
        require(msg.sender == distributorContract, "Unauthorized");
        uint256 blockTimestamp = getBlockTimestamp();
        if (blockTimestamp < vestingBegin) return 0;
        if (blockTimestamp > vestingEnd) {
            amount = IERC20(MON).balanceOf(address(this));
        } else {
            amount = _getUnlockedAmount();
        }
        if (amount > 0) IERC20(MON).safeTransfer(distributorContract, amount);
    }

    function setDistributorContract(address _distributorContract) external onlyOwner {
        require(_distributorContract != address(0), "Not valid address");
        distributorContract = _distributorContract;
    }

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}