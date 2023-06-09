// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import './Base64.sol';
import './Utils.sol';


contract CryptoDuckies is ERC721Enumerable, Ownable {
    bytes[119] private _assets;
    uint256[1250] private _tokensData;

    bool public canMigrate;
    bool public isSealed;

    uint256 private constant ERC1155_ADDRESS0 = 0xa4a236d97a2afa4b37693e5df8aa5afc68c42cd1000000000000000000000001;
    uint256 private constant ERC1155_ADDRESS1 = 0x877ac19ddc87391373cc71e25ee8e6e14f237ae5000000000000000000000001;
    address private constant OPENSEA_OPENSTORE = address(0x495f947276749Ce646f68AC8c248420045cb7b5e);
    address private constant OPENSEA_PROXYREGISTRY = address(0xa5409ec958C83C3f309868babACA7c86DCB077c1);

    address private constant BURN = address(0x000000000000000000000000000000000000dEaD);

    

    constructor() ERC721("CryptoDuckies", "DUCKIE") {}

    modifier validTokenId(uint256 tokenId) {
        require(tokenId >= 1 && tokenId <= 5000, "Not a valid token number");
        _;
    }

    modifier migrating() {
        require(canMigrate, "Migration has not started");
        _;
    }

    modifier unsealed() {
        require(!isSealed, "Contract is sealed");
        _;
    }

    
    function setAsset(uint256 index, bytes calldata encodedAsset) external onlyOwner unsealed {
        unchecked {
            _assets[index-1] = encodedAsset;
        }
    }

    function setTokens(uint256 index, uint256[] calldata encodedTokens) external onlyOwner unsealed {
        unchecked {
            uint length = encodedTokens.length;
            for (uint i=0; i<length; i++) {
                _tokensData[index] = encodedTokens[i];
                index++;
            }
        }
    }

    function seal() external onlyOwner {
        isSealed = true;
    }

    function flipMigration() external onlyOwner {
        canMigrate = !canMigrate;
    }

   
    function _tokenData(uint256 tokenId) private view validTokenId(tokenId) returns (uint256 tokenData) {
        unchecked {
            uint256 index = tokenId-1;
            tokenData = _tokensData[index >> 2] >> (((index & 3) << 6)+15);
        }
    }

    function _traits(uint256 tokenData) private view returns (string memory text) {
        bytes memory buffer = new bytes(320); // create a big enough buffer to store the maximum amount of traits
        assembly {
            mstore(buffer, 0) // set initial length to 0
        }
        unchecked {
            bytes32 trait_start = bytes32('[{"trait_type":"');
            for (uint j = 0; j < 7; j++) {
                uint256 assetIndex = tokenData & 0x7f;
                if (assetIndex == 0) {
                    break;
                }

                bytes storage asset = _assets[assetIndex-1];
                uint256 trait;
                assembly {
                    trait := sload(asset.slot)
                    if eq(and(trait, 1), 1) {
                        mstore(0, asset.slot)
                        trait := sload(keccak256(0, 32))
                    }
                }
                trait <<= 8; // first byte is offset to image data
                uint256 strLength = trait >> 248;
                if (strLength > 0) {
                    Utils.appendString(buffer, trait_start, 16);
                    trait_start = bytes32(',{"trait_type":"');

                    // append trait type
                    trait <<= 8;
                    Utils.appendString(buffer, trait, strLength);
                    trait <<= strLength << 3;

                    Utils.appendString(buffer, bytes32('","value":"'), 11);

                    // append trait value
                    strLength = trait >> 248;
                    trait <<= 8;
                    Utils.appendString(buffer, trait, strLength);

                    Utils.appendString(buffer, bytes32('"}'), 2);
                }

                tokenData >>= 7;
            }
            
            Utils.appendString(buffer, bytes32(']'), 1);
        }

        return string(buffer);
    }

    function _imagePixels(uint256 tokenData, bool premultipliedAlpha) private view returns (bytes memory pixels) {
        pixels = new bytes(2304);
        unchecked {
            bool hasAlpha = false;
            for (uint j = 0; j < 6; j++) {
                tokenData >>= 7;
                uint256 assetIndex = tokenData & 0x7f;
                if (assetIndex == 0) {
                    break;
                }
                hasAlpha = Utils.blend(pixels, _assets[assetIndex-1]) || hasAlpha;
            }
            if (hasAlpha && !premultipliedAlpha) {
                Utils.unpremultiplyingAlpha(pixels);
            }
        }
    }

    function _backgroundColor(uint256 tokenData) private view returns (uint32) {
        uint256 assetIndex = tokenData & 0x7f;
        bytes storage asset = _assets[assetIndex-1];
        uint256 assetData;
        assembly {
            assetData := sload(asset.slot) // background assets are always contained within one word
        }
        uint256 offset = assetData >> 248;
        return uint32((assetData >> ((28 - offset) << 3)) & 0xffffffff);
    }

    

    function _imageSVG(uint256 tokenData) private view returns (string memory) {
        bytes memory pixels = _imagePixels(tokenData, true);
        uint256 bgColor = uint256(_backgroundColor(tokenData));
           
        bytes memory buffer = new bytes(15200); // create a big enough buffer
        Utils.createSVG(buffer, pixels, 24, 24, bgColor);
        return string(buffer);
    }


    /**
     * The traits of the Crypto Duckie as a JSON array
     */
    function traits(uint256 tokenId) public view returns (string memory text) {
        return _traits(_tokenData(tokenId));
    }

    /**
     * The Crypto Duckie as a 24x24x4 sized byte array of RGBA pixel values without the background
     * Set premultipliedAlpha parameter to true if you want the RGB values to be premultiplied by the alpha value
     */
    function imagePixels(uint256 tokenId, bool premultipliedAlpha) public view returns (bytes memory) {
        return _imagePixels(_tokenData(tokenId), premultipliedAlpha);
    }

    /**
     * The background color of the Crypto Duckie as RGBA
     */
    function backgroundColor(uint256 tokenId) public view returns (bytes4) {
        return bytes4(_backgroundColor(_tokenData(tokenId)));
    }
    
    /**
     * SVG of the Crypto Duckie
     */
    function imageSVG(uint256 tokenId) public view returns (string memory svg) {
        return _imageSVG(_tokenData(tokenId));
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint256 tokenData = _tokenData(tokenId);
        string memory attributes = _traits(tokenData);
        string memory svg = _imageSVG(tokenData);
        bytes memory json = abi.encodePacked('{"name":"Duckie #', Utils.toString(tokenId),'", "attributes":', attributes,', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}');
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json)));
    }


    function toERC1155TokenId(uint256 tokenId) public view validTokenId(tokenId) returns (uint256 tokenIdERC1155) {
        unchecked {
            uint256 index = tokenId-1;
            uint256 tokenData = _tokensData[index >> 2] >> ((index & 3) << 6);
            tokenIdERC1155 = ((tokenData & 0x1fff) << 40) | ((tokenData & 0x2000) == 0 ? ERC1155_ADDRESS0 : ERC1155_ADDRESS1);
        }
    }


    function emergencyMint(uint256 tokenId) external onlyOwner validTokenId(tokenId) {
        _mint(msg.sender, tokenId);
    }


    function migrate(uint256 tokenId) external migrating {
        uint256 tokenIdERC1155 = toERC1155TokenId(tokenId);
        IERC1155(OPENSEA_OPENSTORE).safeTransferFrom(msg.sender, BURN, tokenIdERC1155, 1, "");
        _mint(msg.sender, tokenId);
    }

    function migrateFlock(uint256[] calldata tokenIds) external migrating {
        uint256 length = tokenIds.length;
        uint256[] memory tokenIdsERC1155 = new uint256[](length);
        uint256[] memory amounts = new uint256[](length);
        for (uint256 i=0; i<length; i++) {
            uint256 tokenId = tokenIds[i];
            tokenIdsERC1155[i] = toERC1155TokenId(tokenId);
            _mint(msg.sender, tokenId);
            amounts[i] = 1;
        }

        IERC1155(OPENSEA_OPENSTORE).safeBatchTransferFrom(msg.sender, BURN, tokenIdsERC1155, amounts, "");
    }


    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        return super.isApprovedForAll(owner, operator) || address(ProxyRegistry(OPENSEA_PROXYREGISTRY).proxies(owner)) == operator;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}