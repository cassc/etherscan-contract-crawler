//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";

interface IToken {
    function getOwner() external view returns (address);
    function burn(uint256 amount) external returns (bool);
}

interface IOPTX {
    function emitShares() external;
}

contract EmissionRecipient {

    address public constant OPTX = 0x4Ef0F0f98326830d823F28174579C39592cDB367;

    address public monthlyPool = 0xCd9cE071857a313a643e0E35e35f6E64c5da2fFB;
    address public threeMonthlyPool = 0x876d9AF9F3B54c6AAAA26126CFe6e332eEC83b66;
    address public sixMonthlyPool = 0xBD5B0Ac5DE18aBB21cfb96D3edfCd9D109653940;
    address public yearlyPool = 0x2EBcBE94173f3ebB7C2cC302e67ba30C134C540A;

    uint256 public monthlyPoolRate = 52200000000; // 0.15% per day
    uint256 public threeMonthlyPoolRate = 87000000000; // 0.25% per day
    uint256 public sixMonthlyPoolRate = 175000000000; // 0.5% per day
    uint256 public yearlyPoolRate = 350000000000;  // 1% per day

    uint256 public lastReward;

    bool private entered = false;

    modifier onlyOwner() {
        require(
            msg.sender == IToken(OPTX).getOwner(),
            'Only Owner'
        );
        _;
    }

    constructor() {
        lastReward = block.number;
    }

    function resetEmissions() external onlyOwner {
        lastReward = block.number;
    }

    function setLastRewardStartTime(uint startBlock) external onlyOwner {
        lastReward = startBlock;
    }

    function setPools(
        address nMonthly,
        address nThreeMonthly,
        address nSixMonthly,
        address nYearly
    ) external onlyOwner {
        monthlyPool = nMonthly;
        threeMonthlyPool = nThreeMonthly;
        sixMonthlyPool = nSixMonthly;
        yearlyPool = nYearly;
    }

    function setRates(
        uint256 nMonthly,
        uint256 nThreeMonthly,
        uint256 nSixMonthly,
        uint256 nYearly
    ) external onlyOwner {
        monthlyPoolRate = nMonthly;
        threeMonthlyPoolRate = nThreeMonthly;
        sixMonthlyPoolRate = nSixMonthly;
        yearlyPoolRate = nYearly;
    }

    function withdraw(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function withdrawAmount(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function trigger() external {

        if (entered) {
            return;
        }

        entered = true;

        // amount to reward
        (
        uint month, uint threeMonth, uint sixMonth, uint year        
        ) = amountToDistribute();
        
        // reset timer
        lastReward = block.number;

        // send reward to the vault
        _send(monthlyPool, month);
        _send(threeMonthlyPool, threeMonth);
        _send(sixMonthlyPool, sixMonth);
        _send(yearlyPool, year);

        entered = false;
    }

    function amountInPool(address pool) public view returns (uint256) {
        if (pool == address(0)) {
            return 0;
        }
        return IERC20(OPTX).balanceOf(pool);
    }

    function timeSince() public view returns (uint256) {
        return lastReward < block.number ? block.number - lastReward : 0;
    }

    function qtyPerBlock(address pool, uint256 dailyReturn) public view returns (uint256) {
        return ( amountInPool(pool) * dailyReturn ) / 10**18;
    }

    function amountToDistribute() public view returns (uint256, uint256, uint256, uint256) {
        uint nTime = timeSince();
        return(
            qtyPerBlock(monthlyPool, monthlyPoolRate) * nTime,
            qtyPerBlock(threeMonthlyPool, threeMonthlyPoolRate) * nTime,
            qtyPerBlock(sixMonthlyPool, sixMonthlyPoolRate) * nTime,
            qtyPerBlock(yearlyPool, yearlyPoolRate) * nTime
        );
    }

    function totalToDistributePerBlock() public view returns (uint256) {
        (uint m, uint t, uint s, uint y) = amountToDistribute();
        return m + t + s + y;
    }

    function totalToDistribute() external view returns (uint256) {
        return timeSince() * totalToDistributePerBlock();
    }

    function _send(address to, uint amount) internal {
        uint bal = IERC20(OPTX).balanceOf(address(this));
        if (amount > bal) {
            amount = bal;
        }
        if (amount == 0) {
            return;
        }
        IERC20(OPTX).transfer(to, amount); 
    }
}