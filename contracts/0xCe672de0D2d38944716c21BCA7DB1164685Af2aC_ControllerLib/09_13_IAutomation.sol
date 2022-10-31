// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IAutomation {
    function getLoanProvider(address account) external view returns (address);
}