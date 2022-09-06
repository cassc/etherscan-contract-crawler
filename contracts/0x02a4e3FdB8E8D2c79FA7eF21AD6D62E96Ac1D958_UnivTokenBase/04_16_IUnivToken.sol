// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IUnivToken is IAccessControlUpgradeable {

    /**
     * @dev Returns the fee to create a new token a minter must pay.
     */
    function getEscrowFee() external view returns (uint);

    /**
     * @dev Returns the ETH kept in escrow for all the minted
     * tokens.
     */
    function getEscrow() external view returns (uint256);

    /**
     * @dev mintTokenForNft
     * The minter must pay an eth fee that it stores in escrow in case the
     * owner of the Token would like to redeem it (burn).
     * Each time an NFT is generated we also give the minter a free token!
     **/
    function mintTokenForNft(address account) external payable;

    /**
     * @dev mintTokenForMiner
     * The minter must pay an eth fee that it stores in escrow in case the
     * owner of the Token would like to redeem it (burn).
     * Each time 100 NFT(s) are generated we also give the miner a free token!
     **/
    function mintTokenForMiner(address miner) external payable;

    /**
     * @dev owners of tokens can redeem them at any time for the escrow amount they paid.
     */
    function redeemTokens(address payable tokenOwner, uint256 tokenAmount) external;
}