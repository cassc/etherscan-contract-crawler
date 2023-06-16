// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/ISale.sol';
import '../Adminable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

abstract contract BaseIDO is ISale, Adminable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    string public id;
    SaleState internal saleState;
    FundingState internal fundingState;
    SaleTimeline internal timeline;
    WhitelistState internal wlState;
    mapping(address => uint256) internal contributed;

    event FundsReceiverChanged(address account);

    modifier ongoingSale() {
        require(getSaleTimelineStatus() == TimelineStatus.Live, 'NL');
        _;
    }

    constructor(
        string memory _id,
        uint64 _rate,
        uint256 _tokensForSale,
        address _fundToken,
        address _fundsReceiver,
        uint256 _max,
        uint32[5] memory _timeline,
        address[] memory _admins
    ) {
        id = _id;
        setSaleState(_rate, _tokensForSale, _max);
        setFundingState(_fundsReceiver, _fundToken);
        setSaleTimeline(_timeline);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i = 0; i < _admins.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, _admins[i]);
        }
    }

    function getFundingState() external view override returns (FundingState memory) {
        return fundingState;
    }

    function getSaleState() external view virtual override returns (SaleState memory) {
        SaleState memory state = saleState;
        state.status = getSaleTimelineStatus();
        state.initRate = saleState.rate;
        state.rate = getRate();
        state.totalWhitelistAllocation =
            calculatePurchaseAmount(saleState.maxSell) *
            wlState.count +
            calculatePurchaseAmount(wlState.totalSpecialAlloc);
        state.whitelistedCount = wlState.count;
        state.isSoftCap = saleState.saleType == SaleType.SoftCap;

        return state;
    }

    function getSaleTimeline() external view override returns (SaleTimeline memory) {
        return timeline;
    }

    function getSaleTimelineStatus() public view override returns (TimelineStatus) {
        uint256 n = block.timestamp;
        if (n < timeline.registerTime) return TimelineStatus.PreRegister;
        if (n < timeline.registerTime + timeline.registerDuration) return TimelineStatus.Register;
        if (n < timeline.startTime) return TimelineStatus.Prepare;
        if (n < timeline.startTime + timeline.duration - timeline.fcfsDuration) return TimelineStatus.Live;
        if (timeline.fcfsDuration > 0 && n < timeline.startTime + timeline.duration) return TimelineStatus.Fcfs;
        return TimelineStatus.Ended;
    }

    function getRate() public view virtual returns (uint64) {
        return saleState.rate;
    }

    function calculatePurchaseAmount(uint256 purchaseAmountWei) public view returns (uint256) {
        return (purchaseAmountWei * saleState.rate) / 1e6;
    }

    //// Admin setters ////

    function setSaleState(
        uint64 rate,
        uint256 tokensForSale,
        uint256 _max
    ) public onlyOwnerOrAdmin {
        saleState.rate = rate;

        require(getSaleTimelineStatus() != TimelineStatus.Live || tokensForSale > saleState.tokensForSale, 'CAP');
        saleState.tokensForSale = tokensForSale;

        saleState.maxSell = _max;
    }

    function setFundingState(address receiver, address fundToken) public onlyOwnerOrAdmin {
        require(receiver != address(0), 'ZA');
        if (fundingState.fundsReceiver != receiver) {
            fundingState.fundsReceiver = receiver;
            emit FundsReceiverChanged(receiver);
        }

        fundingState.fundByTokens = fundToken != address(0);
        if (fundingState.fundByTokens) {
            fundingState.fundToken = IERC20(fundToken);
            fundingState.currencyDecimals = IERC20Metadata(fundToken).decimals();
        }
    }

    //// Time module ////

    // [startTime, duration, registerTime, registerDuration, FCFSDuration]
    function setSaleTimeline(uint32[5] memory _timeline) public override onlyOwnerOrAdmin {
        require(_timeline[0] > _timeline[2], 'ST');
        timeline.startTime = _timeline[0];
        timeline.duration = _timeline[1];
        timeline.endTime = timeline.startTime + timeline.duration;

        require(_timeline[2] < timeline.startTime, 'RT');
        timeline.registerTime = _timeline[2];

        require(timeline.registerTime + _timeline[3] < timeline.startTime, 'RD');
        timeline.registerDuration = _timeline[3];

        timeline.fcfsDuration = _timeline[4];
    }

    //// Withdrawable module ////

    /**
     * Withdraw ALL both BNB and the currency token if specified
     */
    function withdrawAll() external override onlyOwnerOrAdmin {
        require(fundingState.fundsReceiver != address(0), 'ZA');
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(fundingState.fundsReceiver).transfer(balance);
        }

        if (fundingState.fundByTokens && fundingState.fundToken.balanceOf(address(this)) > 0) {
            fundingState.fundToken.transfer(
                fundingState.fundsReceiver,
                fundingState.fundToken.balanceOf(address(this))
            );
        }
    }

    /**
     * When tokens are sent to the sale by mistake: withdraw the specified token.
     */
    function withdrawToken(address token, uint256 amount) external override onlyOwnerOrAdmin {
        require(amount > 0, 'ZAM');
        IERC20(token).transfer(fundingState.fundsReceiver, amount);
    }

    //// Whitelist module ////

    function getWhitelistedAddresses() public view override returns (address[] memory) {
        return wlState.addresses;
    }

    function batchSetWLAllocation(uint256 amount, address[] calldata addresses) public override onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistAccount(addresses[i]);
            wlState.userAlloc[addresses[i]] = amount;
            wlState.totalSpecialAlloc += amount;
        }
    }

    function batchAddWL(address[] calldata addresses) external override onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistAccount(addresses[i]);
        }
    }

    function whitelistAccount(address account) internal {
        if (!wlState.isWhitelisted[account]) {
            wlState.isWhitelisted[account] = true;
            wlState.addresses.push(account);
            wlState.count += 1;
        }
    }
}