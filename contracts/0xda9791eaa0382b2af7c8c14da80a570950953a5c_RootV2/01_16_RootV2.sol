pragma solidity ^0.8.0;

import "./AdminV1.sol";
import "./meta-transactions/VoucherV2.sol";

import "./interfaces/IERC20UpgradeableWithDecimals.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract RootV2 is AdminV1, VoucherV2 {
    using SafeERC20Upgradeable for IERC20UpgradeableWithDecimals;

    /* -------------------------------------------------------------------------- */
    /*                             ANCHOR Initializer                             */
    /* -------------------------------------------------------------------------- */

    function __RootV1_init(address voucherSigner) public initializer {
        _voucherSigner = voucherSigner;
        __Ownable_init();
        __EIP712_init("gagarin", "1");
    }

    /* -------------------------------------------------------------------------- */
    /*                             ANCHOR Distributor                             */
    /* -------------------------------------------------------------------------- */

    event CreateProject(uint256 indexed projectId);
    event ProjectPropsChanged(uint256 indexed projectId, ProjectProps newProps);

    struct Project {
        uint256 id;
        ProjectProps props;
        mapping(address => InvestorData) investors;
        bool isActive;
        uint256 refunded;
    }

    struct ProjectProps {
        IERC20UpgradeableWithDecimals token;
        IERC20UpgradeableWithDecimals claimToken;
        uint256 price;
        uint256[] claimDates;
        uint256[] claimPercent;
    }

    struct InvestorData {
        uint256 redeemed;
        uint256 claimed;
    }

    modifier whenNotPaused(uint256 projectId) {
        require(_projects[projectId].isActive, "project on pause");
        _;
    }

    mapping(uint256 => Project) internal _projects;

    uint256 private supply;

    function createProject(
        ProjectProps memory props,
        uint256 offchainId,
        address[] memory addrs,
        uint256[] memory redeemed
    ) public onlyAdmin {
        require(
            addrs.length == redeemed.length,
            "createProject: arrays not eq"
        );
        require(
            props.claimDates.length == props.claimPercent.length &&
                props.price > 0 &&
                props.claimToken != IERC20UpgradeableWithDecimals(address(0)),
            "createProject: invalid props"
        );
        ++supply;
        Project storage project = _projects[offchainId];
        for (uint256 i; i < addrs.length; i++) {
            project.investors[addrs[i]].redeemed = redeemed[i];
        }
        project.id = offchainId;
        project.props = props;
        project.isActive = true;
        emit CreateProject(offchainId);
    }

    function changeProjectProps(
        uint256 projectId,
        ProjectProps memory newProps
    ) public onlyAdmin {
        require(
            newProps.claimDates.length == newProps.claimPercent.length,
            "changeProjectProps: arr length not eq"
        );
        Project storage project = _projects[projectId];
        ProjectProps storage oldProps = project.props;
        if (oldProps.token != newProps.token) {
            oldProps.token = newProps.token;
        }
        if (oldProps.claimToken != newProps.claimToken) {
            oldProps.claimToken = newProps.claimToken;
        }
        if (oldProps.price != newProps.price) {
            oldProps.price = newProps.price;
        }
        if (newProps.claimDates.length == oldProps.claimDates.length) {
            bool isClaimDatesOrPercentChanged;
            for (uint256 i; i < newProps.claimDates.length; i++) {
                if (
                    newProps.claimDates[i] != oldProps.claimDates[i] ||
                    newProps.claimPercent[i] != oldProps.claimPercent[i]
                ) {
                    isClaimDatesOrPercentChanged = true;
                    break;
                }
            }
            if (isClaimDatesOrPercentChanged) {
                oldProps.claimDates = newProps.claimDates;
                oldProps.claimPercent = newProps.claimPercent;
            }
        } else {
            oldProps.claimDates = newProps.claimDates;
            oldProps.claimPercent = newProps.claimPercent;
        }
        emit ProjectPropsChanged(projectId, project.props);
    }

    function projectPauseToggle(uint256 projectId) public onlyAdmin {
        Project storage project = _projects[projectId];
        project.isActive = !project.isActive;
    }

    struct InvestorDataWithAddress {
        address addr;
        uint256 redeemed;
        uint256 claimed;
    }

    function changeProject(
        uint256 projectId,
        address[] memory removedInvestors,
        InvestorDataWithAddress[] memory investors
    ) public onlyAdmin {
        Project storage project = _projects[projectId];
        for (uint256 i; i < investors.length; i++) {
            InvestorDataWithAddress memory investor = investors[i];
            project.investors[investor.addr] = InvestorData(
                investor.redeemed,
                investor.claimed
            );
        }
        if (removedInvestors.length > 0) {
            _removeInvestors(project, removedInvestors);
        }
    }

    function cancelParticipation(
        uint256 projectId,
        address investorAddr
    ) public {
        require(
            msg.sender == _voucherSigner,
            "cancelParticipation: wrong caller"
        );
        require(
            _projects[projectId].investors[investorAddr].claimed == 0,
            "cancelParticipation: already claimed"
        );
        delete _projects[projectId].investors[investorAddr];
    }

    function _removeInvestors(
        Project storage project,
        address[] memory removedInvestors
    ) private {
        for (uint256 i; i < removedInvestors.length; i++) {
            address removedInvestor = removedInvestors[i];

            delete project.investors[removedInvestor];
        }
    }

    function claimProject(uint256 projectId) public whenNotPaused(projectId) {
        Project storage project = _projects[projectId];
        require(
            project.props.claimToken !=
                IERC20UpgradeableWithDecimals(address(0)),
            "claimProject: claimToken var is empty"
        );
        InvestorData storage investorData = project.investors[msg.sender];
        require(
            investorData.redeemed > 0,
            "claimProject: investor is not redeem allocation"
        );
        _claim(project, investorData, msg.sender);
    }

    function airDrop(
        uint256 projectId,
        address[] memory investors
    ) public onlyAdmin {
        Project storage project = _projects[projectId];
        for (uint256 i; i < investors.length; i++) {
            address investor = investors[i];
            InvestorData storage investorData = project.investors[investor];
            if (investorData.redeemed > 0) {
                _claim(project, investorData, investor);
            }
        }
    }

    function _claim(
        Project storage project,
        InvestorData storage investorData,
        address addr
    ) private {
        uint256 toClaim;
        uint256 redeemedConverted = getRedeemedConverted(
            project.props.claimToken,
            investorData.redeemed,
            project.props.price
        );
        for (
            uint256 i = investorData.claimed;
            i < project.props.claimDates.length;
            i++
        ) {
            if (block.timestamp >= project.props.claimDates[i]) {
                toClaim +=
                    (redeemedConverted * project.props.claimPercent[i]) /
                    100e5;
                investorData.claimed += 1;
            } else {
                break;
            }
        }
        if (toClaim > 0) {
            project.props.claimToken.safeTransfer(addr, toClaim);
        }
    }

    function returnProjectTokens(
        ReturnProjectTokensVoucher calldata voucher
    ) public {
        require(
            _verifyReturnProjectTokens(voucher) == _voucherSigner,
            "returnProjectTokens: invalid voucher"
        );
        Project storage project = _projects[voucher.projectId];
        (uint256 lastClaimAmount, ) = getLastClaimAmount(
            voucher.projectId,
            voucher.investorAddr
        );
        require(lastClaimAmount > 0, "returnProjectTokens: nothing to return");
        project.props.claimToken.safeTransferFrom(
            msg.sender,
            address(this),
            lastClaimAmount
        );
        projectTokensReturnedAmount[voucher.projectId][
            msg.sender
        ] = lastClaimAmount;
        project.investors[msg.sender].claimed -= 1;
    }

    function projectById(
        uint256 projectId
    )
        public
        view
        returns (uint256 id, ProjectProps memory props, bool isActive)
    {
        Project storage project = _projects[projectId];
        id = project.id;
        props = project.props;
        isActive = project.isActive;
    }

    function investorDataFromProject(
        uint256 projectId,
        address investor
    ) public view returns (InvestorData memory) {
        return _projects[projectId].investors[investor];
    }

    function investorDataWithProject(
        uint256 projectId,
        address investor
    )
        public
        view
        returns (
            uint256 id,
            ProjectProps memory props,
            bool isActive,
            InvestorData memory investorData
        )
    {
        Project storage project = _projects[projectId];
        id = project.id;
        props = project.props;
        isActive = project.isActive;
        investorData = project.investors[investor];
    }

    function getInvestorsFromProject(
        uint256 projectId,
        address[] memory investors
    ) public view returns (InvestorData[] memory) {
        InvestorData[] memory investorData = new InvestorData[](
            investors.length
        );
        for (uint256 i; i < investors.length; i++) {
            investorData[i] = _projects[projectId].investors[investors[i]];
        }
        return investorData;
    }

    function getLastClaimAmount(
        uint256 projectId,
        address investorAddr
    ) public view returns (uint256 lastClaimAmount, uint256 lastClaimIndex) {
        Project storage project = _projects[projectId];
        require(
            project.props.claimDates.length > 0,
            "getLastClaimAmount: claimDates not set"
        );
        require(
            project.props.claimDates[0] <= block.timestamp,
            "getLastClaimAmount: claim has not started"
        );
        if (
            project.props.claimDates[project.props.claimDates.length - 1] <
            block.timestamp
        ) {
            lastClaimIndex = project.props.claimDates.length - 1;
        } else {
            for (uint256 i = 1; i < project.props.claimDates.length; i++) {
                if (project.props.claimDates[i] > block.timestamp) {
                    lastClaimIndex = i - 1;
                    break;
                }
            }
        }
        InvestorData storage investorData = project.investors[investorAddr];
        if (investorData.claimed == lastClaimIndex + 1) {
            uint256 redeemedConverted = getRedeemedConverted(
                project.props.claimToken,
                investorData.redeemed,
                project.props.price
            );
            lastClaimAmount =
                (redeemedConverted *
                    project.props.claimPercent[lastClaimIndex]) /
                100e5;
        }
    }

    function getRedeemedConverted(
        IERC20UpgradeableWithDecimals token,
        uint256 redeemed,
        uint256 price
    ) public view returns (uint256) {
        uint256 decimalsMultiplier = 10 ** uint256(token.decimals());
        return ((redeemed * decimalsMultiplier) / price);
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    /* -------------------------------------------------------------------------- */
    /*                              ANCHOR Collector                              */
    /* -------------------------------------------------------------------------- */

    event RedeemIdo(
        uint256 indexed projectId,
        address indexed investor,
        uint256 indexed amount,
        RedeemType redeemType
    );

    event RedeemIno(
        uint256 indexed projectId,
        address indexed investor,
        uint256 indexed amount,
        RedeemType redeemType,
        uint256[] boxIDs,
        uint256[] boxCounts
    );

    event Refund(
        uint256 indexed projectId,
        address indexed investor,
        uint256 amount,
        RefundType indexed refundType,
        OfferingType offeringType
    );

    struct InoData {
        ///@notice boxID => boxCount
        mapping(uint256 => uint256) boxesCount;
        uint256 amount;
    }

    struct InoBalanceType {
        InoData swap;
        InoData fcfs;
    }

    struct BalanceType {
        uint256 swap;
        uint256 fcfs;
    }

    struct InoBalance {
        ///@notice boxID => boxCount
        mapping(uint256 => uint256) boxesCount;
        uint256 balance;
    }

    mapping(address => mapping(uint256 => BalanceType))
        private _investorsBalancesFromIdo;
    mapping(uint256 => uint256) private _idosBalances;
    address private _voucherSigner;
    mapping(address => mapping(uint256 => InoBalanceType))
        private _investorsBalancesFromIno;
    mapping(uint256 => InoBalance) private _inosBalances;

    function redeemIdo(RedeemIdoVoucher calldata voucher) public {
        require(
            _verifyRedeemIdo(voucher) == _voucherSigner,
            "redeem: invalid voucher"
        );
        require(voucher.amount > 0, "redeem: incorrect amount");
        uint256 transferAmount = voucher.amount;
        if (voucher.fee > 0) {
            transferAmount += voucher.fee;
            _collectedFee[voucher.projectId] += voucher.fee;
            _userFee[msg.sender][voucher.projectId] += voucher.fee;
        }
        IERC20UpgradeableWithDecimals(voucher.token).safeTransferFrom(
            msg.sender,
            address(this),
            transferAmount
        );
        voucher.redeemType == RedeemType.swap
            ? _investorsBalancesFromIdo[msg.sender][voucher.projectId]
                .swap += voucher.amount
            : _investorsBalancesFromIdo[msg.sender][voucher.projectId]
                .fcfs += voucher.amount;
        _idosBalances[voucher.projectId] += voucher.amount;

        emit RedeemIdo(
            voucher.projectId,
            msg.sender,
            voucher.amount,
            voucher.redeemType
        );
    }

    function redeemIno(RedeemInoVoucher calldata voucher) public {
        require(
            _verifyRedeemIno(voucher) == _voucherSigner,
            "redeem: invalid voucher"
        );
        require(voucher.amount > 0, "redeem: incorrect amount");
        IERC20UpgradeableWithDecimals(voucher.token).safeTransferFrom(
            msg.sender,
            address(this),
            voucher.amount
        );
        InoBalance storage inoBalance = _inosBalances[voucher.projectId];
        InoData storage balance;

        if (voucher.redeemType == RedeemType.swap) {
            balance = _investorsBalancesFromIno[msg.sender][voucher.projectId]
                .swap;
        } else {
            balance = _investorsBalancesFromIno[msg.sender][voucher.projectId]
                .fcfs;
        }
        for (uint256 i; i < voucher.boxIDs.length; i++) {
            balance.boxesCount[voucher.boxIDs[i]] += voucher.boxCounts[i];
            inoBalance.boxesCount[voucher.boxIDs[i]] += voucher.boxCounts[i];
        }
        balance.amount += voucher.amount;
        inoBalance.balance += voucher.amount;

        emit RedeemIno(
            voucher.projectId,
            msg.sender,
            voucher.amount,
            voucher.redeemType,
            voucher.boxIDs,
            voucher.boxCounts
        );
    }

    function removeBalances(
        uint256 projectId,
        address[] memory addrs,
        OfferingType offeringType
    ) public onlyAdmin {
        for (uint256 i; i < addrs.length; i++) {
            _removeBalance(addrs[i], projectId, offeringType);
        }
    }

    function _removeBalance(
        address investorAddr,
        uint256 projectId,
        OfferingType offeringType
    ) private {
        if (offeringType == OfferingType.ido) {
            BalanceType storage balance = _investorsBalancesFromIdo[
                investorAddr
            ][projectId];
            _idosBalances[projectId] -= (balance.swap + balance.fcfs);
            delete _investorsBalancesFromIdo[investorAddr][projectId];
        } else {
            InoBalanceType storage balance = _investorsBalancesFromIno[
                investorAddr
            ][projectId];
            _idosBalances[projectId] -= (balance.swap.amount +
                balance.fcfs.amount);
            delete _investorsBalancesFromIno[investorAddr][projectId];
        }
    }

    function refund(RefundVoucher calldata voucher) public {
        require(
            _verifyRefund(voucher) == _voucherSigner,
            "refund: invalid voucher"
        );

        uint256 refundedSum;
        if (voucher.offeringType == OfferingType.ido) {
            BalanceType storage balance = _investorsBalancesFromIdo[msg.sender][
                voucher.projectId
            ];
            refundedSum = balance.swap + balance.fcfs;
        } else {
            InoBalanceType storage balance = _investorsBalancesFromIno[
                msg.sender
            ][voucher.projectId];
            refundedSum = balance.swap.amount + balance.fcfs.amount;
        }

        require(refundedSum > 0, "refund: nothing to refund");

        IERC20UpgradeableWithDecimals(voucher.token).safeTransfer(
            msg.sender,
            refundedSum
        );

        _removeBalance(msg.sender, voucher.projectId, voucher.offeringType);

        emit Refund(
            voucher.projectId,
            msg.sender,
            refundedSum,
            voucher.refundType,
            voucher.offeringType
        );
    }

    function getIdoBalance(uint256 projectId) public view returns (uint256) {
        return _idosBalances[projectId];
    }

    function getInoBalance(
        uint256 projectId,
        uint256[] memory boxIDs
    ) public view returns (uint256[] memory, uint256) {
        uint256[] memory boxesCount = new uint256[](boxIDs.length);
        InoBalance storage balance = _inosBalances[projectId];
        for (uint256 i; i < boxIDs.length; i++) {
            boxesCount[i] = balance.boxesCount[boxIDs[i]];
        }
        return (boxesCount, balance.balance);
    }

    function getInvestorsBalancesFromIdo(
        uint256 projectId,
        address[] memory addrs
    ) public view returns (BalanceType[] memory) {
        BalanceType[] memory balances = new BalanceType[](addrs.length);
        for (uint256 i; i < addrs.length; i++) {
            balances[i] = _investorsBalancesFromIdo[addrs[i]][projectId];
        }
        return balances;
    }

    struct InoBalanceReturnType {
        uint256[] boxCounts;
        uint256 amount;
    }

    function getInvestorsBalancesFromIno(
        uint256 projectId,
        address[] memory addrs,
        uint256[] memory boxIDs
    )
        public
        view
        returns (InoBalanceReturnType[] memory, InoBalanceReturnType[] memory)
    {
        InoBalanceReturnType[] memory swap = new InoBalanceReturnType[](
            addrs.length
        );
        InoBalanceReturnType[] memory fcfs = new InoBalanceReturnType[](
            addrs.length
        );
        for (uint256 i; i < addrs.length; i++) {
            InoBalanceType storage inoBalance = _investorsBalancesFromIno[
                addrs[i]
            ][projectId];
            InoData storage inoDataSwap = inoBalance.swap;
            InoData storage inoDataFcfs = inoBalance.fcfs;
            uint256[] memory boxCountsSwap = new uint256[](boxIDs.length);
            uint256[] memory boxCountsFcfs = new uint256[](boxIDs.length);
            for (uint256 x; x < boxIDs.length; x++) {
                boxCountsSwap[x] = inoDataSwap.boxesCount[boxIDs[x]];
                boxCountsFcfs[x] = inoDataFcfs.boxesCount[boxIDs[x]];
            }
            swap[i] = InoBalanceReturnType(boxCountsSwap, inoDataSwap.amount);
            fcfs[i] = InoBalanceReturnType(boxCountsFcfs, inoDataFcfs.amount);
        }
        return (swap, fcfs);
    }

    function setSigner(address newSigner) public onlyOwner {
        _voucherSigner = newSigner;
    }

    function getSigner() public view returns (address) {
        return _voucherSigner;
    }

    /* -------------------------------------------------------------------------- */
    /*                             ANCHOR TokenManager                            */
    /* -------------------------------------------------------------------------- */

    function withdraw(
        IERC20UpgradeableWithDecimals token,
        address to,
        uint256 amount
    ) public onlyOwner {
        if (amount == 0) {
            amount = token.balanceOf(address(this));
        }
        token.safeTransfer(to, amount);
    }

    function distribute(
        IERC20UpgradeableWithDecimals token,
        address[] memory investors,
        uint256[] memory amounts
    ) public onlyOwner {
        require(investors.length == amounts.length, "arr length not eq");
        for (uint256 i = 0; i < investors.length; i++) {
            token.safeTransfer(investors[i], amounts[i]);
        }
    }

    function getCollectedFee(uint256 projectId) public view returns (uint256) {
        return _collectedFee[projectId];
    }

    function getUsersFees(
        address[] memory users,
        uint256 projectId
    ) public view returns (uint256[] memory) {
        uint256[] memory fees = new uint256[](users.length);
        for (uint i; i < users.length; i++) {
            fees[i] = getUserFee(users[i], projectId);
        }
        return fees;
    }

    function getUserFee(
        address user,
        uint256 projectId
    ) public view returns (uint256) {
        return _userFee[user][projectId];
    }

    ///@notice projectId => userAddr => amount
    mapping(uint256 => mapping(address => uint256))
        public projectTokensReturnedAmount;
    address private _feeVault;
    mapping(uint256 => uint256) private _collectedFee;
    ///@notice userAddr => projectId => amount
    mapping(address => mapping(uint256 => uint256)) private _userFee;
}