// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { Owned } from "lib/solmate/src/auth/Owned.sol";
import { ITokenURI } from "./ITokenURI.sol";

/**
 * @notice An ERC721A token that can be minted and burned by the owner.
 */
contract BondingNft is ERC721A, Owned {
    /// @notice TokenURI provider contract.
    ITokenURI public tokenURIProvider;

    constructor(string memory _name, string memory _symbol) ERC721A(_name, _symbol) Owned(msg.sender) {}

    function mint(address to) public onlyOwner returns (uint256 id) {
        _mint(to, 1);
        id = totalSupply();
    }

    function burn(uint256 id) public onlyOwner {
        _burn(id);
    }

    function setTokenURIProvider(address _tokenURIProvider) public onlyOwner {
        tokenURIProvider = ITokenURI(_tokenURIProvider);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return tokenURIProvider.tokenURI(id);
    }

    // override start token id to 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(_owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}