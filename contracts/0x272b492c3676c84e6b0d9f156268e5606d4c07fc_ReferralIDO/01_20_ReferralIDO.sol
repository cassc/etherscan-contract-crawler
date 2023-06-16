// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import '../interfaces/IReferralSale.sol';
import './BaseIDO.sol';

// See https://etherscan.io/tx/0xc7205487b6468ae38f99df5b45ecea5fcccb204b474705d2ad854269dc3ea46d

/**
 * This sale supports:
 * - Whitelist, or if it's of the "Open" type - special allocation per user
 * - Referrals: if used referral code (affiliate's address), affiliate gets X% of the value contributed by the user
 * - Hard Cap mode: when hard cap is reached (saleState.tokensForSale), sale is closed
 * - Soft Cap mode: when soft cap is reached, users get proportionally less tokens for what they contributed
 */
contract ReferralIDO is IReferralSale, BaseIDO {
    using SafeERC20 for IERC20;
    
    RefState internal refState;

    constructor(
        string memory _id,
        uint64 _rate,
        uint256 _tokensForSale,
        address _fundToken,
        address _fundsReceiver,
        uint256 _max,
        uint32[5] memory _timeline,
        address[] memory _admins
    ) BaseIDO(_id, _rate, _tokensForSale, _fundToken, _fundsReceiver, _max, _timeline, _admins) {
        refState.percent = 50;
        saleState.saleType = SaleType.SoftCap;
        saleState.isSoftCap = true;
    }

    function refAddCommission(address account, uint256 totalValue) internal {
        require(account != address(0), 'ZA');
        require(account != msg.sender, 'SR');
        require(refState.percent > 0, 'ZP');

        uint256 amount = (totalValue * refState.percent) / 1000;

        refState.totalCommission += amount;
        if (refState.affiliateCommission[account] == 0) refState.totalAffiliatesN += 1;
        refState.affiliateCommission[account] += amount;
        refState.affiliatePurchasesN[account] += 1;
    }

    function setRefCommissionPercent(uint16 percent) external onlyOwnerOrAdmin {
        refState.percent = percent;
        emit RefCommissionPercentChanged(percent);
    }

    function setAffiliatePercent(address account, uint16 percent) external override onlyOwnerOrAdmin {
        refState.affiliatePercent[account] = percent;
        emit AffiliatePercentChanged(account, percent);
    }

    function isSoftCapReached() public view returns (bool) {
        return saleState.isSoftCap && calculatePurchaseAmount(saleState.raised) >= saleState.tokensForSale;
    }

    function getDynamicBalance(address account) public view returns (uint256) {
        return (contributed[account] * getRate()) / 1e6;
    }

    function getRate() public view override returns (uint64) {
        return isSoftCapReached() ? uint64((saleState.tokensForSale * 1e6) / saleState.raised) : saleState.rate;
    }

    function getReferralState(address account)
        external
        view
        override
        returns (
            uint16,
            uint256,
            uint256,
            uint16,
            uint16,
            uint16,
            uint256,
            uint256
        )
    {
        uint16 percent = refState.affiliatePercent[account] > 0 ? refState.affiliatePercent[account] : refState.percent;
        uint16 purchasesN = refState.affiliatePurchasesN[account];
        uint256 commission = refState.affiliateCommission[account];
        uint256 withdrawn = refState.affiliateWithdrawn[account];
        return (
            percent,
            refState.totalCommission,
            refState.totalWithdrawn,
            refState.totalAffiliatesN,
            refState.totalWithdrawnN,
            purchasesN,
            commission,
            withdrawn
        );
    }

    // Should be withdrawable once the soft cap is hit
    function withdrawReferralCommission() external override {
        require(isSoftCapReached() || getSaleTimelineStatus() != TimelineStatus.Ended, 'NW');
        require(refState.affiliateCommission[msg.sender] > 0, 'NR');
        uint256 commission = refState.affiliateCommission[msg.sender];
        refState.affiliateCommission[msg.sender] = 0;
        refState.affiliateWithdrawn[msg.sender] += commission;
        refState.totalWithdrawn += commission;
        refState.totalWithdrawnN += 1;
        if (fundingState.fundByTokens) {
            IERC20(fundingState.fundToken).transfer(msg.sender, commission);
        } else {
            payable(msg.sender).transfer(commission);
        }
    }

    function getUserState(address account) public view override returns (UserState memory) {
        UserState memory state;

        state.contributed = contributed[account];
        state.balance = getDynamicBalance(account);
        state.isWhitelisted = wlState.isWhitelisted[account];

        // User can have a special allocation without being whitelisted
        uint256 alloc = wlState.userAlloc[account] > 0 ? wlState.userAlloc[account] : saleState.maxSell;
        if (saleState.saleType == SaleType.Open || saleState.saleType == SaleType.SoftCap) {
            state.totalAlloc = alloc;
        } else if (saleState.saleType == SaleType.WhitelistOnly) {
            if (state.isWhitelisted) {
                state.totalAlloc = state.wlAlloc = alloc;
            }
        }

        return state;
    }

    function buyTokens(address affiliateAddress) external payable override nonReentrant {
        require(getSaleTimelineStatus() == TimelineStatus.Live, 'NL');
        require(!fundingState.fundByTokens, 'FBT');

        if (affiliateAddress != address(0)) {
            refAddCommission(affiliateAddress, msg.value);
        }

        internalBuyTokens(msg.value);
    }

    /**
     * The fund token must be first approved to be transferred by presale contract for the given "value".
     */
    function buyTokens(uint256 value, address affiliateAddress) external override nonReentrant {
        require(getSaleTimelineStatus() == TimelineStatus.Live, 'NL');
        require(fundingState.fundByTokens, 'NFBT');
        require(fundingState.fundToken.allowance(msg.sender, address(this)) >= value, 'NA');

        fundingState.fundToken.safeTransferFrom(msg.sender, address(this), value);
        if (affiliateAddress != address(0)) {
            refAddCommission(affiliateAddress, value);
        }

        if (fundingState.currencyDecimals < 18) {
            value = value * (10**(18 - fundingState.currencyDecimals));
        }
        internalBuyTokens(value);
    }

    function internalBuyTokens(uint256 value) private {
        UserState memory userState = getUserState(_msgSender());
        require(userState.totalAlloc > 0, 'ZAL');
        require(value > 0, 'ZV');

        if (contributed[_msgSender()] == 0) saleState.participants += 1;
        saleState.raised += value;
        uint256 amount = calculatePurchaseAmount(value);
        require(amount > 0, 'ZAM');
        require(saleState.isSoftCap || saleState.tokensSold + amount <= saleState.tokensForSale, 'CAP');

        emit TokensPurchased(_msgSender(), value, isSoftCapReached() ? 0 : amount);

        saleState.tokensSold = saleState.tokensForSale < saleState.tokensSold + amount
            ? saleState.tokensForSale
            : saleState.tokensSold + amount;
        contributed[_msgSender()] += value;

        require(value >= saleState.minSell, 'TL');
        require(saleState.maxSell == 0 || contributed[_msgSender()] <= saleState.maxSell, 'MAX');
        require(userState.totalAlloc == 0 || contributed[_msgSender()] <= userState.totalAlloc, 'MAXAL');

        // Store the first and last block numbers to simplify data collection later
        if (saleState.firstPurchaseBlockN == 0) {
            saleState.firstPurchaseBlockN = block.number;
        }
        saleState.lastPurchaseBlockN = block.number;
    }
}