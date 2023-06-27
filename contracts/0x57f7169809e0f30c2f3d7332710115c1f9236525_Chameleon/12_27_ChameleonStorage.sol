// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Fees.sol";
import "./BiggestBuyer.sol";
import "./Referrals.sol";
import "./Transfers.sol";
import "./ChameleonDividendTracker.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./IMysteryContract.sol";
import "./Transfers.sol";

library ChameleonStorage {
    using Transfers for Transfers.Data;

    struct Data {
        Fees.Data fees;
        BiggestBuyer.Data biggestBuyer;
        Referrals.Data referrals;
        Transfers.Data transfers;
        IUniswapV2Router02 router;
        IUniswapV2Pair pair;
        ChameleonDividendTracker dividendTracker;
        address marketingWallet1;
        address marketingWallet2;
        IMysteryContract mysteryContract;
    }

    function handleTransfer(Data storage data, address from, address to, uint256 amount, int256 fees) public {
        if(address(data.mysteryContract) != address(0)) {
            if(data.transfers.transferIsBuy(from, to)) {
                try data.mysteryContract.handleBuy{gas: 50000}(to, amount, fees) {} catch {}
            }
            else if(data.transfers.transferIsSell(from, to)) {
                try data.mysteryContract.handleSell{gas: 50000}(from, amount, fees) {} catch {}
            }
        }
    }
}