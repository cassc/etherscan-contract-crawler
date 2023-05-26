// SPDX-License-Identifier: MIT
// Author: Eric Gao (@itsoksami, https://github.com/Ericxgao)

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "./LinearDutchAuction.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
contract BaseDutchAuctionERC721A is ERC721A, LinearDutchAuction, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    string public prefix = "Windchime";
    string public prefixDiscounted = "Windchime";
    string private baseTokenURI = '';
    string public licenseTerms = '';

    mapping(address => uint256) private _whitelistClaimed;
    mapping(address => uint256) private _publicListClaimed;

    uint256 public whitelistMaxMint;
    uint256 public publicListMaxMint;
    uint256 public reservedMax;
    uint256 public max;
    uint256 public nonReservedMinted;
    uint256 public reservedMinted;
    uint256 public discountedPrice;

    PaymentSplitter private _splitter;
    bool public isAllowedRefund;
    bool public allowPublicRefunds;
    bool allowWhitelistRefunds;
    bool allowDiscountRefunds;
    uint256 public isRefund;
    uint256 public refundPrice;
    uint256 public totalMintsForRefund;
    mapping(address => uint256) publicPurchasePrices;
    mapping(address => uint256) whitelistPurchasePrices;
    mapping(address => uint256) discountedPurchasePrices;

    mapping(address => uint256) private _discountClaimed;
    
    uint64 private constant decreaseInterval = 900;
    uint64 private constant numDecreases = 9;
    uint64 private constant startPrice = 5 ether;
    uint64 private constant decreaseSize = 0.5 ether;

    uint256 public publicTotalMaxMint;
    uint256 public publicTotalMinted;
    constructor(
        address[] memory payees, 
        uint256[] memory shares,
        string memory name,
        string memory symbol,
        uint256 _whitelistMaxMint, 
        uint256 _publicListMaxMint,
        uint256 _nonReservedMax,
        uint256 _reservedMax,
        uint256 _discountedPrice,
        uint256 _publicTotalMaxMint
    )
        ERC721A(name, symbol, 20)
        LinearDutchAuction(
            LinearDutchAuction.DutchAuctionConfig({
                startPoint: 0, // disabled at deployment
                startPrice: startPrice,
                unit: AuctionIntervalUnit.Time,
                decreaseInterval: decreaseInterval, // 15 minutes
                decreaseSize: decreaseSize,
                numDecreases: numDecreases
            }),
            .5 ether
        )
    {
        whitelistMaxMint = _whitelistMaxMint;
        publicListMaxMint = _publicListMaxMint;
        reservedMax = _reservedMax;
        max = _nonReservedMax + reservedMax;
        nonReservedMinted = 0;
        reservedMinted = 0;
        discountedPrice = _discountedPrice;
        publicTotalMaxMint = _publicTotalMaxMint;
        _splitter = new PaymentSplitter(payees, shares);
    }

    function release(address payable account) external {
        _splitter.release(account);
    }

    function _hash(string memory _prefix, address _address) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_prefix, _address));
    }

    function _whitelistHash(address _address, uint256 _price, uint256 _quantity) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address, _price, _quantity));
    }

    function _verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return (_recover(hash, signature) == owner());
    }

    function _recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.recover(signature);
    }

    function setPrefix(string memory _prefix) public onlyOwner {
        prefix = _prefix;
    }

    function setLicenseTerms(string memory _licenseTerms) public onlyOwner {
        licenseTerms = _licenseTerms;
    }

    function setMax(uint256 _max) external onlyOwner {
        max = _max;
    }

    function setPrefixDiscounted(string memory _prefix) public onlyOwner {
        prefixDiscounted = _prefix;
    }

    function setWhitelistMaxMint(uint256 _whitelistMaxMint) external onlyOwner {
        whitelistMaxMint = _whitelistMaxMint;
    }

    function setPublicListMaxMint(uint256 _publicListMaxMint) external onlyOwner {
        publicListMaxMint = _publicListMaxMint;
    }

    function mintPublic(uint256 numberOfTokens) external payable {
        require(_publicListClaimed[msg.sender] + _whitelistClaimed[msg.sender] + numberOfTokens <= publicListMaxMint, 'You cannot mint this many.');
        
        publicTotalMinted += numberOfTokens;
        require(publicTotalMinted <= publicTotalMaxMint, "exceed amount");

        _publicListClaimed[msg.sender] += numberOfTokens;
        _nonReservedMintHelper(numberOfTokens, true);
    }
    
    function mintWhitelist(bytes32 hash, bytes memory signature, uint256 numberOfTokens) external payable {
        require(_verify(hash, signature), "This hash's signature is invalid.");
        require(_hash(prefix, msg.sender) == hash, "The address hash does not match the signed hash.");
        require(_whitelistClaimed[msg.sender] + numberOfTokens <= whitelistMaxMint, 'You cannot mint this many.');

        _whitelistClaimed[msg.sender] += numberOfTokens;
        _nonReservedMintHelper(numberOfTokens, false);
    }

    function mintWhitelistPrice(bytes32 hash, bytes memory signature, uint256 price, uint256 numberOfTokens) external payable {
        require(_verify(hash, signature), "This hash's signature is invalid.");
        require(_whitelistHash(msg.sender, price, numberOfTokens) == hash, "The address hash does not match the signed hash.");
        require(_whitelistClaimed[msg.sender] + numberOfTokens <= whitelistMaxMint, 'You cannot mint this many.');

        _whitelistClaimed[msg.sender] += numberOfTokens;
        _mintWhitelistPrice(price, numberOfTokens);
    }

    function _mintWhitelistPrice(uint256 _price, uint256 _quantity) internal nonReentrant {
        require(totalSupply() + _quantity <= max, "Sold out.");
        uint256 amount = _price * _quantity;
        require(amount <= msg.value, "Invalid amount.");

        _safeMint(msg.sender, _quantity);

        totalMintsForRefund += _quantity;
        whitelistPurchasePrices[msg.sender] += amount;

        if (msg.value > amount) {
            address payable reimburse = payable(_msgSender());
            uint256 refundAmount = msg.value - amount;

            (bool success, bytes memory returnData) = reimburse.call{
                value: refundAmount
            }("");
            require(success, string(returnData));
        }
    }

    function _hashMintWhitelistAmountAndPrice(string memory _prefix, address _address, uint256 _amount, uint256 _price) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_prefix, _address, _amount, _price));
    }

    function mintWhitelistAmountAndPrice(bytes32 hash, bytes calldata signature, uint256 numberOfTokens, uint256 customLimit, uint256 price) external payable {
        require(_verify(hash, signature), "This hash's signature is invalid.");
        require(_hashMintWhitelistAmountAndPrice(prefixDiscounted, msg.sender, customLimit, price) == hash, "Hash invalid.");
        require(_whitelistClaimed[msg.sender] + numberOfTokens <= customLimit, 'You cannot mint this many.');
        require(_whitelistClaimed[msg.sender] + numberOfTokens <= whitelistMaxMint, 'You cannot mint this many.');

        _whitelistClaimed[msg.sender] += numberOfTokens;
        _mintWhitelistPrice(price, numberOfTokens);
    }

    function _nonReservedMintHelper(uint256 numberOfTokens, bool isPublic) internal nonReentrant {
        require(totalSupply() + numberOfTokens <= max, "Sold out.");
        uint256 price = cost(numberOfTokens);
        require(price <= msg.value, "Invalid amount.");

        _safeMint(msg.sender, numberOfTokens);

        totalMintsForRefund += numberOfTokens;
        if (isPublic) {
            publicPurchasePrices[msg.sender] += price;
        } else {
            whitelistPurchasePrices[msg.sender] += price;
        }

        if (msg.value > price) {
            address payable reimburse = payable(_msgSender());
            uint256 refundAmount = msg.value - price;

            // Using Address.sendValue() here would mask the revertMsg upon
            // reentrancy, but we want to expose it to allow for more precise
            // testing. This otherwise uses the exact same pattern as
            // Address.sendValue().
            (bool success, bytes memory returnData) = reimburse.call{
                value: refundAmount
            }("");
            // Although `returnData` will have a spurious prefix, all we really
            // care about is that it contains the ReentrancyGuard reversion
            // message so we can check in the tests.
            require(success, string(returnData));
        }
    }

    function splitPayments(uint256 _amount) public payable onlyOwner {
        (bool success, ) = payable(_splitter).call{value: _amount}(
        ""
        );
        require(success, "transfer failed");
    }

    function airdropMint(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        uint256 len = recipients.length;
        for(uint256 i = 0; i < len; i ++) {
            require(
                totalSupply() + amounts[i] <= reservedMax,
                "Sold out."
            );

            if (amounts[i] < maxBatchSize) {
                _safeMint(recipients[i], amounts[i]);
            } else {
                require(
                    amounts[i] % maxBatchSize == 0,
                    "Can only mint a multiple of the maxBatchSize."
                );
                uint256 numChunks = amounts[i] / maxBatchSize;
                for (uint256 i = 0; i < numChunks; i++) {
                    _safeMint(recipients[i], maxBatchSize);
                }
            }
        }
    }

    function mintReserved(uint256 quantity, address recipient) external onlyOwner {
        require(
            totalSupply() + quantity <= reservedMax,
            "Sold out."
        );

        if (quantity < maxBatchSize) {
            _safeMint(recipient, quantity);
        } else {
            require(
                quantity % maxBatchSize == 0,
                "Can only mint a multiple of the maxBatchSize."
            );
            uint256 numChunks = quantity / maxBatchSize;
            for (uint256 i = 0; i < numChunks; i++) {
                _safeMint(recipient, maxBatchSize);
            }
        }
    }

    function mintWhitelistDiscounted(bytes32 hash, bytes memory signature, uint256 numberOfTokens) external payable {
        require(_verify(hash, signature), "This hash's signature is invalid.");
        require(_hash(prefixDiscounted, msg.sender) == hash, "The address hash does not match the signed hash.");
        require(_whitelistClaimed[msg.sender] + numberOfTokens <= whitelistMaxMint, 'You cannot mint this many.');
        require(discountedPrice * numberOfTokens == msg.value, "Invalid amount.");

        _whitelistClaimed[msg.sender] += numberOfTokens;
        _discountClaimed[msg.sender] += numberOfTokens;
        
        totalMintsForRefund += numberOfTokens;
        discountedPurchasePrices[msg.sender] += msg.value;
        
        _safeMint(msg.sender, numberOfTokens);
    }

    function setBaseURI(string memory baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function setRefundPrice(uint256 _price) external onlyOwner {
        refundPrice = _price;
    }

    function setAllowPublicRefunds(bool _allow) external onlyOwner {
        allowPublicRefunds = _allow;
    }

    function setAllowWhitelistRefunds(bool _allow) external onlyOwner {
        allowWhitelistRefunds = _allow;
    }
   
    function setAllowDiscountRefunds(bool _allow) external onlyOwner {
        allowDiscountRefunds = _allow;
    }

    function allowRefund(bool _allow) external onlyOwner {
        isAllowedRefund = _allow;
    }

    function getRefundTotal() external view returns(uint256) {
        require(isAllowedRefund, "refund not allowed");
        return totalMintsForRefund * refundPrice;
    }

    function getPublicRefundAmount() public view returns(uint256) {
        if (allowPublicRefunds && (publicPurchasePrices[msg.sender] > _publicListClaimed[msg.sender] * refundPrice)) {
            return publicPurchasePrices[msg.sender] - _publicListClaimed[msg.sender] * refundPrice;
            
        }
        return 0;
    }

    function getWhitelistRefundAmount() public view returns(uint256) {
        if (allowWhitelistRefunds && (whitelistPurchasePrices[msg.sender] > (_whitelistClaimed[msg.sender] - _discountClaimed[msg.sender]) * refundPrice)) {
            return whitelistPurchasePrices[msg.sender] - (_whitelistClaimed[msg.sender] - _discountClaimed[msg.sender]) * refundPrice;
        }
        return 0;
    }
    
    function getDiscountRefundAmount() public view returns(uint256) {
        if (allowDiscountRefunds && (discountedPurchasePrices[msg.sender] > _discountClaimed[msg.sender] * refundPrice)) {
            return discountedPurchasePrices[msg.sender] - _discountClaimed[msg.sender] * refundPrice;
        }
        return 0;
    }

    function refund() external nonReentrant {
        require(isAllowedRefund == true, "refund not allowed");
        uint256 amount;
        
        uint256 refundAmount = getPublicRefundAmount();
        if (refundAmount != 0) {
            amount = refundAmount;
            publicPurchasePrices[msg.sender] = 0;
            totalMintsForRefund = totalMintsForRefund - _publicListClaimed[msg.sender];
        }

        refundAmount = getWhitelistRefundAmount();
        if (refundAmount != 0) {
            amount += refundAmount;
            whitelistPurchasePrices[msg.sender] = 0;
            totalMintsForRefund = totalMintsForRefund - (_whitelistClaimed[msg.sender] - _discountClaimed[msg.sender]);
        }

        refundAmount = getDiscountRefundAmount();
        if (refundAmount != 0) {
            amount += refundAmount;
            discountedPurchasePrices[msg.sender] = 0;
            totalMintsForRefund = totalMintsForRefund - _discountClaimed[msg.sender];
        }
        
        require(amount != 0, "no refunds");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success == true, "failed to refund");
    }

    function getStartPrice() external view onlyOwner returns(uint64) {
        return startPrice;
    }

    function getDecreaseInterval() external view onlyOwner returns(uint64) {
        return decreaseInterval;
    }

    function getNumDescreases() external view onlyOwner returns(uint64) {
        return numDecreases;
    }

    function getDecreaseSize() external view onlyOwner returns(uint64) {
        return decreaseSize;
    }

    function getPublicMinted() external view returns(uint256) {
        return _publicListClaimed[msg.sender];
    }
    
    function getWhitelistMinted() external view returns(uint256) {
        return _whitelistClaimed[msg.sender];
    }
    
    function setPublicTotalMaxMint(uint256 _amount) external onlyOwner {
        publicTotalMaxMint = _amount;
    }

    function setDiscountedPrice(uint256 _discountedPrice) external onlyOwner {
        discountedPrice = _discountedPrice;
    }
}