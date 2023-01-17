// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../common/BaseProxy.sol";
import "../common/BaseDAO.sol";

contract InvestorsDAO is BaseDAO, BaseProxy, IDAOInvestors {
    struct Vesting {
        uint256 amount;
        uint256 amountWithdrawn;
        uint256 startDate;
        uint256 duration;
    }

    struct VestingWithProgress {
        uint256 amount;
        uint256 amountWithdrawn;
        uint256 startDate;
        uint256 duration;
        uint256 progress;
    }

    struct Investor {
        uint256 fixedAmount;
        uint256 startLockIndex;
        Vesting[] vestings;
    }

    uint256 public index;
    uint256 public totalLock;
    address[] public treasuries;

    mapping(address => Investor) public investors;
    mapping(uint256 => uint256) public lockAmounts;
    mapping(uint256 => uint256) public revenueAmounts;

    IMFToken public mf;
    IERC20 public usdt;

    event Deposit(
        address indexed investor,
        uint256 amount,
        uint256 indexed index
    );

    event Withdraw(address indexed investor, uint256 amount);
    event SendProfit(address indexed investor, uint256 amout);

    function initialize(
        address[] memory _treasuries,
        address _mf,
        address _usdt
    ) public initializer {
        treasuries = _treasuries;
        mf = IMFToken(_mf);
        usdt = IERC20(_usdt);

        __Ownable_init();
    }

    function _unsafe_inc(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    function getVestingAvaliableAmount(
        Vesting memory _vesting,
        uint256 progress
    ) private pure returns (uint256) {
        return
            (_vesting.amount * progress) / precision - _vesting.amountWithdrawn;
    }

    function updateVestingWithdrawnReadyAmount(address _investor)
        private
        returns (uint256)
    {
        Investor memory investor = investors[_investor];
        if (investor.vestings.length == 0) return 0;

        uint256 vestingAmount;

        for (uint256 i; i < investor.vestings.length; i = _unsafe_inc(i)) {
            uint256 progress = getProgress(
                investor.vestings[i].startDate,
                investor.vestings[i].duration
            );

            if (progress > 0) {
                uint256 vestingAvailableAmount = getVestingAvaliableAmount(
                    investor.vestings[i],
                    progress
                );

                vestingAmount += vestingAvailableAmount;
                investors[_investor]
                    .vestings[i]
                    .amountWithdrawn += vestingAvailableAmount;
            }
        }

        return vestingAmount;
    }

    function getVestingWithdrawReadyAmount() external view returns (uint256) {
        address _investor = msg.sender;

        Investor memory investor = investors[_investor];
        if (investor.vestings.length == 0) return 0;

        uint256 vestingAmount;

        for (uint256 i; i < investor.vestings.length; i = _unsafe_inc(i)) {
            uint256 progress = getProgress(
                investor.vestings[i].startDate,
                investor.vestings[i].duration
            );

            if (progress > 0) {
                vestingAmount += getVestingAvaliableAmount(
                    investor.vestings[i],
                    progress
                );
            }
        }

        return vestingAmount + investor.fixedAmount;
    }

    function makeDaoProfit() public {
        uint256 usdtAmount;

        for (uint256 i; i < treasuries.length; i = _unsafe_inc(i)) {
            address treasury = treasuries[i];
            uint256 balance = usdt.allowance(treasury, address(this));

            if (balance > 0) {
                usdt.transferFrom(treasury, address(this), balance);
                usdtAmount += balance;
            }
        }

        if (usdtAmount > 0) {
            revenueAmounts[index] = usdtAmount;
            lockAmounts[index] = totalLock;
            index = _unsafe_inc(index);
        }
    }

    function getTotalInvestmentAmount(address _investor)
        public
        view
        returns (uint256)
    {
        uint256 availableVestingSum;
        Investor memory investor = investors[_investor];

        for (uint256 i; i < investor.vestings.length; i = _unsafe_inc(i)) {
            availableVestingSum +=
                investor.vestings[i].amount -
                investor.vestings[i].amountWithdrawn;
        }
        return availableVestingSum + investor.fixedAmount;
    }

    function deposit(uint256 _amount, address _investor) external {
        Investor storage investor = investors[_investor];
        mf.transferFrom(_investor, address(this), _amount);

        sendProfit(_investor);

        investor.startLockIndex = index;
        investor.fixedAmount += _amount;
        totalLock += _amount;

        emit Deposit(_investor, getTotalInvestmentAmount(_investor), index);
    }

    function vestingDeposit(
        uint256 _amount,
        address _investor,
        uint256 _vestingDuration,
        uint256 _vestingStartDate
    ) external {
        Investor storage investor = investors[_investor];

        mf.transferFrom(msg.sender, address(this), _amount);

        sendProfit(_investor);

        totalLock += _amount;
        investor.startLockIndex = index;
        investor.vestings.push(
            Vesting(_amount, 0, _vestingStartDate, _vestingDuration)
        );

        emit Deposit(_investor, getTotalInvestmentAmount(msg.sender), index);
    }

    function getProfit(address _investor) public view returns (uint256) {
        Investor memory investor = investors[_investor];

        uint256 totalRevenue;
        uint256 totalInvestment = getTotalInvestmentAmount(_investor);

        for (
            uint256 i = investor.startLockIndex;
            i < index;
            i = _unsafe_inc(i)
        ) {
            totalRevenue +=
                (totalInvestment * revenueAmounts[i]) /
                lockAmounts[i];
        }

        return totalRevenue;
    }

    function sendProfit(address _investor) public {
        uint256 totalRevenue = getProfit(_investor);

        investors[_investor].startLockIndex = index;
        usdt.transfer(_investor, totalRevenue);

        emit SendProfit(_investor, totalRevenue);
    }

    function withdraw() external {
        address _investor = msg.sender;

        Investor storage investor = investors[_investor];
        uint256 fixedAmount = investor.fixedAmount;
        uint256 withdrawVestingResult = updateVestingWithdrawnReadyAmount(
            _investor
        );

        sendProfit(_investor);

        uint256 totalAmount = fixedAmount + withdrawVestingResult;
        totalLock -= totalAmount;

        mf.transfer(_investor, totalAmount);
        investor.fixedAmount = 0;

        emit Withdraw(_investor, totalAmount);
    }

    function setTreasury(address[] calldata _treasuries) external onlyOwner {
        treasuries = _treasuries;
    }

    function getInvestorVesting(address _investor)
        external
        view
        returns (VestingWithProgress[] memory)
    {
        Vesting[] memory _vestings = investors[_investor].vestings;
        VestingWithProgress[]
            memory vestingsWithProgress = new VestingWithProgress[](
                _vestings.length
            );

        for (uint256 i; i < _vestings.length; i = _unsafe_inc(i)) {
            Vesting memory _vesting = _vestings[i];

            vestingsWithProgress[i] = VestingWithProgress(
                _vesting.amount,
                _vesting.amountWithdrawn,
                _vesting.startDate,
                _vesting.duration,
                getProgress(_vesting.startDate, _vesting.duration)
            );
        }

        return vestingsWithProgress;
    }
}