/*                                                                                                                                                                                                    
        .lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkl.                                                                                
        .lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkl.                                                                                
        .lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkl.                                                                                
        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                                                
        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                                                
        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                                                
        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                                                
        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                                                
        .kNNNNNNNNNNNNNNNNNNNNNNNWMMMMMMMMMMMMO.                                                                                
         .'''...................;OMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xMMMMMMMMMMMMO.                                                                                
                                .xWMMMMMMMMMMMO.                                                                                
                                .xWMMMMMMMMMMMO.                                                                                
        .cddddddddddddddddddddddxXMMMMMMMMMMMMO.                                                                                
        '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                                                
        '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                                                
        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                                                
        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                                                
        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                                                
        .OWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWO.                                                                                
         ',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'                                                                                 
                                                                                                                                                                                                                                                                                                                                                                                                                
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
 

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";


import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


contract JaduHoverboard is ERC721Enumerable, AccessControl, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string _baseTokenURI = "https://api.jadu.ar/token/";

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public upgradedToAddress = address(0);
    uint256 internal _cap = 6666;


    constructor() ERC721("Jadu Hoverboard", "Hoverboard")  {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function upgrade(address _upgradedToAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        
        upgradedToAddress = _upgradedToAddress;
    }

    function getCurrentTokenId() public view returns (uint256) {
        return _tokenIds.current();
    }

    function cap() external view returns (uint256) {
        return _cap;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");

        _baseTokenURI = baseURI;
    }

    function mintNextToken(address _mintTo) external returns (bool) {
        _tokenIds.increment();
        return mint(_mintTo, _tokenIds.current());
    }

    function mint(address _mintTo, uint256 _tokenId) public returns (bool) {
        require(address(0) == upgradedToAddress, "Contract has been upgraded to a new address");
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        require(_mintTo != address(0), "ERC721: mint to the zero address");
        require(!_exists(_tokenId), "ERC721: token already minted");

        require(_tokenId <= _cap, "Cap reached, maximum 6666 mints possible");
        
        _mint(_mintTo, _tokenId);

        return true;
    }

}