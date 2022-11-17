// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../lib/erc721-operator-filter/ERC721AOperatorFilterUpgradeable.sol";
import "../lib/OnlyDevMultiSigUpgradeable.sol";

abstract contract BlackdustFactory {
    function awaken(address to, uint256 tokenId)
        public
        virtual
        returns (uint256);

    function awaken(address to, uint256[] memory tokenIds)
        public
        virtual
        returns (uint256[] memory);
}

error SetBlackdustToZeroAddress();

abstract contract AwakeningV2 is
    ReentrancyGuardUpgradeable,
    OnlyDevMultiSigUpgradeable,
    ERC721AOperatorFilterUpgradeable
{
    error BlackdustFactoryNotOpenYet();
    error AwakenIsClosed();
    error CannotAwakenWithUnownedTakrut();

    address private blackdustContract;
    bool public canAwaken;

    event Awakened(address to, uint256 takrutId);
    event AwakenedMany(address to, uint256[] takrutIds);

    function awaken(uint256 takrutId) public nonReentrant returns (uint256) {
        if (!canAwaken) {
            if (_msgSenderERC721A() != owner()) revert AwakenIsClosed();
        }
        address to = ownerOf(takrutId);

        if (to != _msgSenderERC721A()) {
            if (_msgSenderERC721A() != owner())
                revert CannotAwakenWithUnownedTakrut();
        }

        BlackdustFactory factory = BlackdustFactory(blackdustContract);

        _burn(takrutId, true);

        uint256 blackdustTokenId = factory.awaken(to, takrutId);

        emit Awakened(to, takrutId);
        return blackdustTokenId;
    }

    function awakenMany(uint256[] memory takrutIds)
        public
        nonReentrant
        returns (uint256[] memory)
    {
        if (!canAwaken) {
            if (_msgSenderERC721A() != owner()) revert AwakenIsClosed();
        }

        uint256 n = takrutIds.length;
        for (uint256 i = 0; i < n; ++i) {
            address to = ownerOf(takrutIds[i]);
            if (to != _msgSenderERC721A()) {
                if (_msgSenderERC721A() != owner())
                    revert CannotAwakenWithUnownedTakrut();
            }
            _burn(takrutIds[i], true);
        }

        BlackdustFactory factory = BlackdustFactory(blackdustContract);
        uint256[] memory blackdustTokenIds = factory.awaken(
            _msgSenderERC721A(),
            takrutIds
        );

        emit AwakenedMany(_msgSenderERC721A(), takrutIds);
        return blackdustTokenIds;
    }

    function takrutUsed(address addr) external view returns (uint256) {
        return _numberBurned(addr);
    }

    function totalTakrutUsed() external view returns (uint256) {
        return _totalBurned();
    }

    function toggleCanAwaken() external onlyOwner {
        if (blackdustContract == address(0))
            revert BlackdustFactoryNotOpenYet();
        canAwaken = !canAwaken;
    }

    function setBlackdustContract(address contractAddress) external onlyOwner {
        blackdustContract = contractAddress;
    }
}