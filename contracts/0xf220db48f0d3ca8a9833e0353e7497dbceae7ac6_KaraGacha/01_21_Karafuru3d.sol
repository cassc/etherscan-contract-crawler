// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PrivateSalesActivation.sol";
import "./PublicSalesActivation.sol";
import "./DASalesActivation.sol";
import "./Whitelist.sol";
import "./ERC721Opensea.sol";
import "./Withdrawable.sol";

contract KaraGacha is
    Ownable,
    EIP712,
    DASalesActivation,
    PrivateSalesActivation,
    PublicSalesActivation,
    Whitelist,
    ERC721Opensea,
    Withdrawable
{
    uint256 public constant TOTAL_MAX_QTY = 15555;
    uint256 public GIFT_MAX_QTY = 5655;
    uint256 public constant DASALES_MAX_QTY = 4000;
    uint256 public constant DA_MAX_QTY_PER_MINTER = 2;
    uint256 public constant PUBLIC_MAX_QTY_PER_MINTER = 2;
    uint256 public constant DA_SALES_START_PRICE = 0.5 ether;
    uint256 public DA_LAST_PRICE = DA_SALES_START_PRICE;
    uint256 public constant priceDropDuration = 1800;
    uint256 public constant priceDropAmount = 0.025 ether;
    uint256 public constant priceDropFloor = 0.25 ether;
    uint256 public fPublicSalesPrice = DA_SALES_START_PRICE;

    mapping(address => uint256) public DASalesMinterToTokenQty;
    mapping(address => uint256) public privateSalesMinterToTokenQty;
    mapping(address => uint256) public publicSalesMinterToTokenQty;
    // mapping(address => uint256) public DAAddressIdToPrice;
    struct TokenBatchPriceData {
        uint256 pricePaid;
        uint256 qtyMinted;
    }
    mapping(address => TokenBatchPriceData[]) public userToTokenBatchPriceData;

    uint256 public DASalesMintedQty = 0;
    uint256 public privateSalesMintedQty = 0;
    uint256 public publicSalesMintedQty = 0;
    uint256 public giftedQty = 0;

    constructor()
        ERC721("Karafuru Gachapon", "KARA-GACHA")
        Whitelist("Karafuru 3D", "1")
    {}

    // function refundAll() external {
    // require(
    //     !isDASalesActivated() || DASalesMintedQty >= DASALES_MAX_QTY,
    //     "DA still ongoing"
    // );
    // require(block.timestamp <= publicSalesStartTime, "Refund time passed");

    //     uint256 refundValue = DAAddressIdToPrice[msg.sender] - DA_LAST_PRICE;
    //     DAAddressIdToPrice[msg.sender] = DA_LAST_PRICE;
    //     payable(msg.sender).transfer(refundValue);
    // }

    function claimRefund() external {
        require(
            !isDASalesActivated() || DASalesMintedQty >= DASALES_MAX_QTY,
            "DA still ongoing"
        );
        require(block.timestamp <= publicSalesStartTime, "Refund time passed");

        uint256 _claimableAmount = claimableAmount(msg.sender);
        require(
            address(this).balance >= _claimableAmount,
            "Not enough balance"
        );

        _removeAuctionPurchaseHistory(msg.sender);
        payable(msg.sender).transfer(_claimableAmount);
    }

    function _removeAuctionPurchaseHistory(address buyer) internal {
        TokenBatchPriceData[] storage histories = userToTokenBatchPriceData[
            buyer
        ];

        for (uint256 i = histories.length; i > 0; i--) {
            histories.pop();
        }
    }

    function claimableAmount(address buyer) public view returns (uint256) {
        TokenBatchPriceData[] memory histories = userToTokenBatchPriceData[
            buyer
        ];
        uint256 _claimableAmount = 0;

        for (uint256 i; i < histories.length; i++) {
            _claimableAmount +=
                histories[i].pricePaid -
                (DA_LAST_PRICE * histories[i].qtyMinted);
        }

        return _claimableAmount;
    }

    function getPrice() public view returns (uint256) {
        if (isDASalesActivated()) {
            uint256 dropCount = (block.timestamp - DASalesStartTime) /
                priceDropDuration;
            return
                dropCount < 10
                    ? DA_SALES_START_PRICE - dropCount * priceDropAmount
                    : priceDropFloor;
        } else if (isPrivateSalesActivated()) {
            return (DA_LAST_PRICE * 70) / 100;
        }
        return DA_LAST_PRICE;
    }

    function mint(address sender) internal {
        uint256 newTokenId = totalSupply() + 1;
        _safeMint(sender, newTokenId);
    }

    function DASalesMint(
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    )
        external
        payable
        isDASalesActive
        isSenderWhitelisted(_signedQty, _nonce, _signature)
    {
        uint256 price = getPrice();

        require(
            DASalesMintedQty +
                privateSalesMintedQty +
                publicSalesMintedQty +
                GIFT_MAX_QTY <
                TOTAL_MAX_QTY,
            "Exceed sales max limit"
        );
        require(DASalesMintedQty + 1 <= DASALES_MAX_QTY, "DA quota limit");
        require(
            DASalesMinterToTokenQty[msg.sender] + 1 <= DA_MAX_QTY_PER_MINTER,
            "Exceed max mint per minter"
        );
        require(msg.value >= price, "Insufficient ETH");

        DASalesMinterToTokenQty[msg.sender] += 1;
        DASalesMintedQty += 1;
        // DAAddressIdToPrice[msg.sender] = msg.value;
        TokenBatchPriceData[] storage histories = userToTokenBatchPriceData[
            msg.sender
        ];
        histories.push(TokenBatchPriceData(msg.value, 1));
        mint(msg.sender);

        DA_LAST_PRICE = price;
    }

    function privateSalesMint(
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    )
        external
        payable
        isPrivateSalesActive
        isSenderWhitelisted(_signedQty, _nonce, _signature)
    {
        uint256 price = getPrice();
        require(
            DASalesMintedQty +
                privateSalesMintedQty +
                publicSalesMintedQty +
                GIFT_MAX_QTY <
                TOTAL_MAX_QTY,
            "Exceed sales max limit"
        );
        require(
            privateSalesMinterToTokenQty[msg.sender] + 1 <= _signedQty,
            "Exceed signed quantity"
        );
        require(msg.value >= price, "Insufficient ETH");

        privateSalesMinterToTokenQty[msg.sender] += 1;
        privateSalesMintedQty += 1;

        mint(msg.sender);
    }

    function publicSalesMint(
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    )
        external
        payable
        isPublicSalesActive
        isSenderWhitelisted(_signedQty, _nonce, _signature)
    {
        require(
            DASalesMintedQty +
                privateSalesMintedQty +
                publicSalesMintedQty +
                GIFT_MAX_QTY <
                TOTAL_MAX_QTY,
            "Exceed sales max limit"
        );
        require(msg.value >= fPublicSalesPrice, "Insufficient ETH");

        require(
            publicSalesMinterToTokenQty[msg.sender] + 1 <=
                PUBLIC_MAX_QTY_PER_MINTER,
            "Exceed max mint per minter"
        );
        publicSalesMinterToTokenQty[msg.sender] += 1;
        publicSalesMintedQty += 1;

        mint(msg.sender);
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(
            DASalesMintedQty +
                privateSalesMintedQty +
                publicSalesMintedQty +
                receivers.length <=
                TOTAL_MAX_QTY,
            "Exceed total max limit"
        );
        require(
            giftedQty + receivers.length <= GIFT_MAX_QTY,
            "Exceed gift max limit"
        );
        giftedQty = giftedQty + receivers.length;
        for (uint256 i = 0; i < receivers.length; i++) {
            mint(receivers[i]);
        }
    }

    function changeGiftAmount(uint256 giftAmount) external onlyOwner {
        GIFT_MAX_QTY = giftAmount;
    }

    function changeFPublicSalesprice(uint256 price) external onlyOwner {
        fPublicSalesPrice = price;
    }
}