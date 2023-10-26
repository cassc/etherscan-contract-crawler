// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultFacetFees {
    enum Fee { Deposit, Withdraw }

    function defaultNativeDepositFee() external view returns (uint);
    function defaultNativeWithdrawFee() external view returns (uint);
    function defaultAlienDepositFee() external view returns (uint);
    function defaultAlienWithdrawFee() external view returns (uint);

    function fees(address token) external view returns (uint);

    function skim(
        address token
    ) external;

    function setDefaultAlienWithdrawFee(uint fee) external;
    function setDefaultAlienDepositFee(uint fee) external;
    function setDefaultNativeWithdrawFee(uint fee) external;
    function setDefaultNativeDepositFee(uint fee) external;

    function setTokenWithdrawFee(
        address token,
        uint _withdrawFee
    ) external;
    function setTokenDepositFee(
        address token,
        uint _depositFee
    ) external;
}