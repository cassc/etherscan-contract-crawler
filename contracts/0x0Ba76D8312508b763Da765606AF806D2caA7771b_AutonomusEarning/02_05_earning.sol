// SPDX-License-Identifier:MIT
pragma solidity 0.8.18;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract AutonomusEarning is Ownable {
    using SafeMath for uint256;

    enum STATUS {
        ACTIVE,
        COMPLETED
    }

    struct LendInterfce {
        address user;
        uint256 amount;
        STATUS status;
        uint256 startDay;
        uint256 endDay;
    }

    struct Percent {
        uint256 amount;
        uint256 date;
        uint256 edate;
    }

    Percent[] percent;
    LendInterfce[] internal lenders;
    IERC20 token;

    bool start = true;
    uint256 startDate = block.timestamp;

    uint32 DAY_IN_SECONDS = 24 * 60 * 60;
    uint16[] periodInDays = [30, 60, 90, 180, 270, 360, 720, 1440];
    uint256 MINIMUM_AMOUT = 1;
    uint16 PERCENT_DENOMINATOR = 1000;
    uint16 YEAR = 365;
    uint256 PRECISION = 100000;
    uint256 LEND = 0;
    uint256 WITHDRAW = 0;

    event Lend(address user, uint256 amount, uint256 start, uint256 end);
    event Withdraw(address indexed user, uint256 amount, uint256 date);
    event Received(address, uint256);

    mapping(address => uint256[]) lendingsMap;

    constructor(address _token) {
        require(_token != address(0), "Invalid address for token");
        token = IERC20(_token);
        percent.push(Percent(120, _getCurrentDay(), 0));
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }

    function enableLend() external onlyOwner {
        require(start == false, "Lending enabled");
        start = true;
    }

    function disableLend() external onlyOwner {
        require(start == true, "Lending disabled");
        start = false;
    }

    function setMinAmount(uint256 amount) external onlyOwner {
        require(amount > 0, "MINIMUM_AMOUT > 0");
        MINIMUM_AMOUT = amount;
    }

    function pushPercent(uint256 p) external onlyOwner {
        require(p > 0, "PERCENT > 0");
        uint256 date = _getCurrentDay();
        percent.push(Percent(p, date, 0));
        if (percent.length > 1) {
            percent[percent.length - 2].edate = date;
        }
    }

    function pushPeriodInDays(uint16 p) external onlyOwner {
        require(p > 0, "percent > 0");
        periodInDays.push(p);
    }

    function popPeriodInDays(uint256 index) external onlyOwner {
        require(periodInDays.length > index, "index > 0");
        periodInDays[index] = periodInDays[periodInDays.length - 1];
        periodInDays.pop();
    }

    modifier calculation(uint256 index) {
        require(lenders.length > index, "Incorrect lender");
        require(lenders[index].user == address(msg.sender), "Not owner");
        _;
    }

    function params()
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (address(token), MINIMUM_AMOUT, startDate, LEND, WITHDRAW, start);
    }

    function getLenderSize() external view returns (uint256) {
        return lenders.length;
    }

    function getLender(uint256 index)
        external
        view
        returns (LendInterfce memory)
    {
        require(lenders.length > index, "Incorrect lender");
        return lenders[index];
    }

    function userLendings() external view returns (uint256[] memory) {
        return lendingsMap[address(msg.sender)];
    }

    function getPercent(uint256 index) external view returns (Percent memory) {
        require(percent.length > index, "Incorrect lender");
        return percent[index];
    }

    function getPercentSize() external view returns (uint256) {
        return percent.length;
    }

    function getPeriod(uint256 index) external view returns (uint16) {
        require(periodInDays.length > index, "Incorrect lender");
        return periodInDays[index];
    }

    function getPeriodSize() external view returns (uint256) {
        return periodInDays.length;
    }

    function getTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getCurrentDate() external view returns (uint256) {
        return block.timestamp;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        address payable owner = payable(owner());
        owner.transfer(balance);
    }

    function withdrawToken(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "Insufficient balance");
        require(_token.transfer(address(owner()), balance), "Transfer failed");
    }

    function getCurrentDay() external view returns (uint256) {
        return _getCurrentDay();
    }

    function _getCurrentDay() internal view returns (uint256) {
        uint256 date = (block.timestamp.sub(startDate)).div(DAY_IN_SECONDS);
        return date;
    }

    function lend(uint256 amount, uint256 periodIndex) external {
        _lend(amount, periodIndex);
    }

    function _lend(uint256 amount, uint256 periodIndex) internal {
        require(start == true, "Staking not started");
        require(amount >= MINIMUM_AMOUT, "Amount should be greater than 100");

        require(amount > 0, "Amount should be greater than 0");
        require(
            (periodIndex >= 0 && periodInDays.length > periodIndex),
            "Amount should be range"
        );

        require(
            token.balanceOf(address(msg.sender))  >= amount,
            "Insufficient balance"
        );

        require(
            token.transferFrom(address(msg.sender), address(this.owner()), amount),
            "Transfer failed"
        );

        uint256 startdate = _getCurrentDay();
        uint256 enddate = startdate.add(periodInDays[periodIndex]);
        LEND = LEND.add(amount);

        lenders.push(
            LendInterfce(
                address(msg.sender),
                amount,
                STATUS.ACTIVE,
                startdate,
                enddate
            )
        );

        lendingsMap[address(msg.sender)].push(lenders.length - 1);
        emit Lend(address(msg.sender), amount, startdate, enddate);
    }

    function calculateEarn(uint256 index)
        external
        view
        returns (uint256, uint256)
    {
        return _calculateEarn(index);
    }

    function _calculateEarn(uint256 index)
        internal
        view
        returns (uint256, uint256)
    {
        LendInterfce memory ll = lenders[index];
        uint256 pr = 0;
        uint256 di = 0;

        for (uint256 i = 0; i < percent.length; i++) {
            Percent memory item = percent[i];
            uint256 currentDate = _getCurrentDay();

            if (item.edate == 0) {
                if (currentDate < ll.endDay) {
                    uint256 d = currentDate.sub(ll.startDay).sub(item.date);
                    pr += item.amount.mul(d);
                    di += d;
                } else {
                    uint256 d = ll.endDay.sub(item.date);
                    pr += item.amount.mul(d);
                    di += d;
                }
            } else {
                if (currentDate <= item.edate) {
                    if (ll.endDay >= currentDate) {
                        uint256 d = currentDate.sub(item.date);
                        pr += item.amount.mul(d);
                        di += d;
                    }
                    if (ll.endDay >= item.date && ll.endDay < item.edate) {
                        uint256 d = ll.endDay.sub(item.date);
                        pr += item.amount.mul(d);
                        di += d;
                    }
                } else {
                    if (ll.endDay >= item.edate) {
                        uint256 d = item.edate.sub(item.date);
                        pr += item.amount.mul(d);
                        di += d;
                    } else {
                        uint256 d = ll.endDay.sub(item.date);
                        pr += item.amount.mul(d);
                        di += d;
                    }
                }
            }
        }

        return (pr, di);
    }

    function withdrawLend(uint256 index) external calculation(index) {
        (uint256 pr, uint256 di) = _calculateEarn(index);
        require(lenders[index].status == STATUS.ACTIVE, "Lend is completed");

        uint256 date = _getCurrentDay();
        require(date > lenders[index].endDay, "Lend not finished");
        uint256 p = pr.mul(PRECISION).div(di).div(PERCENT_DENOMINATOR);
        uint256 y = (lenders[index].endDay.sub(lenders[index].startDay))
            .mul(PRECISION)
            .div(YEAR);
        uint256 l = lenders[index].amount.mul(p).mul(y).div(
            PRECISION.mul(PRECISION)
        );
        uint256 amount = lenders[index].amount.add(l);
        require(
            token.transfer(address(lenders[index].user), amount),
            "No balance"
        );
        lenders[index].status = STATUS.COMPLETED;
        WITHDRAW = WITHDRAW.add(amount);

        emit Withdraw(address(lenders[index].user), amount, date);
    }
}
