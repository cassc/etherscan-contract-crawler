// SPDX-License-Identifier: GPL-3.0

/// @title The Nouns ERC-721 token

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {Ownable} from "../../../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import {ERC721Checkpointable} from "./base/ERC721Checkpointable.sol";
import {INounsDescriptorMinimal} from "./interfaces/INounsDescriptorMinimal.sol";
import {INounsSeeder} from "./interfaces/INounsSeeder.sol";
import {INounsToken} from "./interfaces/INounsToken.sol";
import {ERC721} from "./base/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import { IERC721 } from '../../../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IProxyRegistry} from "./external/opensea/IProxyRegistry.sol";

contract NounsToken is INounsToken, Ownable, ERC721Checkpointable {
    // The nounders DAO address (creators org)
    address public noundersDAO;

    mapping(address => bool) public mintWhitelist;

    // The Nouns token URI descriptor
    INounsDescriptorMinimal public descriptor;

    // The Nouns token seeder
    INounsSeeder public seeder;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // The noun seeds
    mapping(uint256 => INounsSeeder.Seed) public seeds;

    // The internal noun ID tracker
    uint256 private _currentNounId;

    // keep track of amont of one of ones to know when we upload more.
    // allows us to skip expensive one of one minting ops if we need have minted
    // all available one of ones
    uint256 public lastOneOfOneCount;

    // one of one tracker
    mapping(uint256 => uint8) private oneOfOneSupply;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash =
        "bafkreigxno7h3uczurvxrkfrcm5fzahlylmjvlidrwgnr2fn6qon4urnmy";

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

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
        require(mintWhitelist[msg.sender] == true, "Sender is not the minter");
        _;
    }

    constructor(
        address _noundersDAO,
        address _minter,
        INounsDescriptorMinimal _descriptor,
        INounsSeeder _seeder,
        IProxyRegistry _proxyRegistry
    ) ERC721("Nouns", "NOUN") {
        noundersDAO = _noundersDAO;
        descriptor = _descriptor;
        seeder = _seeder;
        proxyRegistry = _proxyRegistry;
        addAddressToWhitelist(_minter);
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked("ipfs://", _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash)
        external
        onlyOwner
    {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(IERC721, ERC721)
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function mintTo(address to) public onlyMinter returns (uint256) {
        if (_currentNounId <= 1820 && _currentNounId % 10 == 0) {
            _mintTo(noundersDAO, _currentNounId++, false, 0);
        }
        return _mintTo(to, _currentNounId++, false, 0);
    }

    /**
     * @notice Mint a Noun to the minter, along with a possible nounders reward
     * Noun. Nounders reward Nouns are minted every 10 Nouns, starting at 0,
     * until 183 nounder Nouns have been minted (5 years w/ 24 hour auctions).
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        if (_currentNounId <= 1820 && _currentNounId % 10 == 0) {
            _mintTo(noundersDAO, _currentNounId++, false, 0);
        }
        // TODO: Fix
        return _mintTo(noundersDAO, _currentNounId++, false, 0);
    }

    /**
     * @notice Mint a one of one Noun to the minter.
     * @dev Call _mintTo with the to address(es) with the one of one id to mint.
     */
    function mintOneOfOne(address to, uint48 oneOfOneId)
        public
        onlyMinter
        returns (uint256)
    {
        uint256 oneCount = descriptor.oneOfOnesCount();

        // validation; ensure a valid one of one index is requested
        require(
            uint256(oneOfOneId) < oneCount && oneOfOneId >= 0,
            "one of one does not exist"
        );

        // validation; only one edition of each one of one can exist
        /* TODO: uncomment
        require(
            oneOfOneSupply[oneOfOneId] == 0,
            "one of one edition already minted"
        );
        */

        uint256 nounId = _mintTo(to, _currentNounId++, true, oneOfOneId);

        // set that we have minted a one of one at index
        oneOfOneSupply[oneOfOneId] = 1;
        return (nounId);
    }

    /**
     * @notice Burn a noun.
     */
    function burn(uint256 nounId) public override onlyMinter {
        _burn(nounId);
        emit NounBurned(nounId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "NounsToken: URI query for nonexistent token"
        );
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "NounsToken: URI query for nonexistent token"
        );
        return descriptor.dataURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Set the nounders DAO.
     * @dev Only callable by the nounders DAO when not locked.
     */
    function setNoundersDAO(address _noundersDAO)
        external
        override
        onlyNoundersDAO
    {
        noundersDAO = _noundersDAO;

        emit NoundersDAOUpdated(_noundersDAO);
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
    function setDescriptor(INounsDescriptorMinimal _descriptor)
        external
        override
        onlyOwner
        whenDescriptorNotLocked
    {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor()
        external
        override
        onlyOwner
        whenDescriptorNotLocked
    {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(INounsSeeder _seeder)
        external
        override
        onlyOwner
        whenSeederNotLocked
    {
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
     * @notice Mint a Noun with `nounId` to the provided `to` address.
     */
    function _mintTo(
        address to,
        uint256 nounId,
        bool isOneOfOne,
        uint48 oneOfOneIndex
    ) internal returns (uint256) {
        INounsSeeder.Seed memory seed = seeds[nounId] = seeder.generateSeed(
            nounId,
            descriptor,
            isOneOfOne,
            oneOfOneIndex
        );

        _mint(owner(), to, nounId);
        emit NounCreated(nounId, seed);

        return nounId;
    }

    /* Mint Whitelist Management */

    /**
     * @dev add an address to the mintWhitelist
     * @param addr address
     * @return success if the address was added to the mintWhitelist, false if the address was already in the mintWhitelist
     */
    function addAddressToWhitelist(address addr)
        public
        override
        onlyOwner
        whenMinterNotLocked
        returns (bool success)
    {
        if (!mintWhitelist[addr]) {
            mintWhitelist[addr] = true;
            emit MintWhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the mintWhitelist
     * @param addrs addresses
     */
    function addAddressesToWhitelist(address[] memory addrs)
        public
        override
        onlyOwner
        whenMinterNotLocked
        returns (bool success)
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    /**
     * @dev remove an address from the mintWhitelist
     * @param addr address
     * @return success if the address was removed from the mintWhitelist,
     * false if the address wasn't in the mintWhitelist in the first place
     */
    function removeAddressFromWhitelist(address addr)
        public
        override
        onlyOwner
        whenMinterNotLocked
        returns (bool success)
    {
        if (mintWhitelist[addr]) {
            mintWhitelist[addr] = false;
            emit MintWhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    /**
     * @dev remove addresses from the mintWhitelist
     * @param addrs addresses
     * @return success if at least one address was removed from the mintWhitelist,
     * false if all addresses weren't in the mintWhitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] memory addrs)
        public
        override
        onlyOwner
        whenMinterNotLocked
        returns (bool success)
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
}