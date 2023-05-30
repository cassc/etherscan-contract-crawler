//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EmissionsPrivateDispenserStatic is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public vestingTotal;
    uint256 public vestingStart;
    uint256 public vestingDuration;
    mapping(address => uint256) public investorsPercentages; // 1e12 = 100%
    mapping(address => uint256) public investorsClaimedAmount;

    event ConfigureInvestor(address investor, uint256 percentage);
    event Claim(address user, uint256 amount);

    constructor(
        address _token,
        uint256 _vestingTotal,
        uint256 _vestingStart,
        uint256 _vestingDuration,
        address[] memory investors,
        uint256[] memory percentages
    ) {
        token = IERC20(_token);
        vestingTotal = _vestingTotal;
        vestingStart = _vestingStart;
        vestingDuration = _vestingDuration;
        require(investors.length == percentages.length);
        uint256 total = 0;
        for (uint256 i = 0; i < investors.length; i++) {
            require(investors[i] != address(0), "!zero");
            investorsPercentages[investors[i]] = percentages[i];
            emit ConfigureInvestor(investors[i], percentages[i]);
            total += percentages[i];
        }
        require(total == 1e12, "percentages do not add up to 100%");
    }

    function updateInvestorAddress(address oldAddress, address newAddress) public onlyOwner {
        require(investorsPercentages[oldAddress] > 0, "not an investor");
        investorsPercentages[newAddress] = investorsPercentages[oldAddress];
        investorsPercentages[oldAddress] = 0;
        investorsClaimedAmount[newAddress] = investorsClaimedAmount[oldAddress];
        investorsClaimedAmount[oldAddress] = 0;
        emit ConfigureInvestor(newAddress, investorsPercentages[newAddress]);
    }

    function claimable(address user) public view returns (uint256) {
        uint elapsed = block.timestamp - vestingStart;
        uint vested = vestingTotal * _min(1e12, (elapsed * 1e12) / vestingDuration) / 1e12;
        return ((vested * investorsPercentages[user]) / 1e12) - investorsClaimedAmount[user];
    }

    function claim() public {
        uint256 amount = claimable(msg.sender);
        require(amount > 0, "nothing to claim");
        investorsClaimedAmount[msg.sender] += amount;
        token.safeTransfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }

    function _min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}