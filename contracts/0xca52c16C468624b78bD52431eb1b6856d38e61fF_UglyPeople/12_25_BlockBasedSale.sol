// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BlockBasedSale is Ownable {
    using SafeMath for uint256;

    event AssignGovernorAddress(address indexed _address);
    event AssignOperatorAddress(address indexed _address);
    event AssignDiscountBlockSize(uint256 size);
    event AssignPriceDecayParameter(
        uint256 _lowerBoundPrice,
        uint256 _priceFactor
    );
    event AssignTransactionLimit(
        uint256 privateSaleLimit,
        uint256 publicSaleLimit,
        uint256 maxWhitelist
    );
    event AssignPrivateSaleConfig(uint256 beginBlock, uint256 endBlock);
    event AssignPublicSaleConfig(uint256 beginBlock, uint256 endBlock);
    event AssignPrivateSalePrice(uint256 price);
    event AssignPublicSalePrice(uint256 price);
    event AssignReserveLimit(uint256 limit);
    event AssignPrivateSapeCap(uint256 cap);
    event EnablePublicSale();
    event EnablePrivateSale();
    event ForceCloseSale();
    event ForcePauseSale();
    event ResetOverridedSaleState();

    enum OverrideSaleState {
        None,
        Pause,
        Close
    }

    enum SalePhase {
        None,
        Private,
        Public
    }

    OverrideSaleState public overridedSaleState = OverrideSaleState.None;
    SalePhase public salePhase = SalePhase.None;
    bool private operatorAssigned;
    bool private governorAssigned;

    address private operatorAddress;
    address private governorAddress;

    uint256 public maxPrivateSalePerTx = 10;
    uint256 public maxPublicSalePerTx = 20;
    uint256 public maxWhitelistClaimPerWallet = 10;

    uint256 public privateSaleCapped = 690;
    uint256 public totalPrivateSaleMinted = 0;
    uint256 public privateSalePrice;

    uint256 public totalPublicMinted = 0;
    uint256 public totalReserveMinted = 0;
    uint256 public maxSupply = 6969;
    uint256 public maxReserve = 169;

    uint256 public discountBlockSize = 180;
    uint256 public lowerBoundPrice = 0;
    uint256 public publicSalePrice;
    uint256 public priceFactor = 1337500000000000;

    struct SaleConfig {
        uint256 beginBlock;
        uint256 endBlock;
    }

    SaleConfig public privateSale;
    SaleConfig public publicSale;

    modifier operatorOnly() {
        require(
            operatorAssigned && msg.sender == operatorAddress,
            "Only operator allowed."
        );
        _;
    }

    modifier governorOnly() {
        require(
            governorAssigned && msg.sender == governorAddress,
            "Only governor allowed."
        );
        _;
    }

    function setOperatorAddress(address _operator) external onlyOwner {
        require(_operator != address(0));
        operatorAddress = _operator;
        operatorAssigned = true;
        emit AssignOperatorAddress(_operator);
    }

    function setGovernorAddress(address _governor) external onlyOwner {
        require(_governor != address(0));
        governorAddress = _governor;
        governorAssigned = true;
        emit AssignGovernorAddress(_governor);
    }

    function setDiscountBlockSize(uint256 size) external operatorOnly {
        discountBlockSize = size;
        emit AssignDiscountBlockSize(size);
    }

    function setPriceDecayParams(uint256 _lowerBoundPrice, uint256 _priceFactor)
        external
        operatorOnly
    {
        require(_lowerBoundPrice >= 0);
        require(_priceFactor <= publicSalePrice);
        lowerBoundPrice = _lowerBoundPrice;
        priceFactor = _priceFactor;
        emit AssignPriceDecayParameter(_lowerBoundPrice, _priceFactor);
    }

    function setTransactionLimit(
        uint256 privateSaleLimit,
        uint256 publicSaleLimit,
        uint256 maxWhitelist
    ) external operatorOnly {
        require(privateSaleLimit > 0);
        require(publicSaleLimit > 0);
        require(maxWhitelist <= privateSaleLimit);
        maxPrivateSalePerTx = privateSaleLimit;
        maxPublicSalePerTx = publicSaleLimit;
        maxWhitelistClaimPerWallet = maxWhitelist;
        emit AssignTransactionLimit(
            privateSaleLimit,
            publicSaleLimit,
            maxWhitelist
        );
    }

    function setPrivateSaleConfig(SaleConfig memory _privateSale)
        external
        operatorOnly
    {
        privateSale = _privateSale;
        emit AssignPrivateSaleConfig(
            _privateSale.beginBlock,
            _privateSale.endBlock
        );
    }

    function setPublicSaleConfig(SaleConfig memory _publicSale)
        external
        operatorOnly
    {
        publicSale = _publicSale;
        emit AssignPublicSaleConfig(
            _publicSale.beginBlock,
            _publicSale.endBlock
        );
    }

    function setPublicSalePrice(uint256 _price) external operatorOnly {
        publicSalePrice = _price;
        emit AssignPublicSalePrice(_price);
    }

    function setPrivateSalePrice(uint256 _price) external operatorOnly {
        privateSalePrice = _price;
        emit AssignPrivateSalePrice(_price);
    }

    function setCloseSale() external operatorOnly {
        overridedSaleState = OverrideSaleState.Close;
        emit ForceCloseSale();
    }

    function setPauseSale() external operatorOnly {
        overridedSaleState = OverrideSaleState.Pause;
        emit ForcePauseSale();
    }

    function resetOverridedSaleState() external operatorOnly {
        overridedSaleState = OverrideSaleState.None;
        emit ResetOverridedSaleState();
    }

    function setReserve(uint256 reserve) external operatorOnly {
        maxReserve = reserve;
        emit AssignReserveLimit(reserve);
    }

    function setPrivateSaleCap(uint256 cap) external operatorOnly {
        privateSaleCapped = cap;
        emit AssignPrivateSapeCap(cap);
    }

    function enablePublicSale() external operatorOnly {
        salePhase = SalePhase.Public;
        emit EnablePublicSale();
    }

    function enablePrivateSale() external operatorOnly {
        salePhase = SalePhase.Private;
        emit EnablePrivateSale();
    }

    function isPrivateSaleSoldOut() external view returns (bool) {
        return totalPrivateSaleMinted == privateSaleCapped;
    }

    function isPublicSaleSoldOut() external view returns (bool) {
        uint256 supplyWithoutReserve = maxSupply - maxReserve;
        uint256 mintedWithoutReserve = totalPublicMinted +
            totalPrivateSaleMinted;
        return supplyWithoutReserve == mintedWithoutReserve;
    }
}