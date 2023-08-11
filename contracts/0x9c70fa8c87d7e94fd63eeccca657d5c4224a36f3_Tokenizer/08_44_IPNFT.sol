// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { ERC721BurnableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import { ERC721URIStorageUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IAuthorizeMints, SignedMintAuthorization } from "./IAuthorizeMints.sol";
import { IReservable } from "./IReservable.sol";

/*
 ______ _______         __    __ ________ ________
|      \       \       |  \  |  \        \        \
 \▓▓▓▓▓▓ ▓▓▓▓▓▓▓\      | ▓▓\ | ▓▓ ▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓
  | ▓▓ | ▓▓__/ ▓▓______| ▓▓▓\| ▓▓ ▓▓__      | ▓▓
  | ▓▓ | ▓▓    ▓▓      \ ▓▓▓▓\ ▓▓ ▓▓  \     | ▓▓
  | ▓▓ | ▓▓▓▓▓▓▓ \▓▓▓▓▓▓ ▓▓\▓▓ ▓▓ ▓▓▓▓▓     | ▓▓
 _| ▓▓_| ▓▓            | ▓▓ \▓▓▓▓ ▓▓        | ▓▓
|   ▓▓ \ ▓▓            | ▓▓  \▓▓▓ ▓▓        | ▓▓
 \▓▓▓▓▓▓\▓▓             \▓▓   \▓▓\▓▓         \▓▓
 */

/// @title IPNFT V2.4
/// @author molecule.to
/// @notice IP-NFTs capture intellectual property to be traded and synthesized
contract IPNFT is ERC721URIStorageUpgradeable, ERC721BurnableUpgradeable, IReservable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _reservationCounter;

    /// @notice by reserving a mint an user captures a new token id
    mapping(uint256 => address) public reservations;

    /// @notice an authorizer that checks whether a mint operation is allowed
    IAuthorizeMints mintAuthorizer;

    mapping(uint256 => mapping(address => uint256)) internal readAllowances;

    uint256 constant SYMBOLIC_MINT_FEE = 0.001 ether;

    /// @notice an IPNFT's base symbol, to be determined by the minter / owner, e.g. BIO-00001
    mapping(uint256 => string) public symbol;

    event Reserved(address indexed reserver, uint256 indexed reservationId);
    event IPNFTMinted(address indexed owner, uint256 indexed tokenId, string tokenURI, string symbol);
    event ReadAccessGranted(uint256 indexed tokenId, address indexed reader, uint256 until);
    event AuthorizerUpdated(address authorizer);

    error NotOwningReservation(uint256 id);
    error ToZeroAddress();
    error Unauthorized();
    error InsufficientBalance();
    error BadDuration();
    error MintingFeeTooLow();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Contract initialization logic
    function initialize() external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
        __Pausable_init();
        __ERC721_init("IPNFT", "IPNFT");
        _reservationCounter.increment(); //start at 1.
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setAuthorizer(IAuthorizeMints authorizer_) external onlyOwner {
        mintAuthorizer = authorizer_;
        emit AuthorizerUpdated(address(authorizer_));
    }

    /// @notice https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public pure returns (string memory) {
        return "https://mint.molecule.to/contract-metadata/ipnft.json";
    }

    /**
     * @notice reserves a new token id. Checks that the caller is authorized, according to the current implementation of IAuthorizeMints.
     * @return reservationId a new reservation id
     */
    function reserve() external whenNotPaused returns (uint256 reservationId) {
        if (!mintAuthorizer.authorizeReservation(_msgSender())) {
            revert Unauthorized();
        }
        reservationId = _reservationCounter.current();
        _reservationCounter.increment();
        reservations[reservationId] = _msgSender();
        emit Reserved(_msgSender(), reservationId);
    }

    /**
     * @notice mints an IPNFT with `tokenURI` as source of metadata. Invalidates the reservation. Redeems `mintpassId` on the authorizer contract
     * @notice We are charging a nominal fee to symbolically represent the transfer of ownership rights, for a price of .001 ETH (<$2USD at current prices). This helps the ensure the protocol is affordable to almost all projects, but discourages frivolous IP-NFT minting.
     *
     * @param to the recipient of the NFT
     * @param reservationId the reserved token id that has been reserved with `reserve()`
     * @param _tokenURI a location that resolves to a valid IP-NFT metadata structure
     * @param _symbol a symbol that represents the IPNFT's derivatives. Can be changed by the owner
     * @param authorization a bytes encoded parameter that's handed to the current authorizer
     * @return the `reservationId`
     */
    function mintReservation(address to, uint256 reservationId, string calldata _tokenURI, string calldata _symbol, bytes calldata authorization)
        external
        payable
        override
        whenNotPaused
        returns (uint256)
    {
        if (reservations[reservationId] != _msgSender()) {
            revert NotOwningReservation(reservationId);
        }

        if (msg.value < SYMBOLIC_MINT_FEE) {
            revert MintingFeeTooLow();
        }

        if (!mintAuthorizer.authorizeMint(_msgSender(), to, abi.encode(SignedMintAuthorization(reservationId, _tokenURI, authorization)))) {
            revert Unauthorized();
        }

        delete reservations[reservationId];
        symbol[reservationId] = _symbol;
        mintAuthorizer.redeem(authorization);

        _mint(to, reservationId);
        _setTokenURI(reservationId, _tokenURI);
        emit IPNFTMinted(to, reservationId, _tokenURI, _symbol);
        return reservationId;
    }

    /**
     * @notice grants time limited "read" access to gated resources
     * @param reader the address that should be able to access gated content
     * @param tokenId token id
     * @param until the timestamp when read access expires (unsafe but good enough for this use case)
     */
    function grantReadAccess(address reader, uint256 tokenId, uint256 until) external {
        if (ownerOf(tokenId) != _msgSender()) {
            revert InsufficientBalance();
        }

        if (block.timestamp >= until) {
            revert BadDuration();
        }

        readAllowances[tokenId][reader] = until;
        emit ReadAccessGranted(tokenId, reader, until);
    }

    /**
     * @notice check whether `reader` currently is able to access gated content behind `tokenId`
     * @param reader the address in question
     * @param tokenId the ipnft id
     * @return bool current read allowance
     */
    function canRead(address reader, uint256 tokenId) external view returns (bool) {
        return (ownerOf(tokenId) == reader || readAllowances[tokenId][reader] > block.timestamp);
    }

    /// @notice in case someone sends Eth to this contract, this function gets it out again
    function withdrawAll() public whenNotPaused onlyOwner {
        (bool success,) = _msgSender().call{ value: address(this).balance }("");
        require(success, "transfer failed");
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address /*newImplementation*/ )
        internal
        override
        onlyOwner // solhint-disable-next-line no-empty-blocks
    { }

    /// @inheritdoc ERC721Upgradeable
    function _burn(uint256 tokenId) internal virtual override(ERC721URIStorageUpgradeable, ERC721Upgradeable) {
        super._burn(tokenId);
    }

    /// @inheritdoc ERC721Upgradeable
    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}