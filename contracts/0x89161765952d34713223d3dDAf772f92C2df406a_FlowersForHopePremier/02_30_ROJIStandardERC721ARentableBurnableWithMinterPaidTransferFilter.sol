// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../utils/EIP712OwnableRoles.sol";
import "./ROJIStandardERC721ARentableBurnableWithMinterPaid.sol";
import "../utils/errors.sol";
import {OperatorFilterer} from "../vectorized-closedsea/operator-filterer.sol";

// import {DefaultOperatorFilterer} from "../opensea-operator-filter/DefaultOperatorFilterer.sol";

/// @title ERC721A based NFT contract with included paid minter protected by off chain allowlist
/// @author Martin Wawrusch for Roji Inc.
/// @dev
/// General
/// This contract extends the standard NFT contract with a minter that is guarded through
/// an external signature mechanism (allowlist).
///
/// The mintableSupply determines how many NFTs can be minted by users directly through the {mint} method.
/// 
/// Includes the OpenSea Transfer filter code
/// @custom:security-contact [email protected]
contract ROJIStandardERC721ARentableBurnableWithMinterPaidTransferFilter is ROJIStandardERC721ARentableBurnableWithMinterPaid, // MUST ALWAYS BE FIRST
                        OperatorFilterer {

    bool public operatorFilteringEnabled;

    /// @notice The constructor of this contract.
    /// @param price_ The price per NFT in wei.
    /// @param maxMintQuantityPerAddress_ The maximum number of mints per wallet address.
    /// @param mintableSupply_ The number of NFTs that can be minted by users through the mint method.
    /// @param defaultRoyaltiesBasisPoints_ The default royalties basis points (out of 10000).
    /// @param name_ The name of the NFT.
    /// @param symbol_ The symbol of the NFT. Must not exceed 11 characters as that is the Metamask display limit.
    /// @param baseTokenURI_ The base URI of the NFTs. The final URI is composed through baseTokenURI + tokenId + .json. Normally you will want to include the trailing slash.
    constructor(uint256 price_,
                uint256 maxMintQuantityPerAddress_,
                uint256 mintableSupply_,
                uint256 defaultRoyaltiesBasisPoints_,
                string memory name_,
                string memory symbol_,
                string memory baseTokenURI_) 
                ROJIStandardERC721ARentableBurnableWithMinterPaid(price_,
                 maxMintQuantityPerAddress_,
                 mintableSupply_,
                 defaultRoyaltiesBasisPoints_,
                name_,
                symbol_,
                 baseTokenURI_) {
    _registerForOperatorFiltering();
    operatorFilteringEnabled = true;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721A)  payable  onlyAllowedOperator(from, operatorFilteringEnabled) {
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