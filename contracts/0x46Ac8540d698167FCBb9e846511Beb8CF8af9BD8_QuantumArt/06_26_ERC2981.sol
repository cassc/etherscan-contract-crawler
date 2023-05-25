//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ERC2981 is IERC2981, ERC165 {

    /*
    % * 10000
    example : 5% -> 0.05 * 10000
    */
    uint256 internal royaltyFee;

    function setRoyalteFee(uint256 fee) public virtual;

    function royaltyInfo(uint256 tokenId,uint256 salePrice) public virtual override(IERC2981) view returns (
        address receiver,
        uint256 royaltyAmount
    );

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}