// SPDX-License-Identifier: GPL-3.0-or-later

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address addy) external view returns (uint256);
}