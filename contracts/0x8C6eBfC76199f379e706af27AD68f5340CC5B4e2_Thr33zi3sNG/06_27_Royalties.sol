// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./NiftyPermissions.sol";
import "../libraries/Clones.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC2981.sol";
import "../structs/RoyaltyRecipient.sol";

abstract contract Royalties is NiftyPermissions, IERC2981 {

    event RoyaltyReceiverUpdated(address previousReceiver, address newReceiver);

    uint256 constant public BIPS_PERCENTAGE_TOTAL = 10000;

    RoyaltyRecipient internal royaltyRecipient;

    function supportsInterface(bytes4 interfaceId) public view virtual override(NiftyPermissions, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||            
            super.supportsInterface(interfaceId);
    }

    function getRoyaltySettings() public view returns (RoyaltyRecipient memory) {
        return royaltyRecipient;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public virtual override view returns (address, uint256) {                        
        return royaltyRecipient.recipient == address(0) ? 
            (address(0), 0) :
            (royaltyRecipient.recipient, (salePrice * royaltyRecipient.bips) / BIPS_PERCENTAGE_TOTAL);
    }

    function initializeRoyalties(address payee, uint256 bips) external returns (RoyaltyRecipient memory) {
        _requireOnlyValidSender();
        require(bips <= BIPS_PERCENTAGE_TOTAL, ERROR_BIPS_OVER_100_PERCENT);
        address previousReceiver = royaltyRecipient.recipient;
        royaltyRecipient.recipient = payee;
        royaltyRecipient.bips = uint16(bips);
        emit RoyaltyReceiverUpdated(previousReceiver, royaltyRecipient.recipient);
        return royaltyRecipient;
    }
}