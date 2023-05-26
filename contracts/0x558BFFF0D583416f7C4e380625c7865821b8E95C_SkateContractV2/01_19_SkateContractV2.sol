// SPDX-License-Identifier: GPL-3.0

/// @title The Gnars ERC-721 token

// LICENSE
// SkateContractV2.sol is a modified version of Nounders DAO's NounsToken.sol:
// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/NounsToken.sol
//
// NounsToken.sol source code Copyright Nounders DAO licensed under the GPL-3.0 license.
// With modifications by Gnars.

pragma solidity 0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "./base/ERC721.sol";
import {ERC721Checkpointable} from "./base/ERC721Checkpointable.sol";
import {ISkateContractV2} from "../interfaces/ISkateContractV2.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IGnarSeederV2} from "../interfaces/IGNARSeederV2.sol";
import {IGnarDescriptorV2} from "../interfaces/IGNARDescriptorV2.sol";
import {IProxyRegistry} from "../interfaces/IProxyRegistry.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract SkateContractV2 is ISkateContractV2, Ownable, ERC721Checkpointable {
    using Strings for uint256;

    // The nounders DAO address (creators org)
    address public noundersDAO;

    // An address who has permissions to mint Gnar
    address public minter;

    // The Gnar token URI descriptor
    IGnarDescriptorV2 public descriptor;

    // The Gnar token seeder
    IGnarSeederV2 public seeder;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // The Gnar seeds
    mapping(uint256 => IGnarSeederV2.Seed) public seeds;

    uint256 public initialGnarId;

    // The internal Gnar ID tracker
    uint256 private currentGnarId;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    // Store custom descriptions for Gnars
    mapping(uint256 => string) public customDescription;

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, "Minter is locked");
        _;
    }

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, "Descriptor is locked");
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, "Seeder is locked");
        _;
    }

    /**
     * @notice Require that the sender is the nounders DAO.
     */
    modifier onlyNoundersDAO() {
        require(msg.sender == noundersDAO, "Sender is not the nounders DAO");
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    constructor(
        address _noundersDAO,
        address _minter,
        IGnarDescriptorV2 _descriptor,
        IGnarSeederV2 _seeder,
        IProxyRegistry _proxyRegistry,
        uint256 _initialGnarId
    ) ERC721("Gnars", "GNAR") {
        require(
            _noundersDAO != address(0) &&
                _minter != address(0) &&
                address(_descriptor) != address(0) &&
                address(_seeder) != address(0) &&
                address(_proxyRegistry) != address(0),
            "ZERO ADDRESS"
        );

        noundersDAO = _noundersDAO;
        minter = _minter;
        descriptor = _descriptor;
        seeder = _seeder;
        proxyRegistry = _proxyRegistry;
        initialGnarId = _initialGnarId;
        currentGnarId = _initialGnarId;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(_owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(_owner, operator);
    }

    /**
     * @notice Mint a Gnar to the minter, along with a possible nounders reward
     * Noun. Nounders reward Gnars are minted every 10 Gnars, starting at 0.
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        if ((currentGnarId - initialGnarId) % 10 == 0) {
            _mintTo(noundersDAO, currentGnarId++);
        }
        return _mintTo(minter, currentGnarId++);
    }

    /**
     * @notice Burn a Gnar.
     */
    function burn(uint256 gnarId) public override onlyMinter {
        require(minter == ownerOf(gnarId), "Can burn its own token only");

        _burn(gnarId);
        emit GnarBurned(gnarId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    // function tokenURI(uint256 tokenId) public view override returns (string memory) {
    //     require(_exists(tokenId), "GnarToken: URI query for nonexistent token");
    //     return descriptor.tokenURI(tokenId, seeds[tokenId]);
    // }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "GnarToken: URI query for nonexistent token");
        string memory gnarId = tokenId.toString();
        string memory name = string(abi.encodePacked("Gnar ", gnarId));
        string memory description = viewDescription(tokenId);
        return descriptor.genericDataURI(name, description, seeds[tokenId]);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        require(_minter != address(0), "ZERO ADDRESS");

        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(IGnarDescriptorV2 _descriptor) external override onlyOwner whenDescriptorNotLocked {
        require(address(_descriptor) != address(0), "ZERO ADDRESS");

        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external override onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(IGnarSeederV2 _seeder) external override onlyOwner whenSeederNotLocked {
        require(address(_seeder) != address(0), "ZERO ADDRESS");

        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }

    /**
     * @notice Mint a Gnar with `gnarId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 gnarId) internal returns (uint256) {
        IGnarSeederV2.Seed memory seed = seeds[gnarId] = seeder.generateSeed(gnarId, descriptor);

        _mint(owner(), to, gnarId);
        emit GnarCreated(gnarId, seed);

        return gnarId;
    }

    /**
     * @notice Set a custom description for a Gnar token on-chain that will display on OpenSea and other sites.
     * Takes the format of "Gnar [tokenId] is a [....]"
     * May be modified at any time
     * Send empty string to revert to default.
     * @dev Only callable by the holder of the token.
     */
    function setCustomDescription(uint256 tokenId, string calldata _description) external returns (string memory) {
        require(msg.sender == ownerOf(tokenId), "not your Gnar");
        customDescription[tokenId] = _description;
        string memory returnMessage = string(abi.encodePacked("Description set to: ", viewDescription(tokenId)));
        return returnMessage;
    }

    function viewDescription(uint256 tokenId) public view returns (string memory) {
        string memory description = "";
        string memory gnarId = tokenId.toString();

        if (bytes(customDescription[tokenId]).length != 0) {
            description = string(abi.encodePacked(description, "Gnar ", gnarId, " is a ", customDescription[tokenId]));
        } else {
            description = string(abi.encodePacked(description, "Gnar ", gnarId, " is a member of Gnars DAO"));
        }
        return description;
    }
}