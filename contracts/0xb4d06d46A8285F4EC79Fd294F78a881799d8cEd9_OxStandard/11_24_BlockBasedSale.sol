// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BlockBasedSale is Ownable {
    using SafeMath for uint256;

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

    function setDiscountBlockSize(uint256 blockNumber) external onlyOwner {
        discountBlockSize = blockNumber;
    }

    function setPriceDecayParams(uint256 _lowerBoundPrice, uint256 _priceFactor) external onlyOwner{
        require(_lowerBoundPrice >= 0);
        require(_priceFactor <= publicSalePrice);
        lowerBoundPrice = _lowerBoundPrice;
        priceFactor = _priceFactor;
    }

    function setTransactionLimit(uint256 privateSaleLimit,uint256 publicSaleLimit, uint256 maxWhitelist) external onlyOwner {
        require(privateSaleLimit > 0);
        require(publicSaleLimit > 0);
        require(maxWhitelist <= privateSaleLimit);
        maxPrivateSalePerTx = privateSaleLimit;
        maxPublicSalePerTx = publicSaleLimit;
        maxWhitelistClaimPerWallet = maxWhitelist;
    }

    function setPrivateSaleConfig(SaleConfig memory _privateSale)
        external
        onlyOwner
    {
        privateSale = _privateSale;
    }

    function setPublicSaleConfig(SaleConfig memory _publicSale) external onlyOwner {
        publicSale = _publicSale;
    }

    function setPublicSalePrice(uint256 _price) external onlyOwner {
        publicSalePrice = _price;
    }

    function setPrivateSalePrice(uint256 _price) external onlyOwner {
        privateSalePrice = _price;
    }

    function setCloseSale() external onlyOwner {
        overridedSaleState = OverrideSaleState.Close;
    }

    function setPauseSale() external onlyOwner {
        overridedSaleState = OverrideSaleState.Pause;
    }

    function resetOverridedSaleState() external onlyOwner {
        overridedSaleState = OverrideSaleState.None;
    }

    function setReserve(uint256 reserve) external onlyOwner {
        maxReserve = reserve;
    }

    function setPrivateSaleCap(uint256 cap) external onlyOwner {
        privateSaleCapped = cap;
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

    function enablePublicSale() external onlyOwner {
        salePhase = SalePhase.Public;
    }

    function enablePrivateSale() external onlyOwner {
        salePhase = SalePhase.Private;
    }
}