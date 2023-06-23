// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './RandomlyAssigned.sol';

/**
 * @title The Party Spud Club's ApeRon Giveaway contract
 * @dev Extends the ERC721 Non-Fungible Token Standard
 */
contract ApeRonGiveaway is ERC721, Ownable, RandomlyAssigned {
    using SafeMath for uint256;
    using Strings for uint256;

    // ======================================================== Structs and Enums

    struct MintTypes {
        uint256 _numberOfGiveawaysByAddress;
        uint256 _numberOfMintsByAddress;
    }

    struct Voucher {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }
    enum VoucherType {
        OGHodler,
        FreeMint,
        Whitelist,
        ApeFreeMint,
        ApeGiveaway
    }
    enum SalePhase {
        Locked,
        Open
    }

    // ======================================================== Private Variables

    string private constant _defaultBaseURI =
        'https://api.thepartyspudclub.io/aperon-giveaway/metadata';

    address private teamAddress = 0xa54F87a652254baA2D1B39984a7E25022681fF41;

    // ======================================================== Public Variables

    uint256 public constant MAX_GIVEAWAY_SUPPLY = 199;

    address public immutable adminSigner;

    string public tokenBaseURI;

    SalePhase public phase = SalePhase.Open;

    uint256 public apePrice = 0.005555 ether;

    uint256 public maxMintsPerAddress = 10; // max total mints per address

    mapping(address => MintTypes) public addressToMints;

    // ======================================================== Constructor

    constructor(
        string memory _uri,
        address _adminSigner
    )
        ERC721('ApeRon LFG', 'APERONLFG')
        RandomlyAssigned(MAX_GIVEAWAY_SUPPLY, 0)
    {
        tokenBaseURI = _uri;
        adminSigner = _adminSigner;
    }

    // ======================================================== Spud Emperor Functions

    /// Set the base URI for the metadata
    /// @dev modifies the state of the `_tokenBaseURI` variable
    /// @param URI the URI to set as the base token URI
    function setBaseURI(string memory URI) external onlyOwner {
        tokenBaseURI = URI;
    }

    /// Updates the team address
    /// @dev modifies the state of the `teamAddress` variable
    /// @notice updates the team address
    /// @param newAddress_ The new price for minting
    function updateTeamAddress(address newAddress_) external onlyOwner {
        teamAddress = newAddress_;
    }

    /// Adjust the mint price
    /// @dev modifies the state of the `apePrice` variable
    /// @notice sets the price for minting a token
    /// @param newPrice_ The new price for minting
    function adjustMintPrice(uint256 newPrice_) external onlyOwner {
        apePrice = newPrice_;
    }

    /// Adjust the maximum allowed mints per address
    /// @dev modifies the state of the `maxMintsPerAddress` variable
    /// @notice sets the maximum allowed mints per address
    /// @param maxMintsPerAddress_ The new price maximum
    function adjustMaximumMints(
        uint256 maxMintsPerAddress_
    ) external onlyOwner {
        maxMintsPerAddress = maxMintsPerAddress_;
    }

    /// Enter Phase
    /// @dev Updates the `phase` variable
    /// @notice Enters a new sale phase
    function enterPhase(SalePhase phase_) external onlyOwner {
        phase = phase_;
    }

    /// Disburse payments
    /// @dev transfers amounts that correspond to addresses passeed in as args
    /// @param payees_ recipient addresses
    /// @param amounts_ amount to payout to address with corresponding index in the `payees_` array
    function disbursePayments(
        address[] memory payees_,
        uint256[] memory amounts_
    ) external onlyOwner {
        require(
            payees_.length == amounts_.length,
            'Payees and amounts length mismatch'
        );
        for (uint256 i; i < payees_.length; i++) {
            makePaymentTo(payees_[i], amounts_[i]);
        }
    }

    /// Make a payment
    /// @dev internal fn called by `disbursePayments` to send Ether to an address
    function makePaymentTo(address address_, uint256 amt_) private {
        (bool success, ) = address_.call{value: amt_}('');
        require(success, 'Transfer failed.');
    }

    // ======================================================== External Functions

    /// Claim Free Mint Tokens
    /// @dev mints the qty of tokens verified using vouchers signed by an admin signer
    /// @notice claims earned free tokens
    /// @param count number of tokens to claim in transaction
    /// @param allotted total number of tokens recipient is allowed to claim
    /// @param voucher voucher for verifying the signer
    function claimGiveawayTokens(
        uint256 count,
        uint256 allotted,
        Voucher memory voucher
    ) external ensureAvailabilityFor(count) {
        require(phase == SalePhase.Open, 'Giveaway Minting is not active');
        bytes32 digest = keccak256(
            abi.encode(VoucherType.ApeGiveaway, allotted, msg.sender)
        );
        require(_isVerifiedVoucher(digest, voucher), 'Invalid voucher');
        require(
            count + addressToMints[msg.sender]._numberOfGiveawaysByAddress <=
                allotted,
            'Exceeds number of earned Apes'
        );
        addressToMints[msg.sender]._numberOfGiveawaysByAddress += count;
        for (uint256 i; i < count; i++) {
            _mintRandomId(msg.sender);
        }
    }

    /// Public minting open to all
    /// @dev mints tokens during public sale, limited by `maxMintsPerAddress`
    /// @notice mints tokens with randomized IDs to the sender's address
    /// @param count number of tokens to mint in transaction
    function mintApe(
        uint256 count
    ) external payable validateEthPayment(count) ensureAvailabilityFor(count) {
        require(phase == SalePhase.Open, 'Public sale is not active');
        require(
            count + addressToMints[msg.sender]._numberOfMintsByAddress <=
                maxMintsPerAddress,
            'Exceeds maximum allowable mints'
        );
        addressToMints[msg.sender]._numberOfMintsByAddress += count;
        for (uint256 i; i < count; i++) {
            _mintRandomId(msg.sender);
        }
    }

    // ======================================================== Internal Functions

    /// @dev make sure that the voucher sent was signed by the admin signer
    function _isVerifiedVoucher(
        bytes32 digest,
        Voucher memory voucher
    ) private view returns (bool) {
        address signer = ecrecover(digest, voucher.v, voucher.r, voucher.s);
        require(signer != address(0), 'ECDSA: invalid voucher');
        return signer == adminSigner;
    }

    /// @dev internal check to ensure a reserved token ID, or ID outside of the collection, doesn't get minted
    function _mintRandomId(address to) private {
        uint256 id = nextToken();
        assert(id <= MAX_GIVEAWAY_SUPPLY);
        _safeMint(to, id);
    }

    // ======================================================== Overrides

    /// Return the tokenURI for a given ID
    /// @dev overrides ERC721's `tokenURI` function and returns either the `_tokenBaseURI` or a custom URI
    /// @notice reutrns the tokenURI using the `_tokenBase` URI if the token ID hasn't been supplied with a unique custom URI
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Cannot query non-existent token');

        return
            bytes(tokenBaseURI).length > 0
                ? string(
                    abi.encodePacked(tokenBaseURI, '/', tokenId.toString())
                )
                : _defaultBaseURI;
    }

    // ======================================================== Modifiers

    /// Modifier to validate Eth payments on payable functions
    /// @dev compares the product of the state variable `apePrice` and supplied `count` to msg.value
    /// @param count factor to multiply by
    modifier validateEthPayment(uint256 count) {
        require(
            apePrice * count <= msg.value,
            'You have not sent enough ether'
        );
        _;
    }
}