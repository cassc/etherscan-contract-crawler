pragma solidity 0.8.13;

/**
 *  * SPDX-License-Identifier: GPL-3.0-or-later
 */

import "../interfaces/Interfaces.sol";
import "../interfaces/IOptionsVaultFactory.sol";
import "../interfaces/IOptionsVaultERC20.sol";

library OptionsLib {

    function IsTrue(IStructs.BoolState value) internal pure returns (bool){
        return (value==IStructs.BoolState.TrueMutable || value==IStructs.BoolState.TrueImmutable);
    }

    function IsFalse(IStructs.BoolState value) internal pure returns (bool){
        return !IsTrue(value);
    }

    function IsMutable(IStructs.BoolState value) internal pure returns (bool){
        return (value==IStructs.BoolState.TrueMutable || value==IStructs.BoolState.FalseMutable);
    }

    function IsImmutable(IStructs.BoolState value) internal pure returns (bool){
        return !IsMutable(value);
    }

    function ToBoolState(bool value) internal pure returns (IStructs.BoolState){
        if (value)
          return IStructs.BoolState.TrueMutable;
        else
          return IStructs.BoolState.FalseMutable;
    }

    function getStructs(IOptionsVaultFactory factory, address holder, uint256 period, uint256 optionSize, uint256 strike, IStructs.OptionType optionType, uint vaultId, IOracle oracle, address referrer) internal view returns(IStructs.InputParams memory inParams_){

        IStructs.OracleResponse memory o = IStructs.OracleResponse({
            roundId: 0,
            answer: 0,
            startedAt: 0,
            updatedAt: 0,
            answeredInRound: 0
        });

        IStructs.InputParams memory i = IStructs.InputParams({
        holder: holder,
        period: period,
        optionSize: optionSize,
        strike: strike,
        currentPrice: 0,
        optionType: optionType,
        vaultId: vaultId,
        oracle: oracle,
        referrer: referrer,
        vault: IOptionsVaultERC20(address(factory.vaults(vaultId))),
        oracleResponse: o});

        inParams_ = i;
    }
}