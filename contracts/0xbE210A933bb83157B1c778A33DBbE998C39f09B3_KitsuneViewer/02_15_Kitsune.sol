//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Kitsune is ERC721, Ownable{
    IERC721Enumerable ronin;

    string __uriBase;
    string __uriSuffix;

    bool public started = false;
    uint supply = 0;
    mapping(uint => bool) claimed;

    event ClaimKitsune(uint indexed roninId, uint indexed kitsuneId, address claimer);
    event Start(bool _started);

    constructor(address _ronin, string memory _uriBase, string memory _uriSuffix) ERC721("Kitsune","KITSUNE"){
        ronin = IERC721Enumerable(_ronin);
        __uriBase   = _uriBase;
        __uriSuffix = _uriSuffix;
    }

    function toggleStart() public onlyOwner{
        started = !started;
        emit Start(started);
    }

    function claimKitsune(uint _tokenId) public{
        require(started,"claim process not started");
        _claim(_tokenId);
    }
    function _claim(uint _tokenId) internal{

        require(ronin.ownerOf(_tokenId) == msg.sender,"owner");

        uint newTokenId = _tokenId%10000;

        require(!claimed[newTokenId],"kitsune already claimed");

        _safeMint(msg.sender,++supply);

        claimed[newTokenId] = true;

        emit ClaimKitsune(newTokenId,supply,msg.sender);

    }



    function claimMultiple(uint[] calldata _tokenIds) public{
        require(started,"claim process not started");
        for(uint i = 0; i < _tokenIds.length; i++){
            _claim(_tokenIds[i]);
        }
    }

    function claimable(uint _tokenId) public view returns(bool){
        uint newTokenId = _tokenId%10000;
        return !claimed[newTokenId];
    }


    function tokenURI(uint256 _tokenId) public view virtual override  returns (string memory){
        require(_exists(_tokenId),"exists");

        if(_tokenId == 0){
            return string(abi.encodePacked(__uriBase,bytes("0"),__uriSuffix));
        }


        uint _i = _tokenId;
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

        return string(abi.encodePacked(__uriBase,bstr,__uriSuffix));
    }
    function setUriComponents(string calldata _newBase, string calldata _newSuffix) public onlyOwner{
        __uriBase   = _newBase;
        __uriSuffix = _newSuffix;
    }

    function totalSupply() public view returns(uint){
        return supply;
    }

}