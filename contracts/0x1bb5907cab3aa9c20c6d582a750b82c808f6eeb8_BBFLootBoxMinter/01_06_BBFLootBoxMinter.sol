// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC1155Mintable} from "../interfaces/IERC1155Mintable.sol";
import {IERC1155Burnable} from "../interfaces/IERC1155Burnable.sol";
import {IERC721Transfer} from "../interfaces/IERC721Transfer.sol";
import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";

contract BBFLootBoxMinter is Ownable {
    error ArrayLengthMismatch();
    error InvalidAmount();
    error InvalidSignature();
    error Paused();

    address private constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant SCISSORS_TOKEN_ID = 5;
    IERC721Transfer public constant BBF =
        IERC721Transfer(0x68Bd8b7C45633de6d7AFD0B1F7B86b37B8a3C02A);
    IERC1155Burnable public constant NEXTENSIONS =
        IERC1155Burnable(0x232765be70a5f0B49E2D72Eee9765813894C1Fc4);
    IERC1155Mintable public immutable lootBox;

    bool public cuttingEnabled;
    address public signer;

    constructor(address lootBox_, address signer_) {
        lootBox = IERC1155Mintable(lootBox_);

        _initializeOwner(tx.origin);
        signer = signer_;
    }

    function burn2Mint(
        uint256[] calldata bbfIds,
        uint256[] calldata lootBoxIds,
        uint256[] calldata lootBoxAmounts,
        bytes calldata signature
    ) external {
        if (!cuttingEnabled) {
            revert Paused();
        }
        uint256 lootBoxLength = lootBoxAmounts.length;
        if (lootBoxIds.length != lootBoxLength) {
            revert ArrayLengthMismatch();
        }

        bytes memory mintData = abi.encode(bbfIds, lootBoxIds, lootBoxAmounts);
        checkValidity(signature, mintData);

        uint256 bbfLength = bbfIds.length;
        for (uint256 j; j < bbfLength;) {
            uint256 tokenId = bbfIds[j];
            BBF.transferFrom(msg.sender, DEAD_ADDRESS, tokenId);

            unchecked {
                ++j;
            }
        }
        NEXTENSIONS.burn(msg.sender, SCISSORS_TOKEN_ID, bbfLength);
        lootBox.batchMint(msg.sender, lootBoxIds, lootBoxAmounts);
    }

    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    function setEnabled(bool enabled) external onlyOwner {
        cuttingEnabled = enabled;
    }

    function checkValidity(bytes calldata signature, bytes memory data) private view {
        if (
            ECDSA.recoverCalldata(ECDSA.toEthSignedMessageHash(keccak256(data)), signature)
                != signer
        ) {
            revert InvalidSignature();
        }
    }
}