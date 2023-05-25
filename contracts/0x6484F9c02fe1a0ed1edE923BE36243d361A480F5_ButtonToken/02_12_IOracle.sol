// SPDX-License-Identifier: GPL-3.0-or-later

interface IOracle {
    function getData() external view returns (uint256, bool);
}