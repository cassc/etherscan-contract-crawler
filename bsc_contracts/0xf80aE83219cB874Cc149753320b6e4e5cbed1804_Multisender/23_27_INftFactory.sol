// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface INftFactory {

    function createNft(string calldata _name, string calldata _symbol, string calldata _rarity, string calldata _season) external;

    function mintNft(address _nft, address _to, uint256 _amount) external;

}