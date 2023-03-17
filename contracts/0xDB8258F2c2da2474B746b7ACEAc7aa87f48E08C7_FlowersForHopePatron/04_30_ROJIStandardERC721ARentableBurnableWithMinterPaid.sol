// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ROJIStandardERC721ARentableBurnable.sol";
import "../utils/errors.sol";

/// @title ERC721A based NFT contract with included paid minter protected by off chain allowlist
/// @author Martin Wawrusch for Roji Inc.
/// @dev
/// General
/// This contract extends the standard NFT contract with a minter that is guarded through
/// an external signature mechanism (allowlist).
///
/// The mintableSupply determines how many NFTs can be minted by users directly through the {mint} method.
/// 
/// @custom:security-contact [email protected]
contract ROJIStandardERC721ARentableBurnableWithMinterPaid is ROJIStandardERC721ARentableBurnable // IMPORTANT MUST ALWAYS BE FIRST - NEVER CHANGE THAT
                                             {

    /// @notice This is to protect against larger gas costs on transfers.
    uint256 private constant MAX_MINT_PER_REQUEST = 20;

    /// @notice The number of NFTs that can be minted by users through the mint method.
    uint256 private _mintableSupply;

    /// @notice The price per NFT in wei.
    uint256 private _price;

    /// @notice The maximum number of mints per wallet address.
    uint256 private _maxMintQuantityPerAddress;

    /// @notice The event emitted when the price per NFT changed.
    /// @param price The new price per NFT in wei.
    event PriceChanged(uint256 price);

    /// @notice The event emitted when the maximum number of mints per wallet address is updated.
    /// @param maxMintQuantityPerAddress The new maximum number of mints per wallet address.
    event MaxMintQuantityPerAddressChanged(uint256 maxMintQuantityPerAddress);

    /// @notice The event emitted when the mintable supply has been manully updated. That means, not through minting.
    /// @param mintableSupply The new mintable supply.
    event MintableSupplyChanged(uint256 mintableSupply);

    /// @notice The constructor of this contract.
    /// @param price_ The price per NFT in wei.
    /// @param maxMintQuantityPerAddress_ The maximum number of mints per wallet address.
    /// @param mintableSupply_ The number of NFTs that can be minted by users through the mint method.
    /// @param defaultRoyaltiesBasisPoints_ The default royalties basis points (out of 10000).
    /// @param name_ The name of the NFT.
    /// @param symbol_ The symbol of the NFT. Must not exceed 11 characters as that is the Metamask display limit.
    /// @param baseTokenURI_ The base URI of the NFTs. The final URI is composed through baseTokenURI + tokenId + .json. Normally you will want to include the trailing slash.
    constructor(uint256 price_,
                uint256 maxMintQuantityPerAddress_,
                uint256 mintableSupply_,
                uint256 defaultRoyaltiesBasisPoints_,
                string memory name_,
                string memory symbol_,
                string memory baseTokenURI_) 
                ROJIStandardERC721ARentableBurnable(defaultRoyaltiesBasisPoints_, name_,symbol_, baseTokenURI_) {
      _mintableSupply = mintableSupply_;
      _price = price_;
      _maxMintQuantityPerAddress = maxMintQuantityPerAddress_;
    }

    /// @inheritdoc ROJIStandardERC721ARentableBurnable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ROJIStandardERC721ARentableBurnable )
        returns (bool)
    {
        return  ROJIStandardERC721ARentableBurnable.supportsInterface(interfaceId);
    }


    /// @notice Mints numberOfTokens amount of tokens to address of sender.
    /// @param quantity The number of tokens to mint.
    /// @dev Requires that the signature is valid, the contract is not paused, and the
    /// quantity is less than or equal the [maxMintQuantityPerAddress] minus the already minted NFTs.
    function mint(uint256 quantity) external payable requiresMaxSupply(quantity) whenNotPaused() {

       if( quantity > MAX_MINT_PER_REQUEST) { revert InternalMintPerCallLimitExceeded(MAX_MINT_PER_REQUEST); }
       if(_numberMinted(_msgSenderERC721A()) + quantity > _maxMintQuantityPerAddress) revert TokenLimitPerAddressExceeded();
       if(msg.value < _price * quantity) { revert InsufficientPayment(); }
       if(_mintableSupply < quantity) { revert NotEnoughTokens(); }

      unchecked {
        _mintableSupply -= quantity;
      }
      // Note: 0 quantity check is performed at the ERC721A base class.
      _mint(_msgSenderERC721A(), quantity);
   }

    /// @notice Sets the new mintable supply.
    /// @dev This method requires the DEFAULT_ADMIN_ROLE role.
    /// @param mintableSupply_ The new mintable supply.
    function setMintableSupply(uint256 mintableSupply_) external onlyOwner {
        _mintableSupply = mintableSupply_;
        emit MintableSupplyChanged(mintableSupply_);
    }
    
    /// @notice Sets the price in gwai for a single nft sale. 
    /// @dev This method requires the DEFAULT_ADMIN_ROLE role.
    /// @param price_ The new price per NFT in wei.
    function setPrice(uint256 price_) external onlyOwner {
        _price = price_;
        emit PriceChanged( price_);
    }

    /// @notice Sets the maximum number of mints per wallet address.
    /// @dev This method requires the DEFAULT_ADMIN_ROLE role.
    /// @param maxMintQuantityPerAddress_ The new maximum number of mints per wallet address.
    function setMaxMintQuantityPerAddress(uint256 maxMintQuantityPerAddress_) external onlyOwner {
        _maxMintQuantityPerAddress = maxMintQuantityPerAddress_;
        emit MaxMintQuantityPerAddressChanged( maxMintQuantityPerAddress_);
    }

    /// @notice Returns the price per NFT in wei.
    function price() external view returns(uint256) {
        return _price;
    }

    /// @notice Returns the maximum number of NFTs that can be minted per address.
    function maxMintQuantityPerAddress() external view returns(uint256) {
        return _maxMintQuantityPerAddress;
    }

    /// @notice Returns the maximum numbers of NFTs that can be minted with the {mint} method.
    function mintableSupply() external view returns(uint256) {
        return _mintableSupply;
    }

}