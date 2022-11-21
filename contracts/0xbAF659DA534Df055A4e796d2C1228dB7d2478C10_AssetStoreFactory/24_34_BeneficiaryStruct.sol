//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Structure to store different types of Beneficiary
 * (ERC721, ERC1155, ERC20)
 * @param beneficiaryAddress address for assets to go to
 * @param beneficiaryName name of entity recieveing the assets
 * @param isCharity boolean representing if Beneficiary is a charity
 * because charities will be a recieve only address and cannot be
 * expected to call a function to claim assets
 *
 */
struct Beneficiary {
    address beneficiaryAddress;
    bool isCharity;
    string beneficiaryName;
}