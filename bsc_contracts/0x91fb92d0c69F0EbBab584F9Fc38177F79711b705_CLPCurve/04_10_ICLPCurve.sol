//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

interface ICLPCurve {
    /**
        @notice Used to specify the necessary parameters for a Curve interaction
        @dev Users may either deposit/withdraw 'base' assets or 'underlying' assets into/from a Curve pool.
            Some Curve pools allow directly depositing 'underlying' assets, whilst other Curve pools necessitate
            the usage of a 'helper' contract. 
            In order to accomodate different behaviour between different Curve pools, the caller of this contract
            must explicitly state the desired behaviour:

            If depositing/withdrawing 'base' assets, this parameter MUST be BASE and the `curveDepositAddress`/`curveWithdrawAddress` parameter MUST be the address of the Curve contract.

            If depositing/withdrawing 'underlying assets', check whether the Curve contract supports underlying assets:
                If underlying assets are supported, this parameter MUST be UNDERLYING and the `curveDepositAddress`/`curveWithdrawAddress` parameter MUST be the address of the Curve contract.
                If underlying assets are not supported, this parameter MUST be CONTRACT and the `curveDepositAddress`/`curveWithdrawAddress` parameter MUST be the address of the helper 'Deposit.vy' contract.

        @param BASE The user is interacting directly with the Curve contract and depositing base assets.
        @param UNDERLYING The user is interacting directly with the Curve contract and depositing underlying assets.
        @param HELPER The user is interacting with a Curve `Deposit.vy` contract, and depositing underlying assets.
        @param METAPOOL_HELPER The user is interacting with a Curve 'metapool_helper' contract, and depositing underlying assets.
    */
    enum CurveLPType {
        BASE,
        UNDERLYING,
        HELPER,
        METAPOOL_HELPER
    }

    struct CurveLPDepositParams {
        uint256 minReceivedLiquidity;
        CurveLPType lpType;
        address curveDepositAddress;
        address metapool;
    }
    struct CurveLPWithdrawParams {
        uint256[] minimumReceived;
        CurveLPType lpType;
        address curveWithdrawAddress;
        address metapool;
    }
}