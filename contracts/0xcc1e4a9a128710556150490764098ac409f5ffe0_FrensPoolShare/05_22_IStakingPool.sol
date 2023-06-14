// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IFrensArt.sol";

interface IStakingPool {

    function pubKey() external view returns(bytes memory);

    function depositForId(uint _id) external view returns (uint);

    function totalDeposits() external view returns(uint);

    function transferLocked() external view returns(bool);

    function locked(uint id) external view returns(bool);

    function artForPool() external view returns (IFrensArt);

    function owner() external view returns (address);

    function depositToPool() external payable;

    function addToDeposit(uint _id) external payable;

    function withdraw(uint _id, uint _amount) external;

    function claim(uint id) external;

    function getIdsInThisPool() external view returns(uint[] memory);

    function getShare(uint _id) external view returns (uint);

    function getDistributableShare(uint _id) external view returns (uint);

    function rageQuitInfo(uint id) external view returns(uint, uint, bool);

    function setPubKey(
        bytes calldata pubKey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external;

    function getState() external view returns (string memory);

    // function getDepositAmount(uint _id) external view returns(uint);

    function stake(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external;

    function stake() external;

}