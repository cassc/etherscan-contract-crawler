// AbsoluteLabsAirdrop v0.1
// Contract performing airdrops for customers of absolutelabs.io

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./utils/Errors.sol";

interface IERC721 {
    function approve(address to, uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(address operator, bool _approved) external;
}

contract AbsoluteLabsAirDropERC721 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable
{
    // ERC721 token IDs per team.
    // teamId => (NFT coll contract address => IDs in airdrop contract)
    mapping(string => mapping(IERC721 => uint256[])) public erc721TokenIds;

    function initialize() public initializer {
        __Ownable_init();
    }

    function getBalance(
        string calldata teamId,
        IERC721 token
     ) external view returns(uint256) {
        return erc721TokenIds[teamId][token].length;
     }

    // Fund this contract with ERC721 tokens
    function fundERC721(
        string calldata teamId,
        IERC721 token,
        uint256[] calldata _tokenIds
    ) external nonReentrant {
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ) {
            if (token.ownerOf(_tokenIds[i]) != msg.sender)
                revert Errors.NotTheTokenOwner();
            token.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            erc721TokenIds[teamId][token].push(_tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function airdropERC721(
        string calldata teamId,
        IERC721 token,
        address[] memory recipients,
        uint256 amountPerRecipient
    ) external onlyOwner returns (bool) {
        if (
            amountPerRecipient * recipients.length >
            erc721TokenIds[teamId][token].length
        ) revert Errors.InsufficientBalance();

        uint256 currIndex = 0;

        for (uint256 recipientId = 0; recipientId < recipients.length; ) {
            for (uint256 i = 0; i < amountPerRecipient; ) {
                token.transferFrom(
                    address(this),
                    recipients[recipientId],
                    erc721TokenIds[teamId][token][currIndex]
                );

                erc721TokenIds[teamId][token][currIndex] = erc721TokenIds[teamId][token][erc721TokenIds[teamId][token].length - 1];
                erc721TokenIds[teamId][token].pop();

                unchecked {
                    ++i;
                    ++currIndex;
                }
            }

            unchecked {
                recipientId++;
            }
        }

        return true;
    }

    function directAirdropERC721(
        IERC721 token,
        address[] calldata recipients,
        uint256[] calldata _tokenIds
    ) external onlyOwner {
        if (recipients.length != _tokenIds.length)
            revert Errors.RecipientsAndIDsAreNotTheSameLength();
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ) {
            address tokenOwner = token.ownerOf(_tokenIds[i]);
            token.transferFrom(
                tokenOwner,
                address(recipients[i]),
                _tokenIds[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    function withdrawERC721(
        string calldata teamId,
        IERC721 token,
        uint256 quantity,
        address to
    ) external onlyOwner {
        if (quantity > erc721TokenIds[teamId][token].length)
            revert Errors.InsufficientBalance();
        for (uint256 i = 0; i < quantity; ) {
            token.transferFrom(
                address(this),
                to,
                erc721TokenIds[teamId][token][i]
            );

            erc721TokenIds[teamId][token][i] = erc721TokenIds[teamId][token][erc721TokenIds[teamId][token].length - 1];
            erc721TokenIds[teamId][token].pop();

            unchecked {
                ++i;
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}