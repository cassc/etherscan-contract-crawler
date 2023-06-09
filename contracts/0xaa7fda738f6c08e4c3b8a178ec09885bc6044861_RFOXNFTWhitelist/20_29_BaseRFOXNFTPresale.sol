// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BaseRFOXNFT.sol";

/**
 * @dev The extension of the BaseRFOX standard.
 * This is the base contract for the presale / whitelist mechanism.
 */
contract BaseRFOXNFTPresale is BaseRFOXNFT
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // How many NFTs can be minted per address during presale
    uint256 public maxMintedPresalePerAddress;

    // Timestamp of selling started for public
    uint256 public publicSaleStartTime;

    // Price for presale minting
    uint256 public TOKEN_PRICE_PRESALE;

    // Flag for total NFT minted during presale
    mapping(address => uint256) totalPresaleMintedPerAddress;

    // Merkle root for whitelist proof
    bytes32 public merkleRoot;

    // The flag for whitelist activation
    bool public isWhitelistActivated;

    event MaxMintedPresalePerAddress(address indexed sender, uint256 oldMaxMintedPresalePerAddress, uint256 newMaxMintedPresalePerAddress);
    event ActivateWhitelist(address indexed sender);
    event DeactivateWhitelist(address indexed sender);
    event UpdateMerkleRoot(
        address indexed sender,
        bytes32 oldMerkleRoot,
        bytes32 newMerkleRoot
    );
    event UpdateTokenPricePresale(
        address indexed sender,
        uint256 oldTokenPrice,
        uint256 newTokenPrice
    );

    /**
     * @dev Check if the whitelist feature is activated.
     */
    modifier whenWhitelistActivated() {
        require(isWhitelistActivated, "Whitelist is not active");
        _;
    }

    /**
     * @dev Check if the whitelist feature is disabled.
     */
    modifier whenWhitelistDeactivated() {
        require(!isWhitelistActivated, "Whitelist is active");
        _;
    }

    /**
     * @dev The rules are:
     * 1. If whitelist activated:
            - Only whitelisted address can mint the NFT after the saleEndTime (presale start time).
     * 2. If whitelist is not activated:
            - If users is not whitelisted & whitelisted, they can only mint after the publicSaleStartTime and before the saleEndTime.
     *
     * @param proof Array of the merkle tree proof, to check if the sender is whitelisted or not.
     */
    modifier authorizePresale(bytes32[] calldata proof) {
        if (isWhitelistActivated) {
            require(
                (checkWhitelisted(msg.sender, proof) && block.timestamp >= saleStartTime),
                "Unauthorized to join the presale"
            );
        } else {
            require(
                block.timestamp >= publicSaleStartTime,
                "Sale has not been started"
            );
        }

        _;
    }

    /**
     * @notice Base function to process the presale transaction submitted by the whitelisted address.
     * Each whitelisted address has quota to mint for the presale.
     * There is limit amount of token that can be minted during the presale.
     *
     * @param tokensNumber How many NFTs for buying this round
     */

    /// @param tokensNumber How many NFTs for buying this round
    function _buyNFTsPresale(uint256 tokensNumber) internal tokenInSupply(tokensNumber) {
        require(totalPresaleMintedPerAddress[msg.sender].add(tokensNumber) <= maxMintedPresalePerAddress, "Exceed the limit");
        totalPresaleMintedPerAddress[msg.sender] = totalPresaleMintedPerAddress[msg.sender].add(tokensNumber);
        
        if (saleEndTime > 0)
            require(block.timestamp <= saleEndTime, "Sale has been finished");

        if (address(saleToken) == address(0)) {
            require(
                msg.value == TOKEN_PRICE_PRESALE.mul(tokensNumber),
                "Invalid eth for purchasing"
            );
        } else {
            require(msg.value == 0, "ETH_NOT_ALLOWED");

            saleToken.safeTransferFrom(
                msg.sender,
                address(this),
                TOKEN_PRICE_PRESALE.mul(tokensNumber)
            );
        }

        _safeMint(msg.sender, tokensNumber);
    }

    /**
     * @dev setting whitelist purposes
     *
     * @param _maxMintedPresalePerAddress how many token can be minted per address during the presale
     */
    function updateMaxMintedPresalePerAddress(uint256 _maxMintedPresalePerAddress) external onlyOwner {
        require(_maxMintedPresalePerAddress <= MAX_NFT, "Invalid max mint per address");
        uint256 oldMaxMintedPresalePerAddress = maxMintedPresalePerAddress;
        maxMintedPresalePerAddress = _maxMintedPresalePerAddress;

        emit MaxMintedPresalePerAddress(msg.sender, oldMaxMintedPresalePerAddress, maxMintedPresalePerAddress);
    }

    /**
     * @dev Activate whitelist feature
     */
    function activateWhitelist() external onlyOwner whenWhitelistDeactivated {
        isWhitelistActivated = true;
        emit ActivateWhitelist(msg.sender);
    }

    /**
     * @dev Deactivate whitelist feature
     */
    function deactivateWhitelist() external onlyOwner whenWhitelistActivated {
        isWhitelistActivated = false;
        emit DeactivateWhitelist(msg.sender);
    }

    /**
     * @dev Update the merkle root for the whitelist tree.
     * If the whitelist changed, then need to update the hash root.
     *
     * @param _merkleRoot new hash of the root.
     */
    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        bytes32 oldMerkleRoot = merkleRoot;
        merkleRoot = _merkleRoot;
        emit UpdateMerkleRoot(msg.sender, oldMerkleRoot, merkleRoot);
    }

    /**
     * @dev Getter for the hash of the address.
     *
     * @param account The address to be checked.
     *
     * @return The hash of the address
     */
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    /**
     * @dev Check if the particular address is whitelisted or not.
     *
     * @param account The address to be checked. 
     * @param proof The bytes32 array from the offchain whitelist address.
     *
     * @return true / false.
     */
    function checkWhitelisted(address account, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = _leaf(account);
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /**
     * @dev Update the token price.
     *
     * @param newTokenPricePresale The new token price during presale.
     */
    function setTokenPricePresale(uint256 newTokenPricePresale) external onlyOwner {
        uint256 oldTokenPricePresale = TOKEN_PRICE_PRESALE;
        TOKEN_PRICE_PRESALE = newTokenPricePresale;
        emit UpdateTokenPricePresale(msg.sender, oldTokenPricePresale, TOKEN_PRICE_PRESALE);
    }
}