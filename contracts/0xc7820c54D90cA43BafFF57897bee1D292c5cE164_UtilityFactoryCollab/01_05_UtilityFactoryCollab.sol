// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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

contract UtilityFactoryCollab is ReentrancyGuard {
    struct Token {
        address contractAddress;
        uint256 tokenId;
        address winner;
    }

    struct Owner {
        uint16 nbTokens;
        mapping(uint16 => Token) tokens;
    }

    mapping(address => bool) admins;
    mapping(address => Owner) arrOwners;

    constructor() {
        admins[msg.sender] = true;
    }

    /**
     * Approve this contract to transfer the token when a winner is found
     */
    function addToken(
        address contractAddr,
        uint256 tokenId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        // Check signature
        require(
            checkSign(contractAddr, tokenId, msg.value, v, r, s),
            "UtilityFactory needs you to pre-pay transfer gas fees, sorry for that but we cannot offer gas fees..."
        );

        // Check token is approved :
        require(
            IERC721(contractAddr).getApproved(tokenId) == address(this),
            "This contract must be approved"
        );

        arrOwners[msg.sender].tokens[arrOwners[msg.sender].nbTokens] = Token({
            contractAddress: contractAddr,
            tokenId: tokenId,
            winner: address(0)
        });
        arrOwners[msg.sender].nbTokens++;
    }

    function getTokens(uint16 nb) public view returns (Token[] memory) {
        uint16 size = nb;
        if (nb > arrOwners[msg.sender].nbTokens) {
            size = arrOwners[msg.sender].nbTokens;
        }

        Token[] memory arrTokens = new Token[](size);

        for (
            uint16 i = 0;
            i < size;
            i++
        ) {
            arrTokens[i] = arrOwners[msg.sender].tokens[arrOwners[msg.sender].nbTokens - i - 1];
        }
        return arrTokens;
    }

    /**
     * SECURITY
     */

    function checkSign(
        address contractAddr,
        uint256 tokenId,
        uint256 value,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(contractAddr, tokenId, value))
            )
        );
        address recovered = ecrecover(digest, v, r, s);
        return admins[recovered];
    }

    function checkWL(
        address collectionAddress,
        address userAddress,
        uint quantity,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool) {
        return _checkList(collectionAddress, userAddress, quantity, v, r, s, 0);
    }

    function checkFreeMint(
        address collectionAddress,
        address userAddress,
        uint quantity,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool) {
        return _checkList(collectionAddress, userAddress, quantity, v, r, s, 1);
    }

    receive() external payable {}

    /**
     *   UTILS
     */

    function _checkList(
        address collectionAddress,
        address userAddress,
        uint quantity,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint8 checkType
    ) private view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(collectionAddress, userAddress, quantity, checkType))
            )
        );
        address recovered = ecrecover(digest, v, r, s);
        return admins[recovered];
    }

    function withdrawMoney()
        external
        onlyAdmin
        nonReentrant
    {
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
}