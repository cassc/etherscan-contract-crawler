// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ITestNft.sol";

contract Minter {
    

    /// Core contract address this minter interacts with
    ITestNft public nft;

    mapping(uint256 => address) public projectMinter;


    constructor(address _art721Address) {
        nft = ITestNft(_art721Address);
    }

    /**
     * @notice Sets minter for project `_projectId` to minter
     * `_minterAddress`.
     * @param _projectId Project ID to set minter for.
     * @param _minterAddress Minter to be the project's minter.
     */
    function setMinterForProject(uint256 _projectId, address _minterAddress) external {
        projectMinter[_projectId] = _minterAddress;
    }

    /**
     * @notice Updates project `_projectId` to have no configured minter.
     * @param _projectId Project ID to remove minter.
     * @dev requires project to have an assigned minter
     */
    function removeMinterForProject(uint256 _projectId) external {
        projectMinter[_projectId] = address(0);
    }

    function mint(address _to, uint256 _projectId, address sender) external returns (uint256 _tokenId) {
        require(msg.sender == projectMinter[_projectId], "Only assigned minter");
        // EFFECTS
        uint256 tokenId = nft.mint(_to, _projectId, sender);
        return tokenId;
    }
}