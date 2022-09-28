// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {CantBeEvil, LicenseVersion} from "@a16z/contracts/licenses/CantBeEvil.sol";

import {ERC721Checkpointable} from "src/base/ERC721Checkpointable.sol";
import {IBBOTSRenderer} from "src/interface/BBOTSRenderer.interface.sol";
import {IBBOTS, MintPhase, Ticket} from "src/interface/BBOTS.interface.sol";
import {ExternalRenderer} from "src/metadata/ExternalRenderer.sol";

//_/\\\\\\\\\\\\\__________________/\\\\\\\\\\\\\_________/\\\\\_______/\\\\\\\\\\\\\\\_____/\\\\\\\\\\\___
//_\/\\\/////////\\\_______________\/\\\/////////\\\_____/\\\///\\\____\///////\\\/////____/\\\/////////\\\_
// _\/\\\_______\/\\\_______________\/\\\_______\/\\\___/\\\/__\///\\\________\/\\\________\//\\\______\///__
//  _\/\\\\\\\\\\\\\\___/\\\\\\\\\\\_\/\\\\\\\\\\\\\\___/\\\______\//\\\_______\/\\\_________\////\\\_________
//   _\/\\\/////////\\\_\///////////__\/\\\/////////\\\_\/\\\_______\/\\\_______\/\\\____________\////\\\______
//    _\/\\\_______\/\\\_______________\/\\\_______\/\\\_\//\\\______/\\\________\/\\\_______________\////\\\___
//     _\/\\\_______\/\\\_______________\/\\\_______\/\\\__\///\\\__/\\\__________\/\\\________/\\\______\//\\\__
//      _\/\\\\\\\\\\\\\/________________\/\\\\\\\\\\\\\/_____\///\\\\\/___________\/\\\_______\///\\\\\\\\\\\/___
//       _\/////////////__________________\/////////////_________\/////_____________\///__________\///////////_____

