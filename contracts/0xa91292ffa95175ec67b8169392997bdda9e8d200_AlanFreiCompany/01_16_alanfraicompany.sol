// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "base64-sol/base64.sol";


contract AlanFreiCompany is ERC721, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    string constant uriBase = "data:application/json;base64,";


    struct Metadata {
        uint256 tokenID;
        string name;
        string imageURL;
        string attribute1;
        string attribute2;
        string attribute3;
        string attribute4;
        string value1;
        string value2;
        string value3;
        string value4;
    }

    mapping(uint256 => Metadata) tokenIdToMetadataStruct;

    constructor() ERC721("Alan Frei Company", "AFC") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }
    
    
    function mint(
        string memory _name,
        string memory _imageURL,
        string memory _attr1,
        string memory _attr2,
        string memory _attr3,
        string memory _attr4,
        string memory _value1,
        string memory _value2,
        string memory _value3,
        string memory _value4
    ) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        Metadata memory newToken = Metadata(
            tokenId,
            _name,
            _imageURL,
            _attr1,
            _attr2,
            _attr3,
            _attr4,
            _value1,
            _value2,
            _value3,
            _value4
            );
        tokenIdToMetadataStruct[tokenId] = newToken;
    }

    


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        // get metadata struct of tokenID
        Metadata memory metadata = tokenIdToMetadataStruct[tokenId];
        // get metadata
        string memory _name = metadata.name;
        string memory imageURL = metadata.imageURL;
        string memory attr1 = metadata.attribute1;
        string memory attr2 = metadata.attribute2;
        string memory attr3 = metadata.attribute3;
        string memory attr4 = metadata.attribute4;
        string memory val1 = metadata.value1;
        string memory val2 = metadata.value2;
        string memory val3 = metadata.value3;
        string memory val4 = metadata.value4;
        

        return
        string(
            abi.encodePacked(
                uriBase,
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            _name,
                            '","external_url":"https://www.alanfrei.com',
                            '","image":"',
                            imageURL,
                            '","attributes":[{"trait_type":"',
                            attr1,
                            '", "value":"',
                            val1,
                            '"},'
                            '{"trait_type":"',
                            attr2,
                            '", "value":"',
                            val2,
                            '"},'
                            '{"trait_type":"',
                            attr3,
                            '", "value":"',
                            val3,
                            '"},'
                            '{"trait_type":"',
                            attr4,
                            '", "value":"',
                            val4,
                            '"}]}'
                        )
                    )
                )
            )
        );
        
            
        

        
    }


    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}