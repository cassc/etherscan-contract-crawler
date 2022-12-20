// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract RocksClaim is Ownable, Pausable {
    uint256 public constant ROCKS_CLAIM_PER_GRUG = 3000 * 10 ** 18;

    address public rocks;
    address public grugs;

    mapping(uint256 => bool) public grugHasClaimed;

    constructor(address _rocks, address _grugs) {
        rocks = _rocks;
        grugs = _grugs;
    }

    function claim(uint256[] memory tokenIds) public whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(!grugHasClaimed[tokenIds[i]], "Grug has already claimed");

            // owner of grug
            address grugOwner = IERC721(grugs).ownerOf(tokenIds[i]);

            // check owner
            require(grugOwner == msg.sender, "Grug is not owned by sender");

            // mark grug as claimed
            grugHasClaimed[tokenIds[i]] = true;
        }

        IERC20(rocks).transfer(
            msg.sender,
            ROCKS_CLAIM_PER_GRUG * tokenIds.length
        );
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // transfer ownership
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    // withdraw all rocks
    function withdraw() public onlyOwner {
        IERC20(rocks).transfer(
            msg.sender,
            IERC20(rocks).balanceOf(address(this))
        );
    }
}