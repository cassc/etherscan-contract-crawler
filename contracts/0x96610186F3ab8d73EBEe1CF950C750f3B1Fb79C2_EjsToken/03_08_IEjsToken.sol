// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./IERC20Mintable.sol";

/**
 * @title IEjsToken
 * @author Enjinstarter
 */
interface IEjsToken is IERC20Mintable {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function setGovernanceAccount(address account) external;

    function setMinterAccount(address account) external;
}