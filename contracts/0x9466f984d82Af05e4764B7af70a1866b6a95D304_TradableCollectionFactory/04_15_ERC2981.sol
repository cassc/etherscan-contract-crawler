// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC2981.sol";

/// @dev a contract adding ERC2981 support to ERC721 and ERC1155
contract ERC2981 is ERC165, IERC2981 {

    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    RoyaltyInfo public royalties;

    constructor(address recipient, uint24 basispoints) {
        setRoyalties(recipient, basispoints);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function setRoyalties(address recipient, uint24 basispoints) internal {
        require(basispoints <= 10000, "ERC2981: royalty basispoints too high");
        royalties.recipient = recipient;
        royalties.amount = basispoints;
    }

    function royaltyInfo(uint, uint salePrice) external view override returns (address receiver, uint royaltyAmount) {
        receiver = royalties.recipient;
        royaltyAmount = (salePrice * royalties.amount) / 10000;
    }
}