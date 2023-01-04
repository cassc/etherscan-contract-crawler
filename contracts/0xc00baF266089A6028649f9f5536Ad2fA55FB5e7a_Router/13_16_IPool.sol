// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

interface IPool {
    struct Account {
        uint256 notional;
    }

    event Initialized(
        address indexed _router,
        address indexed _borrower,
        address[] _collateralAssets,
        address indexed _lentAsset
    );

    event OracleSet(address indexed _emitter, address _oracle);

    function leftoversWithdrawn() external view returns (bool);

    function startsAt() external view returns (uint32);

    function activeAt() external view returns (uint32);

    function maturesAt() external view returns (uint32);

    function coupon() external view returns (uint96);

    function ltv() external view returns (uint96);

    function originationFee() external view returns (uint96);

    function minSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);

    function supply() external view returns (uint256);

    function borrowed() external view returns (uint256);

    function borrower() external view returns (address);

    function whitelistedLender() external view returns (address);

    function lentAsset() external view returns (address);

    function collateralAssets(uint256) external view returns (address);

    function collateralReserves(address) external view returns (uint256);

    function notionals(address) external view returns (uint256);

    function initialize(
        address _borrower,
        address _lentAsset,
        address[] memory _collateralAssets,
        uint96 _coupon,
        uint96 _ltv,
        uint96 _originationFee,
        uint32 _activeAt,
        uint32 _maturesAt,
        uint256 _minSupply,
        uint256 _maxSupply,
        address _whitelistedLender
    ) external;

    function deposit(address, uint256) external;

    function supplyCollateral(address, uint256) external;

    function borrow(address, uint256) external;

    function repay(uint256) external;

    function redeem(address) external;

    function _default(address) external;

    function withdrawLeftovers(uint256) external;

    function getCollateralAssets() external view returns (address[] memory);
}