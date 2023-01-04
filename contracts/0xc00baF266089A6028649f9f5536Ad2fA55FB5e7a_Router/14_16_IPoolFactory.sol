// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

interface IPoolFactory {
    event PoolCreated(
        uint256 indexed _pid,
        address[] _collateralAssets,
        address indexed _lentAsset,
        uint256 _upfrontCoupon
    );

    event ParametersChanged(
        uint256 indexed _maxNumberOfCollateralAssets,
        uint96 indexed _originationFee
    );

    function createPool(
        address _lentAsset,
        address[] memory _collateralAssets,
        uint96 _coupon,
        uint96 _ltv,
        uint32 _activeAt,
        uint32 _maturesAt,
        uint256 _minSupply,
        uint256 _maxSupply,
        address _whitelistedLender
    ) external returns (address pool);

    function setMaxNumberOfCollateralAssets(
        uint256 _maxNumberOfCollateralAssets
    ) external;

    function setOriginationFee(uint96 _originationFee) external;

    function router() external view returns (address);

    function pid() external view returns (uint256);

    function maxNumberOfCollateralAssets() external view returns (uint256);

    function originationFee() external view returns (uint96);

    function MAX_ORIGINATION_FEE() external view returns (uint96);

    function pidToPoolAddress(uint256) external view returns (address);

    function getAllPools() external view returns (address[] memory);
}