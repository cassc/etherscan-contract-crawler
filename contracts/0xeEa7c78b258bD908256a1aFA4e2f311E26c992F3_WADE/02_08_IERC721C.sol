//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/IERC721AQueryable.sol";

interface IERC721C is IERC721AQueryable {
    error CannotIncreaseMaxMintableSupply();
    error CannotUpdatePermanentBaseURI();
    error NoSupplyLeft();
    error WithdrawFailed();

    event SetMaxMintableSupply(uint256 maxMintableSupply);
    event SetBaseURI(string baseURI);
    event PermanentBaseURI(string baseURI);
    event Withdraw(uint256 value);

    function getMaxMintableSupply() external view returns (uint256);

    function totalMintedByAddress(address a) external view returns (uint256);

    function getTokenURISuffix() external view returns (string memory);

}