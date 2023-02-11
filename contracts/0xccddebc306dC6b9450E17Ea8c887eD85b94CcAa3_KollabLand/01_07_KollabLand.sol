// SPDX-License-Identifier: MIT
// Creator: Serozense

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface IContractCollection {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IContractStaking {
    struct StakedToken {
        address staker;
        uint256 tokenId;
    }
    function getStakedTokens(address _user) external view returns (StakedToken[] memory);
}

error CannotSetZeroAddress();

contract KollabLand is ERC165, Ownable {

    address public collectionAddress;
    address public stakingAddress;

    constructor(address _collectionAddress, address _stakingAddress) {
        setCollectionAddress(_collectionAddress);
        setStakingAddress(_stakingAddress);
    }

    function setCollectionAddress(address _newAddress) public onlyOwner {
        if (_newAddress == address(0)) revert CannotSetZeroAddress();
        collectionAddress = _newAddress;
    }

    function setStakingAddress(address _newAddress) public onlyOwner {
        if (_newAddress == address(0)) revert CannotSetZeroAddress();
        stakingAddress = _newAddress;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return IContractCollection(collectionAddress).balanceOf(owner) + IContractStaking(stakingAddress).getStakedTokens(owner).length;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

}