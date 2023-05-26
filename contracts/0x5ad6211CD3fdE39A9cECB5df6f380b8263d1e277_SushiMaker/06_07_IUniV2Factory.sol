// SPDX-License-Identifier: GPL-3.0-or-later

interface IUniV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}