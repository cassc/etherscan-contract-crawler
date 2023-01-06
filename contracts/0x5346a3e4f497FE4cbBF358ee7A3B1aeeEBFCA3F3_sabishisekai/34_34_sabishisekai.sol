// SPDX-License-Identifier: Apache-2.0
// Max Free Mints Per Wallet: 1
// Price after free mint is: 0.003
// Max total per wallet: 10
// Max Supply: 4444

pragma solidity ^0.8.13;

import "@thirdweb-dev/contracts/base/ERC721DelayedReveal.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "@thirdweb-dev/contracts/extension/PrimarySale.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";


contract sabishisekai is Ownable, ERC721DelayedReveal, PrimarySale, DefaultOperatorFilterer {

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _saleRecipient,
        uint256 _pricePerToken,
        uint256 _mintForFree
    ) ERC721DelayedReveal(_name, _symbol, _royaltyRecipient, _royaltyBps) {
        _setupPrimarySaleRecipient(_saleRecipient);
        pricePerToken = _pricePerToken;
        mintForFree = _mintForFree;
    }

    mapping(address => uint256) public numClaimedForFree;
    uint256 public pricePerToken;
    uint256 public mintForFree;

    function _canLazyMint() internal view override returns (bool) {
        return msg.sender == owner();
    }

    function _transferTokensOnClaim(address _receiver, uint256 _quantity)
        internal
        virtual
        override
        returns (uint256 startTokenId)
    {
        startTokenId = super._transferTokensOnClaim(_receiver, _quantity);

        uint256 freeAllowance = mintForFree - numClaimedForFree[_receiver];
        uint256 freeQuantity = _quantity > freeAllowance ? freeAllowance : _quantity;
        uint256 paidQuantity = _quantity > freeQuantity ? (_quantity - freeQuantity) : 0;

        if (paidQuantity > 0) {
            require(msg.value == paidQuantity * pricePerToken, "Incorrect payment amount");
        }

        numClaimedForFree[_receiver] += freeQuantity;

        return startTokenId;
    }

    function priceForAddress(address _address, uint256 _quantity)
        external
        view
        returns (uint256 price)
    {
        uint256 freeAllowance = mintForFree - numClaimedForFree[_address];
        uint256 freeQuantity = _quantity > freeAllowance ? freeAllowance : _quantity;
        uint256 paidQuantity = _quantity > freeQuantity ? (_quantity - freeQuantity) : 0;

        price = paidQuantity * pricePerToken;

        return price;
    }

    function _canSetPrimarySaleRecipient() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function setPricePerToken(uint256 _newPrice) external {
        require(msg.sender == owner(), "Not authorized");
        pricePerToken = _newPrice;
    }


    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

  function withdraw() external onlyOwner {
  uint _balance = address(this).balance;
     payable(msg.sender).transfer(_balance ); 
       
  }

}