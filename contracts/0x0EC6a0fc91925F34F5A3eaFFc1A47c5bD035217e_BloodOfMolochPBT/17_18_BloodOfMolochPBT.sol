// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chiru-labs/pbt/src/PBTSimple.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IBurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error MintNotOpen();
error TotalSupplyReached();
error CannotUpdateDeadline();
error CannotMakeChanges();
error NoClaimToken();

contract BloodOfMolochPBT is PBTSimple, Ownable, ReentrancyGuard {
    uint256 public constant TOTAL_SUPPLY = 350;
    uint256 public supply;
    uint256 public changeDeadline;
    bool public canMint;

    string private _baseTokenURI;
    address private _claimToken;
    bool private _seeded;

    event Burn (
        address indexed from,
        uint256 tokenId,
        address indexed claimToken
    );

    constructor() PBTSimple("Blood of Moloch", "BoM") {}

    function mint(
        uint256 claimTokenId,
        bytes calldata signatureFromChip,
        uint256 blockHashUsedInSig
    ) external nonReentrant {
        if (!canMint) {
            revert MintNotOpen();
        }
        if (supply == TOTAL_SUPPLY) {
            revert TotalSupplyReached();
        }
        if (_claimToken == address(0)) {
            revert NoClaimToken();
        }
        require(IERC721(_claimToken).ownerOf(claimTokenId) == _msgSender(), "BloodOfMoloch: not owner of claim token");
        require(
            IERC721(_claimToken).isApprovedForAll(_msgSender(), address(this)) || IERC721(_claimToken).getApproved(claimTokenId) == address(this),
            "BloodOfMoloch: not approved"
        );
        _mintTokenWithChip(signatureFromChip, blockHashUsedInSig);
        _burnClaimToken(claimTokenId);
        unchecked {
            ++supply;
        }
    }

    /**************************************
     *        Only Owner Functions        *
     **************************************/

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
        _seeded = true;
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
        require(bytes(_baseTokenURI).length > 0, "BloodOfMoloch: no base URI");
        require(_claimToken != address(0), "BloodOfMoloch: no claim token");
        require(_seeded, "BloodOfMoloch: no chips seeded");
        canMint = true;
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

    function setClaimToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "BloodOfMoloch: null address");
        _claimToken = tokenAddress;
    }

    /**************************************
     *        Internal Functions          *
     **************************************/

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _burnClaimToken(uint256 tokenId) internal {
        IBurnable(_claimToken).burn(tokenId);
        emit Burn(_msgSender(), tokenId, _claimToken);
    }
}