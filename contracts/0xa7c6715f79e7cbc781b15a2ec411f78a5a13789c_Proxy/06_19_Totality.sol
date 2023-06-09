// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./ERC1967/ERC1967ProxyImplementation.sol";
import "./OpenSea/ERC721Tradable.sol";


contract Totality is ProxyImplementation, ERC721Tradable
{
    string public _htmlPrefix;
    string public _htmlPostfix;
    string public _baseUri;

    function init(
        string memory name, 
        string memory symbol,
        address proxyRegistryAddress,
        string memory htmlPrefix,
        string memory htmlPostfix,
        string memory baseUri) 
        public onlyAdmin initializer
    {
        _initializeEIP712(name);
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __ERC721Tradable_init_unchained(proxyRegistryAddress);

        _htmlPrefix = htmlPrefix;
        _htmlPostfix = htmlPostfix;
        _baseUri = baseUri;
    }

    function getTokenHtmlForHash(bytes32 hash) public view returns(string memory)
    {
        return string(abi.encodePacked(
            _htmlPrefix, 
            StringsUpgradeable.toHexString(uint256(hash)), 
            _htmlPostfix));
    }

    function getTokenHtml(uint256 tokenId) public view returns(string memory)
    {
        require(_exists(tokenId), "Token doesn't exist");
        
        return getTokenHtmlForHash(keccak256(abi.encodePacked("Totality.Tsukamoto.Hideki", tokenId)));
    }

    function _escapedHtml(string memory rawString) private view returns(string memory)
    {
        bytes memory escapedComma = "&#44;";
        bytes memory rawStringBytes = bytes(rawString);
        bytes memory escapedStringBytes = new bytes(rawStringBytes.length + 8000); // a bit hacky but we know there's ~2000 commas in the source, buffer will resize though if needed
        uint256 escapedStringBytesAvailable = escapedStringBytes.length;
        
        uint256 n = rawStringBytes.length;
        uint256 start = 0;
        uint256 end = 0;
        while (end < n)
        {
            if (rawStringBytes[end] == ',')
            {
                uint256 sliceLength = end - start;
                
                if ((sliceLength + 5) > escapedStringBytesAvailable)
                {
                    bytes memory newEscapedStringBytes = new bytes(escapedStringBytes.length + sliceLength + 1000);
                    uint256 escapedStringBytesUsed = escapedStringBytes.length - escapedStringBytesAvailable;
                    
                    assembly
                    {
                        pop(staticcall(gas(), 0x4, add(escapedStringBytes, 32), escapedStringBytesUsed, add(escapedStringBytes, 32), escapedStringBytesUsed))
                    }
                    
                    escapedStringBytes = newEscapedStringBytes;
                    escapedStringBytesAvailable = escapedStringBytes.length - escapedStringBytesUsed;
                }
                
                uint256 dst = escapedStringBytes.length - escapedStringBytesAvailable;
                escapedStringBytesAvailable -= (sliceLength + 5);
                
                assembly
                {
                    pop(staticcall(gas(), 0x4, add(add(rawStringBytes, 32), start), sliceLength, add(add(escapedStringBytes, 32), dst), sliceLength))
                    pop(staticcall(gas(), 0x4, add(escapedComma, 32), 5, add(add(add(escapedStringBytes, 32), dst), sliceLength), 5))
                }
                
                start = end + 1;
            }
            ++end;
        }
        if (start != end)
        {
            uint256 sliceLength = end - start;
                
            if (sliceLength > escapedStringBytesAvailable)
            {
                bytes memory newEscapedStringBytes = new bytes(escapedStringBytes.length + sliceLength);
                uint256 escapedStringBytesUsed = escapedStringBytes.length - escapedStringBytesAvailable;
                
                assembly
                {
                    pop(staticcall(gas(), 0x4, add(escapedStringBytes, 32), escapedStringBytesUsed, add(escapedStringBytes, 32), escapedStringBytesUsed))
                }
                
                escapedStringBytes = newEscapedStringBytes;
                escapedStringBytesAvailable = escapedStringBytes.length - escapedStringBytesUsed;
            }
            
            uint256 dst = escapedStringBytes.length - escapedStringBytesAvailable;
            escapedStringBytesAvailable -= sliceLength;
            
            assembly
            {
                pop(staticcall(gas(), 0x4, add(add(rawStringBytes, 32), start), sliceLength, add(add(escapedStringBytes, 32), dst), sliceLength))
            }
        }
        
        return string(escapedStringBytes);
    }

    function getEscapedTokenHtmlForHash(bytes32 hash) public view returns(string memory)
    {
        return _escapedHtml(getTokenHtmlForHash(hash));
    }

    function getEscapedTokenHtml(uint256 tokenId) public view returns(string memory)
    {
        return _escapedHtml(getTokenHtml(tokenId));
    }

    function _encodeBase64(string memory rawString) private pure returns(string memory)
    {
        bytes memory rawStringBytes = bytes(rawString);
        string memory base64String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        bytes memory base64Bytes = bytes(base64String);
        
        uint256 bitCount = rawStringBytes.length * 8;
        uint256 encodedStringLength = bitCount / 6;
        
        // ceil the result
        if (bitCount % 6 != 0)
        {
            ++encodedStringLength;
        }
        
        // add space for padding
        uint256 remainder = encodedStringLength % 4;
        if (remainder != 0)
        {
            encodedStringLength += 4 - remainder;
        }
        bytes memory encodedStringBytes = new bytes(encodedStringLength);
        
        uint256 encodedIdx = 0;
        for (uint256 i = 0; i < rawStringBytes.length; i += 3)
        {
            uint256 bytesRemaining = rawStringBytes.length - i;
            uint256 a = uint256(uint8(rawStringBytes[i]));
            uint256 b;
            uint256 c;
            
            if (bytesRemaining > 1)
            {
                b = uint256(uint8(rawStringBytes[i + 1]));
            }
            if (bytesRemaining > 2)
            {
                c = uint256(uint8(rawStringBytes[i + 2]));
            }
            
            encodedStringBytes[encodedIdx] = base64Bytes[((a & 0xFC) >> 2)];
            encodedStringBytes[encodedIdx + 1] = base64Bytes[((a & 0x3) << 4) | ((b & 0xF0) >> 4)];
        	
        	if (bytesRemaining > 1)
        	{
                encodedStringBytes[encodedIdx + 2] = base64Bytes[((b & 0xF) << 2) | ((c & 0xC0) >> 6)];
        	}
        	else
        	{
        	    encodedStringBytes[encodedIdx + 2] = '=';
        	}
        	
        	if (bytesRemaining > 2)
        	{
        	    encodedStringBytes[encodedIdx + 3] = base64Bytes[(c & 0x3F)];
        	}
        	else
        	{
        	    encodedStringBytes[encodedIdx + 3] = '=';
        	}
        	
        	encodedIdx += 4;
        }
        
        return string(encodedStringBytes);
    }

    function getTokenHtmlBase64ForHash(bytes32 hash) public view returns(string memory)
    {
        return _encodeBase64(getTokenHtmlForHash(hash));
    }

    function getTokenHtmlBase64(uint256 tokenId) public view returns(string memory)
    {
        return _encodeBase64(getTokenHtml(tokenId));
    }

    function _getURI(string memory base64) private pure returns(string memory)
    {
        return string(abi.encodePacked("data:text/html;base64,", base64));
    }

    function getTokenHtmlURIForHash(bytes32 hash) public view returns(string memory)
    {
        return _getURI(getTokenHtmlBase64ForHash(hash));
    }

    function getTokenHtmlURI(uint256 tokenId) public view returns(string memory)
    {
        return _getURI(getTokenHtmlBase64(tokenId));
    }

    function _getEscapedURI(string memory base64) private pure returns(string memory)
    {
        return string(abi.encodePacked("data:text/html;base64&#44;", base64));
    }

    function getTokenHtmlEscapedURIForHash(bytes32 hash) public view returns(string memory)
    {
        return _getEscapedURI(getTokenHtmlBase64ForHash(hash));
    }

    function getTokenHtmlEscapedURI(uint256 tokenId) public view returns(string memory)
    {
        return _getEscapedURI(getTokenHtmlBase64(tokenId));
    }

    function mint(address to, uint256 tokenId) public onlyAdmin
    {
        _safeMint(to, tokenId);   
    }

    function mintBatch(address[] memory to, uint256 firstTokenId) public onlyAdmin
    {
        for (uint256 i = 0; i < to.length; ++i)
        {
            _safeMint(to[i], firstTokenId + i);
        }
    }

    function setHtmlPrefix(string memory htmlPrefix) public onlyAdmin
    {
        _htmlPrefix = htmlPrefix;
    }

    function setHtmlPostfix(string memory htmlPostfix) public onlyAdmin
    {
        _htmlPostfix = htmlPostfix;
    }

    function setBaseUri(string memory baseUri) public onlyAdmin
    {
        _baseUri = baseUri;
    }

    function _baseURI() override internal view virtual returns (string memory)
    {
        return _baseUri;
    }
}