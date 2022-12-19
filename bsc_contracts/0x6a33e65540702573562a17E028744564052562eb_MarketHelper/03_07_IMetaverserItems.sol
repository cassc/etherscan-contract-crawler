// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol"; 

interface IMetaverserItems is IERC1155 {
    struct Assets {
        string asset_name;
        uint256 supply;
    }

    function mint(address _to, uint256 _amount, string memory _name) external;

    function getTokenName(uint256 _tokenId) external view returns(string memory);
    function getTokensByOwner(address _user) external view returns(Assets[] memory);
    function getTokenCount() external view returns(uint256);
    function getHolderAddressByIndex(uint256 _index) external view returns(address);
    function getExistAddress(address _holder) external view returns(bool);
    function usersCounter() external view returns(uint256);
}