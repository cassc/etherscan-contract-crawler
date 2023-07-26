//SPDX-License-Identifier: Spaghetti

pragma solidity ^0.8.0;

import "./IDoomsdayFallen.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DoomsdayCollectibles is ERC721, Ownable{
    IDoomsdayFallen doomsday;

    bytes private __uriBase = bytes("https://gateway.pinata.cloud/ipfs/QmXBFscVqjj3kEEnjWZG6dCibRgL4Bi4dUwb3eHtB4JnhS/");
    bytes private __uriSuffix = bytes(".json");


    constructor(address _doomsday) ERC721("Doomsday NFT Collectibles","FALLEN"){
        doomsday = IDoomsdayFallen(_doomsday);
    }

    mapping(uint => bool) minted;

    function claim(uint _tokenId) public {
        (uint16 _cityId, address _owner) = doomsday.getFallen(_tokenId);
        _cityId;
        require(_owner == msg.sender,"didn't own");
        require(!minted[_tokenId],"minted");

        minted[_tokenId] = true;

        _mint(msg.sender,_tokenId);
    }

    function claimMultiple(uint[] calldata _tokenIds) public{
        for(uint i = 0; i < _tokenIds.length; i++){
            claim(_tokenIds[i]);
        }
    }

    // METADATA FUNCTIONS
    function tokenURI(uint256 _tokenId) public override view returns (string memory){
        //Note: changed visibility to public
        require(minted[_tokenId],"doesn't exist");

        (uint _cityId, address _owner) = doomsday.getFallen(_tokenId);
        _owner;

        uint _i = _cityId;
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
        __uriBase   = bytes(_newBase);
        __uriSuffix = bytes(_newSuffix);
    }

    function myFallen(uint startId, uint limit)  public view returns(uint[] memory _tokenIds, uint16[] memory _cityIds){
        uint _totalSupply = doomsday.totalSupply();
//        uint _myBalance = doomsday.balanceOf(msg.sender);
        uint _maxId = _totalSupply + doomsday.destroyed();
//        if(_totalSupply == 0 || _myBalance == 0){
//            uint[] memory _none;
//            return _none;
//        }
        require(startId < _maxId + 1,"Invalid start ID");
        uint sampleSize = _maxId - startId + 1;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        _tokenIds = new uint256[](sampleSize);
        _cityIds  = new uint16[](sampleSize);

        uint _tokenId = startId;
        uint found = 0;
        for(uint i = 0; i < sampleSize; i++){
            try doomsday.getFallen(_tokenId) returns (uint16 _cityId, address _owner) {
                _cityId;
                if(msg.sender == _owner && !minted[_tokenId]){
                    _tokenIds[found++] = _tokenId;
                    _cityIds[found++] = _cityId;
                }
            } catch {

            }
            _tokenId++;
        }
        return (_tokenIds,_cityIds);
    }

}