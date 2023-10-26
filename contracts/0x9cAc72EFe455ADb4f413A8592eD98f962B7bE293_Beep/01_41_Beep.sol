// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";
import "@thirdweb-dev/contracts/lib/TWStrings.sol";

contract Beep is ERC721Drop {
    using TWStrings for uint256;

    uint256 public quantityPerClaim = 1;
    string public globalBaseURI;

    event QuantityPerClaimUpdated(uint256 newQuantity);
    event GlobalBaseURIUpdated(string newURI);

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    )
        ERC721Drop(
            _defaultAdmin,
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {}

    /// @dev Override _beforeClaim to add quantity check
    function _beforeClaim(
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata,
        bytes memory
    ) internal view virtual override {
        if (_quantity > quantityPerClaim) {
            revert("Too many tokens claimed at once");
        }
        if (_currentIndex + _quantity > nextTokenIdToLazyMint) {
            revert("Not enough minted tokens");
        }
    }

    /// @dev Override tokenURI to allow globalBaseURI added to tokenURI
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        if (bytes(globalBaseURI).length > 0) {
            return string(abi.encodePacked(globalBaseURI, _tokenId.toString()));
        }
        return super.tokenURI(_tokenId);
    }

    function setQuantityPerClaim(uint256 _quantity) public onlyOwner {
        quantityPerClaim = _quantity;
        emit QuantityPerClaimUpdated(_quantity);
    }

    function setGlobalBaseURI(string memory _globalBaseURI) public onlyOwner {
        globalBaseURI = _globalBaseURI;
        emit GlobalBaseURIUpdated(_globalBaseURI);
    }
}