// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721LazyMint.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@thirdweb-dev/contracts/extension/PrimarySale.sol";
import "@thirdweb-dev/contracts/lib/CurrencyTransferLib.sol";

contract ChainStoryMembershipPassContract is ERC721LazyMint, PrimarySale {

    /*//////////////////////////////////////////////////////////////
                    Private Contract Variables
    //////////////////////////////////////////////////////////////*/

    // Limit on how many tokens can exist
    uint256 MAX_SUPPLY = 10000;

    // Price per token for each sale
    uint256 public pricePerToken;

    // Current Token Id
    uint256 private _currentTokenId;

      constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _saleRecipient,
        uint256 _pricePerToken
    )
        ERC721LazyMint(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps
        )
    {
        _setupPrimarySaleRecipient(_saleRecipient);
        pricePerToken = _pricePerToken;
    }

     /**
     *  @notice         Returns the metadata URI for an NFT.
     *  @dev            See `BatchMintMetadata` for handling of metadata in this contract.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory baseUri = "https://chainstory.xyz/api/nft/genesis?address=";
        string memory tokenParam = "&tokenId=";
        return string(abi.encodePacked(baseUri, Strings.toHexString(ownerOf(_tokenId)), tokenParam, Strings.toString(_tokenId)));
    }

    function _transferTokensOnClaim(address _receiver, uint256 _quantity)
        internal
        virtual
        override
        returns (uint256 startTokenId)
    {
        require(_currentTokenId + _quantity <= MAX_SUPPLY, "We're all sold out!");
        require(msg.value == _quantity * pricePerToken, "Incorrect value passed in!");

        _currentTokenId = _currentTokenId + _quantity;
        startTokenId = super._transferTokensOnClaim(_receiver, _quantity);
        _collectPrice(_receiver, _quantity);
    }

    function _canLazyMint() internal view override returns (bool) {
        return msg.sender == owner();
    }

    function _collectPrice(address _receiver, uint256 _quantity) private {

        uint256 totalPrice = _quantity * pricePerToken;

        CurrencyTransferLib.safeTransferNativeToken(primarySaleRecipient(), totalPrice);
    }

    function priceForAddress(address _address, uint256 _quantity)
        external
        view
        returns (uint256 price)
    {
        price = _quantity * pricePerToken;
        return price;
    }

    function _canSetPrimarySaleRecipient() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function setPricePerToken(uint256 _newPrice) external {
        require(msg.sender == owner(), "Not authorized");
        pricePerToken = _newPrice;
    }

}