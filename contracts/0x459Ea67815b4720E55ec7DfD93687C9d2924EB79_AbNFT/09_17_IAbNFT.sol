// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OpenZeppelin
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**************************************

    Minter interface

 **************************************/

interface IAbNFT is IERC721Enumerable {

    // external functions
    function mint(uint256[] calldata _nftIds, address _owner) external;
    function reveal(uint256 _range, string memory _revealedURI, uint256 _toClaim) external;
    function vestedClaim(uint256[] calldata _nftIds, address _owner) external;

}