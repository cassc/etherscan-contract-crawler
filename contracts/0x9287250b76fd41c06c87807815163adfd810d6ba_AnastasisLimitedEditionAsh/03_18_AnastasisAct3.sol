// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./ERC721.sol";
import "./IEIP2981.sol";
import "./AdminControl.sol";
import "./Strings.sol";

contract Anastasis_Act3 is ERC721, AdminControl {
    
    address payable  private _royalties_recipient;
    uint256 private _royaltyAmount; //in % 
    uint256 public _editionNumber = 33;
    uint256 public _tokenId = 1;
    uint256[] public _availableURIs;
    uint256 public _maxSupply;
    uint256 public _saURI;
    string public _uri;
    
    mapping (uint256 => uint256) _stock;
    mapping(uint256 => uint256) public _tokenURIs;
    
    constructor () ERC721("f-1 Anastasis - Act3", "f-1 AA3") {
        _availableURIs = [1,2,3,4,5,6,7,8];
        _saURI = _availableURIs.length;
        for(uint256 i = 1; i <= _availableURIs.length; i++){
            _stock[i] = _editionNumber;
        }
        _maxSupply = _availableURIs.length * _editionNumber;
        _royalties_recipient = payable(msg.sender);
        _royaltyAmount = 10;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AdminControl)
        returns (bool)
    {
        return
        AdminControl.supportsInterface(interfaceId) ||
        ERC721.supportsInterface(interfaceId) ||
        interfaceId == type(IEIP2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function mint( 
        address to
    ) external adminRequired{
        require(_tokenId <= _maxSupply, "Max supply reached");
        _mint(to, _tokenId);
        uint256 uri = getURI();
        _tokenURIs[_tokenId] = uri;
        _tokenId += 1;
    }

    function getURI()internal returns(uint256){
        uint256 rnd = getPseudoRandomNumber(_availableURIs.length, msg.sender);
        uint256 uri = _availableURIs[rnd];
        if(_stock[uri] == 1){
            removeToken(rnd);
        }
        _stock[uri] -= 1;   
        if(uri == _saURI){
            uri = _saURI + _stock[uri];
        }
        require(uri>0,'invalid URI');
        return uri;
    }

    function removeToken(uint index) public{
        if(_availableURIs.length>1){
        _availableURIs[index] = _availableURIs[_availableURIs.length - 1];
        }
        _availableURIs.pop();
    }

    function getPseudoRandomNumber(uint256 length, address account) public view returns (uint256){    
        uint256 rnd = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _tokenId, length, msg.sender, account))) % length;
        return rnd % length;
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        require(msg.sender == owner, "Owner only");
        _burn(tokenId);
    }

    function setURI(
        string calldata updatedURI
    ) external adminRequired{
        _uri = updatedURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_uri, Strings.toString(_tokenURIs[tokenId]), ".json"));
    }

    function setRoyalties(address payable _recipient, uint256 _royaltyPerCent) external adminRequired {
        _royalties_recipient = _recipient;
        _royaltyAmount = _royaltyPerCent;
    }

    function royaltyInfo(uint256 salePrice) external view returns (address, uint256) {
        if(_royalties_recipient != address(0)){
            return (_royalties_recipient, (salePrice * _royaltyAmount) / 100 );
        }
        return (address(0), 0);
    }

    function withdraw(address recipient) external adminRequired {
        payable(recipient).transfer(address(this).balance);
    }

}