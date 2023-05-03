// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import { IOERC20 } from "./IOERC20.sol";

interface IUSX is IOERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}