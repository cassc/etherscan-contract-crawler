//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract RoyaltyByToken is ERC165 {

    //Royalties recipient
    address payable private _royaltyRecipient;

    //Royalties by token
    mapping(uint256 => uint256) private _royaltyBps; // Divided per 10000 (1000 = 0.1 = 10%)
    
    
    //EIP-2981 royalties
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    
    //Rarible royalties
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;


    //Constructor
    constructor() {
        _royaltyRecipient = payable(msg.sender); // sender must be a payable address
    }

    //Change recipient
    function setRecipient(address newRecipient) public {
        require(msg.sender == _royaltyRecipient, 'Only current recipient can set new recipient');
        _royaltyRecipient = payable(newRecipient); // newRecipient must be a payable address
    }

    //Set royalty fees for a tokenId
    function setRoyalties(uint256 tokenId, uint256 bps) public {
        require(msg.sender == _royaltyRecipient, 'Only current recipient can set royalties');
        _royaltyBps[tokenId] = bps;
    }

    //Rarible royalties impl
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps[tokenId];
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256 tokenId) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps[tokenId];
        }
        return bps;
    }

    //EIP-2981 royalties impl
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps[tokenId]/10000);
    }


    // IERC165-supportsInterface.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || super.supportsInterface(interfaceId);
    } 
}