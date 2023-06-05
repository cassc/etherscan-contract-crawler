// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IDivineAnarchyToken {
    function getTokenClass(uint256 _id) external view returns(uint256);
    function getTokenClassSupplyCap(uint256 _classId) external view returns(uint256);
    function getTokenClassCurrentSupply(uint256 _classId) external view returns(uint256);
    function getTokenClassVotingPower(uint256 _classId) external view returns(uint256);
    function getTokensMintedAtPresale(address account) external view returns(uint256);
    function isTokenClass(uint256 _id) external pure returns(bool);
    function isTokenClassMintable(uint256 _id) external pure returns(bool);
    function isAscensionApple(uint256 _id) external pure returns(bool);
    function isBadApple(uint256 _id) external pure returns(bool);
    function consumedAscensionApples(address account) external view returns(uint256);
    function airdropApples(uint256 amount, uint256 appleClass, address[] memory accounts) external;
	function burn(address account, uint256 id) external;
    function ownerOf(uint256 _id) external view returns(address);
}