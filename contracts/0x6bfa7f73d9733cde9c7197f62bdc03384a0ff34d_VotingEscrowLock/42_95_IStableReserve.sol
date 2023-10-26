//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IStableReserve {
    event AdminUpdated(address indexed minter);
    event Redeemed(address to, uint256 amount);

    function redeem(uint256 amount) external;

    function payInsteadOfWorking(uint256 amount) external;

    function reserveAndMint(uint256 amount) external;

    function grant(
        address recipient,
        uint256 amount,
        bytes memory data
    ) external;

    function allow(address account, bool active) external;

    function baseCurrency() external view returns (address);

    function commitToken() external view returns (address);

    function priceOfCommit() external view returns (uint256);

    function allowed(address account) external view returns (bool);

    function mintable() external view returns (uint256);
}