// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
@author: dotyigit - twitter.com/dotyigit
$$$$$$$$\ $$$$$$$\  $$$$$$$\
$$  _____|$$  __$$\ $$  __$$\
$$ |      $$ |  $$ |$$ |  $$ |
$$$$$\    $$$$$$$  |$$$$$$$\ |
$$  __|   $$  ____/ $$  __$$\
$$ |      $$ |      $$ |  $$ |
$$ |      $$ |      $$$$$$$  |
\__|      \__|      \_______/
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./IMetadataProvider.sol";

contract FluffyPolarBears is ERC721, Ownable, Pausable {
    // Migration variables
    uint256 public immutable MAX_TOKEN_FPB = 9342;
    uint256 public immutable MAX_TOKEN_FPB99 = 99;
    address public immutable oldFpbContract;
    address public immutable oldFpb99Contract;
    uint256 public lastCheckedFPB = 0;
    uint256 public lastCheckedFPB99 = 0;

    // Metadata provider
    address public metadataProvider;

    // State variables
    bool public MIGRATION_OPENED = true;

    constructor(
        address oldFpbContract_,
        address oldFpb99Contract_,
        address metadataProvider_
    ) ERC721("Fluffy Polar Bears", "FPB") {
        oldFpbContract = oldFpbContract_;
        oldFpb99Contract = oldFpb99Contract_;
        metadataProvider = metadataProvider_;
    }

    function migrateFluffyPolarBears(uint256 quantity) external onlyOwner {
        require(MIGRATION_OPENED, "FPB: Migration is closed.");
        require(
            lastCheckedFPB + quantity <= MAX_TOKEN_FPB,
            "FPB: Max token allocation is reached."
        );

        IERC721 oldFpbContract_ = IERC721(oldFpbContract);
        uint256 lastCheckedFPB_ = lastCheckedFPB;
        for (uint256 i = 0; i < quantity; i++) {
            _mint(oldFpbContract_.ownerOf(lastCheckedFPB_), lastCheckedFPB_);
            lastCheckedFPB_++;
        }
        lastCheckedFPB = lastCheckedFPB_;
    }

    function migrateSpecialEditions(uint256 quantity) external onlyOwner {
        require(MIGRATION_OPENED, "FPB: Migration is closed.");
        require(
            lastCheckedFPB99 + quantity <= MAX_TOKEN_FPB99,
            "FPB: Max token allocation is reached."
        );
        IERC721 oldFpb99Contract_ = IERC721(oldFpb99Contract);
        uint256 lastCheckedFPB99_ = lastCheckedFPB99;
        for (uint256 i = 0; i < quantity; i++) {
            _mint(
                oldFpb99Contract_.ownerOf(lastCheckedFPB99_),
                lastCheckedFPB99_ + 9342
            );
            lastCheckedFPB99_++;
        }
        lastCheckedFPB99 = lastCheckedFPB99_;
    }

    function toggleMigration() external onlyOwner {
        MIGRATION_OPENED = !MIGRATION_OPENED;
    }

    function totalSupply() public view returns (uint256) {
        return lastCheckedFPB + lastCheckedFPB99;
    }

    function setMetadataProvider(address _metadataProvider) external onlyOwner {
        metadataProvider = _metadataProvider;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "FPB: URI query for nonexistent token");
        require(
            metadataProvider != address(0),
            "FPB: Invalid metadata provider address"
        );

        return IMetadataProvider(metadataProvider).getMetadata(_tokenId);
    }

    // High gas alert - only call from RPC
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_owner);
        if (balance == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](balance);
            uint256 index = 0;

            uint256 totalSupply_ = totalSupply();
            for (uint256 tokenId = 0; tokenId < totalSupply_; tokenId++) {
                if (index == balance) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }
            return result;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}