// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Purchasable.sol";

abstract contract ERC721NativePurchasable is ERC721Purchasable {
    constructor(
        uint256 _maxSupply,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _contractURI
    ) ERC721Purchasable(_maxSupply, _name, _symbol, _baseURI, _contractURI) {}

    /**
     * @notice Allows user to mint a token by native token
     * @param account Account address
     */
    function mint(address account) external payable nonReentrant whenNotPaused {
        require(totalSupply() < totalMaxSupply, "Maximum total supply exceeded");

        uint256 tokenId = totalSupply();
        uint256 price = tokenPrice(tokenId);
        require(price <= msg.value, "Incorrect price");

        _mint(account, tokenId);

        (address[] memory receiverAddresses, uint256[] memory amounts) = _getPaymentDetails(price, tokenId);

        uint256 len = receiverAddresses.length;
        for (uint256 i = 0; i < len; ) {
            (bool success, ) = receiverAddresses[i].call{value: amounts[i]}("");
            require(success, "Failed to send native token");

            unchecked {
                ++i;
            }
        }
    }
}