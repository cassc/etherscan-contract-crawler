// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * UtilityFactory : Product Suite for Tokens Utility
 * Visit : https://utilityfactory.xyz to know more
 *
 */

contract UtilityFactoryCollab is ReentrancyGuard {
    mapping(address => bool) admins;

    event AddToken(
        address indexed _owner,
        uint8 tokenType,
        address indexed _contract,
        uint256 indexed _tokenId,
        uint256 amount,
        uint256 _prepaid
    );

    constructor() {
        admins[msg.sender] = true;
    }

    /**
     * Approve this contract to transfer the token when a winner is found
     */
    function addToken(
        address adminAddr,
        uint8 tokenType,
        address contractAddr,
        uint256 tokenId,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        // Check signature
        require(
            checkSign(
                tokenType,
                contractAddr,
                tokenId,
                amount,
                msg.value,
                v,
                r,
                s
            ),
            "UtilityFactory needs you to pre-pay transfer gas fees, sorry for that but we cannot offer gas fees..."
        );

        // Check token is approved :
        // Type 1 : ERC20
        if (tokenType == 1) {
            require(
                IERC20(contractAddr).allowance(msg.sender, adminAddr) >= amount,
                "An admin of Collab Factory must be approved"
            );
        }

        // Type 2 : ERC721
        if (tokenType == 2) {
            require(
                admins[IERC721(contractAddr).getApproved(tokenId)],
                "An admin of Collab Factory must be approved"
            );
        }

        // Type 3 : ERC1155
        if (tokenType == 3) {
            require(
                IERC1155(contractAddr).isApprovedForAll(msg.sender, adminAddr),
                "An admin of Collab Factory must be approved"
            );
        }

        //Emit an event
        emit AddToken(
            msg.sender,
            tokenType,
            contractAddr,
            tokenId,
            amount,
            msg.value
        );
    }

    /**
     * SECURITY
     */

    function checkSign(
        uint8 tokenType,
        address contractAddr,
        uint256 tokenId,
        uint256 amount,
        uint256 value,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        tokenType,
                        contractAddr,
                        tokenId,
                        amount,
                        value
                    )
                )
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