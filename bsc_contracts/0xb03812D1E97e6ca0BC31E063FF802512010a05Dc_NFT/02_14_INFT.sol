// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
 
interface INFT {
    function setContractURI(string memory _contractURI) external returns(bool);
 
    function createToken(string memory _tokenURI) external returns(uint256 tokenId);
 
    function getInfo(uint256 _nftTokenId) external view returns (address, string memory, string memory, string memory);
 
    function getTokens(address _user) external returns(uint256[] memory);
}