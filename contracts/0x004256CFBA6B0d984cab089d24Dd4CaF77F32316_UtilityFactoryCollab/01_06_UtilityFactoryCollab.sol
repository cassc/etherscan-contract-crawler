// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * UtilityFactory : Product Suite for Tokens Utility
 * Visit : https://utilityfactory.xyz to know more
 *
 * This contract receives ERC721 tokens and can be attributed to influencers here :
 * https://utilityfactory.xyz/collab/
 *
 *
 * *******  If you want to support this project, send ETH here to help paying gas for transfers *******
 */

contract UtilityFactoryCollab is ReentrancyGuard, IERC721Receiver {
    mapping(address => bool) admins;

    constructor() {
        admins[msg.sender] = true;
    }

    /**
     *   UtilityFactory Collab
     */
    function transferTokenToWinner(
        address contractAddr,
        uint256 tokenId,
        address toAddr
    ) public onlyAdmin {
        IERC721(contractAddr).transferFrom(address(this), toAddr, tokenId);
    }

    /**
     * A owner can get his token back. See conditions on website.
     */
    function transferTokenBackToOwner(
        address contractAddr,
        uint256 tokenId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // Check signature
        require(
            checkSign(contractAddr, tokenId, msg.sender, v, r, s),
            "UtilityFactory does not seem to find you as the owner of this token..."
        );

        IERC721(contractAddr).transferFrom(address(this), msg.sender, tokenId);
    }

    /**
     * SECURITY
     */

    function checkSign(
        address contractAddr,
        uint256 tokenId,
        address toAddr,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(contractAddr, tokenId, toAddr))
            )
        );
        address recovered = ecrecover(digest, v, r, s);
        return admins[recovered];
    }

    /**
     *   UTILS
     */

    // If you want to support this project, send ETH here to help paying gas for transfers
    receive() external payable {}

    // Should not have value on this contract ...
    // Just in case someone makes a mistake
    function withdrawMoney() external onlyAdmin nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function addAdmin(address a) public onlyAdmin {
        admins[a] = true;
    }

    function removeAdmin(address a) public onlyAdmin {
        admins[a] = false;
    }

    /** modifiers */
    modifier onlyAdmin() {
        require(admins[msg.sender], "User should be admin");
        if (admins[msg.sender]) {
            _;
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}