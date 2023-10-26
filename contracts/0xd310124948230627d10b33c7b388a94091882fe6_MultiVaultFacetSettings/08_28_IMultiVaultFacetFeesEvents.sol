// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultFacetFeesEvents {
    event UpdateDefaultNativeDepositFee(uint fee);
    event UpdateDefaultNativeWithdrawFee(uint fee);
    event UpdateDefaultAlienDepositFee(uint fee);
    event UpdateDefaultAlienWithdrawFee(uint fee);

    event UpdateTokenDepositFee(address token, uint256 fee);
    event UpdateTokenWithdrawFee(address token, uint256 fee);

    event EarnTokenFee(address token, uint amount);

    event SkimFee(
        address token,
        uint256 amount
    );
}