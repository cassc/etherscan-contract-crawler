pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

abstract contract HasAffiliateFees is ERC165Storage {

    event AffiliateFees(uint256 tokenId, address[] recipients, uint[] bps);

    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    constructor() {
        _registerInterface(_INTERFACE_ID_FEES);
    }

    function checkAffiliateSale(uint256 id) external virtual view returns (bool);
    function setAffiliateSale(uint256 id) external virtual;
    function getFeeRecipients(uint256 id) public virtual view returns (address[] memory);
    function getFeeBps(uint256 id) public virtual view returns (uint[] memory);
    function getAffiliateFeeRecipient() external virtual returns (address);
    function getAffiliateFee() external virtual returns (uint);
}