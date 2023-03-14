// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "./IStakingConfig.sol";
import "../libs/ValidatorUtil.sol";

interface IValidatorStorage {

    function getValidator(address) external view returns (Validator memory);

    function validatorOwners(address) external view returns (address);

    function create(
        address validatorAddress,
        address validatorOwner,
        ValidatorStatus status,
        uint64 epoch
    ) external;

    function activate(address validatorAddress) external returns (Validator memory);

    function disable(address validatorAddress) external returns (Validator memory);

    function change(address validatorAddress, uint64 epoch) external;

    function changeOwner(address validatorAddress, address newOwner) external returns (Validator memory);

//    function activeValidatorsList() external view returns (address[] memory);

    function isOwner(address validatorAddress, address addr) external view returns (bool);

    function migrate(Validator calldata validator) external;

    function getValidators() external view returns (address[] memory);
}