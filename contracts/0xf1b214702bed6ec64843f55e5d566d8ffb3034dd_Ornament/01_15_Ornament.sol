/**
 _____________________________________________________________
|  _________________________________________________________  | 
| |  _____________________________________________________  | |
| | |  _________________________________________________  | | |
| | | |  _____________________________________________  | | | |
| | | | |  _________________________________________  | | | | |
| | | | | |											| | | | | |
| | | | | |											| | | | | |
| | | | | |											| | | | | |
| | | | | |_________________________________________| | | | | |
| | | | |_____________________________________________| | | | |
| | | |_________________________________________________| | | |
| | |_____________________________________________________| | |
| |_________________________________________________________| |
|_____________________________________________________________|


Ornament, 2021
Jan Robert Leegte
http://www.leegte.org

"So to ward off the threat from the outside, the bad spirits, you needed to
disperse signs of humanity around you. Small friendly tokens like embroidery,
geraniums, curly woodcarvings painted in gold, silver or bright colours.
Ornaments to enchant the wilderness, to control it, to frame it, to be able to
handle it in daily life." - 2006

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { ERC721Enumerable } from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import { Base64 } from 'base64-sol/base64.sol';
import 'hardhat/console.sol';

/// @author Jake Allen & Jan Robert Leegte
contract Ornament is Ownable, ERC721Enumerable {
    using Strings for uint256;

    // Mint price & max supply
    uint256 public price = 0.23 ether;
    uint256 public maxTokens = 256;
    
    // Ornament data
    string[256] public svgData;

    // Base `external_url` in attributes
    string public baseUrl;

    // Toggle to permanently disable metadata updates
    bool public metadataFrozen;

    // Sale status. Toggle to enable minting.
    bool public saleActive = false;

    // SVG elements
    string private svgPart1 = '<svg xmlns="http://www.w3.org/2000/svg" width="800px" height="800px"><rect width="100%" height="100%" fill="silver"/><path fill="none" stroke="#444" d="';
    string private svgPart2 = '"/><path fill="none" stroke="#FFF" d="';
    string private svgPart3 = '"/></svg>';

    // Internal tokenId tracker
    uint256 private _currentId;

    // Dev address. Set to owner's address to revoke.
    address private devAddress;

    event OrnamentCreated(uint256 indexed tokenId);
    event TokenUpdated(uint256 tokenId);

    /**
     * @notice Throws if called by an account other than the owner or dev.
     */
    modifier onlyOwnerOrDev() {
        require(owner() == msg.sender || devAddress == msg.sender, "Caller is not owner or dev.");
        _;
    }

    constructor() ERC721('Ornament', unicode'▣') {
        baseUrl = "https://ornament.leegte.org/ornament.html?tokenid=";
        devAddress = 0x0EEb237e58824fa2c0836d4793aa835f99373bB7;
    }

    /**
     * @notice Update SVG and token metadata for a given tokenId.
     */
    function updateToken(
        uint256 tokenId,
        string calldata _svgData
    )
        external
        onlyOwnerOrDev
    {
        require(!metadataFrozen, "Metadata permanently frozen.");
        
        svgData[tokenId] = _svgData;
        emit TokenUpdated(tokenId);
    }

    /**
     * @notice Permanently freeze metadata updates. Caution, not reversable.
     */
    function permanentlyFreezeMetadata() external onlyOwnerOrDev {
        metadataFrozen = true;
    }

    /**
     * @notice Withdraw contract balance to owner.
     */
    function withdrawAll() external {
        uint256 amount = address(this).balance;
        require(payable(owner()).send(amount));
    }

    /**
     * @notice Update the baseUrl in case of website change.
     * @dev Forms the first part of the `external_url` field in tokenURI.
     */
    function updateBaseUrl(string calldata _baseUrl) external onlyOwnerOrDev {
        baseUrl = _baseUrl;
    }

    /**
     * @notice Disable/enable minting (but won't exceed maxTokens)
     * @dev Only callable by owner. 
     */
    function toggleSale() external onlyOwnerOrDev {
        saleActive = !saleActive;
    }

    /**
     * @notice Mint Ornaments to sender.
     */
    function mint() external payable {
        require(saleActive, "Sale not active.");
        require(totalSupply() < maxTokens, "Maximum supply reached.");
        require(msg.value >= price, "Not enough Ether sent.");

        _mint(msg.sender, _currentId);
        emit OrnamentCreated(_currentId++);
    }

    /**
     * @notice Let team mint artist prints.
     */
    function mintSpecial() external onlyOwnerOrDev {
        require(totalSupply() < maxTokens, "Maximum supply reached.");

        _mint(msg.sender, _currentId);
        emit OrnamentCreated(_currentId++);
    }

    /**
     * @notice Transfer tokenId to burn address.
     */
    function burn(uint256 tokenId) external onlyOwnerOrDev {
        _burn(tokenId);
    }

    /**
     * @notice Compose on-chain tokenURI for Ornament.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'Nonexistent token.');
        
        // Compose SVG paths and assemble final SVG
        (
            string memory polyWhitePath,
            string memory polyBlackPath,
            string memory style,
            string memory lightness
        ) = composePaths(bytes(svgData[tokenId]));
        string memory svg = Base64.encode(abi.encodePacked(
            svgPart1,
            polyWhitePath,
            svgPart2,
            polyBlackPath,
            svgPart3
        ));

        // Compose and return base 64 encoded JSON string
        string memory json = packJSONString(tokenId, svg, style, lightness, baseUrl);
    
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    /**
     * @notice Compose both SVG path values from data string.
     */
    function composePaths(bytes memory svgBytes)
        internal
        pure
        returns(string memory, string memory, string memory, string memory)
    {
        string memory polyWhitePath = 'M0 0';
        string memory polyBlackPath = 'M0 0';
        string memory firstChars;
        uint256 offset;
        uint256 length;

        // Iterate over 4 byte chunks and compose path strings
        for (uint256 i = 4; i < svgBytes.length; i+=4) {
            // Convert first 3 bytes to uint256 to get `length` and `offset`
            firstChars = string(abi.encodePacked(svgBytes[i], svgBytes[i+1], svgBytes[i+2]));
            offset = strToUint(firstChars); 
            length = 800 - (2 * offset);

            // Compose path strings
            if (svgBytes[i + 3] == 'n') {
                polyBlackPath = string(abi.encodePacked(polyBlackPath, ' M', uintToStr(offset), ' ', uintToStr(offset + length), ' V', uintToStr(offset), ' H', uintToStr(offset + length)));
                polyWhitePath = string(abi.encodePacked(polyWhitePath, ' M', uintToStr(offset), ' ', uintToStr(offset + length), ' H', uintToStr(offset + length), ' V', uintToStr(offset)));
            }

            if (svgBytes[i + 3] == 'p') {
                polyBlackPath = string(abi.encodePacked(polyBlackPath, ' M', uintToStr(offset), ' ', uintToStr(offset + length), ' H', uintToStr(offset + length), ' V', uintToStr(offset)));
                polyWhitePath = string(abi.encodePacked(polyWhitePath, ' M', uintToStr(offset), ' ', uintToStr(offset + length), ' V', uintToStr(offset), ' H', uintToStr(offset + length)));
            }
            
        }

        // Calculate attributes
        // Frame width is first 4 bytes of string
        uint256 totalLeftMargins = strToUint(string(abi.encodePacked(svgBytes[0], svgBytes[1], svgBytes[2], svgBytes[3])));
        string memory style;
        // Total bevels is the length of our SVG bytes, minus the first four (which
        // are for totalLeftMargins), divided by our 4 byte chunks
        string memory lightness = (totalLeftMargins / ((svgBytes.length - 4) / 4)).toString();

        if (totalLeftMargins < 120) {
            style = 'sharp';
        } else if (120 <= totalLeftMargins && totalLeftMargins < 300) {
            style = 'robust';
        } else if (totalLeftMargins >= 300) {
            style = 'monumental';
        }

        return (polyWhitePath, polyBlackPath, style, lightness);
    }

    /**
     * @notice Compose the final base 64 encoded JSON to return from `tokenURI`.
     */
    function packJSONString(
        uint256 tokenId,
        string memory encodedSVG,
        string memory style,
        string memory lightness,
        string memory _baseUrl
    )
        internal
        pure
        returns (string memory)
    {
        string memory name = string(abi.encodePacked('Ornament No. ', tokenId.toString()));
        string memory description = string(abi.encodePacked('Ornament is swapping the actors. The frame becoming the content. Ornament is an on-chain deterministically generated SVG. No. ', tokenId.toString(), ' / 256'));
        
        return Base64.encode(abi.encodePacked(
            '{"name":"', name, '", "description":"', description, '", "image":"data:image/svg+xml;base64,', encodedSVG, '", "attributes":[{"trait_type":"Style","value":"', style,'"}, {"trait_type": "Lightness", "value":"', lightness,'"}]', bytes(_baseUrl).length > 0 ? string(abi.encodePacked(', "external_url":"', _baseUrl,tokenId.toString(), '"')) : "",' }'
        ));
    }

    /**
     * @notice Utility to convert string to uint256.
     */
    function strToUint(string memory _str) internal pure returns(uint256 res) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
                return 0;
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
        }
        return res;
    }

    /**
     * @notice Utility to convert uint256 to string.
     */
    function uintToStr(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @notice Update dev address. To revoke, set to owner's address.
     */
    function updateDevAddress(address _address) external onlyOwnerOrDev {
        devAddress = _address;
    }

}