// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * As defined at: https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/IRoyaltyEngineV1.sol
 * Retrieved 1/26/23
 */
interface IRoyaltyEngineV1 is IERC165 {
    /**
     * View only version of getRoyalty
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts);
}