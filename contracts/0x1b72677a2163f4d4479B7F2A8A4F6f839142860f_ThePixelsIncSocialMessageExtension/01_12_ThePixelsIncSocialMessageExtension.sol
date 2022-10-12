// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./../../common/interfaces/IINT.sol";
import "./../../common/interfaces/IThePixelsIncExtensionStorageV2.sol";
import "./../../common/interfaces/ICoreRewarder.sol";
import "./../../common/interfaces/IThePixelsInc.sol";

contract ThePixelsIncSocialMessageExtension is AccessControl {
    uint256 public constant EXTENSION_ID = 2;

    uint256 public nextMessageId;
    mapping(uint256 => uint256) public messagePrices;

    address public immutable INTAddress;
    address public extensionStorageAddress;
    address public pixelRewarderAddress;
    address public dudesRewarderAddress;
    address public DAOAddress;

    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");

    constructor(
        address _INTAddress,
        address _extensionStorageAddress,
        address _pixelRewarderAddress,
        address _dudesRewarderAddress,
        address _DAOAddress
    ) {
        INTAddress = _INTAddress;
        extensionStorageAddress = _extensionStorageAddress;
        pixelRewarderAddress = _pixelRewarderAddress;
        dudesRewarderAddress = _dudesRewarderAddress;
        DAOAddress = _DAOAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MOD_ROLE, msg.sender);
    }

    function setExtensionStorageAddress(address _extensionStorageAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        extensionStorageAddress = _extensionStorageAddress;
    }

    function setPixelRewarderAddress(address _rewarderAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pixelRewarderAddress = _rewarderAddress;
    }

    function setDudeRewarderAddress(address _rewarderAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        dudesRewarderAddress = _rewarderAddress;
    }

    function setDAOAddress(address _DAOAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        DAOAddress = _DAOAddress;
    }

    function grantModRole(address modAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(MOD_ROLE, modAddress);
    }

    function revokeModRole(address modAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(MOD_ROLE, modAddress);
    }

    function setMessagePrice(uint256 collectionId, uint256 price)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        messagePrices[collectionId] = price;
    }

    function sendGlobalMessage(uint256 senderId, string memory message)
        public
        onlyRole(MOD_ROLE)
    {
        uint256 currentMessageId = nextMessageId;
        emit GlobalMessageSent(
            msg.sender,
            currentMessageId,
            senderId,
            message,
            block.timestamp
        );
        nextMessageId = currentMessageId + 1;
    }

    function updateGlobalMessageVisibility(
        uint256[] memory messageIds,
        uint256[] memory senderIds,
        bool[] memory isHiddens
    ) public onlyRole(MOD_ROLE) {
        for (uint256 i; i < messageIds.length; i++) {
            emit GlobalMessageVisibilityUpdated(
                msg.sender,
                messageIds[i],
                senderIds[i],
                isHiddens[i],
                block.timestamp
            );
        }
    }

    function updateGlobalTokenBlockStatus(
        uint256[] memory senderIds,
        uint256[] memory targetTokenIds,
        uint256[] memory collectionIds,
        bool[] memory isBlockeds
    ) public onlyRole(MOD_ROLE) {
        for (uint256 i; i < senderIds.length; i++) {
            emit GlobalTokenBlockStatusUpdated(
                msg.sender,
                senderIds[i],
                targetTokenIds[i],
                collectionIds[i],
                isBlockeds[i],
                block.timestamp
            );
        }
    }

    function enableSocialMessages(
        uint256[] memory tokenIds,
        uint256[] memory salts
    ) public {
        uint256 length = tokenIds.length;
        uint256[] memory variants = new uint256[](length);
        bool[] memory useCollection = new bool[](length);
        uint256[] memory collectionTokenIds = new uint256[](length);

        address _extensionStorageAddress = extensionStorageAddress;
        for (uint256 i = 0; i < length; i++) {
            uint256 currentVariant = IThePixelsIncExtensionStorageV2(
                _extensionStorageAddress
            ).currentVariantIdOf(EXTENSION_ID, tokenIds[i]);
            require(currentVariant == 0, "Token has no social extension");

            uint256 rnd = _rnd(tokenIds[i], salts[i]) % 100;
            uint256 variant;

            if (rnd >= 80 && rnd < 100) {
                variant = 3;
            } else if (rnd >= 50 && rnd < 80) {
                variant = 2;
            } else {
                variant = 1;
            }
            variants[i] = variant;
        }

        IThePixelsIncExtensionStorageV2(_extensionStorageAddress)
            .extendMultipleWithVariants(
                msg.sender,
                EXTENSION_ID,
                tokenIds,
                variants,
                useCollection,
                collectionTokenIds
            );
    }

    function sendMessages(
        uint256[] memory senderTokenIds,
        uint256[] memory targetTokenIds,
        uint256[] memory collectionIds,
        string[] memory messages
    ) public {
        uint256 currentMessageId = nextMessageId;
        uint256 totalPayment;

        address _extensionStorageAddress = extensionStorageAddress;
        address _pixelRewarderAddress = pixelRewarderAddress;
        address _dudeRewarderAddress = dudesRewarderAddress;

        uint256 pixelBalance;
        bool pixelBalanceChecked;

        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            if (collectionIds[i] == 0) {
                require(
                    ICoreRewarder(_pixelRewarderAddress).isOwner(
                        msg.sender,
                        senderTokenIds[i]
                    ),
                    "Not authorised - Invalid owner"
                );

                uint256 currentVariant = IThePixelsIncExtensionStorageV2(
                    _extensionStorageAddress
                ).currentVariantIdOf(EXTENSION_ID, senderTokenIds[i]);
                require(currentVariant > 0, "Token has no social extension");

            } else if (collectionIds[i] == 1) {
                require(
                    ICoreRewarder(_dudeRewarderAddress).isOwner(
                        msg.sender,
                        senderTokenIds[i]
                    ),
                    "Not authorised - Invalid owner"
                );
                if (!pixelBalanceChecked) {
                    pixelBalance = ICoreRewarder(_pixelRewarderAddress).tokensOfOwner(
                        msg.sender
                    ).length;
                    pixelBalanceChecked = true;
                }
                require(
                    pixelBalance > 0,
                    "Not authorised - Not a the pixels inc owner"
                );
            } else {
                revert();
            }

            uint256 messagePrice = messagePrices[collectionIds[i]];
            totalPayment += messagePrice;

            emit MessageSent(
                msg.sender,
                currentMessageId,
                senderTokenIds[i],
                targetTokenIds[i],
                collectionIds[i],
                messages[i],
                block.timestamp
            );
            currentMessageId++;
        }
        nextMessageId = currentMessageId;
        if (totalPayment > 0) {
            payToDAO(msg.sender, totalPayment);
        }
    }

    function updateMessageVisibility(
        uint256[] memory senderTokenIds,
        uint256[] memory messageIds,
        bool[] memory isHiddens
    ) public {
        address _extensionStorageAddress = extensionStorageAddress;
        address _rewarderAddress = pixelRewarderAddress;
        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            require(
                ICoreRewarder(_rewarderAddress).isOwner(
                    msg.sender,
                    senderTokenIds[i]
                ),
                "Not authorised - Invalid owner"
            );

            uint256 currentVariant = IThePixelsIncExtensionStorageV2(
                _extensionStorageAddress
            ).currentVariantIdOf(EXTENSION_ID, senderTokenIds[i]);
            require(currentVariant > 0, "Token has no social extension");

            emit MessageVisibilityUpdated(
                msg.sender,
                messageIds[i],
                senderTokenIds[i],
                isHiddens[i],
                block.timestamp
            );
        }
    }

    function updateTokenBlockStatus(
        uint256[] memory senderTokenIds,
        uint256[] memory targetTokenIds,
        uint256[] memory collectionIds,
        bool[] memory isBlockeds
    ) public {
        address _extensionStorageAddress = extensionStorageAddress;
        address _rewarderAddress = pixelRewarderAddress;
        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            require(
                ICoreRewarder(_rewarderAddress).isOwner(
                    msg.sender,
                    senderTokenIds[i]
                ),
                "Not authorised - Invalid owner"
            );

            uint256 currentVariant = IThePixelsIncExtensionStorageV2(
                _extensionStorageAddress
            ).currentVariantIdOf(EXTENSION_ID, senderTokenIds[i]);
            require(currentVariant > 0, "Token has no social extension");

            emit TokenBlockStatusUpdated(
                msg.sender,
                senderTokenIds[i],
                targetTokenIds[i],
                collectionIds[i],
                isBlockeds[i],
                block.timestamp
            );
        }
    }

    function payToDAO(address owner, uint256 amount) internal {
        IINT(INTAddress).transferFrom(owner, DAOAddress, amount);
    }

    function _rnd(uint256 _tokenId, uint256 _salt)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        msg.sender,
                        _tokenId,
                        _salt
                    )
                )
            );
    }

    event MessageSent(
        address owner,
        uint256 indexed id,
        uint256 indexed senderTokenId,
        uint256 indexed targetTokenId,
        uint256 collectionId,
        string message,
        uint256 dateCrated
    );

    event MessageVisibilityUpdated(
        address owner,
        uint256 indexed id,
        uint256 indexed senderTokenId,
        bool indexed isHidden,
        uint256 dateCrated
    );

    event TokenBlockStatusUpdated(
        address owner,
        uint256 indexed senderTokenId,
        uint256 indexed targetTokenId,
        uint256 collectionId,
        bool indexed isBlocked,
        uint256 dateCrated
    );

    event GlobalMessageSent(
        address owner,
        uint256 indexed id,
        uint256 indexed senderId,
        string message,
        uint256 dateCrated
    );

    event GlobalMessageVisibilityUpdated(
        address owner,
        uint256 indexed id,
        uint256 indexed senderId,
        bool indexed isHidden,
        uint256 dateCrated
    );

    event GlobalTokenBlockStatusUpdated(
        address owner,
        uint256 indexed senderId,
        uint256 indexed targetTokenId,
        uint256 collectionId,
        bool indexed isBlocked,
        uint256 dateCrated
    );
}