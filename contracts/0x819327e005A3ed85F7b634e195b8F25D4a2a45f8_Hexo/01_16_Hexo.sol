// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

import "./interfaces/IPublicResolver.sol";
import "./interfaces/IENS.sol";

contract Hexo is ERC721Enumerable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    /// Structs

    struct TokenInfo {
        string color;
        string object;
        uint8 generation;
    }

    /// Fields

    uint256 public price;
    // For gas efficiency, first generation is 0
    uint8 public generation;

    string public baseImageURI;
    // Mapping from token id to custom image URI (if any)
    mapping(uint256 => string) public customImageURIs;

    // Keep track of available colors and objects
    mapping(bytes32 => bool) public colors;
    mapping(bytes32 => bool) public objects;

    // Mapping from token id to token info (eg. color, object, generation)
    mapping(uint256 => TokenInfo) public tokenInfos;

    /// Constants

    address public constant ensRegistry =
        address(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    address public constant ensPublicResolver =
        address(0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41);

    // namehash("hexo.eth")
    bytes32 public constant rootNode =
        0xf55a38be8aab2a9e033746f5d0c4af6122e4dc9e896858445fa8e2e46abce36c;

    /// Events

    event PriceChanged(uint256 price);
    event GenerationIncremented(uint256 generation);
    event BaseImageURIChanged(string baseImageURI);
    event ColorsAdded(bytes32[] colorHashes);
    event ObjectsAdded(bytes32[] objectHashes);

    event ItemMinted(
        uint256 indexed tokenId,
        string color,
        string object,
        uint8 generation,
        address indexed buyer
    );
    event SubdomainClaimed(uint256 indexed tokenId, address indexed claimer);
    event CustomImageURISet(uint256 indexed tokenId, string customImageURI);

    /// Constructor

    constructor(uint256 price_, string memory baseImageURI_)
        ERC721("Hexo Codes", "HEXO")
    {
        price = price_;
        baseImageURI = baseImageURI_;
    }

    /// Owner actions

    function changePrice(uint256 price_) external onlyOwner {
        price = price_;
        emit PriceChanged(price);
    }

    function incrementGeneration() external onlyOwner {
        generation++;
        emit GenerationIncremented(generation);
    }

    function changeBaseImageURI(string calldata baseImageURI_)
        external
        onlyOwner
    {
        baseImageURI = baseImageURI_;
        emit BaseImageURIChanged(baseImageURI);
    }

    function addColors(bytes32[] calldata _colorHashes) external onlyOwner {
        for (uint256 i = 0; i < _colorHashes.length; i++) {
            colors[_colorHashes[i]] = true;
        }
        emit ColorsAdded(_colorHashes);
    }

    function addObjects(bytes32[] calldata _objectHashes) external onlyOwner {
        for (uint256 i = 0; i < _objectHashes.length; i++) {
            objects[_objectHashes[i]] = true;
        }
        emit ObjectsAdded(_objectHashes);
    }

    /// User actions

    function mintItems(string[] calldata _colors, string[] calldata _objects)
        external
        payable
    {
        require(_colors.length == _objects.length, "Invalid input");
        require(msg.value == price * _colors.length, "Incorrect amount");

        for (uint256 i = 0; i < _colors.length; i++) {
            require(colors[keccak256(bytes(_colors[i]))], "Color not added");
            require(objects[keccak256(bytes(_objects[i]))], "Object not added");

            uint256 tokenId = uint256(
                keccak256(
                    bytes(string(abi.encodePacked(_colors[i], _objects[i])))
                )
            );

            TokenInfo storage tokenInfo = tokenInfos[tokenId];
            tokenInfo.color = _colors[i];
            tokenInfo.object = _objects[i];
            if (generation != 0) {
                tokenInfo.generation = generation;
            }

            _safeMint(msg.sender, tokenId);

            emit ItemMinted(
                tokenId,
                _colors[i],
                _objects[i],
                generation,
                msg.sender
            );
        }

        // Relay the funds to the contract owner
        payable(owner()).sendValue(msg.value);
    }

    function claimSubdomains(uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(msg.sender == ownerOf(_tokenIds[i]), "Unauthorized");

            TokenInfo storage tokenInfo = tokenInfos[_tokenIds[i]];
            bytes32 label = keccak256(
                abi.encodePacked(tokenInfo.color, tokenInfo.object)
            );

            // Temporarily set this contract as the owner of the ENS subdomain,
            // giving it permission to set up ENS forward resolution
            IENS(ensRegistry).setSubnodeRecord(
                rootNode,
                label,
                address(this),
                ensPublicResolver,
                0
            );

            // Set up ENS forward resolution to point to the owner
            IPublicResolver(ensPublicResolver).setAddr(
                keccak256(abi.encodePacked(rootNode, label)),
                msg.sender
            );

            // Give ownership back to the proper owner
            IENS(ensRegistry).setSubnodeOwner(rootNode, label, msg.sender);

            emit SubdomainClaimed(_tokenIds[i], msg.sender);
        }
    }

    function setCustomImageURI(
        uint256 _tokenId,
        string calldata _customImageURI
    ) external {
        require(
            msg.sender == ownerOf(_tokenId) || msg.sender == owner(),
            "Unauthorized"
        );
        customImageURIs[_tokenId] = _customImageURI;
        emit CustomImageURISet(_tokenId, _customImageURI);
    }

    /// Views

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory metadata)
    {
        require(_exists(_tokenId), "Inexistent token");

        TokenInfo storage tokenInfo = tokenInfos[_tokenId];
        string memory tokenColor = _capitalize(tokenInfo.color);
        string memory tokenObject = _capitalize(tokenInfo.object);
        uint256 tokenGeneration = tokenInfo.generation + 1;

        // Name
        metadata = string(
            abi.encodePacked(
                '{\n  "name": "',
                tokenColor,
                " ",
                tokenObject,
                '",\n'
            )
        );

        // Description
        metadata = string(
            abi.encodePacked(
                metadata,
                '  "description": "Unique combos of basic colors and objects that form universally recognizable NFT identities. Visit hexo.codes to learn more.",\n'
            )
        );

        // Image
        metadata = string(
            abi.encodePacked(
                metadata,
                '  "image": "',
                imageURI(_tokenId),
                '",\n'
            )
        );

        // Attributes
        metadata = string(abi.encodePacked(metadata, '  "attributes": [\n'));
        metadata = string(
            abi.encodePacked(
                metadata,
                '    {\n      "trait_type": "Color",\n      "value": "',
                tokenColor,
                '"\n',
                "    },\n"
            )
        );
        metadata = string(
            abi.encodePacked(
                metadata,
                '    {\n      "trait_type": "Object",\n      "value": "',
                tokenObject,
                '"\n',
                "    },\n"
            )
        );
        metadata = string(
            abi.encodePacked(
                metadata,
                '    {\n      "display_type": "number",\n      "trait_type": "Generation",\n      "value": ',
                tokenGeneration.toString(),
                "\n",
                "    }\n"
            )
        );
        metadata = string(abi.encodePacked(metadata, "  ]\n}"));

        // Return a data URI of the metadata
        metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(metadata))
            )
        );
    }

    function contractURI() external view returns (string memory metadata) {
        // Name
        metadata = string(abi.encodePacked('{\n  "name": "Hexo Codes",\n'));

        // Description
        metadata = string(
            abi.encodePacked(
                metadata,
                '  "description": "Unique combos of basic colors and objects that form universally recognizable NFT identities. Visit hexo.codes to learn more.",\n'
            )
        );

        // Image
        metadata = string(
            abi.encodePacked(
                metadata,
                '  "image": "https://hexo.codes/images/logo.svg",\n'
            )
        );

        // External link
        metadata = string(
            abi.encodePacked(
                metadata,
                '  "external_link": "https://hexo.codes",\n'
            )
        );

        // Resell fee
        metadata = string(
            abi.encodePacked(metadata, '  "seller_fee_basis_points": 333,\n')
        );

        // Fee recipient
        metadata = string(
            abi.encodePacked(
                metadata,
                '  "fee_recipient": "',
                uint256(uint160(owner())).toHexString(),
                '"\n'
            )
        );

        metadata = string(abi.encodePacked(metadata, "}"));

        // Return a data URI of the metadata
        metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(metadata))
            )
        );
    }

    function imageURI(uint256 _tokenId)
        public
        view
        returns (string memory uri)
    {
        require(_exists(_tokenId), "Inexistent token");

        uri = customImageURIs[_tokenId];
        if (bytes(uri).length == 0) {
            // If a custom image URI is not set, use the default
            uri = string(abi.encodePacked(baseImageURI, _tokenId.toString()));
        }
    }

    /// Internals

    function _capitalize(string memory _string)
        internal
        pure
        returns (string memory)
    {
        bytes memory _bytes = bytes(_string);
        if (_bytes[0] >= 0x61 && _bytes[0] <= 0x7A) {
            _bytes[0] = bytes1(uint8(_bytes[0]) - 32);
        }
        return string(_bytes);
    }
}