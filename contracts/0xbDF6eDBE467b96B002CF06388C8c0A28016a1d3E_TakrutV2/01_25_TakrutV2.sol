// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "../lib/erc721-operator-filter/ERC721AOperatorFilterUpgradeable.sol";
import "../lib/OnlyDevMultiSigUpgradeable.sol";
import "./AwakeningV2.sol";
import "../lib/Refund.sol";
import "./TakrutSaleV2.sol";

error SetDevMultiSigToZeroAddress();
error InvalidQueryRange();
error NotTakrutOwner();

contract TakrutV2 is
    ReentrancyGuardUpgradeable,
    OnlyDevMultiSigUpgradeable,
    ERC721AOperatorFilterUpgradeable,
    ERC2981Upgradeable,
    AwakeningV2,
    Refund,
    TakrutSaleV2
{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;
    string private baseURI;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNewSupply(uint256 _newMaxSupply) public onlyOwner {
        MAX_SUPPLY = _newMaxSupply;
    }

    function setNewMaxFreeSupply(uint256 _newMaxFreeSupply) public onlyOwner {
        MAX_FREE_SUPPLY = _newMaxFreeSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "NOT_EXISTS");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function walletOfOwner(address owner_)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(owner_);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner_, i);
        }

        return tokenIds;
    }

    function explicitOwnershipOf(uint256 tokenId)
        public
        view
        returns (TokenOwnership memory)
    {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds)
        external
        view
        returns (TokenOwnership[] memory)
    {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](
                tokenIdsLength
            );
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (
                uint256 i = start;
                i != stop && tokenIdsIdx != tokenIdsMaxLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function tokenOfOwnerByIndex(address owner_, uint256 index)
        public
        view
        returns (uint256)
    {
        require(
            index < balanceOf(owner_),
            "ERC721AUpgradeable: owner index out of bounds"
        );
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);

        for (uint256 i = 0; i < numMintedSoFar; i++) {
            TokenOwnership memory ownership = _ownershipOf(i);
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner_) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("ERC721AUpgradeable: unable to get token of owner by index");
    }

    /* 
        BACK OFFICE
    */
    function setDevMultiSigAddress(address payable _address)
        external
        onlyDevMultiSig
    {
        if (_address == address(0)) revert SetDevMultiSigToZeroAddress();
        _devMultiSigWallet = _address;
        updateDevMultiSigWallet(_address);
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyDevMultiSig
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function withdrawTokensToDev(IERC20Upgradeable token)
        public
        onlyDevMultiSig
    {
        uint256 funds = token.balanceOf(address(this));
        require(funds > 0, "No token left");
        token.transfer(address(_devMultiSigWallet), funds);
    }

    function withdrawETHBalanceToDev() public onlyDevMultiSig {
        require(address(this).balance > 0, "No ETH left");

        (bool success, ) = address(_devMultiSigWallet).call{
            value: address(this).balance
        }("");

        require(success, "Transfer failed.");
    }

    function burnMany(uint256[] memory takrutIds) public nonReentrant {
        uint256 n = takrutIds.length;
        for (uint256 i = 0; i < n; ++i) {
            address to = ownerOf(takrutIds[i]);
            if (to != _msgSenderERC721A()) {
                revert NotTakrutOwner();
            }

            _burn(takrutIds[i], true);
        }
    }
}