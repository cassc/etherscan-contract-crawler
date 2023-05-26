// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

interface IMasterContract {
    // METH functions

    function claim(address to, uint256 amount) external;

    function pay(uint256 payment, uint256 fee) external;

    // Teens functions

    function airdrop(address to, uint256 amount) external;

    function burnTeenBull(uint256 tokenId) external;

    // Utilities functions

    function burn(uint256 id, uint256 amount) external;

    function airdrop(
        address to,
        uint256 amount,
        uint256 id
    ) external;
}