//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPermissions.sol";
import "./IStkEth.sol";

/// @title Core interface
/// @author Ankit Parashar
interface ICore is IPermissions {

    event SetCoreContract(bytes32 _key, address indexed _address);

    event SetWithdrawalCredential(bytes32 _withdrawalCreds);

    function stkEth() external view returns(IStkEth);

    function oracle() external view returns(address);

    function withdrawalCredential() external view returns(bytes32);

    function keysManager() external view returns(address);

    function pstakeTreasury() external view returns(address);

    function validatorPool() external view returns(address);

    function issuer() external view returns(address);

    function set(bytes32 _key, address _address) external;

    function coreContract(bytes32 key) external view returns (address);

}