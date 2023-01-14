// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./DollarsBillals_Status.sol";

contract DollarsBillals is DollarsBillals_Status {
    using SafeMath for uint;
    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint indexed level,
        uint amount
    );
    event FeePayed(address indexed user, uint totalAmount);
    event Reinvestment(address indexed user, uint amount);

    constructor(address _devAddr, address _token) {
        devAddress = _devAddr;
        token = IERC20(_token);

        emit Paused(msg.sender);
    }

    modifier isNotContract() {
        require(!isContract(msg.sender), "contract not allowed");
        _;
    }

    modifier checkUser_() {
        bool check = checkUser(msg.sender);
        require(check, "try again later");
        _;
    }

    function checkUser(address _user) public view returns (bool) {
        uint check = block.timestamp.sub(
            getlastActionDate(users[_user])
        );
        if (check > TIME_STEP) return true;
        return false;
    }

    function useHasMaxWithDraw(address _user) public view returns (bool) {
        if(users[_user].totalWithdraw >= getUserMaxProfit(_user)) {
            return true;
        }
        return false;
    }

    modifier whenNotMaxWithDraw() {
        require(!useHasMaxWithDraw(msg.sender), "you have max withdraw");
        _;
    }

    modifier tenBlocks() {
        require(
            block.number.sub(lastBlock[msg.sender]) > 10,
            "wait 10 blocks"
        );
        _;
    }
 
    function invest(address referrer, uint investAmt) external whenNotPaused nonReentrant isNotContract tenBlocks {
        // uint investAmt = msg.value;
        lastBlock[msg.sender] = block.number;
        token.transferFrom(msg.sender, address(this), investAmt);
        require(investAmt >= INVEST_MIN_AMOUNT, "insufficient deposit");

        User storage user = users[msg.sender];

        if (user.depositsLength == 0) {
            user.checkpoint = block.timestamp;
            user.userAddress = msg.sender;
            totalUsers++;
            emit Newbie(msg.sender);
        }

        if (
            user.referrer == address(0) &&
            users[referrer].depositsLength > 0 &&
            referrer != msg.sender &&
            users[referrer].referrer != msg.sender
        ) {
            user.referrer = referrer;
        } else {
            user.referrer = ownerAddress;
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint i; i < MACHINEBONUS_LENGTH; i++) {
                if (upline != address(0)) {
                    if (user.depositsLength == 0) {
                        users[upline].referrerCount[i] += 1;
                    }
                    uint amount = (investAmt.mul(REFERRAL_PERCENTS[i])).div(
                        PERCENTS_DIVIDER
                    );
                    if (users[upline].machineDeposits[i].start == 0) {
                        users[upline].machineDeposits[i].start = block
                            .timestamp;
                        users[upline].machineDeposits[i].level = i + 1;
                    } else {
                        updateDeposit(upline, i);
                    }
                    users[upline].machineDeposits[i].initAmount += amount;
                    users[upline].totalBonus += amount;
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        Deposit memory newDeposit;
        newDeposit.amount = investAmt;
        newDeposit.initAmount = investAmt;
        newDeposit.start = block.timestamp;
        user.deposits[user.depositsLength] = newDeposit;
        user.depositsLength++;
        user.totalInvest += investAmt;
        user.primeInvest += investAmt;
        user.machineAllow = true;

        totalInvested += investAmt;
        totalDeposits++;

        payInvestFee(investAmt);
        emit NewDeposit(msg.sender, investAmt);
    }

    function withdraw_f() external whenNotPaused checkUser_ whenNotMaxWithDraw nonReentrant isNotContract isNotBlocked tenBlocks returns (bool) {
        lastBlock[msg.sender] = block.number;
        User storage user = users[msg.sender];

        uint totalAmount;

        for (uint i; i < user.depositsLength; i++) {
            uint dividends;
            Deposit memory deposit = user.deposits[i];

            if (
                deposit.withdrawn < getMaxprofit(deposit) &&
                deposit.isForceWithdraw == false
            ) {
                dividends = calculateDividents(deposit, user, totalAmount);

                if (dividends > 0) {
                    user.deposits[i].withdrawn += dividends; /// changing of storage data
                    totalAmount += dividends;
                }
            }
        }

        for (uint i; i < MACHINEBONUS_LENGTH; i++) {
            uint dividends;
            MachineBonus memory machineBonus = user.machineDeposits[i];
            if (
                machineBonus.withdrawn < machineBonus.initAmount &&
                user.machineAllow == true
            ) {
                dividends = calculateMachineDividents(
                    machineBonus,
                    user,
                    totalAmount
                );
                if (dividends > 0) {
                    user.machineDeposits[i].withdrawn = machineBonus
                        .withdrawn
                        .add(dividends); /// changing of storage data
                    delete user.machineDeposits[i].bonus;
                    totalAmount += dividends;
                }
            }
        }

        require(totalAmount >= MIN_WITHDRAW, "User has no dividends");

        uint totalFee = withdrawFee(totalAmount, getlastActionDate(user));

        uint toTransfer = totalAmount.sub(totalFee);

        totalWithdrawn += totalAmount;

        user.checkpoint = block.timestamp;

        transferHandler(msg.sender, toTransfer);
        user.totalWithdraw += totalAmount;

        if (!user.hasWithdraw_f) {
            user.hasWithdraw_f = true;
        }

        emit FeePayed(msg.sender, totalFee);
        emit Withdrawn(msg.sender, totalAmount);
        return true;
    }

    function withdraw_C() external whenNotPaused checkUser_ whenNotMaxWithDraw nonReentrant isNotContract isNotBlocked tenBlocks returns (bool) {
        lastBlock[msg.sender] = block.number;
        User storage user = users[msg.sender];
        require(!user.hasWithdraw_f, "User has withdraw_f");

        uint totalAmount;
        uint _bonus;

        for (uint i; i < user.depositsLength; i++) {
            uint dividends;
            Deposit memory deposit = user.deposits[i];

            if (
                deposit.withdrawn < getMaxprofit(deposit) &&
                deposit.isForceWithdraw == false
            ) {
                dividends = calculateDividents(deposit, user, totalAmount);
                _bonus += deposit.initAmount.mul(FORCE_BONUS_PERCENT).div(
                    PERCENTS_DIVIDER
                );
                if (dividends > 0) {
                    user.deposits[i].withdrawn += dividends; /// changing of storage data
                    totalAmount += dividends;
                }
                user.deposits[i].isForceWithdraw = true;
            }
        }

        for (uint i; i < MACHINEBONUS_LENGTH; i++) {
            uint dividends;
            MachineBonus memory machineBonus = user.machineDeposits[i];
            if (
                machineBonus.withdrawn < machineBonus.initAmount &&
                user.machineAllow == true
            ) {
                dividends = calculateMachineDividents(
                    machineBonus,
                    user,
                    totalAmount
                );
                if (dividends > 0) {
                    user.machineDeposits[i].withdrawn += dividends;
                    delete user.machineDeposits[i].bonus;
                    totalAmount += dividends;
                }
            }
        }
        uint _depositsWithdrawn = totalAmount;
        totalAmount += _bonus;
        require(totalAmount >= MIN_WITHDRAW, "User has no dividends");
        user.machineAllow = false;

        uint totalFee = withdrawFee(totalAmount, 0);

        uint toTransfer = totalAmount.sub(totalFee);

        totalWithdrawn += totalAmount;


        user.checkpoint = block.timestamp;

        transferHandler(msg.sender, toTransfer);

        user.totalWithdraw += _depositsWithdrawn;
        user.bonusWithdraw_c += _bonus; //registrar y mostrar este valor

        emit FeePayed(msg.sender, totalFee);
        emit Withdrawn(msg.sender, totalAmount);
        return true;
    }

    function reinvestment() external whenNotPaused checkUser_ whenNotMaxWithDraw nonReentrant isNotContract isNotBlocked tenBlocks returns (bool) {
        //arreglar reinvest, a;adir el reinvest del machine deposit
        lastBlock[msg.sender] = block.number;
        User storage user = users[msg.sender];

        uint totalDividends;

        for (uint i; i < user.depositsLength; i++) {
            uint dividends;
            Deposit memory deposit = user.deposits[i];

            if (deposit.withdrawn < getMaxprofit(deposit)) {
                dividends = calculateDividents(deposit, user, totalDividends);

                if (dividends > 0) {
                    user.deposits[i].amount += dividends;
                    totalDividends += dividends;
                }
            }
        }

        for (uint i; i < MACHINEBONUS_LENGTH; i++) {
            MachineBonus memory machineBonus = user.machineDeposits[i];
            if (
                machineBonus.withdrawn < machineBonus.initAmount &&
                user.machineAllow == true
            ) {
                uint dividends = calculateMachineDividents(
                    machineBonus,
                    user,
                    totalDividends
                );
                if (dividends > 0) {
                    user.machineDeposits[i].initAmount += dividends;
                    delete user.machineDeposits[i].bonus;
                    totalDividends += dividends;
                }
            }
        }

        require(totalDividends > MINIMAL_REINVEST_AMOUNT, "User has no dividends");
        user.checkpoint = block.timestamp;

        user.reinvested += totalDividends;
        user.totalInvest += totalDividends;
        totalReinvested += totalDividends;

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint i; i < MACHINEBONUS_LENGTH; i++) {
                if (upline != address(0)) {
                    if (user.depositsLength == 0) {
                        users[upline].referrerCount[i] += 1;
                    }
                    uint amount = (totalDividends.mul(REFERRAL_PERCENTS[i]))
                        .div(PERCENTS_DIVIDER);
                    if (users[upline].machineDeposits[i].start == 0) {
                        users[upline].machineDeposits[i].start = block
                            .timestamp;
                        users[upline].machineDeposits[i].level = i + 1;
                    } else {
                        updateDeposit(upline, i);
                    }
                    users[upline].machineDeposits[i].initAmount += amount;
                    users[upline].totalBonus += amount;
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        emit Reinvestment(msg.sender, totalDividends);
        return true;
    }

    function getNextUserAssignment(address userAddress)
        public
        view
        returns (uint)
    {
        uint checkpoint = getlastActionDate(users[userAddress]);
        if (initDate > checkpoint) checkpoint = initDate;
        return checkpoint.add(TIME_STEP);
    }

    function getPublicData()
        external
        view
        returns (
            uint totalUsers_,
            uint totalInvested_,
            uint totalReinvested_,
            uint totalWithdrawn_,
            uint totalDeposits_,
            uint balance_,
            uint roiBase,
            uint maxProfit,
            uint minDeposit,
            uint daysFormdeploy
        )
    {
        totalUsers_ = totalUsers;
        totalInvested_ = totalInvested;
        totalReinvested_ = totalReinvested;
        totalWithdrawn_ = totalWithdrawn;
        totalDeposits_ = totalDeposits;
        balance_ = getContractBalance();
        roiBase = ROI_BASE;
        maxProfit = MAX_PROFIT;
        minDeposit = INVEST_MIN_AMOUNT;
        daysFormdeploy = (block.timestamp.sub(initDate)).div(TIME_STEP);
    }

    function getUserData(address userAddress)
        external
        view
        returns (
            uint totalWithdrawn_,
            uint depositBalance,
            uint machineBalance,
            uint totalDeposits_,
            uint totalreinvest_,
            uint balance_,
            uint nextAssignment_,
            uint amountOfDeposits,
            uint checkpoint,
            uint maxWithdraw,
            address referrer_,
            uint[MACHINEBONUS_LENGTH] memory referrerCount_
        )
    {
        totalWithdrawn_ = users[userAddress].totalWithdraw + users[userAddress]
            .bonusWithdraw_c;
        totalDeposits_ = getUserTotalDeposits(userAddress);
        nextAssignment_ = getNextUserAssignment(userAddress);
        depositBalance = getUserDepositBalance(userAddress);
        machineBalance = getUserMachineBalance(userAddress);
        balance_ = getAvatibleDividens(userAddress);
        totalreinvest_ = users[userAddress].reinvested;
        amountOfDeposits = users[userAddress].depositsLength;
        checkpoint = getlastActionDate(users[userAddress]);
        referrer_ = users[userAddress].referrer;
        referrerCount_ = users[userAddress].referrerCount;
        maxWithdraw = getUserMaxProfit(userAddress);
    }

    function getContractBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function getUserDepositBalance(address userAddress)
        internal
        view
        returns (uint)
    {
        User storage user = users[userAddress];

        uint totalDividends;

        for (uint i; i < user.depositsLength; i++) {
            Deposit memory deposit = users[userAddress].deposits[i];

            if (deposit.withdrawn < getMaxprofit(deposit)) {
                uint dividends = calculateDividents(deposit, user, totalDividends);
                totalDividends += dividends;
            }
        }

        return totalDividends;
    }

    function getUserMachineBalance(address userAddress) public view returns(uint) {
        User storage user = users[userAddress];
        uint fromDeposits = getUserDepositBalance(userAddress);
        uint totalDividends;
        for (uint i; i < MACHINEBONUS_LENGTH; i++) {
            MachineBonus memory machineBonus = user.machineDeposits[i];
            if (
                machineBonus.withdrawn < machineBonus.initAmount &&
                user.machineAllow == true
            ) {
                uint dividends = calculateMachineDividents(
                    machineBonus,
                    user,
                    fromDeposits + totalDividends
                );
                if (dividends > 0) {
                    totalDividends += dividends;
                }
            }
        }
        return totalDividends;
    }


    function getAvatibleDividens(address _user) internal view returns(uint) {
        return getUserDepositBalance(_user) + getUserMachineBalance(_user);
    }

    function calculateDividents(Deposit memory deposit, User storage user, uint _currentDividends)
        internal
        view
        returns (uint)
        {
        if(deposit.isForceWithdraw == true) {
            return 0;
        }
        uint dividends;
        uint depositPercentRate = getDepositRoi();

        uint checkDate = getDepsitStartDate(deposit);

        if (checkDate < getlastActionDate(user)) {
            checkDate = getlastActionDate(user);
        }

        dividends = (
            deposit.amount.mul(
                depositPercentRate.mul(block.timestamp.sub(checkDate))
            )
        ).div((PERCENTS_DIVIDER).mul(TIME_STEP));

        uint _userMaxDividends = getUserMaxProfit(user.userAddress);
        if (
            user.totalWithdraw + dividends + _currentDividends >
            _userMaxDividends
        ) {
            if (user.totalWithdraw + _currentDividends < _userMaxDividends) {
                dividends =
                    _userMaxDividends -
                    user.totalWithdraw -
                    _currentDividends;
            } else {
                dividends = 0;
            }
        }

        if (deposit.withdrawn.add(dividends) > getMaxprofit(deposit)) {
            dividends = getMaxprofit(deposit).sub(deposit.withdrawn);
        }

        return dividends;
    }

    function calculateMachineDividents(
        MachineBonus memory deposit,
        User storage user,
        uint _currentDividends
    ) internal view returns (uint) {
        if (!user.machineAllow) {
            return 0;
        }

        if (user.referrerCount[0] < deposit.level) {
            return 0;
        }

        uint dividends;

        uint checkDate = deposit.start;

        if (checkDate < getlastActionDate(user)) {
            checkDate = getlastActionDate(user);
        }

        if (checkDate < deposit.lastPayBonus) {
            checkDate = deposit.lastPayBonus;
        }

        dividends = (
            deposit.initAmount.mul(
                MACHINE_ROI.mul(block.timestamp.sub(checkDate))
            )
        ).div((PERCENTS_DIVIDER).mul(TIME_STEP));

        dividends += deposit.bonus;

        uint _userMaxDividends = getUserMaxProfit(user.userAddress);
        if (
            user.totalWithdraw + dividends + _currentDividends >
            _userMaxDividends
        ) {
            if (user.totalWithdraw + _currentDividends < _userMaxDividends) {
                dividends =
                    _userMaxDividends -
                    user.totalWithdraw -
                    _currentDividends;
            } else {
                dividends = 0;
            }
        }

        if (deposit.withdrawn.add(dividends) > deposit.initAmount) {
            dividends = deposit.initAmount.sub(deposit.withdrawn);
        }

        return dividends;
    }

    function getUserDepositInfo(address userAddress, uint index)
        external
        view
        returns (
            uint amount_,
            uint withdrawn_,
            uint timeStart_,
            uint reinvested_,
            uint maxProfit
        )
    {
        Deposit memory deposit = users[userAddress].deposits[index];
        amount_ = deposit.amount;
        withdrawn_ = deposit.withdrawn;
        timeStart_ = getDepsitStartDate(deposit);
        reinvested_ = users[userAddress].reinvested;
        maxProfit = getMaxprofit(deposit);
    }

    function getUserTotalDeposits(address userAddress)
        internal
        view
        returns (uint)
    {
        return users[userAddress].totalInvest;
    }

    function getUserDeposittotalWithdrawn(address userAddress)
        internal
        view
        returns (uint)
    {
        User storage user = users[userAddress];

        uint amount;

        for (uint i; i < user.depositsLength; i++) {
            amount += users[userAddress].deposits[i].withdrawn;
        }
        return amount;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getDepositRoi() private pure returns (uint) {
        return ROI_BASE;
    }

    function getDepsitStartDate(Deposit memory ndeposit)
        private
        view
        returns (uint)
    {
        if (initDate > ndeposit.start) {
            return initDate;
        } else {
            return ndeposit.start;
        }
    }

    function WITHDRAW_FEE_PERCENT(uint lastWithDraw)
        public
        view
        returns (uint)
    {
        if (initDate > lastWithDraw) {
            lastWithDraw = initDate;
        }
        uint delta = block.timestamp.sub(lastWithDraw);
        if (delta < TIME_STEP.mul(7)) {
            return WITHDRAW_FEE_PERCENT_DAY;
        } else if (delta < TIME_STEP.mul(15)) {
            return WITHDRAW_FEE_PERCENT_WEEK;
        } else if (delta < TIME_STEP.mul(30)) {
            return WITHDRAW_FEE_PERCENT_TWO_WEEK;
        }
        return WITHDRAW_FEE_PERCENT_MONTH;
    }

    function updateDeposit(address _user, uint _machineDeposit) internal {
        uint dividends = calculateMachineDividents(
            users[_user].machineDeposits[_machineDeposit],
            users[_user],
            0
        );
        if (dividends > 0) {
            users[_user].machineDeposits[_machineDeposit].bonus = dividends;
            users[_user].machineDeposits[_machineDeposit].lastPayBonus = block
                .timestamp;
        }
    }

    function withdrawFee(uint _totalAmount, uint checkExtraFee) internal returns(uint) {
        uint fee = WITHDRAW_FEE_BASE;
        if(checkExtraFee > 0) {
            fee = fee.add(WITHDRAW_FEE_PERCENT(checkExtraFee));
        }
        uint feeAmout = _totalAmount.mul(fee).div(PERCENTS_DIVIDER);
        uint feeToWAllet = feeAmout.div(5);
        transferHandler(devAddress, feeToWAllet);
        transferHandler(ownerAddress, feeToWAllet);
        transferHandler(markAddress, feeToWAllet);
        transferHandler(proJectAddress, feeToWAllet);
        transferHandler(partnerAddress, feeToWAllet);
        return feeAmout;
    }

    function payInvestFee(uint investAmount) internal {
        uint feeDev = investAmount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
        uint feeOwner = investAmount.mul(OWNER_FEE).div(PERCENTS_DIVIDER);
        uint feeMark = investAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint feeProject = investAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        uint feePartner = investAmount.mul(PARTNER_FEE).div(PERCENTS_DIVIDER);
        uint feeEvent = investAmount.mul(EVENT_FEE).div(PERCENTS_DIVIDER);

        transferHandler(devAddress, feeDev);
        transferHandler(ownerAddress, feeOwner);
        transferHandler(markAddress, feeMark);
        transferHandler(proJectAddress, feeProject);
        transferHandler(partnerAddress, feePartner);
        transferHandler(eventAddress, feeEvent);
    }

    function transferHandler(address _address, uint _amount) internal {
        uint balance = token.balanceOf(address(this));
        if(balance < _amount) {
            _amount = balance;
        }
        token.transfer(_address, _amount);
    }

}