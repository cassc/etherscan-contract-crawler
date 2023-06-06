// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12; // solhint-disable-line compiler-version
pragma experimental ABIEncoderV2;

// this interface is defined because ConvexStakingWrapper has incompatible 0.6.12
// original file is contracts/interfaces/IBaseSilo.sol
interface ISilo0612Like {
    struct AssetStorage {
        address collateralToken;
        address collateralOnlyToken;
        address debtToken;
        uint256 totalDeposits;
        uint256 collateralOnlyDeposits;
        uint256 totalBorrowAmount;
    }

    function assetStorage(address _asset) external view returns (AssetStorage memory);
}