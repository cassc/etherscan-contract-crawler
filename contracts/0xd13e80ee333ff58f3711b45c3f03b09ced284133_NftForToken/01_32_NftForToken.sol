// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@thirdweb-dev/contracts/extension/SoulboundERC721A.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract NftForToken is SoulboundERC721A, ERC721Base {
    struct TokenUri {
        uint256 threshold; // ERC-20 balance threshold
        string uri; // tokenURI
    }
    // an array of tokenURIs
    TokenUri[] public tokenURIs;
    // the ERC-20 where balances are checked
    IERC20 public immutable token;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _token
    )
        ERC721Base(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps
        )
    {
        token = IERC20(_token);
    }

    /**
     *  @notice          Lets an authorized address mint an NFT to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     */
    function mintTo(address _to) public virtual {
        // user can only own one NFT
        require(_canMint(_to), "Not authorized to mint.");
        
        _safeMint(_to, 1, "");
    }

    /// @dev Returns whether a token can be minted in the given execution context.
    function _canMint(address _to) internal view virtual returns (bool) {
        // one nft per wallet
        return balanceOf(_to) == 0;
    }

    /**
     *  @notice Sets the tokenURIs for this contract.
     *
     *  @param  _tokenURIs An array of TokenUri structs.
     */
    function setTokenURIs(TokenUri[] memory _tokenURIs) external onlyOwner {
        // clear the tokenURIs array
        delete tokenURIs;
        uint len = _tokenURIs.length;
        // Copy the TokenUri structs from the memory array to the storage array
        for (uint i = 0; i < len; i++) {
            // require that the tokenURIs array is ordered by threshold (lowest number first)
            require(_tokenURIs[i].threshold < _tokenURIs[i + 1].threshold, "NftForToken: tokenURIs must be ordered by threshold");
            // add token URI to array
            tokenURIs.push(
                TokenUri({
                    threshold: _tokenURIs[i].threshold,
                    uri: _tokenURIs[i].uri
                })
            );
        }
    }

    /**
     *  @notice Returns the metadata URI for an NFT.
     *  @dev    See `BatchMintMetadata` for handling of metadata in this contract.
     *
     *  @param  _tokenId The tokenId of an NFT.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        // find owner of this token id
        address owner = ownerOf(_tokenId);
        // get the erc-20 balance of this owner
        uint256 balance = token.balanceOf(owner);
        // find the token URI where the threshold is greater than the balance
        for (uint256 i = 0; i < tokenURIs.length; i++) {
            if (tokenURIs[i].threshold > balance) {
                return tokenURIs[i].uri;
            }
        }
        // if no threshold is greater than the balance, return the last token URI
        return tokenURIs[tokenURIs.length - 1].uri;
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, SoulboundERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        SoulboundERC721A._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @dev Returns whether transfers can be restricted in a given execution context.
    function _canRestrictTransfers() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}