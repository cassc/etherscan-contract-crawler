// SPDX-License-Identifier: MIT

/*
                8888888888 888                   d8b
                888        888                   Y8P
                888        888
                8888888    888 888  888 .d8888b  888 888  888 88888b.d88b.
                888        888 888  888 88K      888 888  888 888 "888 "88b
                888        888 888  888 "Y8888b. 888 888  888 888  888  888
                888        888 Y88b 888      X88 888 Y88b 888 888  888  888
                8888888888 888  "Y88888  88888P' 888  "Y88888 888  888  888
                                    888
                               Y8b d88P
                                "Y88P"
                888b     d888          888              .d8888b.                888
                8888b   d8888          888             d88P  Y88b               888
                88888b.d88888          888             888    888               888
                888Y88888P888  .d88b.  888888  8888b.  888         .d88b.   .d88888 .d8888b
                888 Y888P 888 d8P  Y8b 888        "88b 888  88888 d88""88b d88" 888 88K
                888  Y8P  888 88888888 888    .d888888 888    888 888  888 888  888 "Y8888b.
                888   "   888 Y8b.     Y88b.  888  888 Y88b  d88P Y88..88P Y88b 888      X88
                888       888  "Y8888   "Y888 "Y888888  "Y8888P88  "Y88P"   "Y88888  88888P'
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

contract MetaGodsLootBoxRewardPool is Initializable, OwnableUpgradeable, PausableUpgradeable {

    address private signerAddress;

    mapping(uint256 => bool) public rewardsClaimed;

    event RewardClaimed(address wallet, uint256 identifier);

    modifier notClaimed(uint256 identifier_) {
        require(rewardsClaimed[identifier_] == false, "Already claimed");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
    }

    function areRewardsClaimed(uint256[] calldata identifiers_) external view returns (bool[] memory) {
        bool[] memory areClaimed = new bool[](identifiers_.length);
        for(uint i = 0; i < identifiers_.length; ++i) {
            areClaimed[i] = rewardsClaimed[identifiers_[i]];
        }
        return areClaimed;
    }

    function claimERC20Asset(
        uint256 identifier_,
        address fromAddress_,
        address collectionAddress_,
        uint256 amount_,
        bytes calldata signature_
    ) external whenNotPaused notClaimed(identifier_) {
        _validateClaimERC20Asset(identifier_, fromAddress_, collectionAddress_, amount_, signature_);
        signalRewardClaimed(msg.sender, identifier_);
        IERC20Upgradeable(collectionAddress_).transferFrom(fromAddress_, msg.sender, amount_);
    }

    function claimERC721Asset(
        uint256 identifier_,
        address fromAddress_,
        address collectionAddress_,
        uint256 tokenId_,
        bytes calldata signature_
    ) external whenNotPaused notClaimed(identifier_) {
        _validateClaimERC721Asset(identifier_, fromAddress_, collectionAddress_, tokenId_, signature_);
        signalRewardClaimed(msg.sender, identifier_);
        IERC721Upgradeable(collectionAddress_).safeTransferFrom(fromAddress_, msg.sender, tokenId_);
    }

    function claimERC1155Asset(
        uint256 identifier_,
        address fromAddress_,
        address collectionAddress_,
        uint256 tokenId_,
        uint256 amount_,
        bytes calldata signature_
    ) external whenNotPaused notClaimed(identifier_) {
        _validateClaimERC1155Asset(identifier_, fromAddress_, collectionAddress_, tokenId_, amount_, signature_);
        signalRewardClaimed(msg.sender, identifier_);
        IERC1155Upgradeable(collectionAddress_).safeTransferFrom(fromAddress_, msg.sender, tokenId_, amount_, "");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setSignerAddress(address signerAddress_) external onlyOwner {
        signerAddress = signerAddress_;
    }

    function signalRewardClaimed(address wallet_, uint256 identifier_) internal {
        rewardsClaimed[identifier_] = true;
        emit RewardClaimed(wallet_, identifier_);
    }

    function _validateClaimERC20Asset(
        uint256 identifier_,
        address fromAddress_,
        address collectionAddress_,
        uint256 amount_,
        bytes calldata signature_
    ) internal view {
        bytes32 dataHash = keccak256(abi.encodePacked(identifier_, fromAddress_, collectionAddress_, amount_, msg.sender));
        bytes32 message = ECDSAUpgradeable.toEthSignedMessageHash(dataHash);
        address receivedAddress = ECDSAUpgradeable.recover(message, signature_);
        require(receivedAddress != address(0) && receivedAddress == signerAddress);
    }

    function _validateClaimERC721Asset(
        uint256 identifier_,
        address fromAddress_,
        address collectionAddress_,
        uint256 tokenId_,
        bytes calldata signature_
    ) internal view {
        bytes32 dataHash = keccak256(abi.encodePacked(identifier_, fromAddress_, collectionAddress_, tokenId_, msg.sender));
        bytes32 message = ECDSAUpgradeable.toEthSignedMessageHash(dataHash);
        address receivedAddress = ECDSAUpgradeable.recover(message, signature_);
        require(receivedAddress != address(0) && receivedAddress == signerAddress);
    }

    function _validateClaimERC1155Asset(
        uint256 identifier_,
        address fromAddress_,
        address collectionAddress_,
        uint256 tokenId_,
        uint256 amount_,
        bytes calldata signature_
    ) internal view {
        bytes32 dataHash = keccak256(abi.encodePacked(identifier_, fromAddress_, collectionAddress_, tokenId_, amount_, msg.sender));
        bytes32 message = ECDSAUpgradeable.toEthSignedMessageHash(dataHash);
        address receivedAddress = ECDSAUpgradeable.recover(message, signature_);
        require(receivedAddress != address(0) && receivedAddress == signerAddress);
    }

}