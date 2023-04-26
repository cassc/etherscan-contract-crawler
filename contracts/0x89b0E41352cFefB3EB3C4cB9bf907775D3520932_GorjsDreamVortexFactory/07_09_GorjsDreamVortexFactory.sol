// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Initializable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { IGorjsDreamVortexCollection } from "../interfaces/IGorjsDreamVortexCollection.sol";
import { IGorjsArtistCollection } from "../interfaces/IGorjsArtistCollection.sol";

/**
 * @title GorjsDreamVortexFactory
 * @author Harry.
 * @dev Implementation of a DreamVortex NFT collection based on the OS Seadrop.
 * This contract allows users to burn their DreamVortex NFTs and mint a corresponding
 * GorjsArtistCollection NFT. The minting process is determined by a list of
 * pairs, each of which specifies an index for the corresponding GorjsArtistCollection
 * contract and a token ID to mint. The pairs are consumed sequentially as NFTs are minted.
 * The contract owner can set the minting stage (either "Mint" or "Pause"), set the
 * number of GorjsArtistCollection NFTs that can be minted per transaction, and set the
 * list of GorjsArtistCollection contract addresses.
 */
contract GorjsDreamVortexFactory is Initializable, OwnableUpgradeable{
    // Define an enum for the minting stage
    enum MintStage {
        Pause,
        Mint
    }
    
    MintStage public mintStage;

    /// @notice Array containing the pairs of GorjsArtist NFT contract addresses and token IDs
    string[] private pairs;

    /// @notice Array containing the addresses of the GorjsArtist NFT contracts
    address[] public nftAddresses;
    
    /// @notice Address of the GorjsDreamVortexCollection contract
    address public dreamVortexCollection;

    /// @notice Total number of GorjsArtist NFTs minted
    uint256 public totalMintedAmount;
    
    /// @notice Maximum number of GorjsArtist NFTs that can be minted in a single transaction
    uint256 public mintLimitPerTx;

    /**
     * @dev Initializes the smart contract with the required parameters.
     * @param _mintLimitPerTx Maximum number of GorjsArtist NFTs that can be minted in a single transaction
     * @param _dreamVortexCollection Address of the GorjsDreamVortexCollection contract
     * @param _nftAddresses Array containing the addresses of the GorjsArtist NFT contracts
     */
    function initialize(
        uint256 _mintLimitPerTx,
        address _dreamVortexCollection,
        address[] memory _nftAddresses
    ) external initializer {
        __Context_init();
        __Ownable_init();

        mintLimitPerTx = _mintLimitPerTx;
        dreamVortexCollection = _dreamVortexCollection;
        nftAddresses = _nftAddresses;
    }

    /**
     * @dev Adds the pairs of GorjsArtist NFT contract addresses and token IDs.
     * @param _pairs Array containing the pairs of GorjsArtist NFT contract addresses and token IDs.
     */
    function addPairs(string[] memory _pairs) external onlyOwner {
        for(uint256 i = 0; i < _pairs.length; ) {
            pairs.push(_pairs[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Clears the pairs of GorjsArtist NFT contract addresses and token IDs.
     */
    function clearPairs() external onlyOwner {
        delete pairs;
    }

    /**
     * @dev Sets the maximum number of GorjsArtist NFTs that can be minted in a single transaction.
     * @param _mintLimitPerTx Maximum number of GorjsArtist NFTs that can be minted in a single transaction.
     */
    function setMintLimitPerTx(uint256 _mintLimitPerTx) external onlyOwner {
        mintLimitPerTx = _mintLimitPerTx;
    }

    /**
     * @dev Sets the addresses of the GorjsArtist NFT contracts.
     * @param _nftAddresses Array containing the addresses of the GorjsArtist NFT contracts.
     */
    function setNftAddresses(address[] memory _nftAddresses) external onlyOwner {
        delete nftAddresses;
        nftAddresses = _nftAddresses;
    }    

    /**
     * @dev Mint stage can only be set by an Admin.
     * @param _mintStage New mint stage to be set.
     */
    function setMintStage(MintStage _mintStage) external onlyOwner {
        mintStage = _mintStage;
    }

    /**
     * @dev Mint function that mints an array of tokens from GorjsDreamVortexCollection
     * and sends them to the caller's address by minting corresponding GorjsArtistCollection tokens.
     *
     * Requirements:
     * - Minting must not be paused.
     * - Number of tokenIds to mint must not exceed mintLimitPerTx.
     * - Caller must approve the contract to spend their GorjsDreamVortexCollection NFTs.
     *
     * @param tokenIds An array of tokenIds to be minted from GorjsDreamVortexCollection.
     */
    function mint(uint256[] memory tokenIds) external {

        // Ensure that minting is not paused
        require(mintStage != MintStage.Pause, "Mint paused");
        // Ensure that the number of tokens being minted does not exceed the limit per transaction
        require(tokenIds.length <= mintLimitPerTx, "Mint limit exceed");
        // Ensure that the caller has approved this contract to manage their DreamVortex NFTs
        require(IGorjsDreamVortexCollection(dreamVortexCollection).isApprovedForAll(msg.sender, address(this)), "Caller must approve contract");

        // Burn DreamVortex NFTs of the caller
        IGorjsDreamVortexCollection(dreamVortexCollection).burn(tokenIds);
            
        for (uint256 i; i < tokenIds.length; ) {
            // Get the address and token ID of the Artist NFT to be minted
            (address nft, uint256 tokenId) = getNftInfo();

            // Mint the Artist NFT and transfer it to the caller
            IGorjsArtistCollection(nft).mint(msg.sender, tokenId);

            // Increment the total number of minted NFTs
            totalMintedAmount++;
                
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Internal functions
    /**
     * @dev Internal function to get the address of the next NFT to mint and its corresponding token ID.
     * @return The address of the NFT contract and the token ID.
     */
    function getNftInfo() internal view returns (address, uint256) {
        // Determine the index of the next NFT to mint based on the total amount already minted.
        uint256 index = totalMintedAmount == 0 ? 0 : totalMintedAmount;

        // Get the pair string from the pairs array based on the index.
        string memory pair = pairs[index];

        // Extract the index of the NFT contract and the token ID from the pair string.
        uint256 nftIndex = parseInt(substring(pair, 0)) - 1;
        uint256 tokenId = parseInt(substring(pair, 2));

        return (nftAddresses[nftIndex], tokenId);
    }

    /**
     * @dev Internal function to extract a substring from a string.
     * @param str The string to extract the substring from.
     * @param startIndex The starting index of the substring.
     * @return The extracted substring.
     */
    function substring(string memory str, uint256 startIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        uint256 endIndex = startIndex == 0 ? 1 : strBytes.length;
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**
     * @dev Internal function to parse a string as an integer.
     * @param str The string to parse.
     * @return The parsed integer value.
     */
    function parseInt(string memory str) internal pure returns (uint256) {
        bytes memory b = bytes(str);
        uint256 result = 0;
        for (uint i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }
}