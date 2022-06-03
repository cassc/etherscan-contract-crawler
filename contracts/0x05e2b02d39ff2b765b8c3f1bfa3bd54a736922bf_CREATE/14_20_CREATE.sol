// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: Yazo
//  https://yazo.fun/
//  r

import "./ERC721TradableCHAIN.sol";

/**
 * @title CREATE
 * Yazo: CREATE
 */


contract CREATE is ERC721TradableCHAIN {
    constructor(address _proxyRegistryAddress) ERC721TradableCHAIN("CREATE", "CREATE", _proxyRegistryAddress) {}
    string private _theBaseURI = "https://yazo.fun/";
    string private _default = "data:image/svg+xml;base64,PHN2ZyBzdHlsZT0iYmFja2dyb3VuZDpibGFjazsiIHZpZXdCb3g9IjAgMCA3MDAgNzAwIiB2ZXJzaW9uPSIxLjEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiPjxyZWN0IGZpbGw9IiMwMDAwMDAiIHg9IjAiIHk9IjAiIHdpZHRoPSI3MDAiIGhlaWdodD0iNzAwIj48L3JlY3Q+PGNpcmNsZSBzdHJva2U9IiNGRkZGRkYiIHN0cm9rZS13aWR0aD0iMTUiIGN4PSIzNTAiIGN5PSIzNTAiIHI9IjE4Ny41Ij48L2NpcmNsZT48bGluZSB4MT0iNTQ1LjUiIHkxPSIxNTUuNSIgeDI9IjE1Ni41IiB5Mj0iNTQ1LjUiIHN0cm9rZT0iI0ZGRkZGRiIgc3Ryb2tlLXdpZHRoPSIxNSIgc3Ryb2tlLWxpbmVjYXA9InNxdWFyZSI+PC9saW5lPjwvc3ZnPg==";
    uint256 private PRICE = 10000000000000000;

    function baseTokenURI() override public view returns (string memory) {
        return Base64.encode(bytes(_theBaseURI));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                       abi.encodePacked(
                        '{"name":"CREATE","description":"CREATE","image":"',_default,'","external_link":"',_theBaseURI,'","seller_fee_basis_points":0,"fee_recipient":""}'
                       )
                    )
                )
        )); 
    }

    function formatTokenURI(uint256 _tokenId) private view returns (string memory) {
        if(TOKENS[_tokenId]._created) {
            string memory name = TOKENS[_tokenId]._name;
            string memory description = TOKENS[_tokenId]._description;
            string memory attributes = TOKENS[_tokenId]._attributes;
            string memory creator = toAsciiString(TOKENS[_tokenId]._creator);
            string memory image = TOKENS[_tokenId]._image;
            string memory animation = TOKENS[_tokenId]._animation;
            string memory _type = TOKENS[_tokenId]._codec;

            if(bytes(image).length > 1) {
                if(!TOKENS[_tokenId]._image_encoded) {
                    image = Base64.encode(bytes(image));
                }
                image = string(abi.encodePacked(', "image":"',_type,image,'"'));
            }
            if(bytes(animation).length > 1) {
                if(!TOKENS[_tokenId]._animation_image_encoded) {
                    animation = Base64.encode(bytes(animation));
                }
                _type = TOKENS[_tokenId]._codec_animation;
                animation = string(abi.encodePacked(', "animation_url":"',_type,animation,'"'));
            }
            return formatTokenURIString(name,description,image,animation,_type,creator,attributes);
        } else {
            return formatTokenURIString("CREATE","CREATE",string(abi.encodePacked(', "image":"',_default,'"')),"","data:image/svg+xml;base64,","CREATE","");
        }        
    }

    function formatTokenURIString(string memory name,string memory description,string memory image, string memory animation, string memory _type, string memory creator, string memory attributes) private view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',name,'","description":"',description,'"',image,'',animation,',"attributes" : [{"trait_type":"Type","value":"',_type,'"},{"trait_type":"Creator","value":"0x',creator,'"}',attributes,']}'
                        )
                    )
                )
            )
        );
    }

    function lock_data(uint256 _tokenId) public {
       require(TOKENS[_tokenId]._owner == msg.sender);
       TOKENS[_tokenId]._locked = true;
    }
    
    function set_token(uint256 _tokenId, string memory name, string memory description, string memory attributes, string memory image, bool base64, string memory data_uri) public {
       require(TOKENS[_tokenId]._owner == msg.sender);
       require(!TOKENS[_tokenId]._locked);

       TOKENS[_tokenId]._created = true;
       TOKENS[_tokenId]._creator = msg.sender;
       TOKENS[_tokenId]._name = name;
       TOKENS[_tokenId]._description = description;
       TOKENS[_tokenId]._attributes = attributes;
       TOKENS[_tokenId]._image = image;
       TOKENS[_tokenId]._codec = data_uri;
       TOKENS[_tokenId]._image_encoded = base64;
    }

    function set_token_animation(uint256 _tokenId, string memory name, string memory description, string memory attributes, string memory image, bool base64, string memory data_uri, string memory animation_image, bool animation_base64, string memory animation_data_uri) public {
       require(TOKENS[_tokenId]._owner == msg.sender);
       require(!TOKENS[_tokenId]._locked);

       TOKENS[_tokenId]._created = true;     
       TOKENS[_tokenId]._creator = msg.sender;
       TOKENS[_tokenId]._name = name;
       TOKENS[_tokenId]._description = description;
       TOKENS[_tokenId]._attributes = attributes;
       TOKENS[_tokenId]._image = image;
       TOKENS[_tokenId]._codec = data_uri;
       TOKENS[_tokenId]._image_encoded = base64;
       TOKENS[_tokenId]._animation = animation_image;
       TOKENS[_tokenId]._codec_animation = animation_data_uri;
       TOKENS[_tokenId]._animation_image_encoded = animation_base64;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
         return formatTokenURI(_tokenId); 
    }

    function token_info(uint256 _tokenId) public view returns (address _creator, bool _locked, uint256 _likes, bool _featured) {
        return (TOKENS[_tokenId]._creator,TOKENS[_tokenId]._locked,TOKENS[_tokenId]._number_likes,TOKENS[_tokenId]._featured);
    }

    function set_featured(uint256 _tokenId) external payable {
        require(msg.value == PRICE, "Invalid ETH");
        TOKENS[_tokenId]._featured = true;
    }

    function set_feature_price(uint256 _price) external onlyME {
        PRICE = _price;
    }

    function add_like(uint256 _tokenId) public {
        require(!TOKENS[_tokenId]._likes[msg.sender]);
        TOKENS[_tokenId]._likes[msg.sender] = true;
        TOKENS[_tokenId]._number_likes++;
    }

}