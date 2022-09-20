// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title Implementation of IERC721Enumerable, meant to be used as staked version of a NFT. 
 *
 * @dev Reduces gas cost for minting and burning by using staked tokens enumerator for {tokenByIndex} and {totalSupply} 
 * and making {tokenOfOwnerByIndex} and {tokensOfOwner} very inefficient.
 * Only use {tokenOfOwnerByIndex} and {tokensOfOwner} these methods in view methods!
 * 
 * This contract assumes to be used with {_stake} and {_unstake} method, do not use {_burn} or {_mint}, {_safeMint}
 * methods directly, as they will break the enumeration assumptions.
 *
 * @author Fab
 */
abstract contract ERC721Staked is ERC721, IERC721Enumerable, IERC721Receiver, Ownable {
    
    IERC721Enumerable private stakedToken;
    string private baseURI;

    constructor(IERC721Enumerable _stakedToken) {
        stakedToken = _stakedToken;
    }


    /**
     * @notice Allows the owner to set the base URI to be used for all not revealed token IDs
     * @param _uri: base URI
     * @dev Callable by owner
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
    
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view override returns (uint256) {
        return stakedToken.balanceOf(address(this));
    }

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     * @dev Warning: This function is very inefficient and is meant to be accessed in view read methods only.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256 tokenId) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

        uint256 indexOfOwner;
        uint256 _totalSupply = totalSupply();
        for (uint256 i = 0; i < _totalSupply; ++i) {
            tokenId = tokenByIndex(i);
            if (ownerOf(tokenId) == owner) {
                if (indexOfOwner == index) return tokenId;
                indexOfOwner++;
            }
        }
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        return stakedToken.tokenOfOwnerByIndex(address(this), index);
    }

    /**
     * @notice Returns all tokenIds owned by `_owner`
     * @param _owner: owner
     * @dev Warning: This function is very inefficient and is meant to be accessed in view read methods only.
     */
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);
        uint256 index;

        uint256 _totalSupply = totalSupply();
        for (uint256 i = 0; i < _totalSupply && index < tokenCount; ++i) {
            uint256 tokenId = tokenByIndex(i);
            if (ownerOf(tokenId) == _owner) {
                result[index++] = tokenId;
            }
        }
        return result;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received} 
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        require(msg.sender == address(stakedToken), "Only staked token");
        return this.onERC721Received.selector;
    }

    /** 
     * @dev Stake `tokenId` by transfering them from `from' to this contract 
     * and minting equivalent tokenId of this token. 
     */
    function _stake(address from, address to, uint256 tokenId) internal {
        if (from != address(this)) {
            stakedToken.safeTransferFrom(from, address(this), tokenId);
        } else {
            require(stakedToken.ownerOf(tokenId) == address(this), "Not owner");
        }
        super._safeMint(to, tokenId);
    }

    /** 
     * @dev Stake `tokenId` by transfering them from `from' to this contract 
     * and minting equivalent tokenId of this token. 
     */
    function _unstake(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Not owner");
        super._burn(tokenId);
        stakedToken.safeTransferFrom(address(this), to, tokenId);
    }

    /**
     * @dev See {ERC721-_baseURI}
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}