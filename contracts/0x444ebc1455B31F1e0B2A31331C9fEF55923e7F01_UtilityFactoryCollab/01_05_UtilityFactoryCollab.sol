// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * UtilityFactory : Product Suite for Tokens Utility
 * Visit : https://utilityfactory.xyz to know more
 *
 */

contract UtilityFactoryCollab is ReentrancyGuard {
    mapping(address => bool) admins;

    event AddToken(address indexed _owner, address indexed _contract, uint indexed _tokenId, uint256 _prepaid);

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
            admins[IERC721(contractAddr).getApproved(tokenId)],
            "An admin of Collab Factory must be approved"
        );

        //Emit an event
        emit AddToken(msg.sender, contractAddr, tokenId, msg.value);
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
        uint256 quantity,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool) {
        return _checkList(collectionAddress, userAddress, quantity, v, r, s, 0);
    }

    function checkFreeMint(
        address collectionAddress,
        address userAddress,
        uint256 quantity,
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
        uint256 quantity,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint8 checkType
    ) private view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        collectionAddress,
                        userAddress,
                        quantity,
                        checkType
                    )
                )
            )
        );
        address recovered = ecrecover(digest, v, r, s);
        return admins[recovered];
    }

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
}