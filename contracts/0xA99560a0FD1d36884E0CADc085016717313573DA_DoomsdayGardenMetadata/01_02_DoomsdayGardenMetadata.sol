// SPDX-License-Identifier: Please may I have some salad
pragma solidity ^0.8.9;

import "./interfaces/IERC721.sol";

contract DoomsdayGardenMetadata {
    string __uriBase;
    string __uriSuffix;

    address garden;

    constructor(address _garden,string memory _uriBase, string memory _uriSuffix){
        garden = _garden;

        __uriBase   = _uriBase;
        __uriSuffix = _uriSuffix;
    }


    function tokenURI(uint _tokenId,bytes32 _hash, uint _supplyAtMint, uint _planted) public view returns (string memory){
        //Validity check
        IERC721(garden).ownerOf(_tokenId);

        _hash;_supplyAtMint;_planted;

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
}