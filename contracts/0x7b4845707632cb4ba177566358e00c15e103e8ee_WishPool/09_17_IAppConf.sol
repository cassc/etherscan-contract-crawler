// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAppConf {
    function getBurnAddr() external view returns(address);
    function getCoolAddr() external view returns(address);
    function getDonateAddr() external view returns(address);
    function getIncenseAddr() external view returns(address);
    function validBlacklist(address addr) external view returns(bool);
    function validWhitelist(address addr) external view returns(bool);
    function getRedeemNftToken() external view returns(address);
    function getGrantNftToken() external view returns(address);
    function getGrantNftGen() external view returns(uint8);
    function getNftFactoryAddr() external view returns(address);
    function validRedeemToken(address redeemToken) external view returns(bool);
    function getNftTokenType(address nftToken) external view returns(uint8);
    function getNftTypeToken(uint8 nftType) external view returns(address);
    function getIncenseMinAmount() external view returns(uint256);
    function getIncenseMaxAmount() external view returns(uint256);
}