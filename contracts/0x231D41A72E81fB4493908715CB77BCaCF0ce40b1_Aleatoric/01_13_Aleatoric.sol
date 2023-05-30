// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 *
 *
 *            ,ggg,                                                                          
 *           dP""8I   ,dPYb,                       I8                                        
 *          dP   88   IP'`Yb                       I8                                        
 *         dP    88   I8  8I                    88888888                       gg            
 *        ,8'    88   I8  8'                       I8                          ""            
 *        d88888888   I8 dP   ,ggg,     ,gggg,gg   I8     ,ggggg,   ,gggggg,   gg     ,gggg, 
 *       ,8"     88   I8dP   i8" "8i   dP"  "Y8I   I8    dP"  "Y8gggdP""""8I   88    dP"  "Yb
 * dP   ,8P      Y8   I8P    I8, ,8I  i8'    ,8I  ,I8,  i8'    ,8I ,8'    8I   88   i8'      
 * Yb,_,dP       `8b,,d8b,_  `YbadP' ,d8,   ,d8b,,d88b,,d8,   ,d8',dP     Y8,_,88,_,d8,_    _
 *  "Y8P"         `Y88P'"Y88888P"Y888P"Y8888P"`Y88P""Y8P"Y8888P"  8P      `Y88P""Y8P""Y8888PP
 *
 * 
 * Aleatoric
 *   a conceptual hijink by one of the many matts (@1ofthemanymatts) and Evan Casey (@ev_ancasey)
 * 
 * Aleatoric is an experiment in—and interrogation of—artistic intentionality, digital scarcity, and serendipity.
 * As the artist, I have no direct control over the scarcity or abundance of the work, nor what it is titled, looks like, or sounds like.
 * 
 * gm and, most importantly, gn.
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Aleatoric
 * @author @shrugs
 * @notice A simple ERC721 token.
 * @dev I believe in the freedom to destroy what you own, so this token is Burnable.
 * @dev Implements EIP-2981 for royalties.
 */
contract Aleatoric is Context, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    
    Counters.Counter private _ids;
    mapping(uint256 => string) private _uris;
    address public beneficiary;

    constructor(address _beneficiary) ERC721("Aleatoric", "ZZZ") {
        beneficiary = _beneficiary;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return _uris[tokenId];
    }

    function mint(address to, string memory uri_) public onlyOwner returns (uint256) {
        uint256 tokenId = _ids.current();
        
        _uris[tokenId] = uri_;
        _mint(to, tokenId);
        
        _ids.increment();
        
        return tokenId;
    }
    
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        
        if (bytes(_uris[tokenId]).length != 0) {
            delete _uris[tokenId];
        }
    }
    
    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
        return (beneficiary, _salePrice * 5 / 100); // constant 5% royalties
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }
}