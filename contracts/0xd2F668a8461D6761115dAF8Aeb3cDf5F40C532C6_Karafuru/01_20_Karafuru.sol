// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PreSalesActivation.sol";
import "./PublicSalesActivation.sol";
import "./Whitelist.sol";
import "./ERC721Opensea.sol";
import "./Withdrawable.sol";

contract Karafuru is
    Ownable,
    EIP712,
    PreSalesActivation,
    PublicSalesActivation,
    Whitelist,
    ERC721Opensea,
    Withdrawable
{
    uint256 public constant TOTAL_MAX_QTY = 5555;
    uint256 public constant GIFT_MAX_QTY = 133;
    uint256 public constant PRESALES_MAX_QTY = 3500;
    uint256 public constant SALES_MAX_QTY = TOTAL_MAX_QTY - GIFT_MAX_QTY;
    uint256 public constant MAX_QTY_PER_MINTER = 2;
    uint256 public constant PRE_SALES_PRICE = 0.2 ether;
    uint256 public constant PUBLIC_SALES_START_PRICE = 0.5 ether;

    uint256 public constant priceDropDuration = 600; // 10 mins
    uint256 public constant priceDropAmount = 0.025 ether;
    uint256 public constant priceDropFloor = 0.2 ether;

    mapping(address => uint256) public preSalesMinterToTokenQty;
    mapping(address => uint256) public publicSalesMinterToTokenQty;

    uint256 public preSalesMintedQty = 0;
    uint256 public publicSalesMintedQty = 0;
    uint256 public giftedQty = 0;

    constructor() ERC721("Karafuru", "KARAFURU") Whitelist("Karafuru", "1") {}

    function getPrice() public view returns (uint256) {
        // Public sales
        if (isPublicSalesActivated()) {
            uint256 dropCount = (block.timestamp - publicSalesStartTime) /
                priceDropDuration;
            // It takes 12 dropCount to reach at 0.2 floor price in Dutch Auction
            return
                dropCount < 12
                    ? PUBLIC_SALES_START_PRICE - dropCount * priceDropAmount
                    : priceDropFloor;
        }
        return PRE_SALES_PRICE;
    }

    function preSalesMint(
        uint256 _mintQty,
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    )
        external
        payable
        isPreSalesActive
        isSenderWhitelisted(_signedQty, _nonce, _signature)
    {
        require(
            preSalesMintedQty + publicSalesMintedQty + _mintQty <=
                SALES_MAX_QTY,
            "Exceed sales max limit"
        );
        require(
            preSalesMintedQty + _mintQty <= PRESALES_MAX_QTY,
            "Exceed pre-sales max limit"
        );
        require(
            preSalesMinterToTokenQty[msg.sender] + _mintQty <= _signedQty,
            "Exceed signed quantity"
        );
        require(msg.value >= _mintQty * getPrice(), "Insufficient ETH");
        require(tx.origin == msg.sender, "Contracts not allowed");

        preSalesMinterToTokenQty[msg.sender] += _mintQty;
        preSalesMintedQty += _mintQty;

        for (uint256 i = 0; i < _mintQty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function publicSalesMint(uint256 _mintQty)
        external
        payable
        isPublicSalesActive
    {
        require(
            preSalesMintedQty + publicSalesMintedQty + _mintQty <=
                SALES_MAX_QTY,
            "Exceed sales max limit"
        );
        require(
            publicSalesMinterToTokenQty[msg.sender] + _mintQty <=
                MAX_QTY_PER_MINTER,
            "Exceed max mint per minter"
        );
        require(msg.value >= _mintQty * getPrice(), "Insufficient ETH");
        require(tx.origin == msg.sender, "Contracts not allowed");

        publicSalesMinterToTokenQty[msg.sender] += _mintQty;
        publicSalesMintedQty += _mintQty;

        for (uint256 i = 0; i < _mintQty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(
            giftedQty + receivers.length <= GIFT_MAX_QTY,
            "Exceed gift max limit"
        );

        giftedQty += receivers.length;

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
}