// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: JUSTIN MALLER
/// @title: FRACTIONALIZED_FCTS
/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                          &&&     &&&#                                                          //
//                                                    .&&&&&&&&     &&&&&&&&%                                                     //
//                                               ,&&&&&&&&&&&&&     &&&&&&&&&&&&&#                                                //
//                                          .&&&&&&&&&&&&&&&&&&     &&&&&&&&&&&&&&&&&&%                                           //
//                                     ,&&&&&&&&&&&&(                         ,&&&&&&&&&&&&&                                      //
//                                *&&/                                                       ,&&%                                 //
//                                                  %&&&&&&&           &&&&&&&&,                                                  //
//                                  .%&&&&&&&&&&&&&&&&&&&&%      &%      &&&&&&&&&&&&&&&&&&&&&.                                   //
//                    #&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%,                    //
//                   .&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&(      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                    //
//                    (&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                     //
//                     %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&.     ,&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                      //
//                      &&&&&&&&&&&&&&&&&&&&&&&&&&&      #&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&                       //
//                       &&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&      /&&&&&&&&&&&&&&&&&&&&&&&&                        //
//                  ,     &&&&&&&&&&&&&&&&&&&&&&      ,&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&     &                   //
//                   &     &&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&      %&&&&&&&&&&&&&&&&&&&     %&                   //
//                   &&     &&&&&&&&&&&&&&&&&,      &&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&     /&#                   //
//                   &&&     &&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&     .&&,                   //
//                   &&&&     &&&&&&&&&&&&(      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#      &&&&&&&&&&&&,     &&&                    //
//                   &&&&#     &&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&(     &&&&                    //
//                   &&&&&/     &&&&&&&%      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.      &&&&&&&%     &&&&&                    //
//                   &&&&&&.     &&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&     &&&&&&                    //
//                   &&&&&&&     .&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&     &&&&&&&                    //
//                   ,&&&&&&&     /      *&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &     &&&&&&&&                    //
//                    &&&&&&&&          &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&          &&&&&&&&&                    //
//                    &&&&&&&&&                                                                     &&&&&&&&&&                    //
//                    &&&&&&%                                                                          &&&&&&,                    //
//                    &&&        *       &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &        &&&                     //
//                            &&&&&&       &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&                             //
//                        ,&&&&&&&&&&&       &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&&&&&                         //
//                       ,&&&&&&&&&&&&&&       %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&&&&&&&%                        //
//                            &&&&&&&&&&&&,      /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&&&&&*                            //
//                                &&&&&&&&&&/      .&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&&&                                 //
//                                    %&&&&&&&#       &&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&                                     //
//                                        *&&&&&&       &&&&&&&&&&&&&&&&&&&%       &&&&&&                                         //
//                                             &&&&       &&&&&&&&&&&&&&&(      ,&&&#                                             //
//                                                 &&       &&&&&&&&&&&*      (&.                                                 //
//                                                            &&&&&&&.                                                            //
//                                                              &&&                                                               //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract FRACTIONALIZED_FCTS is
    ReentrancyGuard,
    AdminControl,
    ERC1155Supply,
    ERC1155Burnable,
    IERC721Receiver
{
    event Activate();
    event Deactivate();

    uint8 constant NUM_FACETS = 10;

    // Immutable constructor arguments
    address private immutable _facetAddress;

    // Contract state
    bool public isRedemptionEnabled;

    // Royalty
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor(address facetAddress) ERC1155("") {
        _facetAddress = facetAddress;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address from,
        uint256 id,
        bytes calldata
    ) external override nonReentrant returns (bytes4) {
        _onERC721Received(from, id);
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC721Receiver-onERC721BatchReceived}.
     */
    function onERC721BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        bytes calldata
    ) external nonReentrant returns (bytes4) {
        require(ids.length > 0, "Invalid input");

        for (uint i = 0; i < ids.length; i++) {
            _onERC721Received(from, ids[i]);
        }

        _onERC721Received(from, ids[0]);
        return this.onERC721BatchReceived.selector;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, ERC1155)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            ERC1155.supportsInterface(interfaceId) ||
            AdminControl.supportsInterface(interfaceId) ||
            interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 ||
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /**
     * @dev Enable token redemption period
     */
    function enableRedemption() external adminRequired {
        isRedemptionEnabled = true;
        emit Activate();
    }

    /**
     * @dev Disable token redemption period
     */
    function disableRedemption() external adminRequired {
        isRedemptionEnabled = false;
        emit Deactivate();
    }

    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps)
        external
        adminRequired
    {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256)
        external
        view
        returns (address payable[] memory recipients, uint256[] memory bps)
    {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256)
        external
        view
        returns (address payable[] memory recipients)
    {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value)
        external
        view
        returns (address, uint256)
    {
        return (_royaltyRecipient, (value * _royaltyBps) / 10000);
    }

    function _onERC721Received(address from, uint256 id) private {
        require(isRedemptionEnabled || isAdmin(from), "Redemption inactive");
        require(msg.sender == _facetAddress, "Invalid NFT");

        try
            // purposely transfer to 0x00...dEaD so that 721 token's `tokenURI` still returns and displays itself on platforms
            ERC721Creator(msg.sender).safeTransferFrom(
                address(this),
                address(0xdEaD),
                id,
                ""
            )
        {} catch (bytes memory) {
            revert("Burn failure");
        }

        // mint the fractionalized editions as 1155s
        _mint(from, id, NUM_FACETS, new bytes(0));
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_facetAddress != address(0), "No facets address");
        require(exists(tokenId), "No facets address");
        // return the original 721 metadata
        return ERC721Creator(_facetAddress).tokenURI(tokenId);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply, ERC1155) {
        ERC1155._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        ERC1155Supply._beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }
}