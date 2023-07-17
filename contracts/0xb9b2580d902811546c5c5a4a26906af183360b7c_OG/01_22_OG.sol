/*

     OOOOOOOOO                  GGGGGGGGGGGGG
   OO:::::::::OO             GGG::::::::::::G
 OO:::::::::::::OO         GG:::::::::::::::G
O:::::::OOO:::::::O       G:::::GGGGGGGG::::G
O::::::O   O::::::O      G:::::G       GGGGGG
O:::::O     O:::::O     G:::::G              
O:::::O     O:::::O     G:::::G              
O:::::O     O:::::O     G:::::G    GGGGGGGGGG
O:::::O     O:::::O     G:::::G    G::::::::G
O:::::O     O:::::O     G:::::G    GGGGG::::G
O:::::O     O:::::O     G:::::G        G::::G
O::::::O   O::::::O      G:::::G       G::::G
O:::::::OOO:::::::O       G:::::GGGGGGGG::::G
 OO:::::::::::::OO         GG:::::::::::::::G
   OO:::::::::OO             GGG::::::GGG:::G
     OOOOOOOOO                  GGGGGG   GGGG
     
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';
import './interfaces/GotTokenInterface.sol';
import './interfaces/OGColorInterface.sol';
import './libs/Customizer.sol';
import './libs/Digits.sol';
import './ERC/HumbleERC721Enumerable.sol';

/**
 * @title OG
 * @author nfttank.eth
 * OG is a free, vector based NFT that is rendered on-chain. OG tokens represent numbers from 0-10000 and are licensed
 * under a public domain CC0 license. Feel free to use your OG tokens in any way you want.
 * Thank you for being a number with me.
 */
