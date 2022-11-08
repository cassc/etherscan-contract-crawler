// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "erc721a/contracts/IERC721A.sol";

interface IPlanetaryScores is IERC721A {
    error NonEOA();
    error InvalidMintState();
    error InvalidToken();
    error EarlyDiscoveryTokenClaimed();
    error NotEnoughFunds();
    error SupplyExceeded();
    error WalletLimitExceeded();
    error AddressNotWhitelisted();
    error EtherWithdrawFailed();
}