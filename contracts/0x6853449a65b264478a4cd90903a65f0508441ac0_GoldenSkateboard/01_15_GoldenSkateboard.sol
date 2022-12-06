// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chiru-labs/pbt/src/PBTSimple.sol";

error MintNotOpen();
error TotalSupplyReached();
error CannotUpdateDeadline();
error CannotMakeChanges();

contract GoldenSkateboard is PBTSimple, Ownable {
    uint256 public constant TOTAL_SUPPLY = 9;
    uint256 public supply;
    uint256 public changeDeadline;
    bool public canMint;

    string private _baseTokenURI;

    constructor(string memory name_, string memory symbol_)
        PBTSimple(name_, symbol_)
    {}

    function mintSkateboard(
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig
    ) external {
        if (!canMint) {
            revert MintNotOpen();
        }
        if (supply == TOTAL_SUPPLY) {
            revert TotalSupplyReached();
        }
        _mintTokenWithChip(signatureFromChip, blockNumberUsedInSig);
        unchecked {
            ++supply;
        }
    }

    function seedChipToTokenMapping(
        address[] calldata chipAddresses,
        uint256[] calldata tokenIds,
        bool throwIfTokenAlreadyMinted
    ) external onlyOwner {
        _seedChipToTokenMapping(
            chipAddresses,
            tokenIds,
            throwIfTokenAlreadyMinted
        );
    }

    function updateChips(
        address[] calldata chipAddressesOld,
        address[] calldata chipAddressesNew
    ) external onlyOwner {
        if (changeDeadline != 0 && block.timestamp > changeDeadline) {
            revert CannotMakeChanges();
        }
        _updateChips(chipAddressesOld, chipAddressesNew);
    }

    function openMint() external onlyOwner {
        canMint = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setChangeDeadline(uint256 timestamp) external onlyOwner {
        if (changeDeadline != 0) {
            revert CannotUpdateDeadline();
        }
        changeDeadline = timestamp;
    }
}