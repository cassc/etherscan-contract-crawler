// SPDX-License-Identifier: Copyright

pragma solidity ^0.8.7;

import "./VNPublicSale.sol";

contract VintageNeighborNFT is VNPublicSale {
    uint256 public constant PUBLIC_SALE_MAX_SUPPLY = 9500;
    uint256 public constant ADVISORY_MAX_SUPPLY = 500;

    uint256 private _publicSaleMinted = 0;
    uint256 private _advisoryMinted = 0;
    uint256 private _tokenIdCounter = 0;

    constructor() ERC721("VintageNeighbor", "VIN") {}

    function purchase(uint256 amount) external payable {
        require(publicSaleStarted(), "Public sale not started");
        require(amount > 0, "Amount can not be 0");

        uint256 totalPrice = getPublicSalePrice() * amount;
        require(msg.value == totalPrice, "invalid amount");

        _publicSaleMinted = _publicSaleMinted + amount;

        require(
            _publicSaleMinted <= PUBLIC_SALE_MAX_SUPPLY,
            "Public sale max reached"
        );

        payable(owner()).transfer(totalPrice);
        mint(msg.sender, amount);
    }

    function whiteListMint() external payable {
        require(super.isWhiteListActive(), "WhiteList not active");
        uint256 price = super.getWhiteListPrice();
        require(msg.value == price, "price not match");
        super.setWhiteListPurchased(msg.sender);

        _publicSaleMinted = _publicSaleMinted + 1;

        require(
            _publicSaleMinted <= PUBLIC_SALE_MAX_SUPPLY,
            "Public sale max reached"
        );

        payable(owner()).transfer(price);
        mint(msg.sender, 1);
    }

    function adminMint(address to, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount can not be 0");

        _advisoryMinted = _advisoryMinted + amount;
        require(_advisoryMinted <= ADVISORY_MAX_SUPPLY, "Advisory max reached");

        mint(to, amount);
    }

    function mint(address to, uint256 amount) private {
        for (uint256 i = 0; i < amount; i++) {
            super._mint(to, _tokenIdCounter);
            _tokenIdCounter = _tokenIdCounter + 1;
        }
    }

    /// @notice Returns all the tokenIds from an owner
    /// @dev This method MUST NEVER be called by smart contract code.
    function getTokenIds(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            result[i] = tokenOfOwnerByIndex(owner, i);
        }

        return result;
    }
}