// SPDX-License-Identifier: MIT
// Creator: Christopher Mikel Shelton

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721SZNS.sol";

error SummerTokensClaimClosed();
error SeasonsMintClosed();
error NoContractMints();
error MaxMintExceeded();
error InvalidSignature();
error NotEnoughEth();
error InncorrectLengths();
error BaseURILocked();
error RoyaltyInfoForNonexistentToken();
error TransferFailed();

contract TheArtOfSeasons is Ownable, ERC721SZNS, IERC2981 {
    using ECDSA for bytes32;

    event PermanentURI(string _value, uint256 indexed _id);
    
    // the largest possible token id from the summer season
    uint256 public constant SUMMER_MAX_TOKEN_ID = 8564;
    uint256 public constant MAX_SEASONS_COUNT = 6304;
    uint256 public constant CLAIMER_MINT_PRICE = 0.04 ether;
    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant MAX_MINT_DURING_CLAIM = 2;
    uint256 public constant MAX_MINT_PER_TX = 8;

    bool public summerTokensClaimable;
    bool public seasonsMintOpen;

    address public sigSigner = 0x68cBE370A1b35f3f185172c063BBbabF836d7Ecc;

    address public royaltyAddress;
    uint256 public royaltyPercent;

    string private _baseTokenURI;
    bool public locked;

    constructor() ERC721SZNS("The Art of Seasons", "TAOS", SUMMER_MAX_TOKEN_ID) {
        royaltyAddress = owner();
        royaltyPercent = 5;
    }

    function mintSeason(uint256 quantity) external payable {
        if (!seasonsMintOpen) revert SeasonsMintClosed();
        if (quantity > MAX_MINT_PER_TX) revert MaxMintExceeded();
        if (tx.origin != msg.sender) revert NoContractMints();
        if (tokensMinted() + quantity > MAX_SEASONS_COUNT) revert MaxMintExceeded();

        _mint(msg.sender, quantity);
        _refundOverPayment(MINT_PRICE * quantity);
    }

    function mintForSummerHolder(bytes calldata ticketSignature, uint256 ticket, uint256 quantity) external payable {
        if (!summerTokensClaimable) revert SummerTokensClaimClosed();
        if (quantity > MAX_MINT_DURING_CLAIM) revert MaxMintExceeded();
        if (tx.origin != msg.sender) revert NoContractMints();
        if (tokensMinted() + quantity > MAX_SEASONS_COUNT) revert MaxMintExceeded();

        _claimSummerMintTicket(ticketSignature, ticket, quantity);
        _mint(msg.sender, quantity);
        _refundOverPayment(CLAIMER_MINT_PRICE * quantity);
    }

    function claimSummer(
        bytes calldata claimSignature,
        uint256[] calldata tokens,
        uint256[] calldata claimIdxs
    ) external payable {
        if (!summerTokensClaimable) revert SummerTokensClaimClosed();
        if (tx.origin != msg.sender) revert NoContractMints();

        uint256 len = claimIdxs.length;
        if (len - 1 > tokens.length) revert InncorrectLengths();

        _verifyClaimSignature(claimSignature, tokens);

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = tokens[claimIdxs[i]];
            _claim(msg.sender, tokenId);
        }
    }

    function claimSummerAndMint(
        bytes calldata claimSignature,
        bytes calldata ticketSignature,
        uint256[] calldata tokens,
        uint256[] calldata claimIdxs,
        uint256 ticket,
        uint256 mintQty
    ) external payable {
        if (!summerTokensClaimable) revert SummerTokensClaimClosed();
        if (mintQty > MAX_MINT_DURING_CLAIM) revert MaxMintExceeded();
        if (tx.origin != msg.sender) revert NoContractMints();
        if (tokensMinted() + mintQty > MAX_SEASONS_COUNT) revert MaxMintExceeded();

        uint256 len = claimIdxs.length;
        if (len - 1 > tokens.length) revert InncorrectLengths();

        _verifyClaimSignature(claimSignature, tokens);

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = tokens[claimIdxs[i]];
            _claim(msg.sender, tokenId);
        }

        if (mintQty == 0) return;

        _claimSummerMintTicket(ticketSignature, ticket, mintQty);
        _mint(msg.sender, mintQty);
        _refundOverPayment(CLAIMER_MINT_PRICE * mintQty);
    }

    function claimAllSummer(bytes calldata signature, uint256[] calldata tokens) external payable {
        if (!summerTokensClaimable) revert SummerTokensClaimClosed();
        if (tx.origin != msg.sender) revert NoContractMints();

        _verifyClaimSignature(signature, tokens);

        uint256 len = tokens.length;

        for (uint256 i = 0; i < len; i++) {
            _claim(msg.sender, tokens[i]);
        }
    }

    function claimAllSummerAndMint(
        bytes calldata claimSignature,
        bytes calldata ticketSignature,
        uint256[] calldata tokens,
        uint256 ticket,
        uint256 mintQty
    ) external payable {
        if (!summerTokensClaimable) revert SummerTokensClaimClosed();
        if (mintQty > MAX_MINT_DURING_CLAIM) revert MaxMintExceeded();
        if (tx.origin != msg.sender) revert NoContractMints();
        if (tokensMinted() + mintQty > MAX_SEASONS_COUNT) revert MaxMintExceeded();

        _verifyClaimSignature(claimSignature, tokens);

        uint256 len = tokens.length;

        for (uint256 i = 0; i < len; i++) {
            _claim(msg.sender, tokens[i]);
        }

        if (mintQty == 0) return;

        _claimSummerMintTicket(ticketSignature, ticket, mintQty);
        _mint(msg.sender, mintQty);
        _refundOverPayment(CLAIMER_MINT_PRICE * mintQty);
    }

    function _refundOverPayment(uint256 amount) internal {
        if (msg.value < amount) revert NotEnoughEth();
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);
        }
    }

    function setSigSigner(address signer) external onlyOwner {
        if (signer == address(0)) revert OwnerIsZeroAddress();
        sigSigner = signer;
    }

    function _verifyClaimSignature(bytes calldata signature, uint256[] calldata tokens) internal view {
        address signedAddr = keccak256(abi.encodePacked(msg.sender, tokens))
            .toEthSignedMessageHash()
            .recover(signature);

        if (sigSigner != signedAddr) revert InvalidSignature();
    }

    uint256 private constant MAX_INT = 2**256-1;

    uint256 private mintGroup0 = MAX_INT;
    uint256 private mintGroup1 = MAX_INT;
    uint256 private mintGroup2 = MAX_INT;
    uint256 private mintGroup3 = MAX_INT;
    uint256 private mintGroup4 = MAX_INT;
    uint256 private mintGroup5 = MAX_INT;

    function _getBitForTicket(uint256 ticket) internal view returns(uint256) {
        uint256 slot;
        uint256 offsetInSlot;
        uint256 localGroup;

        unchecked {
            slot = ticket / 256;
            offsetInSlot = ticket % 256;
        }

        assembly {
            slot := add(mintGroup0.slot, slot)
            localGroup := sload(slot)
        }

        return (localGroup >> offsetInSlot) & uint256(1);
    }

    function _useBitForTicket(uint256 ticket) internal {
        uint256 slot;
        uint256 offsetInSlot;
        uint256 localGroup;

        unchecked {
            slot = ticket / 256;
            offsetInSlot = ticket % 256;
        }

        assembly {
            slot := add(mintGroup0.slot, slot)
            localGroup := sload(slot)
        }

        localGroup = localGroup & ~(uint256(1) << offsetInSlot);

        assembly {
            sstore(slot, localGroup)
        }
    }

    function _claimSummerMintTicket(bytes calldata signature, uint256 ticket, uint256 mintQty) internal {
        
        address signedAddr = keccak256(abi.encodePacked(msg.sender, ticket))
            .toEthSignedMessageHash()
            .recover(signature);

        if (sigSigner != signedAddr) revert InvalidSignature();

        // check the ticket number for the first mint available for minter
        uint256 storedBit1 = _getBitForTicket(ticket);

        // we will use the second ticket slot first
        // so if the first ticket slot is used, then we have none available
        if (storedBit1 == 0) revert MaxMintExceeded();

        uint256 secondTicket = ticket + 1;
        uint256 storedBit2 = _getBitForTicket(secondTicket);

        if (storedBit2 == 1) {
            _useBitForTicket(secondTicket);

            if (mintQty == 2) {
                _useBitForTicket(ticket);
            }
        } else {
            if (mintQty == 2) revert MaxMintExceeded();

            // mintQty is 1 and available is 1
            _useBitForTicket(ticket);
        }
    }

    function numberMintedDuringClaim(uint256 ticket) external view returns (uint256) {
        uint256 storedBit1 = _getBitForTicket(ticket);

        if (storedBit1 == 0) return 2;
        
        uint256 storedBit2 = _getBitForTicket(ticket + 1);

        if (storedBit2 == 0) return 1;

        return 0;
    }

    function toggleClaiming() external onlyOwner {
        summerTokensClaimable = !summerTokensClaimable;
    }

    function toggleMint() external onlyOwner {
        seasonsMintOpen = !seasonsMintOpen;
    }

    function setRoyaltyReceiver(address royaltyReceiver) external onlyOwner {
        royaltyAddress = royaltyReceiver;
    }

    function setRoyaltyPercentage(uint256 royaltyPercentage) external onlyOwner {
        royaltyPercent = royaltyPercentage;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        if (!_exists(tokenId)) revert RoyaltyInfoForNonexistentToken();
        return (royaltyAddress, salePrice * royaltyPercent / 100);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        if (locked) revert BaseURILocked();
        _baseTokenURI = baseURI_;
    }

    function lockBaseURI() external onlyOwner {
        if (locked) revert BaseURILocked();
        locked = true;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    // @dev contract owner must be an EOA account
    function devClaimForHolder(uint256 tokenId, address to) external onlyOwner {
        _claim(to, tokenId);
    }

    // used for giveaways
    // @dev contract owner must be an EOA account
    function devMint(uint256 quantity, address to) external onlyOwner {
        if (tokensMinted() + quantity > MAX_SEASONS_COUNT) revert MaxMintExceeded();

        _mint(to, quantity);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721SZNS, IERC165) returns(bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }
}