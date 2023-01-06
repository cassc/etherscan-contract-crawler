// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTMistery {

    function redeem(address _redeem,uint256 _tokenid, string memory _uri) external returns (uint256);

    function Minting(uint256 _tokenid,address _redeem,string memory _uri) external returns (uint256);

    function openBox(address _redeem,uint256 _idBox, uint256 _tokenid, string memory _uri) external returns(uint256);

    function burnMyNFT(address _burner, uint256 _tokenid) external returns(uint256);

    function walletOfOwner(address _owner) external view returns (uint256[] memory);

    function getTotalSupply() external view returns (uint256);

    function getStartBoxSupply() external view returns (uint256);

    function getMaxSupply() external view returns (uint256);

    function getMaxBoxSupply() external view returns (uint256);

    function getPriceToken() external view returns (address,uint256);

    function transferFrom(address from, address to,uint256 tokenId) external;

    function getAdmin() external view returns (address);

    function getOpenDate() external view returns(uint256);
}