// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC721AUpgradeableInternal } from "./../ERC721AUpgradeableContracts/ERC721AUpgradeableInternal.sol";

contract BurnFacet is ERC721AUpgradeableInternal {
    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }
    
    function burnMultiple(uint256[] memory tokenIds) public {
        for (uint256 i; i < tokenIds.length; ) {
            _burn(tokenIds[i], true);

            unchecked {
                ++i;
            }
        }
    }
}