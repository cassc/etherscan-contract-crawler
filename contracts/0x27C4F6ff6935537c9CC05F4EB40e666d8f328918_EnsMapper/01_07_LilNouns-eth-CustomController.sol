//eip155:1/erc721:0x4b10701bfd7bfedc47d50562b76b436fbb5bdb3b/590

//SPDX-License-Identifier: MIT



//Twitter: @hodl_pcc

pragma solidity ^0.8.13;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IReverseResolver {
    function setName(string memory name) external;
}

contract EnsMapper is Ownable {

    using Strings for uint256;

    address constant REVERSE_RESOLVER_ADDRESS = 0x084b1c3C81545d370f3634392De611CaaBFf8148;

    IReverseResolver constant public ReverseResolver = IReverseResolver(REVERSE_RESOLVER_ADDRESS);
    ENS constant private ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);    
    IERC721 constant public nft = IERC721(0x4b10701Bfd7BFEdc47d50562b76b436fbB5BdB3B);
    bytes32 constant public domainHash = 0x524060b540a9ca20b59a94f7b32d64ebdbeedc42dfdc7aac115003633593b492;
    mapping(bytes32 => mapping(string => string)) public texts;
   


    string constant public domainLabel = "lilnouns";

    mapping(bytes32 => uint256) public hashToIdMap;
    mapping(uint256 => bytes32) public tokenHashmap;
    mapping(bytes32 => string) public hashToDomainMap;

    

    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
    event RegisterSubdomain(address indexed registrar, uint256 indexed token_id, string indexed label);

    event AddrChanged(bytes32 indexed node, address a);

    constructor(){

    }

    //<interface-functions>
    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == 0x3b3b57de //addr
        || interfaceID == 0x59d1d43c //text
        || interfaceID == 0x691f3431 //name
        || interfaceID == 0x01ffc9a7; //supportsInterface << [inception]
    }

    function text(bytes32 node, string calldata key) external view returns (string memory) {
        uint256 token_id = hashToIdMap[node];
        require(tokenHashmap[token_id] != 0x0, "Invalid address");
        if(keccak256(abi.encodePacked(key)) == keccak256("avatar")){

            return string(abi.encodePacked("eip155:1/erc721:0x4b10701Bfd7BFEdc47d50562b76b436fbB5BdB3B/", token_id.toString()));            
        }
        else{
            return texts[node][key];
        }
    }

    function addr(bytes32 nodeID) public view returns (address) {
        uint256 token_id = hashToIdMap[nodeID];
        require(tokenHashmap[token_id] != 0x0, "Invalid address");
        return nft.ownerOf(token_id);
    }  

    function name(bytes32 node) view public returns (string memory){
        return (bytes(hashToDomainMap[node]).length == 0) 
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

    function getTokensDomains(uint256[] memory token_ids) external view returns(string[] memory){
        string[] memory uris = new string[](token_ids.length);
        for(uint256 i; i < token_ids.length; i++){
           uris[i] = getTokenDomain(token_ids[i]);
        }
        return uris;
    }


    //</read-functions>



    //--------------------------------------------------------------------------------------------//

    //<authorised-functions>
    function claimSubdomain(string calldata label, uint256 token_id) public isAuthorised(token_id) {     
        require(tokenHashmap[token_id] == 0x0, "Token has already been set");
           
        bytes32 encoded_label = keccak256(abi.encodePacked(label));
        bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));

        //ens.recordExists seems to not be reliable (tested removing records through ENS control panel and this still returns true)
        require(!ens.recordExists(big_hash) || msg.sender == owner(), "sub-domain already exists");
        
        ens.setSubnodeRecord(domainHash, encoded_label, owner(), address(this), 0);

        hashToIdMap[big_hash] = token_id;        
        tokenHashmap[token_id] = big_hash;
        hashToDomainMap[big_hash] = label;

        address token_owner = nft.ownerOf(token_id);

        emit RegisterSubdomain(token_owner, token_id, label);   
        emit AddrChanged(big_hash, token_owner);  
    }

    function setText(bytes32 node, string calldata key, string calldata value) external isAuthorised(hashToIdMap[node]) {
        uint256 token_id = hashToIdMap[node];
        require(tokenHashmap[token_id] != 0x0, "Invalid address");
        require(keccak256(abi.encodePacked(key)) != keccak256("avatar"), "cannot set avatar");

        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

    //this is to output an event because it seems that etherscan use
    //the graph events for their reverse resolution. If a linked NFT
    //is transfered then it can't callback to this contract so we provide this
    //method for users to do it manually. Anyone can call this method.
    function updateAddresses(uint256[] calldata _ids) external {
        uint256 len = _ids.length;
        for(uint256 i; i < len;){
            bytes32 big_hash = tokenHashmap[_ids[i]];
            require(big_hash != 0x0, "no subdomain on this token");
            emit AddrChanged(big_hash, nft.ownerOf(_ids[i]));  
            unchecked{
                ++i;
            }
        }
    }

    function setContractName(string calldata _name) onlyOwner external {
        ReverseResolver.setName(_name);
    }
        
    function resetHash(uint256 token_id) public isAuthorised(token_id) {
        
        bytes32 domain = tokenHashmap[token_id];
        require(ens.recordExists(domain), "Sub-domain does not exist");
        
        //reset domain mappings
        delete hashToDomainMap[domain];      
        delete hashToIdMap[domain];
        delete tokenHashmap[token_id];

        emit AddrChanged(domain, address(0));  
       
    }
    //</authorised-functions>

    //--------------------------------------------------------------------------------------------//

    // <owner-functions>


    function renounceOwnership() public override onlyOwner {
        require(false, "ENS is responsibility. You cannot renounce ownership.");
        super.renounceOwnership();
    }

    //</owner-functions>

    modifier isAuthorised(uint256 tokenId) {
        require(owner() == msg.sender || nft.ownerOf(tokenId) == msg.sender, "Not authorised");
        _;
    }
}