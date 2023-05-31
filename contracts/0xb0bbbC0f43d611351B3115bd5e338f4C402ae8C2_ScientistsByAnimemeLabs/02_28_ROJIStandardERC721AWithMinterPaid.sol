// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../utils/EIP712AccessControl.sol";
import "./ROJIStandardERC721A.sol";

/// @title ERC721A based NFT contract with included paid minter protected by off chain allowlist
/// @author Martin Wawrusch for Roji Inc.
/// @custom:security-contact [email protected]
contract ROJIStandardERC721AWithMinterPaid is  ROJIStandardERC721A , EIP712AccessControl {
    using SafeMath for uint256;

    /// @notice This is to protect against larger gas costs on transfers.
    uint256 public constant MAX_MINT_PER_REQUEST = 20;

    /// @notice The number of NFTs that can be minted by users through the mint method.
    uint256 public availableSupply;
    /// @notice The price per NFT in wei.
    uint256 public price;
    /// @notice The maximum number of mints per wallet address.
    uint256 public maxMintQuantityPerAddress;

    /// @notice The event emitted when the price per NFT changed.
    /// @param price The new price per NFT in wei.
    event PriceChanged(uint256 price);

    /// @notice The event emitted when the maximum number of mints per wallet address is updated.
    /// @param maxMintQuantityPerAddress The new maximum number of mints per wallet address.
    event MaxMintQuantityPerAddressChanged(uint256 maxMintQuantityPerAddress);

    /// @notice The event emitted when the available supply has been manully updated. That means, not through minting.
    /// @param availableSupply The new available supply.
    event AvailableSupplyChanged(uint256 availableSupply);

    /// @notice The constructor of this contract.
    /// @param price_ The price per NFT in wei.
    /// @param maxMintQuantityPerAddress_ The maximum number of mints per wallet address.
    /// @param availableSupply_ The number of NFTs that can be minted by users through the mint method.
    /// @param defaultRoyaltiesBasisPoints_ The default royalties basis points (out of 10000).
    /// @param name_ The name of the NFT.
    /// @param symbol_ The symbol of the NFT. Must not exceed 11 characters as that is the Metamask display limit.
    /// @param baseTokenURI_ The base URI of the NFTs. The final URI is composed through baseTokenURI + tokenId + .json. Normally you will want to include the trailing slash.
    /// @param domainVerifierAppName_ The app name used in the signature generator
    /// @param domainVerifierAppVersion_ The app version used in the signature generator. Normally 1
    /// @param allowlistSignerAddress_ The address of the signature generator.
    constructor(uint256 price_,
                uint256 maxMintQuantityPerAddress_,
                uint256 availableSupply_,
                uint256 defaultRoyaltiesBasisPoints_,
                string memory name_,
                string memory symbol_,
                string memory baseTokenURI_,
                string memory domainVerifierAppName_,
                string memory domainVerifierAppVersion_,
                address allowlistSignerAddress_) 
                ROJIStandardERC721A(defaultRoyaltiesBasisPoints_, name_,symbol_, baseTokenURI_)
                EIP712AccessControl(domainVerifierAppName_, domainVerifierAppVersion_, allowlistSignerAddress_) {
      availableSupply = availableSupply_;
      price = price_;
      maxMintQuantityPerAddress = maxMintQuantityPerAddress_;
    }

    /// @inheritdoc ROJIStandardERC721A
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ROJIStandardERC721A, AccessControl)
        returns (bool)
    {
        return  ROJIStandardERC721A.supportsInterface(interfaceId) || 
                AccessControl.supportsInterface(interfaceId);
    }


    /// @notice Mints numberOfTokens amount of tokens to address of sender.
    /// @param quantity The number of tokens to mint.
    /// @param signature The allowlist signature tied to the sender address.
    /// @dev Requires that the signature is valid, the contract is not paused, and the
    /// quantity is less than or equal the [maxMintQuantityPerAddress] minus the already minted NFTs.
    function mint(uint256 quantity, bytes calldata signature) external payable requiresAllowlist(signature) whenNotPaused() {
       require(quantity <= MAX_MINT_PER_REQUEST, "quantity > MAX_MINT_PER_REQUEST");

      uint256 numberMinted = _numberMinted(msg.sender);

      require(numberMinted + quantity <= maxMintQuantityPerAddress, "Token limit/address exceeded");
      require(msg.value >= price.mul(quantity), "Insufficient payment");
      require(availableSupply >= quantity, "Not enough tokens left");

      unchecked {
        availableSupply -= quantity;
      }
      // Note: 0 quantity check is performed at the ERC721A base class.

      _mint(msg.sender, quantity);
   }


    /// @notice Sets the new available supply.
    /// @dev This method requires the DEFAULT_ADMIN_ROLE role.
    /// @param availableSupply_ The new available supply.
    function setAvailableSupply(uint256 availableSupply_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        availableSupply = availableSupply_;
        emit AvailableSupplyChanged(availableSupply_);
    }
    
    /// @notice Sets the price in gwai for a single nft sale. 
    /// @dev This method requires the DEFAULT_ADMIN_ROLE role.
    /// @param price_ The new price per NFT in wei.
    function setPrice(uint256 price_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        price = price_;
        emit PriceChanged( price_);
    }

    /// @notice Sets the maximum number of mints per wallet address.
    /// @dev This method requires the DEFAULT_ADMIN_ROLE role.
    /// @param maxMintQuantityPerAddress_ The new maximum number of mints per wallet address.
    function setMaxMintQuantityPerAddress(uint256 maxMintQuantityPerAddress_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxMintQuantityPerAddress = maxMintQuantityPerAddress_;
        emit MaxMintQuantityPerAddressChanged( maxMintQuantityPerAddress_);
    }
}