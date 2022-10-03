// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";



interface Linagee {
  function transfer (bytes32 nameId, address receiver) external;
  function owner (bytes32 nameId) view external returns(address);
  function setContent(bytes32 _node, bytes32 _hash) external;
  function setSubRegistrar(bytes32 _param1, address _param2) external;
  function setAddress(bytes32 _param1, address _param2, bool _param3) external;
}


contract LinageeNameWrapper is ERC721, ERC721Enumerable, Ownable {

   
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(uint256 => bytes32) public idToName;
    mapping(bytes32 => uint256) public nameToId;
    mapping(bytes32 => address) public waitForWrap;
    string _baseUri;
    bool proxyMethodsAvail = false;
    bool wrapEnabled = true;
    Linagee public nameBytes = Linagee(0x5564886ca2C518d1964E5FCea4f423b41Db9F561);

    event Wrapped(uint256 indexed pairId, address indexed owner, bytes32 namer);
    event Unwrapped(uint256 indexed pairId, address indexed owner, bytes32 namer);
    
    constructor(string memory _uri) ERC721("ETHRegistrarLinageeWrapper", "ERLW") {
        _tokenIds._value = 1;
        _baseUri = _uri;
    }


    function changeProxyAvail() public onlyOwner{
        proxyMethodsAvail = !proxyMethodsAvail;
    }

    function changeWrapEnabled() public onlyOwner{
        wrapEnabled = !wrapEnabled;
    }



    function getNameOwner(bytes32 nameId) view public returns(address) {
        return nameBytes.owner(nameId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseUri = _uri;
    }

    function createWrapper(bytes32 _name) public {
        require(getNameOwner(_name) == msg.sender, "You are not the owner");
        require(wrapEnabled,"Wrapping is not enabled");
        waitForWrap[_name] = msg.sender;
    }

    function wrap(bytes32 _name) public {
    
        require(getNameOwner(_name) == address(this), "Contract is not the owner. Please transfer ownership");
        require(waitForWrap[_name] == msg.sender,"You are not waiting for this wrap!");
        require(wrapEnabled,"Wrapping is not enabled");

        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
       
        _mint(msg.sender,tokenId);

        idToName[tokenId] = _name; 
        nameToId[_name] = tokenId;


        delete waitForWrap[_name];
        emit Wrapped(tokenId, msg.sender,_name);
    }

    function unwrap(uint256 _tokenId) public {

        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");
        bytes32 namer = idToName[_tokenId];
        nameBytes.transfer(namer,msg.sender);
        delete idToName[_tokenId];
        delete nameToId[namer];
        _burn(_tokenId);

        emit Unwrapped(_tokenId, msg.sender,namer);
    }
  

    function proxySetContent(uint256 _tokenId, bytes32 _hash) public {
        require(proxyMethodsAvail,"Proxy Methods are not available right now");
        require(ownerOf(_tokenId) == msg.sender,"You need to be the owner");
        nameBytes.setContent(idToName[_tokenId], _hash);

    }
    function proxySetSubRegistrar(uint256 _tokenId, address _param2) payable public {
        require(proxyMethodsAvail,"Proxy Methods are not available right now");
        require(ownerOf(_tokenId) == msg.sender,"You need to be the owner");
        nameBytes.setSubRegistrar(idToName[_tokenId],_param2);
        
    } 
    function proxySetAddress(uint256 _tokenId, address _param2, bool _param3) public {
        require(proxyMethodsAvail,"Proxy Methods are not available right now");
        require(ownerOf(_tokenId) == msg.sender,"You need to be the owner");
        nameBytes.setAddress(idToName[_tokenId],  _param2,  _param3);
    }

    

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}