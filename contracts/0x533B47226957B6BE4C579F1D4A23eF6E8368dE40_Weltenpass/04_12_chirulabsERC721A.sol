// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

contract chirulabsERC721A is ERC721A, ERC2981, Ownable {
    using SafeMath for uint256;

    /**
     * @param name The NFT collection name
     * @param symbol The NFT collection symbol
     * @param receiver The wallet address to recieve the royalties
     * @param feeNumerator Numerator of royalty % where Denominator default is 10000
     */
    constructor (
        string memory name, 
        string memory symbol,
        address receiver,
        uint96 feeNumerator
        ) 
        ERC721A(name, symbol) 
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
        interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
        interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
        interfaceId == type(IERC2981).interfaceId; 
    }
}