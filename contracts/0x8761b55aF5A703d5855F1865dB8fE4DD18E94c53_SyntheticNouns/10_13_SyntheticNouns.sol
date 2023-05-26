//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { INounsDescriptor } from "./interfaces/INounsDescriptor.sol";
import { INounsSeeder } from "./interfaces/INounsSeeder.sol";
import { IENSReverseRecords } from "./interfaces/IENSReverseRecords.sol";

contract SyntheticNouns is ERC721 {
    using Strings for uint256;
    using Strings for address;

    event NounCreated(uint256 indexed tokenId, INounsSeeder.Seed seed);

    // The Nouns token URI descriptor
    INounsDescriptor public descriptor;

    // ENS reverse records contract
    IENSReverseRecords public reverseRecords;

    // The noun seeds
    mapping(uint256 => INounsSeeder.Seed) public seeds;

    // Addresses that have claimed a noun
    mapping(address => bool) public claimed;

    // Claimer of each noun
    mapping(uint256 => address) public claimerOf;

    // The internal noun ID tracker
    uint256 private _currentNounId = 1;

    constructor(INounsDescriptor _descriptor, IENSReverseRecords _reverseRecords) ERC721("Synthetic Nouns", "sNOUN") {
        descriptor = _descriptor;
        reverseRecords = _reverseRecords;
    }

    /**
     * @notice Generate a pseudo-random Noun seed using the previous blockhash and noun ID.
     */
    // prettier-ignore
    function generateSeed(uint256 _pseudorandomness) private view returns (INounsSeeder.Seed memory) {
        
        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 bodyCount = descriptor.bodyCount();
        uint256 accessoryCount = descriptor.accessoryCount();
        uint256 headCount = descriptor.headCount();
        uint256 glassesCount = descriptor.glassesCount();

        return INounsSeeder.Seed({
            background: uint48(
                uint48(_pseudorandomness) % backgroundCount
            ),
            body: uint48(
                uint48(_pseudorandomness >> 48) % bodyCount
            ),
            accessory: uint48(
                uint48(_pseudorandomness >> 96) % accessoryCount
            ),
            head: uint48(
                uint48(_pseudorandomness >> 144) % headCount
            ),
            glasses: uint48(
                uint48(_pseudorandomness >> 192) % glassesCount
            )
        });
    }

    /**
     * @notice Given an address, generate a unique input to be used with the generateSeed function.
     */
    function getSeedInput(address _address) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_address)));
    }

    /**
     * @notice Mint a Noun to the minter.
     * @dev Call _mintTo with the to address.
     */
    function claim() public returns (uint256) {
        require(!claimed[msg.sender], "Noun already claimed");
        claimed[msg.sender] = true;
        uint256 tokenId = _currentNounId++;
        claimerOf[tokenId] = msg.sender;
        return _mintTo(msg.sender, tokenId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "NounsToken: URI query for nonexistent token");
        string memory nounId = _tokenId.toString();
        string memory name = string(abi.encodePacked("Synthetic Noun ", nounId));

        string memory ensName = _reverseName(claimerOf[_tokenId]);
        string memory addressOrENS = bytes(ensName).length == 0 ? claimerOf[_tokenId].toHexString() : ensName;
        string memory description = string(
            abi.encodePacked(
                "Synthetic Noun ",
                nounId,
                " claimed by address, ",
                addressOrENS,
                ", is a member of the Synthetic Nouns DAO"
            )
        );

        return descriptor.genericDataURI(name, description, seeds[_tokenId]);
    }

    /**
     * @notice Given an address, construct a base64 encoded SVG image.
     */
    function addressPreview(address _address) public view returns (string memory) {
        return descriptor.generateSVGImage(generateSeed(getSeedInput(_address)));
    }

    /**
     * @notice Mint a Noun with `nounId` to the provided `to` address.
     */
    function _mintTo(address _to, uint256 _nounId) internal returns (uint256) {
        INounsSeeder.Seed memory seed = seeds[_nounId] = generateSeed(getSeedInput(_to));

        _mint(_to, _nounId);
        emit NounCreated(_nounId, seed);

        return _nounId;
    }

    /**
     * @notice ENS reverse lookup for address.
     */
    function _reverseName(address _address) internal view returns (string memory name) {
        address[] memory t = new address[](1);
        t[0] = _address;
        name = reverseRecords.getNames(t)[0];
    }
}