/// @title B-BOTS: CC0 Media Model
/// @author ghard.eth
contract BBOTS is
    IBBOTS,
    ERC721Checkpointable,
    Ownable,
    ExternalRenderer,
    CantBeEvil
{
    /*///////////////////////////////////////////////////////////////
                            MINT STORAGE
    //////////////////////////////////////////////////////////////*/

    /** Total supply that can ever be minted */
    uint256 public immutable MAX_SUPPLY;
    /** Cost to mint (not applicable to admin) */
    uint256 public immutable MINT_COST;
    /** Max per address that can be minted (not applicable to admin) */
    uint256 public MAX_PER_ADDRESS;
    /** Total supply that is available to mint currently (not applicable to admin) */
    uint256 public AVAILABLE_SUPPLY;
    /** Next tokenId to be minted */
    uint256 public nextId;

    bytes32 public constant TICKET_TYPEHASH =
        keccak256("Ticket(address buyer)");

    mapping(address => uint256) public numMinted;

    MintPhase public mintPhase = MintPhase.Locked;
    address public gatekeeper;

    /*///////////////////////////////////////////////////////////////
                              ROYALTIES
    //////////////////////////////////////////////////////////////*/

    address recipient;
    uint256 royaltyBps;

    constructor(
        IBBOTSRenderer _renderer,
        address _gatekeeper,
        address _recipient,
        uint256 _royaltyBps,
        uint256 _maxSupply,
        uint256 _maxPerAddress,
        uint256 _availableSupply,
        uint256 _mintCost,
        string memory _name,
        string memory _symbol
    )
        ERC721Checkpointable(_name, _symbol)
        ExternalRenderer(_renderer)
        CantBeEvil(LicenseVersion.CBE_CC0)
    {
        gatekeeper = _gatekeeper;

        recipient = _recipient;
        royaltyBps = _royaltyBps;

        if (_availableSupply > _maxSupply) revert InvalidAvailableSupply();

        MAX_SUPPLY = _maxSupply;
        MAX_PER_ADDRESS = _maxPerAddress;
        AVAILABLE_SUPPLY = _availableSupply;
        MINT_COST = _mintCost;
    }

    /*///////////////////////////////////////////////////////////////
                        		MINTING
    //////////////////////////////////////////////////////////////*/

    /// @dev validates payment exceeds minting costs
    modifier validatePayment(uint256 _amt) {
        if (msg.value != _amt * MINT_COST) revert InvalidPayment();
        _;
    }

    /// @dev validates that contract is in the expected phase
    modifier validatePhase(MintPhase _expected) {
        if (mintPhase != _expected) revert InvalidMintPhase();
        _;
    }

    /// @dev validates that call wont exceed available supply
    modifier validateAvailableSupply(uint256 _amt) {
        if (nextId + _amt > AVAILABLE_SUPPLY) revert AvailableSupplyExceeded();
        _;
    }

    /// @dev validates that call wont exceed total supply
    modifier validateTotalSupply(uint256 _amt) {
        if (nextId + _amt > MAX_SUPPLY) revert TotalSupplyExceeded();
        _;
    }

    /// @dev validates address cant mint more than MAX_PER_ADDRESS
    modifier validateAddressSupply(uint256 _amt) {
        numMinted[msg.sender] += _amt;
        if (numMinted[msg.sender] > MAX_PER_ADDRESS) revert MaxMintsExceeded();
        _;
    }

    /// @dev validates that the ticket was signed by the gatekeeper for the caller
    modifier validateTicket(Ticket calldata _ticket) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(abi.encode(TICKET_TYPEHASH, msg.sender));

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        address signatory = ecrecover(digest, _ticket.v, _ticket.r, _ticket.s);

        if (signatory != gatekeeper) revert InvalidTicket();
        _;
    }

    /**
     * @notice Sets the phase which allows who can mint
     * @dev Only callable by owner
     */
    function setMintPhase(MintPhase _phase) external onlyOwner {
        mintPhase = _phase;

        emit MintPhaseSet(_phase);
    }

    /**
     * @notice Sets supply available for public and allowlist minting
     * @dev only callable by owner
     */
    function setAvailableSupply(uint256 _amt) external onlyOwner {
        // Available supply can never be more than max supply
        if (_amt > MAX_SUPPLY) revert InvalidAvailableSupply();
        // Available supply can never be less than current supply
        if (_amt < nextId) revert InvalidAvailableSupply();

        AVAILABLE_SUPPLY = _amt;
        emit AvailableSupplySet(_amt);
    }

    /**
     * @notice Sets how many can be minted per address
     * @dev only callable by owner
     */
    function setMaxPerAddress(uint256 _amt) external onlyOwner {
        MAX_PER_ADDRESS = _amt;
        emit MaxPerAddressSet(_amt);
    }

    /**
     * @notice Allows owner to mint directly `_amt` of B-BOTS to `_to`. Cant exceed total supply.
     * @dev Only callable by owner
     */
    function mintTo(address _to, uint256 _amt) external onlyOwner {
        _processMint(_to, _amt);
    }

    /**
     * @notice Allows an address on the allowlist to mint with a signed ticket.
     * @dev To be called during the allowlist minting phase
     */
    function mint(uint256 _amt, Ticket calldata _ticket)
        external
        payable
        validatePayment(_amt)
        validatePhase(MintPhase.Allow)
        validateTicket(_ticket)
        validateAddressSupply(_amt)
        validateAvailableSupply(_amt)
    {
        _processMint(msg.sender, _amt);
    }

    /**
     * @notice Allows anyone to mint up to `MAX_PER_ADDRESS`.
     * @dev To be called during the public minting phase
     */
    function mint(uint256 _amt)
        external
        payable
        validatePayment(_amt)
        validatePhase(MintPhase.Public)
        validateAddressSupply(_amt)
        validateAvailableSupply(_amt)
    {
        _processMint(msg.sender, _amt);
    }

    /// @dev validate total supply and call internal mint function
    function _processMint(address _to, uint256 _amt)
        internal
        validateTotalSupply(_amt)
    {
        for (uint256 i; i < _amt; i++) {
            // Assume minter can receive to save gas
            _mint(_to, nextId);
            nextId++;
        }
    }

    /*///////////////////////////////////////////////////////////////
                        		ROYALTIES
    //////////////////////////////////////////////////////////////*/

    /// @dev returns royalty info according to EIP-2981 standard
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (recipient, (salePrice * royaltyBps) / 10_000);
    }

    function updateRoyaltyRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    /// @dev send funds to recipient
    function sweep() external {
        (bool success, ) = recipient.call{
            value: address(this).balance
        }(new bytes(0));
        require(success);
    }

    /*///////////////////////////////////////////////////////////////
                        	   METADATA
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the metadata address for token `_id`. Will be updated after the reveal of each tranche
     */
    function tokenURI(uint256 id)
        public
        view
        override
        returns (string memory metadataUri)
    {
        return renderer.tokenURI(id);
    }

    function updateMetadataRenderer(address _renderer)
        external
        override
        onlyOwner
    {
        _updateMetadataRenderer(_renderer);
    }

    function lockMetadata() external override onlyOwner {
        _lockMetadata();
    }

    /*///////////////////////////////////////////////////////////////
                                UTILS
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721, CantBeEvil)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            ERC721.supportsInterface(interfaceId) ||
            CantBeEvil.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }
}