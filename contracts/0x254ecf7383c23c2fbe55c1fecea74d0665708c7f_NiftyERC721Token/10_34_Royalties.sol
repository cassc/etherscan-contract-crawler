// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./NiftyPermissions.sol";
import "../libraries/Clones.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC2981.sol";
import "../interfaces/ICloneablePaymentSplitter.sol";
import "../structs/RoyaltyRecipient.sol";

abstract contract Royalties is NiftyPermissions, IERC2981 {

    event RoyaltyReceiverUpdated(uint256 indexed niftyType, address previousReceiver, address newReceiver);

    uint256 constant public BIPS_PERCENTAGE_TOTAL = 10000;

    // Royalty information mapped by nifty type
    mapping (uint256 => RoyaltyRecipient) internal royaltyRecipients;

    function supportsInterface(bytes4 interfaceId) public view virtual override(NiftyPermissions, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||            
            super.supportsInterface(interfaceId);
    }

    function getRoyaltySettings(uint256 niftyType) public view returns (RoyaltyRecipient memory) {
        return royaltyRecipients[niftyType];
    }
    
    function setRoyaltyBips(uint256 niftyType, uint256 bips) external {
        _requireOnlyValidSender();
        require(bips <= BIPS_PERCENTAGE_TOTAL, ERROR_BIPS_OVER_100_PERCENT);
        royaltyRecipients[niftyType].bips = uint16(bips);
    }
    
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public virtual override view returns (address, uint256) {                        
        uint256 niftyType = _getNiftyType(tokenId); 
        return royaltyRecipients[niftyType].recipient == address(0) ? 
            (address(0), 0) :
            (royaltyRecipients[niftyType].recipient, (salePrice * royaltyRecipients[niftyType].bips) / BIPS_PERCENTAGE_TOTAL);
    }    

    function initializeRoyalties(uint256 niftyType, address splitterImplementation, address[] calldata payees, uint256[] calldata shares) external returns (address)  {
        _requireOnlyValidSender();        
        address previousReceiver = royaltyRecipients[niftyType].recipient;        
        royaltyRecipients[niftyType].isPaymentSplitter = payees.length > 1;
        royaltyRecipients[niftyType].recipient = payees.length == 1 ? payees[0] : _clonePaymentSplitter(splitterImplementation, payees, shares);        
        emit RoyaltyReceiverUpdated(niftyType, previousReceiver, royaltyRecipients[niftyType].recipient);                        
        return royaltyRecipients[niftyType].recipient;
    }      

    function getNiftyType(uint256 tokenId) public view returns (uint256) {
        return _getNiftyType(tokenId);
    }    

    function getPaymentSplitterByNiftyType(uint256 niftyType) public virtual view returns (address) {
        return _getPaymentSplitter(niftyType);
    }

    function getPaymentSplitterByTokenId(uint256 tokenId) public virtual view returns (address) {
        return _getPaymentSplitter(_getNiftyType(tokenId));
    }    

    function _getNiftyType(uint256 tokenId) internal virtual view returns (uint256) {        
        return 0;
    }

    function _clonePaymentSplitter(address splitterImplementation, address[] calldata payees, uint256[] calldata shares_) internal returns (address) {
        require(IERC165(splitterImplementation).supportsInterface(type(ICloneablePaymentSplitter).interfaceId), ERROR_UNCLONEABLE_REFERENCE_CONTRACT);
        address clone = payable (Clones.clone(splitterImplementation));
        ICloneablePaymentSplitter(clone).initialize(payees, shares_);            
        return clone;
    }

    function _getPaymentSplitter(uint256 niftyType) internal virtual view returns (address) {        
        return royaltyRecipients[niftyType].isPaymentSplitter ? royaltyRecipients[niftyType].recipient : address(0);        
    }
}