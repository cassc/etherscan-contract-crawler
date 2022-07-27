// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../contracts/extensions/ERC721AQueryable.sol';

contract BSOP is ERC721AQueryable, Ownable {
    constructor() ERC721A('BSOP', 'BSOP') {
    }

    function mint(uint256 quantity) external onlyOwner payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256){
        uint256 numMintedSoFar = _nextTokenId();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        if (index >= balanceOf(owner)) revert();
        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = explicitOwnershipOf(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        return 0;
    }

    function tokenByIndex(uint256 index) external view returns (uint256){
        uint256 numMintedSoFar = _nextTokenId();
        uint256 tokenIdsIdx;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = explicitOwnershipOf(i);
                if (!ownership.burned) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        revert();
    }
}