// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTWrapper is ERC721Holder {
    IERC721 public stakedNFT;

    mapping(address => uint256[]) private addressToTokenId;
    mapping(uint256 => address) private tokenIdOwner;

    function ownerOfNFT(uint256 tokenId) public view virtual returns (address) {
        return tokenIdOwner[tokenId];
    }

    function balanceOfNFT(address account) public view returns (uint256) {
        return addressToTokenId[account].length;
    }

    function addressToToken(address account)
        public
        view
        returns (uint256[] memory)
    {
        return addressToTokenId[account];
    }

    function tokenToAddress(address account, uint256 tokenId) internal {
        addressToTokenId[account].push(tokenId);
    }

    function removeTokenId(address account, uint256 tokenId) internal {
        uint256 i = 0;
        while (addressToTokenId[account][i] != tokenId) {
            i++;
        }
        while (i < addressToTokenId[account].length - 1) {
            addressToTokenId[account][i] = addressToTokenId[account][i + 1];
            i++;
        }
        addressToTokenId[account].pop();
    }

    function stakeNFT(address account, uint256 tokenId) internal {
        // transfer NFT to this contract
        stakedNFT.safeTransferFrom(account, address(this), tokenId);

        // add entry for tokenIdOwner
        tokenIdOwner[tokenId] = account;
        tokenToAddress(account, tokenId);
    }

    function unstakeNFT(address account, uint256 tokenId) internal{
        require(tokenIdOwner[tokenId] == account, "NOT OWNER OF NFT");

        delete tokenIdOwner[tokenId];
        removeTokenId(account, tokenId);
        stakedNFT.safeTransferFrom(address(this), account, tokenId);
    }
}