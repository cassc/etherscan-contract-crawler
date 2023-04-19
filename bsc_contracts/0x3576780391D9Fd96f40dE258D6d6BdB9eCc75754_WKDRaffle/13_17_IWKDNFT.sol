// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IWKDNFT {
    function mint(address account, uint256 amount) external;

    function burnWinningTokens(address account, uint256 value) external;

    function HATUT_ZERAZ_E() external view returns (uint256);

    function KIMOYO() external view returns (uint256);

    function DORA_MILAJ_E() external view returns (uint256);

    function TAIFA_NAGA_O() external view returns (uint256);

    function NEGUS() external view returns (uint256);
}