contract OG is HumbleERC721Enumerable, Ownable {

    mapping(address => string) private _supportedSlugs;
    mapping(string => address) private _trustedContracts;
    address[] private _supportedCollections;
    bool private _paused;
    uint16 private _unlockSupply;
    uint256 private _currentId = 12; // increases, starting with 13
    uint256 private _currentDozenId = 13; // decreases, starting with 12

    constructor() ERC721("OG", "OG") Ownable() {
        _trustedContracts["gottoken"] = address(0);
        _trustedContracts["ogcolor"] = address(0);
        _paused = true;
        _unlockSupply = 5000;
    }

    function setPaused(bool paused) external onlyOwner {
        _paused = paused;
    }

    function setUnlockSupply(uint16 unlockSupply) external onlyOwner {
         _unlockSupply = unlockSupply;
    }

    function addSupportedCollection(address contractAddress) external onlyOwner {
         _supportedCollections.push(contractAddress);
    }

    function clearSupportedCollections() external onlyOwner {
         delete _supportedCollections;
    }
    
    function setSupportedCollectionSlug(address contractAddress, string calldata svgSlug) external onlyOwner {
        _supportedSlugs[contractAddress] = svgSlug;
    }

    function setSupportedCollectionSlugBase64(address contractAddress, string calldata base64EncodedSvgSlug) external onlyOwner {
        _supportedSlugs[contractAddress] = string(Base64.decode(base64EncodedSvgSlug));
    }

    function setTrustedContractAddresses(address gotTokenAddress, address ogColorAddress) external onlyOwner {
        _trustedContracts["gottoken"] = gotTokenAddress;
        _trustedContracts["ogcolor"] = ogColorAddress;
    }
    
    function renderSvg(uint256 tokenId) public virtual view returns (string memory) {
        require(tokenId >= 0 && tokenId <= 9999, "Token Id invalid");
        
        (string memory back, string memory frame, string memory digit, string memory slug)
            = Customizer.getColors(this, _trustedContracts["ogcolor"], tokenId);
        
        address supportedCollection = Customizer.getOwnedSupportedCollection(this, _trustedContracts["gottoken"], _supportedCollections, tokenId);
        bool hasCollection = supportedCollection != address(0);

        string[8] memory parts;

        parts[0] = "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='1000' height='1000' viewBox='0 0 1000 1000'>";
        
        // OGColor delivers whole definitions like <linearGradient id='back'><stop stop-color='#FFAAFF'/></linearGradient>
        parts[1] = string(abi.encodePacked("<defs>", back, frame, digit, slug, "</defs>"));
        parts[2] = "<mask id='_mask'>";
        
        if (hasCollection)
            parts[3] = "<path id='path-0' d='M 504.28 105.614 C 804.145 105.541 991.639 430.111 841.768 689.836 C 691.898 949.563 317.067 949.655 167.072 690 C 26.805 447.185 181.324 140.169 459.907 108.16 Z' style='fill: none;'/>";
        else
            parts[3] = "";
            
        // don't apply colors on this string, this should be kept white
        parts[4] = string(abi.encodePacked("<circle cx='500' cy='500' r='450' fill='#ffffff' stroke='none' /></mask><circle cx='500' cy='500' r='450' fill='url(#back)' mask='url(#_mask)' stroke-width='130' stroke='url(#frame)' stroke-linejoin='miter' stroke-linecap='square' stroke-miterlimit='3' />"));

        parts[5] = Digits.generateDigits(tokenId);
          
        if (hasCollection)  
            parts[6] = _supportedSlugs[supportedCollection];
        else
            parts[6] = "";
            
        parts[7] = "</svg>";
        
        return string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
    }
    
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(tokenId >= 0 && tokenId <= 9999, "Token Id invalid");
    
        string memory colorAttributes = Customizer.getColorAttributes(this, _trustedContracts["ogcolor"], tokenId);

        string memory attributes = string(abi.encodePacked(
            '"attributes": [',
            colorAttributes, 
            bytes(colorAttributes).length > 0 ? ', ' : '',
            '{ "trait_type": "Tier", "value": "', tier(tokenId), '" }'
            ']'));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "OG #', Strings.toString(tokenId), '", "description": "OG by Tank", ', attributes, ', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(renderSvg(tokenId))), '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function tier(uint256 tokenId) public pure returns (string memory) {
        require(tokenId >= 0 && tokenId <= 9999, "Token Id invalid");

        if (tokenId == 42 || tokenId == 69 || tokenId == 420 || tokenId == 666 || tokenId == 1337)
            return 'Meme';
        else if (tokenId == 33 || tokenId == 888 || tokenId == 2745 || tokenId == 3178 || tokenId == 4156 || tokenId == 6529)
            return 'Honorary';
        else if (tokenId > 0 && tokenId < 13)
            return 'OG Dozen';
        else if (tokenId < 1)
            return 'Glitch';

        return 'OG';
    }

    function mint(uint16 count) public {

        require(!_paused, "Minting is paused");
        require(_currentId < 9999, "Maximum amount of sequential mints reached");

        address sender = _msgSender();
        
        if (sender != owner()) {
            require(count > 0 && count <= 10, "Minting is limited to max. 10 per wallet");
            require(balanceOf(sender) + count <= 10, "Minting is limited to max. 10 per wallet");
        }            

        for (uint16 i = 0; i < count; i++) {
            uint256 newId = ++_currentId;
            if (newId <= 9999) {
                _safeMint(sender, newId);
            }
        }
    }

    function mintOgDozen() public {

        require(!_paused, "Minting is paused");
        require(canMintOgDozen(), "Unlock supply has not yet been reached to mint OG dozen tokens.");

        require(_currentDozenId > 0+1 && _currentDozenId <= 12+1, "No OG dozen tokens available anymore");

        address sender = _msgSender();
        
        if (sender != owner())
            require(balanceOf(sender) + 1 <= 10, "Minting is limited to max. 10 per wallet");

        _safeMint(sender, --_currentDozenId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function canMintOgDozen() public view returns (bool) {
        return totalSupply() >= _unlockSupply && !_exists(1);
    }
}