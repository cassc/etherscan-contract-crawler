// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './RandomlyAssigned.sol';

/**
 * @title The Party Spud Club's Minting contract
 * @dev Extends the ERC721 Non-Fungible Token Standard
 */
contract PartySpudClub is ERC721, AccessControl, RandomlyAssigned {
    using SafeMath for uint256;
    using Strings for uint256;

    // ======================================================== Structs and Enums

    struct MintTypes {
        uint256 _numberOfFreeMintsByAddress;
        uint256 _numberOfWhitelistMintsByAddress;
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
        Whitelist
    }
    enum SalePhase {
        Locked,
        PreSale,
        PublicSale
    } // During public sale, no more discounts, no more max mints

    // ======================================================== Private Variables

    uint256 private constant MAX_COMMUNITY_SPUDS = 69; // reserved for the community and marketing

    string private constant _defaultBaseURI =
        'https://api.thepartyspudclub.io/metadata';

    address private communityAddress =
        0xa54F87a652254baA2D1B39984a7E25022681fF41;

    // ======================================================== Public Variables

    uint256 public constant NUMBER_OF_OG_SPUDS = 200;
    uint256 public constant NUMBER_OF_RESERVED_SPUDS = 35;
    uint256 public constant MAX_SPUDS_SUPPLY = 888;

    bytes32 public constant SPUD_EMPEROR_ROLE = keccak256('SPUD_EMPEROR_ROLE');

    address public immutable adminSigner;

    string public tokenBaseURI;

    bool public claimActive = false;

    SalePhase public phase = SalePhase.Locked;

    uint256 public spudPrice = 0.1 ether;
    uint256 public discountedSpudPrice = 0.075 ether;
    uint256 public communityTokensMinted;

    uint256 public maxMintsPerAddress = 10; // max total mints per address

    mapping(address => MintTypes) public addressToMints;

    // ======================================================== Constructor

    constructor(string memory _uri, address _adminSigner)
        ERC721('Party Spuds', 'SPUDS')
        RandomlyAssigned(
            MAX_SPUDS_SUPPLY + NUMBER_OF_OG_SPUDS + NUMBER_OF_RESERVED_SPUDS,
            NUMBER_OF_OG_SPUDS + NUMBER_OF_RESERVED_SPUDS
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        tokenBaseURI = _uri;
        adminSigner = _adminSigner;
    }

    // ======================================================== Spud Emperor Functions

    /// Set the base URI for the metadata
    /// @dev modifies the state of the `_tokenBaseURI` variable
    /// @param URI the URI to set as the base token URI
    function setBaseURI(string memory URI)
        external
        onlyRole(SPUD_EMPEROR_ROLE)
    {
        tokenBaseURI = URI;
    }

    /// Updates the community address
    /// @dev modifies the state of the `communityAddress` variable
    /// @notice updates the community address
    /// @param newAddress_ The new price for minting
    function updateCommunityAddress(address newAddress_)
        external
        onlyRole(SPUD_EMPEROR_ROLE)
    {
        communityAddress = newAddress_;
    }

    /// Adjust the mint price
    /// @dev modifies the state of the `spudPrice` variable
    /// @notice sets the price for minting a token
    /// @param newPrice_ The new price for minting
    function adjustMintPrice(uint256 newPrice_)
        external
        onlyRole(SPUD_EMPEROR_ROLE)
    {
        spudPrice = newPrice_;
    }

    /// Adjust the discounted mint price
    /// @dev modifies the state of the `discountedSpudPrice` variable
    /// @notice sets the discounted price for minting a token
    /// @param newPrice_ The new price for minting
    function adjustDiscountedMintPrice(uint256 newPrice_)
        external
        onlyRole(SPUD_EMPEROR_ROLE)
    {
        discountedSpudPrice = newPrice_;
    }

    /// Adjust the maximum allowed mints per address
    /// @dev modifies the state of the `maxMintsPerAddress` variable
    /// @notice sets the maximum allowed mints per address
    /// @param maxMintsPerAddress_ The new price maximum
    function adjustMaximumMints(uint256 maxMintsPerAddress_)
        external
        onlyRole(SPUD_EMPEROR_ROLE)
    {
        maxMintsPerAddress = maxMintsPerAddress_;
    }

    /// Enter Phase
    /// @dev Updates the `phase` variable
    /// @notice Enters a new sale phase
    function enterPhase(SalePhase phase_) external onlyRole(SPUD_EMPEROR_ROLE) {
        phase = phase_;
    }

    /// Activate claiming
    /// @dev set the state of `claimActive` variable to true
    /// @notice Activate the claiming event
    function activateClaiming() external onlyRole(SPUD_EMPEROR_ROLE) {
        claimActive = true;
    }

    /// Deactivate claiming
    /// @dev set the state of `claimActive` variable to false
    /// @notice Deactivate the claiming event
    function deactivateClaiming() external onlyRole(SPUD_EMPEROR_ROLE) {
        claimActive = false;
    }

    /// Mint tokens for the community and marketing
    /// @dev Mints the number of tokens passed in as count to the communityAddress
    /// @param count The number of tokens to mint
    function reserveCommunityTokens(uint256 count)
        external
        onlyRole(SPUD_EMPEROR_ROLE)
        ensureAvailabilityFor(count)
    {
        require(
            count + communityTokensMinted <= MAX_COMMUNITY_SPUDS,
            'Exceeds the allowed supply of community tokens'
        );
        for (uint256 i = 0; i < count; i++) {
            _mintRandomId(communityAddress);
        }
        communityTokensMinted += count;
    }

    /// Disburse payments
    /// @dev transfers amounts that correspond to addresses passeed in as args
    /// @param payees_ recipient addresses
    /// @param amounts_ amount to payout to address with corresponding index in the `payees_` array
    function disbursePayments(
        address[] memory payees_,
        uint256[] memory amounts_
    ) external onlyRole(SPUD_EMPEROR_ROLE) {
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

    // ======================================================== Overrides
    /// Overrides supportsInterface
    /// @dev Overrides supportsInterface, defined twice in the base contracts
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ======================================================== External Functions

    /// Claim OG Tokens
    /// @dev mints OG token IDs using verified vouchers signed by an admin address
    /// @notice uses the voucher supplied to confirm that only the owner of the original ID can claim
    /// @param idxsToClaim the indexes for the IDs array of the tokens claimed in this TX
    /// @param idsOfOwner IDs of OG tokens belonging to the caller, used to verify the voucher
    /// @param voucher voucher for verifying the signer
    function claimOGTokensByIds(
        address owner_,
        uint256[] calldata idxsToClaim,
        uint256[] calldata idsOfOwner,
        Voucher memory voucher
    ) external {
        require(claimActive, 'Claim event is not active');
        bytes32 digest = keccak256(
            abi.encode(VoucherType.OGHodler, idsOfOwner, owner_)
        );
        require(_isVerifiedVoucher(digest, voucher), 'Invalid voucher');

        for (uint256 i; i < idxsToClaim.length; i++) {
            uint256 tokenId = idsOfOwner[idxsToClaim[i]];
            _claimReservedToken(owner_, tokenId);
        }
    }

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
        require(phase == SalePhase.PreSale, 'Pre-sale is not active');
        bytes32 digest = keccak256(
            abi.encode(VoucherType.FreeMint, allotted, msg.sender)
        );
        require(_isVerifiedVoucher(digest, voucher), 'Invalid voucher');
        require(
            count + addressToMints[msg.sender]._numberOfFreeMintsByAddress <=
                allotted,
            'Exceeds number of earned Spuds'
        );
        addressToMints[msg.sender]._numberOfFreeMintsByAddress += count;
        for (uint256 i; i < count; i++) {
            _mintRandomId(msg.sender);
        }
    }

    /// Claim Whitelist Tokens
    /// @dev mints the qty of tokens verified using vouchers signed by an admin signer
    /// @notice claims earned whitelist tokens
    /// @param count number of tokens to claim in transaction
    /// @param allotted total number of tokens recipient is allowed to claim
    /// @param voucher voucher for verifying the signer
    function claimWhitelistTokens(
        uint256 count,
        uint256 allotted,
        Voucher memory voucher
    )
        external
        payable
        validateDiscountedEthPayment(count)
        ensureAvailabilityFor(count)
    {
        require(phase == SalePhase.PreSale, 'Pre-sale is not active');
        require(claimActive, 'Claim event is not active');
        bytes32 digest = keccak256(
            abi.encode(VoucherType.Whitelist, allotted, msg.sender)
        );
        require(_isVerifiedVoucher(digest, voucher), 'Invalid voucher');
        require(
            count +
                addressToMints[msg.sender]._numberOfWhitelistMintsByAddress <=
                allotted,
            'Exceeds number of earned Spuds'
        );
        addressToMints[msg.sender]._numberOfWhitelistMintsByAddress += count;
        for (uint256 i; i < count; i++) {
            _mintRandomId(msg.sender);
        }
    }

    /// Public minting open to all
    /// @dev mints tokens during public sale, limited by `maxMintsPerAddress`
    /// @notice mints tokens with randomized IDs to the sender's address
    /// @param count number of tokens to mint in transaction
    function mintSpud(uint256 count)
        external
        payable
        validateEthPayment(count)
        ensureAvailabilityFor(count)
    {
        require(phase == SalePhase.PublicSale, 'Public sale is not active');
        require(
            msg.sender == tx.origin,
            'Smart contracts are not allowed to mint'
        ); // block smart contracts from minting
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

    /// @dev internal check to ensure an OG token ID, or ID outside of the collection, doesn't get minted
    function _mintRandomId(address to) private {
        uint256 id = nextToken();
        assert(
            id > NUMBER_OF_OG_SPUDS + NUMBER_OF_RESERVED_SPUDS &&
                id <=
                MAX_SPUDS_SUPPLY + NUMBER_OF_OG_SPUDS + NUMBER_OF_RESERVED_SPUDS
        );
        _safeMint(to, id);
    }

    /// @dev mints a token with a known ID, must fall within desired range
    function _claimReservedToken(address to, uint256 id) internal {
        assert(id != 0);
        assert(id <= NUMBER_OF_OG_SPUDS);
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
    /// @dev compares the product of the state variable `spudPrice` and supplied `count` to msg.value
    /// @param count factor to multiply by
    modifier validateEthPayment(uint256 count) {
        require(
            spudPrice * count <= msg.value,
            'You have not sent enough ether'
        );
        _;
    }

    /// Modifier to validate Eth payments on payable functions
    /// @dev compares the product of the state variable `discountedSpudPrice` and supplied `count` to msg.value
    /// @param count factor to multiply by
    modifier validateDiscountedEthPayment(uint256 count) {
        require(
            discountedSpudPrice * count <= msg.value,
            'You have not sent enough ether'
        );
        _;
    }
}