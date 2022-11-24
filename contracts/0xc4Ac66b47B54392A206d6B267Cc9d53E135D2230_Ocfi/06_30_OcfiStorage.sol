// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./OcfiFees.sol";
import "./OcfiReferrals.sol";
import "./OcfiTransfers.sol";
import "./OcfiDividendTracker.sol";
import "./OcfiDividendTrackerFactory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Factory.sol";
import "./ICustomContract.sol";
import "./IERC721A.sol";

library OcfiStorage {
    using OcfiTransfers for OcfiTransfers.Data;
    using OcfiReferrals for OcfiReferrals.Data;
    using OcfiFees for OcfiFees.Data;
    
    event UpdateMarketingWallet(address marketingWallet);
    event UpdateTeamWallet(address teamWallet);
    event UpdateDevWallet(address devWallet);

    event UpdateDividendTrackerContract(address dividednTrackerContract);
    event UpdateNftContract(address nftContract);
    event UpdateCustomContract(address customContract);

    struct Data {
        OcfiFees.Data fees;
        OcfiReferrals.Data referrals;
        OcfiTransfers.Data transfers;
        IUniswapV2Router02 router;
        IUniswapV2Pair pair;
        OcfiDividendTracker dividendTracker;
        address marketingWallet;
        address teamWallet;
        address devWallet;
        IERC721A nftContract;
        ICustomContract customContract;
        address presaleContract;

        uint256 swapTokensAtAmount;
        uint256 swapTokensMaxAmount;

        uint256 startTime;

        bool swapping;
    }

    function init(OcfiStorage.Data storage data, address owner) public {
        if(block.chainid == 56) {
            data.router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        }
        else {
            data.router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        }

        data.pair = IUniswapV2Pair(
          IUniswapV2Factory(data.router.factory()
        ).createPair(address(this), data.router.WETH()));

        IUniswapV2Pair(data.pair).approve(address(data.router), type(uint).max);

        setSwapTokensParams(data, 200 * (10**18), 1000 * (10**18));

        data.fees.init(data);
        data.referrals.init();
        data.transfers.init(address(data.router), address(data.pair));
        data.dividendTracker = OcfiDividendTrackerFactory.createDividendTracker();
        data.dividendTracker.transferOwnership(msg.sender);
        setupDividendTracker(data, owner);

        data.marketingWallet = 0xDAf594DdAF523794135a423e0583E64B3Fa8014D;
        data.teamWallet = 0x7305E0D396FDfFF3E01F0DE0e2A5ea6beb8E8d17;
        data.devWallet = 0x4C46b2052D898bc212a8cdC98aaB6e1EE4023cBb;

        data.fees.excludeAddressesFromFees(data, owner);
    }

    function updateMarketingWallet(Data storage data, address account) public {
        data.marketingWallet = account;
        emit UpdateMarketingWallet(account);
    }

    function updateTeamWallet(Data storage data, address account) public {
        data.teamWallet = account;
        emit UpdateTeamWallet(account);
    }

    function updateDevWallet(Data storage data, address account) public {
        data.devWallet = account;
        emit UpdateDevWallet(account);
    }

    function updateDividendTrackerContract(Data storage data, address payable dividendTrackerContract, address owner) public {
        data.dividendTracker = OcfiDividendTracker(dividendTrackerContract);
        emit UpdateDividendTrackerContract(dividendTrackerContract);
        setupDividendTracker(data, owner);
    }
    
    function updateNftContract(Data storage data, address nftContract) public {
        data.nftContract = IERC721A(nftContract);
        emit UpdateNftContract(nftContract);
        data.fees.excludeFromFees(nftContract, true);
    }

    function updateCustomContract(Data storage data, address customContract, bool excludeFromDividends) public {
        data.customContract = ICustomContract(customContract);
        data.fees.excludeFromFees(customContract, true);

        //ensure the functions exist
        data.customContract.beforeTokenTransfer(address(0), address(0), 0);
        data.customContract.handleBuy(address(0), 0, 0);
        data.customContract.handleSell(address(0), 0, 0);
        data.customContract.handleBalanceUpdated(address(0), 0);
        data.customContract.getData(address(0));

        if(excludeFromDividends) {
            data.dividendTracker.excludeFromDividends(customContract);
        }

        emit UpdateCustomContract(customContract);
    }

    function updatePresaleContract(Data storage data, address presaleContract) public {
        data.presaleContract = presaleContract;
    }

    function beforeTokenTransfer(Data storage data, address from, address to, uint256 amount) public {
        if(address(data.customContract) != address(0)) {
            try data.customContract.beforeTokenTransfer(from, to, amount) {} catch {}
        }
    }

    function handleTransfer(Data storage data, address from, address to, uint256 fromBalance, uint256 toBalance, uint256 amount, uint256 fees) public {
        if(from == data.presaleContract && data.startTime == 0) {
            data.startTime = block.timestamp;
        }
        
        if(address(data.customContract) != address(0)) {
            if(data.transfers.transferIsBuy(from, to)) {
                try data.customContract.handleBuy(to, amount, fees) {} catch {}
            }
            else if(data.transfers.transferIsSell(from, to)) {
                try data.customContract.handleSell(from, amount, fees) {} catch {}
            }

            try data.customContract.handleBalanceUpdated(from, fromBalance) {} catch {}
            try data.customContract.handleBalanceUpdated(to, toBalance) {} catch {}
        }
    }

    function getData(OcfiStorage.Data storage data, address account) external view returns (uint256[] memory dividendInfo, uint256[] memory customContractInfo, uint256 reinvestBonus, uint256 referralCode, uint256[] memory fees, uint256 blockTimestamp) {
        dividendInfo = data.dividendTracker.getDividendInfo(account);

        if(address(data.customContract) != address(0)) {
            customContractInfo = data.customContract.getData(account);
        }

        reinvestBonus = data.fees.reinvestBonus;
        referralCode = data.referrals.getReferralCode(account);

        fees = data.fees.getCurrentFees(data);

        blockTimestamp = block.timestamp;
    }

    function setupDividendTracker(OcfiStorage.Data storage data, address owner) public {
        data.fees.excludeFromFees(address(data.dividendTracker), true);
        data.dividendTracker.excludeFromDividends(address(data.dividendTracker));
        data.dividendTracker.excludeFromDividends(address(this));
        data.dividendTracker.excludeFromDividends(owner);
        data.dividendTracker.excludeFromDividends(OcfiFees.deadAddress);
        data.dividendTracker.excludeFromDividends(address(data.router));
        data.dividendTracker.excludeFromDividends(address(data.pair));
    }


    function setSwapTokensParams(OcfiStorage.Data storage data, uint256 atAmount, uint256 maxAmount) public {
        require(atAmount < 1000 * (10**18));
        data.swapTokensAtAmount = atAmount;

        require(maxAmount < 10000 * (10**18));
        data.swapTokensMaxAmount = maxAmount;
    }

    function handleNewBalanceForReferrals(OcfiStorage.Data storage data, address account, uint256 balance) public {
        if(data.fees.isExcludedFromFees[account]) {
            return;
        }

        if(account == address(data.pair)) {
            return;
        }

        data.referrals.handleNewBalance(account, balance);
    }

    function shouldTakeFee(OcfiStorage.Data storage data, address from, address to) public view returns (bool) {
        return data.startTime > 0 &&
               !data.swapping &&
               !data.fees.isExcludedFromFees[from] &&
               !data.fees.isExcludedFromFees[to];
    }
}