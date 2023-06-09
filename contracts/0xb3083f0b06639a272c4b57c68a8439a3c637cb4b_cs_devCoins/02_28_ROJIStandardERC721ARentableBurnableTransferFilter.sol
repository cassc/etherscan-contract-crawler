// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ROJIStandardERC721ARentableBurnable.sol";
import "erc721a/contracts/interfaces/IERC721ABurnable.sol";
import {OperatorFilterer} from "../vectorized-closedsea/operator-filterer.sol";

/// @title ERC721A based NFT contract.
/// @author Martin Wawrusch for Roji Inc.
/// @dev
/// General
///
/// This contract interhits from {ROJIStandardERC721ARentable}
///
/// Burnable Functionality
/// By default, no one can burn a token.
/// The owner can set the burnMode to either {UNRESTRICTED} or {ROLE_ONLY}. 
///
/// - UNRESTRICTED
/// Any owner of a token can burn the token.
///
/// - ROLE_ONLY
/// Only an owner of a token who also has been granted the {ROLE_BURNER} can burn a token
///
///
/// @custom:security-contact [email protected]
contract ROJIStandardERC721ARentableBurnableTransferFilter is ROJIStandardERC721ARentableBurnable, // IMPORTANT MUST ALWAYS BE FIRST - NEVER CHANGE THAT
                                                            OperatorFilterer
{  

    bool public operatorFilteringEnabled;

    /// @notice The constructor of this contract.
    /// @param defaultRoyaltiesBasisPoints_ The default royalties basis points (out of 10000).
    /// @param name_ The name of the NFT.
    /// @param symbol_ The symbol of the NFT. Must not exceed 11 characters as that is the Metamask display limit.
    /// @param baseTokenURI_ The base URI of the NFTs. The final URI is composed through baseTokenURI + tokenId + .json. Normally you will want to include the trailing slash.
    constructor(uint256 defaultRoyaltiesBasisPoints_,
                string memory name_,
                string memory symbol_,
                string memory baseTokenURI_) ROJIStandardERC721ARentableBurnable(defaultRoyaltiesBasisPoints_, name_, symbol_, baseTokenURI_) {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721A)  payable  onlyAllowedOperator(from, operatorFilteringEnabled){
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public  override(ERC721A, IERC721A)  payable  onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
         override(ERC721A, IERC721A)
           payable 
         onlyAllowedOperator(from, operatorFilteringEnabled)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwnerOrRoles(ROJI_ROLE_ADMIN_SETUP) {
        operatorFilteringEnabled = value;
    }

}