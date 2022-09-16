//SPDX-License-Identifier: MIT


/* This code should work for most ERC-721 contracts. Please feel free to reuse

- Change IERC721Enumerable contract address in constructor
- Update domainLabel value
- Update nftImageBaseUri value to the base path of the images
- Set controller address of the parent domain to this deployed contract (in ENS web app)
*/

pragma solidity ^0.8.2;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract EnsMapper is Ownable, ERC721A {
    ENS private ens;    

    bytes32 public domainHash;
    mapping(bytes32 => mapping(string => string)) public texts;
   
    string public domainLabel = unicode"muu";
    string private baseApiUri = "https://avatars.dicebear.com/api/croodles/";
    uint256 private price = 0.005 ether;
    
    bool public useEIP155 = true;
    
    mapping(bytes32 => uint256) public hashToIdMap;
    mapping(uint256 => bytes32) public tokenHashmap;
    mapping(bytes32 => string) public hashToDomainMap;
    mapping(uint256 => string) public subdomainLabel;

    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
    event RegisterSubdomain(address indexed registrar, uint256 indexed token_id, string indexed label);

    constructor() ERC721A("muu.eth", "MUU") {
        ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        domainHash = getDomainHash();
    }

    function mint(string calldata label) public payable {   
        require( msg.value >= price, "Fee to avoid spam mints");

        uint256 token_id = _nextTokenId();
 
        bytes32 encoded_label = keccak256(abi.encodePacked(label));
        bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));

        require(!ens.recordExists(big_hash), "already exists");
        ens.setSubnodeRecord(domainHash, encoded_label, owner(), address(this), 0);

        hashToIdMap[big_hash] = token_id;        
        tokenHashmap[token_id] = big_hash;
        hashToDomainMap[big_hash] = label;
        subdomainLabel[token_id] = label;

        _mint(msg.sender, 1);
        
        emit RegisterSubdomain(ownerOf(token_id), token_id, label);     
    }

    //<interface-functions>
    function supportsInterface(bytes4 interfaceID) public override  pure returns (bool) {
        return interfaceID == 0x3b3b57de //addr
        || interfaceID == 0x59d1d43c //text
        || interfaceID == 0x691f3431 //name
        || interfaceID == 0x01ffc9a7; //supportsInterface << [inception]
    }

    function text(bytes32 node, string calldata key) external view returns (string memory) {
        uint256 token_id = hashToIdMap[node];
        require(token_id > 0 && tokenHashmap[token_id] != 0x0, "Invalid address");
        if(keccak256(abi.encodePacked(key)) == keccak256("avatar")){
            //eip155 string did not seem to work in any supported dapps during testing despite the returned string being properly
            //formatted. So the toggle was added so that we can direct link the image using http:// if this still does not work on 
            //mainnet
            return useEIP155 ? string(abi.encodePacked(baseApiUri,buildImage(token_id)))
                             : string(abi.encodePacked(baseApiUri,buildImage(token_id))); 
        }
        else{
            return texts[node][key];
        }
    }

    function addr(bytes32 nodeID) public view returns (address) {
        uint256 token_id = hashToIdMap[nodeID];
        require(token_id > 0 && tokenHashmap[token_id] != 0x0, "Invalid address");
        return ownerOf(token_id);
    }  

    function name(bytes32 node) view public returns (string memory){
        return (hashToIdMap[node] == 0) 
        ? "" 
        : string(abi.encodePacked(hashToDomainMap[node], ".", domainLabel, ".eth"));
    }
    //</interface-functions>  

    //--------------------------------------------------------------------------------------------//

    //<read-functions>
    function domainMap(string calldata label) public view returns(bytes32){
        bytes32 encoded_label = keccak256(abi.encodePacked(label));
        bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));
        return hashToIdMap[big_hash] > 0 ? big_hash : bytes32(0x0);
    }

   function getTokenDomain(uint256 token_id) private view returns(string memory uri){
        require(tokenHashmap[token_id] != 0x0, "Token does not have an ENS register");
        uri = string(abi.encodePacked(hashToDomainMap[tokenHashmap[token_id]] ,"." ,domainLabel, ".eth"));
    }

    function getTokensDomains(uint256[] memory token_ids) public view returns(string[] memory){
        string[] memory uris = new string[](token_ids.length);
        for(uint256 i; i < token_ids.length; i++){
           uris[i] = getTokenDomain(token_ids[i]);
        }
        return uris;
    }

    function buildImage(uint _tokenId) public view returns(string memory) {
        string memory result = string(abi.encodePacked(
            ':',subdomainLabel[_tokenId],'.svg'
            ));
        return result;
    }

    function buildMeta(uint _tokenId) public view returns(string memory) {
        string memory result = string(
            abi.encodePacked(
                '{"trait_type":"Subdomain", "value":"',
                subdomainLabel[_tokenId],
                '"}'
            )
        );
        return result;
    }

    function tokenURI(uint256 tokenId) public override  view returns (string memory) {
        require(_exists(tokenId));
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',
                                    subdomainLabel[tokenId], 
                                    '.',domainLabel,'.eth", "description": "muu.eth NFTs are ENS subdomains by @elonsdev pointing to the NFT owner. Avatars are randomly generated using croodles by @realvjy (under CC BY 4.0 License) and avatars.dicebear.com api", "image": "',baseApiUri,'',
                                    buildImage(tokenId),
                                    '","attributes": [',
                                    buildMeta(tokenId),
                                    ']}'
                                )
                            )
                        )
                    )
                )
            );
    }


    //</read-functions>

    //--------------------------------------------------------------------------------------------//

    //<helper-functions>
    function addressToString(address _addr) private pure returns(string memory) {
    bytes32 value = bytes32(uint256(uint160(_addr)));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(51);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < 20; i++) {
        str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
    return string(str);
    }

    //this is the correct method for creating a 2 level ENS namehash
    function getDomainHash() private view returns (bytes32 namehash) {
            namehash = 0x0;
            namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked('eth'))));
            namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked(domainLabel))));
    }

    //</helper-functions>

    //--------------------------------------------------------------------------------------------//

    //<authorised-functions>
    

    function setText(bytes32 node, string calldata key, string calldata value) external isAuthorised(hashToIdMap[node]) {
        uint256 token_id = hashToIdMap[node];
        require(token_id > 0 && tokenHashmap[token_id] != 0x0, "Invalid address");
        require(keccak256(abi.encodePacked(key)) != keccak256("avatar"), "cannot set avatar");

        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }
        
    //</authorised-functions>

    //--------------------------------------------------------------------------------------------//

    function setEnsAddress(address addy) public onlyOwner {
        ens = ENS(addy);
    }

    function setbaseApiUri(string memory _baseApiUri) public onlyOwner {
        baseApiUri = _baseApiUri;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	function withdrawTokens(uint256 token) public onlyOwner {
		require(ownerOf(token) == msg.sender);
		uint256 balance = balanceOf(address(this));
		payable(msg.sender).transfer(balance);
	}

    //</owner-functions>

    modifier isAuthorised(uint256 tokenId) {
        require(owner() == msg.sender || ownerOf(tokenId) == msg.sender, "No");
        _;
    }
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}