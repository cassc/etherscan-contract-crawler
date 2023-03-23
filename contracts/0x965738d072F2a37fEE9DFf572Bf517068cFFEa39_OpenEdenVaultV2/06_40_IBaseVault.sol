// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Action.sol";

interface IBaseVault {
    function getTransactionFee() external view returns (uint256 txFee);

    function getMinMaxDeposit()
        external
        view
        returns (uint256 minDeposit, uint256 maxDeposit);

    function getMaxWithdraw() external view returns (uint256 maxWithdraw);

    function getTargetReservesLevel()
        external
        view
        returns (uint256 targetReservesLevel);

    function getOnchainAndOffChainServiceFeeRate()
        external
        view
        returns (uint256 onchainFeeRate, uint256 offchainFeeRate);

    function getFirstDeposit() external view returns (uint256 firstDeposit);
}