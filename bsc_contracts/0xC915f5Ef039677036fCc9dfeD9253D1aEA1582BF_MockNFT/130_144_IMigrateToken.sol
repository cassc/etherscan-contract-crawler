// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IMigrateToken {

    function initialize(uint _pid, IERC20 _baseToken) external;
    function doMigrate() external;
    function unDoMigrate() external;
    function setSkipBalance(address _account, bool _available) external;
    function addBlacklist(address _account) external;
    function delBlacklist(address _account) external;

}