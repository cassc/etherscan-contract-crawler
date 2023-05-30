// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Managable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

abstract contract SetInBaseERC721 is ERC721Enumerable, Managable, IERC2981 {

    address public royaltyReceiver;
    uint public royaltyFraction;
    string public baseURI;

    constructor(string memory _name, 
                string memory _symbol,
                string memory _baseURI,
                address _royaltyReceiver, 
                uint _royaltyFraction) ERC721(_name, _symbol) {
                    
     royaltyReceiver = _royaltyReceiver;
     royaltyFraction = _royaltyFraction;
     baseURI = _baseURI;
    }

    /**
     * Public
     */

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {

        uint256 royaltyAmount = (_salePrice * royaltyFraction) / 10000;
        return (royaltyReceiver, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, IERC165) returns (bool) {

        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * Only manager
     */
    
    function setBaseURI(string memory _baseURI) external onlyManager {

        baseURI = _baseURI;
    }

    /**
     * Only owner
     */

    function setRoyaltyData(address _royaltyReceiver, uint _royaltyFraction) external onlyOwner {

        royaltyReceiver = _royaltyReceiver;
        royaltyFraction = _royaltyFraction;
    }

    /**
     * Internal
     */

    function _baseURI() internal view virtual override returns (string memory) {

        return baseURI;
    }
}