// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IComptrollerDForce {
    function enterMarkets(address[] calldata iTokens)
        external
        returns (bool[] memory);

    function markets(address iTokenAddress)
        external
        view
        returns (
            uint256 _collateralFactor,
            uint256 _borrowFactor,
            uint256 _borrowCapacity,
            uint256 _supplyCapacity,
            bool mintPaused,
            bool redeemPaused,
            bool borrowPaused
        );

    function getAlliTokens() external view returns (address[] memory);

    function calcAccountEquity(address)
        external
        view
        returns (
            uint256 equity,
            uint256 shortfall,
            uint256 collaterals,
            uint256 borrows
        );

    function priceOracle() external view returns (address);

    function hasiToken(address _iToken) external view returns (bool);

    function rewardDistributor() external view returns (address);
}

interface IDistributionDForce {
    function claimReward(address[] memory _holders, address[] memory _iTokens)
        external;

    function rewardToken() external view returns (address);

    function reward(address _account) external view returns (uint256);

    function distributionBorrowState(address _asset)
        external
        view
        returns (uint256 index, uint256 block);

    function distributionBorrowerIndex(address _asset, address _account)
        external
        view
        returns (uint256);

    function distributionSupplyState(address _asset)
        external
        view
        returns (uint256 index, uint256 block);

    function distributionSupplierIndex(address _asset, address _account)
        external
        view
        returns (uint256);

    function distributionSupplySpeed(address _asset)
        external
        view
        returns (uint256);

    function distributionSpeed(address _asset) external view returns (uint256);
}

interface IiToken {
    function mint(address recipient, uint256 mintAmount) external;

    function borrow(uint256 borrowAmount) external;

    function redeemUnderlying(address from, uint256 redeemAmount) external;

    function redeem(address from, uint256 redeemTokenAmount) external;

    function repayBorrow(uint256 repayAmount) external;

    function borrowBalanceCurrent(address account) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);

    function name() external view returns (string memory);

    function isiToken() external view returns (bool);
}

interface IiTokenETH {
    function mint(address recipient) external payable;

    function repayBorrow() external payable;
}