// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC20 } from "./IERC20.sol";

interface IWERC721 is IERC20 {
    event Mint(address indexed from, address indexed to, uint[] tokenIds);
    event Burn(address indexed from, address indexed to, uint[] tokenIds);

    function factory() external view returns (address);
    function collection() external view returns (address);

    function mint(address to, uint[] memory tokenIds) external;
    function burn(address to, uint[] memory tokenIds) external;

    function initialize(address) external;
}