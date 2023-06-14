// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

interface IERC721ABurnable {
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract MultiCall is AccessControl, ReentrancyGuard {
    IERC721ABurnable public oxGlassesContract;

    event Burned(address indexed user, uint256 tokenId);
    event BatchBurned(address indexed user, uint256[] tokenIds);

    constructor(address _oxGlassesContract) {

        oxGlassesContract = IERC721ABurnable(_oxGlassesContract);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function batchBurn(uint256[] memory tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                oxGlassesContract.ownerOf(tokenIds[i]) == msg.sender || oxGlassesContract.isApprovedForAll(oxGlassesContract.ownerOf(tokenIds[i]), msg.sender),
                "Caller is not owner nor approved for all"
            );

            oxGlassesContract.burn(tokenIds[i]);
            emit Burned(msg.sender, tokenIds[i]);
        }

        emit BatchBurned(msg.sender, tokenIds);
    }

function isOwner(uint256 tokenId) public view returns (bool) {
    return oxGlassesContract.ownerOf(tokenId) == msg.sender;
}

}