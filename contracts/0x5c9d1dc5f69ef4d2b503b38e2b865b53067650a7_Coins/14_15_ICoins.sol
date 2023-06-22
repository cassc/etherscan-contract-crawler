// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "IERC1155.sol";

interface ICoins is IERC1155 {
    error Soulbound();
    error NotClaimable();
    error NonExistent();
    error HasClaimed();
    error SignerMismatch();

    function holdsCoin(address) external view returns (bool);
}