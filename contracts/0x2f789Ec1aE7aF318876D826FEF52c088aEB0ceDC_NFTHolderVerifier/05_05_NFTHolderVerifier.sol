// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {ERC165Checker} from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './interfaces/IIdentityVerifier.sol';

/**
 * @title NFT Holder Verifier made by Artiffine
 * @author https://artiffine.com/
 */
contract NFTHolderVerifier is IIdentityVerifier {
    IERC721 public collection;
    address public verifyee;
    mapping(uint256 => mapping(address => bool)) _hasAlreadyMintedTokenId;

    error CallerIsNotVerifyee();

    constructor(address _collection, address _verifyee) {
        require(ERC165Checker.supportsInterface(_collection, type(IERC721).interfaceId));
        require(_verifyee != address(0));
        collection = IERC721(_collection);
        verifyee = _verifyee;
    }

    /**
     * @dev Verify that the NFT buyer is an owner of specific ERC721 {collection}
     * and can mint only one NFT per token ID.
     *
     *  @param identity       The identity to verify.
     *  @param tokenId        The token id associated with this verification.
     *  @param amount         Amount of tokens to buy.
     *  @param data           Additional data needed to verify.
     */
    function verify(address identity, uint256 tokenId, uint256 amount, bytes calldata data) external returns (bool) {
        if (msg.sender != verifyee) revert CallerIsNotVerifyee();
        bool verified = _verify(identity, tokenId, amount);
        if (verified) {
            _hasAlreadyMintedTokenId[tokenId][identity] = true;
        }
        return verified;
    }

    /**
     *  @dev Preview {verify} function result.
     *
     *  @param identity       The identity to verify.
     *  @param tokenId        The token id associated with this verification.
     *  @param amount         Amount of tokens to buy.
     *  @param data           Additional data needed to verify.
     */
    function previewVerify(address identity, uint256 tokenId, uint256 amount, bytes memory data) public view returns (bool) {
        return _verify(identity, tokenId, amount);
    }

    function _verify(address identity, uint256 tokenId, uint256 amount) internal view returns (bool) {
        uint256 balance = collection.balanceOf(identity);
        bool verified = (balance != 0 && amount == 1 && !_hasAlreadyMintedTokenId[tokenId][identity]);
        return verified;
    }

    /**
     * @dev See {IERC165}.
     */
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IIdentityVerifier).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}