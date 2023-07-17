// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "closedsea/OperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error ChunkAlreadyProcessed();
error MismatchedArrays();
error InitialLockOn();
error MismatchedTokenOwnerForClaim();
error CannotBeClaimed();
error ClaimWindowNotOpen();
error OverMaxSupply();

interface Azuki {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract GreenBean is
    ERC1155Burnable,
    OperatorFilterer,
    Ownable,
    ERC2981,
    ReentrancyGuard
{
    using EnumerableSet for EnumerableSet.UintSet;
    using BitMaps for BitMaps.BitMap;

    // The set of chunks processed for the airdrop.
    // Intent is to help prevent double processing of chunks.
    EnumerableSet.UintSet private _processedChunksForAirdrop;

    string private _name = "GreenBean";
    string private _symbol = "GB";

    bool public initialLockOn = true;

    Azuki public immutable AZUKI;
    uint256 public immutable MAX_SUPPLY;

    bool public operatorFilteringEnabled;

    constructor(address _azukiAddress, uint256 _maxSupply) ERC1155("") {
        AZUKI = Azuki(_azukiAddress);
        MAX_SUPPLY = _maxSupply;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    bool public claimOpen = false;
    // Keys are azuki token ids
    BitMaps.BitMap private _azukiCanClaim;

    uint256 public totalMinted = 0;

    function setNameAndSymbol(
        string calldata _newName,
        string calldata _newSymbol
    ) external onlyOwner {
        _name = _newName;
        _symbol = _newSymbol;
    }

    // Thin wrapper around privilegedMint which does chunkNum checks to reduce chance of double processing chunks in a manual airdrop.
    function airdrop(
        address[] calldata receivers,
        uint256[] calldata amounts,
        uint256 chunkNum
    ) external onlyOwner {
        if (_processedChunksForAirdrop.contains(chunkNum))
            revert ChunkAlreadyProcessed();
        privilegedMint(receivers, amounts);
        _processedChunksForAirdrop.add(chunkNum);
    }

    function privilegedMint(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) public nonReentrant onlyOwner {
        if (receivers.length != amounts.length || receivers.length == 0)
            revert MismatchedArrays();
        for (uint256 i; i < receivers.length; ) {
            _mint(receivers[i], 0, amounts[i], "");
            unchecked {
                ++i;
            }
        }
        totalMinted += receivers.length;
        if (totalMinted > MAX_SUPPLY) {
            revert OverMaxSupply();
        }
    }

    function setTokenUri(string calldata newUri) external onlyOwner {
        _setURI(newUri);
    }

    // ----------------------------------------------
    // Claim Window
    // ----------------------------------------------

    function claim(uint256[] calldata azukiTokenIds) external nonReentrant {
        if (!claimOpen) {
            revert ClaimWindowNotOpen();
        }
        uint256 numToClaim = azukiTokenIds.length;
        if (totalMinted + numToClaim > MAX_SUPPLY) {
            revert OverMaxSupply();
        }
        for (uint256 i; i < numToClaim; ) {
            uint256 azukiId = azukiTokenIds[i];
            if (AZUKI.ownerOf(azukiId) != msg.sender)
                revert MismatchedTokenOwnerForClaim();
            if (!_azukiCanClaim.get(azukiId)) revert CannotBeClaimed();
            _azukiCanClaim.unset(azukiId);
            unchecked {
                ++i;
            }
        }
        totalMinted += numToClaim;
        _mint(msg.sender, 0, numToClaim, "");
    }

    function setClaimState(bool _claimOpen) external onlyOwner {
        claimOpen = _claimOpen;
    }

    function setCanClaim(uint256[] calldata azukiIds) external onlyOwner {
        for (uint256 i; i < azukiIds.length; ) {
            _azukiCanClaim.set(azukiIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getCanClaims(uint256[] calldata azukiIds)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory result = new bool[](azukiIds.length);
        for (uint256 i; i < azukiIds.length; ) {
            result[i] = _azukiCanClaim.get(azukiIds[i]);
            unchecked {
                ++i;
            }
        }
        return result;
    }

    // -------------------
    // Break transfer lock
    // -------------------
    function breakLock() external onlyOwner {
        initialLockOn = false;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        if (initialLockOn) revert InitialLockOn();
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        if (initialLockOn) revert InitialLockOn();
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        if (initialLockOn) revert InitialLockOn();
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }
}