// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AdminPrivileges.sol";

/**
* @notice THIS PRODUCT IS IN BETA, SIBLING LABS IS NOT RESPONSIBLE FOR ANY LOST FUNDS OR
* UNINTENDED CONSEQUENCES CAUSED BY THE USE OF THIS PRODUCT IN ANY FORM.
*/

/**
* @dev Contract which adds support for Rarible and EIP2981 NFT
* royalty standards.
*
* Royalty recipient is set to the contract deployer by default,
* and royalty percentage is set to 10% by default.
* 
* Admins can use the {updateRoyalties} function to change the
* royalties percentage or royalty recipient.
*
* Rarible and LooksRare (LooksRare uses the EIP2981 NFT
* royalty standard) are the only marketplaces which this
* contract module will add support for. We recommend updating
* royalty settings for other marketplaces on their
* respective websites.
*
* See more module contracts from Sibling Labs at
* https://github.com/NFTSiblings/Modules
 */
contract RoyaltiesConfig is AdminPrivileges {
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor() {
        _royaltyRecipient = payable(msg.sender);
        _royaltyBps = 500;
    }

    /**
     * @dev See {IERC165-supportsInterface}. Override this function
     * in your base contract. See the bottom of this file for an example.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /**
    * @dev Set royalty recipient and basis points.
     */
    function updateRoyalties(address payable recipient, uint256 bps) external virtual onlyAdmins {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    // RARIBLE ROYALTIES FUNCTIONS //

    function getFeeRecipients(uint256) external virtual view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external virtual view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    // EIP2981 ROYALTY STANDARD FUNCTION //

    function royaltyInfo(uint256, uint256 value) external virtual view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }
}

/**
* For this contract module to work correctly, you must override {supportsInterface}
* in your base contract and return this contract's {supportsInterface} function.
*
* Example:
*
* function supportsInterface(bytes4 interfaceId) public view override(RoyaltiesConfig, ERC1155) returns (bool) {
*     return RoyaltiesConfig.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId);
* }
 */