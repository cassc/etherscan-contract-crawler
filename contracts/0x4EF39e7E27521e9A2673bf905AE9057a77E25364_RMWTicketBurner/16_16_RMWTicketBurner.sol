// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./RMWFreedomTicket.sol";
import "./RMWExclusiveTicket.sol";

contract RMWTicketBurner is Ownable {
    event BurnTicket(
        address indexed user,
        uint256 ticketQuantity,
        uint256 indexed tokenId,
        uint256 upgradeCount,
        uint256 currentLevel,
        bool success
    );

    address public signerAddress;

    RMWExclusiveTicket exclusiveTicket;
    RMWFreedomTicket freedomTicket;
    IERC721 nft;
    address public exclusiveTicketAddress;
    address public freedomTicketAddress;

    uint256 public nonTradableTokenId;
    uint256 public tradableTokenId;

    uint8 public maxNFTLevel = 3;
    uint8 public maxNFTUpgradeTry = 1;
    uint8 public ticketMinBurnLimit = 1;
    mapping(uint256 => uint8) public nftLevelMapping;
    mapping(uint256 => mapping(uint8 => uint8)) public nftUpgradeCountMapping;

    constructor(
        string memory _uri,
        address _nftAddress,
        address _signerAddress,
        address _feeAddress,
        uint96 _feeNumerator
    ) {
        signerAddress = _signerAddress;

        nft = IERC721(_nftAddress);
        exclusiveTicket = new RMWExclusiveTicket(_uri);
        freedomTicket = new RMWFreedomTicket(_uri, _feeAddress, _feeNumerator);
        exclusiveTicketAddress = address(exclusiveTicket);
        freedomTicketAddress = address(freedomTicket);

        nonTradableTokenId = exclusiveTicket.nonTradableTokenId();
        tradableTokenId = freedomTicket.tradableTokenId();
    }

    function mint(uint256 quantity) external onlyOwner {
        freedomTicket.mint(msg.sender, quantity);
    }

    function burn(
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 nftTokenId,
        uint256 randomNumber,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(isAuthorized(randomNumber, v, r, s), "Invalid signature");

        require(nft.ownerOf(nftTokenId) == msg.sender, "Not own this NFT");
        require(
            nftLevelMapping[nftTokenId] + 1 < maxNFTLevel,
            "Exceed NFT upgrade level"
        );

        uint256 ticketQuantity = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            ticketQuantity += amounts[i];
        }

        require(
            ticketQuantity >= ticketMinBurnLimit,
            "Below ticket burn limit"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == nonTradableTokenId) {
                exclusiveTicket.burn(msg.sender, amounts[i]);
            } else if (ids[i] == tradableTokenId) {
                freedomTicket.burn(msg.sender, amounts[i]);
            }
        }

        uint8 currentLevel = nftLevelMapping[nftTokenId];
        bool success = nftUpgradeCountMapping[nftTokenId][currentLevel] >=
            maxNFTUpgradeTry ||
            random() % 2 == 0;
        if (success) {
            nftLevelMapping[nftTokenId] += 1;
        }
        nftUpgradeCountMapping[nftTokenId][currentLevel] += 1;

        emit BurnTicket(
            msg.sender,
            ticketQuantity,
            nftTokenId,
            nftUpgradeCountMapping[nftTokenId][currentLevel],
            nftLevelMapping[nftTokenId],
            success
        );
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        msg.data,
                        msg.sender
                    )
                )
            );
    }

    function mintForAirdrop(address[] memory addresses, uint256 quantity)
        external
        onlyOwner
    {
        exclusiveTicket.mintForAirdrop(addresses, quantity);
    }

    function setMintConfig(uint8 _maxNFTLevel, uint8 _ticketMinBurnLimit)
        external
        onlyOwner
    {
        maxNFTLevel = _maxNFTLevel;
        ticketMinBurnLimit = _ticketMinBurnLimit;
    }

    function isAuthorized(
        uint256 randomNumber,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, randomNumber));
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        return signerAddress == ecrecover(signedHash, v, r, s);
    }
}