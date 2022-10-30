// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './RandomlyAssigned.sol';

/**
 * @title The Party Spud Club's ApeRon LFG Minting contract
 * @dev Extends the ERC721 Non-Fungible Token Standard
 */
contract ApeRonLFG is ERC721, Ownable, RandomlyAssigned {
    using SafeMath for uint256;
    using Strings for uint256;

    // ======================================================== Structs and Enums

    struct MintTypes {
        uint256 _numberOfFreeMintsByAddress;
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
        ApeFreeMint
    }
    enum SalePhase {
        Locked,
        Open
    }

    // ======================================================== Private Variables

    string private constant _defaultBaseURI =
        'https://api.thepartyspudclub.io/aperon/metadata';

    address private teamAddress = 0xa54F87a652254baA2D1B39984a7E25022681fF41;

    // ======================================================== Public Variables

    uint256 public constant NUMBER_OF_RESERVED_APES = 200;
    uint256 public constant MAX_APES_SUPPLY = 5555;

    address public immutable adminSigner;

    string public tokenBaseURI;

    SalePhase public phase = SalePhase.Locked;

    uint256 public apePrice = 0.005555 ether;

    uint256 public teamTokensMinted = 0;

    uint256 public maxMintsPerAddress = 10; // max total mints per address

    mapping(address => MintTypes) public addressToMints;

    // ======================================================== Constructor

    constructor(string memory _uri, address _adminSigner)
        ERC721('ApeRon LFG', 'APERONLFG')
        RandomlyAssigned(MAX_APES_SUPPLY, NUMBER_OF_RESERVED_APES)
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
    function adjustMaximumMints(uint256 maxMintsPerAddress_)
        external
        onlyOwner
    {
        maxMintsPerAddress = maxMintsPerAddress_;
    }

    /// Enter Phase
    /// @dev Updates the `phase` variable
    /// @notice Enters a new sale phase
    function enterPhase(SalePhase phase_) external onlyOwner {
        phase = phase_;
    }

    /// Mint tokens for the team and airdropping
    /// @dev Mints the number of tokens passed in as count to the teamAddress
    /// @param count The number of tokens to mint
    function reserveTeamTokens(uint256 count)
        external
        onlyOwner
        ensureAvailabilityFor(count)
    {
        require(
            count + teamTokensMinted <= NUMBER_OF_RESERVED_APES,
            'Exceeds the allowed supply of team tokens'
        );
        for (uint256 i = teamTokensMinted + 1; i <= count; i++) {
            _claimReservedToken(teamAddress, i);
        }
        teamTokensMinted += count;
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
    function claimFreeMintTokens(
        uint256 count,
        uint256 allotted,
        Voucher memory voucher
    ) external ensureAvailabilityFor(count) {
        require(phase == SalePhase.Open, 'Free Minting is not active');
        bytes32 digest = keccak256(
            abi.encode(VoucherType.ApeFreeMint, allotted, msg.sender)
        );
        require(_isVerifiedVoucher(digest, voucher), 'Invalid voucher');
        require(
            count + addressToMints[msg.sender]._numberOfFreeMintsByAddress <=
                allotted,
            'Exceeds number of earned Apes'
        );
        addressToMints[msg.sender]._numberOfFreeMintsByAddress += count;
        for (uint256 i; i < count; i++) {
            _mintRandomId(msg.sender);
        }
    }

    /// Public minting open to all
    /// @dev mints tokens during public sale, limited by `maxMintsPerAddress`
    /// @notice mints tokens with randomized IDs to the sender's address
    /// @param count number of tokens to mint in transaction
    function mintApe(uint256 count)
        external
        payable
        validateEthPayment(count)
        ensureAvailabilityFor(count)
    {
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
    function _isVerifiedVoucher(bytes32 digest, Voucher memory voucher)
        private
        view
        returns (bool)
    {
        address signer = ecrecover(digest, voucher.v, voucher.r, voucher.s);
        require(signer != address(0), 'ECDSA: invalid voucher');
        return signer == adminSigner;
    }

    /// @dev internal check to ensure a reserved token ID, or ID outside of the collection, doesn't get minted
    function _mintRandomId(address to) private {
        uint256 id = nextToken();
        assert(
            id > NUMBER_OF_RESERVED_APES &&
                id <= MAX_APES_SUPPLY + NUMBER_OF_RESERVED_APES
        );
        _safeMint(to, id);
    }

    /// @dev mints a token with a known ID, must fall within desired range
    function _claimReservedToken(address to, uint256 id) private {
        assert(id != 0);
        assert(id <= NUMBER_OF_RESERVED_APES);
        if (!_exists(id)) {
            _safeMint(to, id);
        }
    }

    // ======================================================== Overrides

    /// Return the tokenURI for a given ID
    /// @dev overrides ERC721's `tokenURI` function and returns either the `_tokenBaseURI` or a custom URI
    /// @notice reutrns the tokenURI using the `_tokenBase` URI if the token ID hasn't been supplied with a unique custom URI
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
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