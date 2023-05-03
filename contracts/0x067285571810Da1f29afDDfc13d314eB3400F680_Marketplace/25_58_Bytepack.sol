//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
contract Bytepack
{
    struct TokenData
    {
        string name;
        string gif;
        string trait;
    }

    struct OGTokenData
    {
        string name;
        string gif;
        string trait;
        bool updated;
    }

    uint private CurrentIndex;
    mapping(uint=>TokenData) private tokenData;
    mapping(uint=>OGTokenData) private OGTokenDatas;

    constructor() {}

    // /**
    //  * @dev Sets Token Data
    //  */
    // function setTokenInfo(TokenData calldata TokenDatas) external  
    // {
    //     tokenData[CurrentIndex] = TokenDatas;
    //     CurrentIndex += 1;
    // }

    function setTokenInfo(string memory Bingbong) external
    {
        CurrentIndex+=1;
    }

    function ogsetTokenInfo(uint _tokenId, string memory _name, string memory _GIF, string memory _trait) external 
    { 
        OGTokenDatas[_tokenId].name = _name;
        OGTokenDatas[_tokenId].trait = _trait;
        OGTokenDatas[_tokenId].gif = _GIF;
        OGTokenDatas[_tokenId].updated = true;
    }
}