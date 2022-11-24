// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SilksPaymentsV1 is Ownable {
    struct Sale {
        string saleId;
        uint price;
        bool paused;
        uint maxPerTx;
        uint maxPerWallet;
        bool valid;
    }
    
    struct Receipt {
        address buyer;
        string saleId;
        uint quantity;
        uint pricePer;
        uint total;
    }
    
    event Purchase(uint receiptId);

    mapping(uint => string) public SaleIndexToId;
    mapping(uint => address) public ReceiptToBuyer;

    mapping(string => Sale) internal sales;
    mapping(uint => Receipt) internal receipts;
    mapping(string => uint) internal numPurchases;
    mapping(address => mapping(string => uint)) internal numPurchasesByAddress;
    
    uint public saleCount;
    uint public receiptCount;
    
    using SafeMath for uint;
    
    string public name = "Silks - Payments V1";
    
    constructor(){}
    
    function getSale(
        string calldata _saleId
    )
    public
    view
    returns (
        uint price,
        bool paused,
        uint maxPerTx,
        uint maxPerWallet,
        bool valid
    ) {
        return (
        sales[_saleId].price,
        sales[_saleId].paused,
        sales[_saleId].maxPerTx,
        sales[_saleId].maxPerWallet,
        sales[_saleId].valid
        );
    }
    
    function setSale(
        string calldata _saleId,
        uint _price,
        bool _paused,
        uint _maxPerTx,
        uint _maxPerWallet,
        bool _valid
    )
    external
    onlyOwner
    {
        if (!sales[_saleId].valid){
            SaleIndexToId[saleCount] = _saleId;
            saleCount++;
        }
        
        sales[_saleId] = Sale(
            _saleId,
            _price,
            _paused,
            _maxPerTx,
            _maxPerWallet,
            _valid
        );
    }
    
    function getReceipt(
        uint _receiptId
    )
    public
    view
    returns (
        address buyer,
        string memory saleId,
        uint quantity,
        uint pricePer,
        uint total
    ) {
        return (
        receipts[_receiptId].buyer,
        receipts[_receiptId].saleId,
        receipts[_receiptId].quantity,
        receipts[_receiptId].pricePer,
        receipts[_receiptId].total
        );
    }
    
    function purchase(
        string calldata _saleId,
        uint _quantity
    )
    public
    payable
    returns(uint)
    {
        (uint price, bool paused, uint maxPerTx, uint maxPerWallet, bool valid) = getSale(_saleId);
        require(
            valid && !paused,
            "NOT_VALID_OR_PAUSED"
        );
        require(
            msg.value % price == 0 &&
            ((msg.value / price) * price == msg.value),
            "INV_ETH_TOTAL"
        );
        require(
            (msg.value / price) == _quantity,
            "INV_QUANTITY"
        );
        require(
            maxPerTx == 0 || (msg.value / price) <= maxPerTx,
            "PER_TX_ERROR"
        );
        require(
            maxPerWallet == 0 || (_quantity + numPurchasesByAddress[msg.sender][_saleId]) <= maxPerWallet,
            "PER_WALLET_ERROR"
        );

        numPurchases[_saleId]++;
        
        receiptCount++;
        receipts[receiptCount] = Receipt(
            msg.sender,
            _saleId,
            _quantity,
            price,
            msg.value);
        ReceiptToBuyer[receiptCount] = msg.sender;
        
        emit Purchase(receiptCount);
        
        return receiptCount;
    }
    
    // Get amount of 1155 minted
    function getNumPurchasesForSale(
        string calldata _saleId
    )
    view
    public
    returns(uint)
    {
        return numPurchases[_saleId];
    }
    
    function getNumPurchasesByBuyer(
        address buyer,
        string calldata _saleId
    )
    view
    public
    returns(uint)
    {
        return numPurchasesByAddress[buyer][_saleId];
    }
    
    // Basic withdrawal of funds function in order to transfer ETH out of the smart contract
    function withdrawFunds()
    public
    onlyOwner
    {
        payable(msg.sender).transfer(address(this).balance);
    }
}