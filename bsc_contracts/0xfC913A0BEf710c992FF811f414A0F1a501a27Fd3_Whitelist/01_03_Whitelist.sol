// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-newone/access/Ownable.sol";

contract Whitelist is Ownable {

    struct TokenList {
        address token;
        uint256 chainId;
    }

    mapping(uint256 => TokenList) public _tokenWithChainID;
    mapping(address => bool) public tokenList;
    mapping(address => mapping(int128 => address)) public poolTokensList;
    uint256 tokenIndex;
    uint256 public nativeReturnAmount;
    uint256 public stableFee;

    function addTokenToWhitelist(address token) public onlyOwner {
        tokenList[token] = true;
    }

    function removeTokenFromWhitelist(address token) public onlyOwner {
        tokenList[token] = false;
    }

    function setListedStatus(address[] calldata tokens, bool[] calldata status, uint256[] calldata chainId) public onlyOwner{

        TokenList memory list;

        for(uint i=0; i<tokens.length; i++){
            tokenList[tokens[i]] = status[i];
            list.token = tokens[i];
            list.chainId = chainId[i];
            _tokenWithChainID[tokenIndex++] = list;
        }

    }

    function setPoolToWhitelist(address pool, address[] calldata tokens, int128 arrLength) public onlyOwner {
        uint j;
        for(int128 i=0; i<arrLength; i++){
            poolTokensList[pool][i] = tokens[j++];
        }
    }

    function checkDestinationToken(address pool, int128 index) external view returns(bool) {
        address destinationToken = poolTokensList[pool][index];
        return tokenList[destinationToken];
    }

    function returnAppovedTokens(uint256 index) public view returns(TokenList[100] memory _tokenList) {
        require(tokenIndex > 100*index);
        uint256 j;
        for(uint i=100*index; i<tokenIndex; i++){
            if(tokenList[_tokenWithChainID[i].token]){
                _tokenList[j].token = _tokenWithChainID[i].token;
                _tokenList[j++].chainId = _tokenWithChainID[i].chainId;
            }
            if(j == 100) {
                break;
            }
        }

    }

    function setNativePrice(uint256 newAmount) public onlyOwner {
        nativeReturnAmount = newAmount;
    }

    function setStableFee(uint256 newAmount) public onlyOwner {
        stableFee = newAmount;
    }

}