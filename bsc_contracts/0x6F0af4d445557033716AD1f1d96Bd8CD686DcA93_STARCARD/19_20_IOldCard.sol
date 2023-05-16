// SPDX-License-Identifier: MIT
interface IOldCard {
    function _cardType(uint tokenId) external returns (uint16);

    function balanceOf(address account) external returns (uint);

    function tokensOf(
        address account,
        uint startIndex,
        uint endIndex
    ) external returns (uint[] memory);

    function transferFrom(address sender, address to, uint tokenId) external;
}