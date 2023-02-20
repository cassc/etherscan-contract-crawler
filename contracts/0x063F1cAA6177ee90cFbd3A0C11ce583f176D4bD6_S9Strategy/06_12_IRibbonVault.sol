pragma solidity >=0.8.4;

// SPDX-License-Identifier: MIT

interface IRibbonVault {
    //read
    //returns heldByAccount, heldByValut
    //heldByAccount: locked
    //heldByVault: avaliable
    function shareBalances(address account)
        external
        view
        returns (uint256 heldByAccount, uint256 heldByVault);

    //shares: amount pending
    function withdrawals(address account)
        external
        view
        returns (uint256 round, uint256 shares);

    //amount in native token available for withdraw
    function depositReceipts(address account)
        external
        view
        returns (
            uint16 round,
            uint104 amount,
            uint128 unredeemedShares
        );

    //multiplied on UI to show amount staked
    function pricePerShare() external view returns (uint256);

    function vaultState()
        external
        view
        returns (
            uint16 round,
            uint104 lockedAmount,
            uint104 lastLockedAmount,
            uint128 totalPending,
            uint128 queuedWithdrawShares,
            uint64 lastEpochTime,
            uint64 lastOptionPurchaseTime,
            uint128 optionsBoughtInRound,
            uint256 amtFundsReturned
        );

    function allocationState()
        external
        view
        returns (
            uint32 nextLoanTermLength,
            uint32 nextOptionPurchaseFreq,
            uint32 currentLoanTermLength,
            uint32 currentOptionPurchaseFreq,
            uint32 loanAllocationPCT,
            uint32 optionAllocationPCT,
            uint256 loanAllocation,
            uint256 optionAllocation
        );
    
    function vaultParams() external view returns(
        uint8 decimals,
        address asset, 
        uint56 minimumSupply,
        uint104 cap
    );

    function roundPricePerShare(uint round) external view returns(uint pricePerShare);
    function balanceOf(address user) external view returns(uint balanace);
    function decimals() external view returns(uint decimals);
    function liquidityGauge() external view returns(address gaugeAddress);

    //write functions
    function deposit(uint256 amount) external;

    function initiateWithdraw(uint256 numShares) external;

    function withdrawInstantly(uint256 numShares) external;

    function maxRedeem() external;

    function stake(uint amount) external;

    //Used for tests
    function rollToNextRound() external;

    function buyOption() external;

    function completeWithdraw() external;

}