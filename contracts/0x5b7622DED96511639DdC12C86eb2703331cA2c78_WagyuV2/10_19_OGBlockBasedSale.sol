// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract OGBlockBasedSale is Ownable {
    using SafeMath for uint256;

    event AssignGovernorAddress(address indexed _address);
    event AssignOperatorAddress(address indexed _address);
    event AssignDiscountBlockSize(uint256 size);
    event AssignPriceDecayParameter(
        uint256 _lowerBoundPrice,
        uint256 _priceFactor
    );
    event AssignPrivateSapeCap(uint256 cap);
    event AssignPrivateSalePrice(uint256 price);
    event AssignPublicSaleConfig(uint256 beginBlock, uint256 endBlock);
    event AssignPublicSalePrice(uint256 price);
    event AssignReserveLimit(uint256 limit);
    event AssignSubsequentSaleNextBlock(uint256 _block);
    event AssignSubsequentSaleNextBlockByOperator(uint256 _block);
    event AssignTransactionLimit(uint256 publicSaleLimit);
    event ResetOverridedSaleState();
    event DisableDutchAuction();
    event EnableDucthAuction();
    event EnablePublicSale();
    event ForceCloseSale();
    event ForcePauseSale();

    enum SaleState {
        NotStarted,
        PrivateSaleBeforeWithoutBlock,
        PrivateSaleBeforeWithBlock,
        PrivateSaleDuring,
        PrivateSaleEnd,
        PrivateSaleEndSoldOut,
        PublicSaleBeforeWithoutBlock,
        PublicSaleBeforeWithBlock,
        PublicSaleDuring,
        PublicSaleEnd,
        PublicSaleEndSoldOut,
        PauseSale,
        AllSalesEnd
    }

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

    uint256 public maxPublicSalePerTx = 1;

    uint256 public totalPublicMinted = 0;
    uint256 public totalReserveMinted = 0;
    uint256 public maxSupply = 1000;
    uint256 public maxReserve = 180; //Subject to change per production config

    uint256 public discountBlockSize = 180;
    uint256 public lowerBoundPrice = 0;
    uint256 public publicSalePrice;
    uint256 public priceFactor = 1337500000000000;

    uint256 public nextSubsequentSale = 0;
    uint256 public subsequentSaleBlockSize = 1661; //Subject to change per production config
    uint256 public publicSaleCap = 100;
    bool public dutchEnabled = false;

    struct SaleConfig {
        uint256 beginBlock;
        uint256 endBlock;
    }

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
        require(_priceFactor <= publicSalePrice);
        lowerBoundPrice = _lowerBoundPrice;
        priceFactor = _priceFactor;
        emit AssignPriceDecayParameter(_lowerBoundPrice, _priceFactor);
    }



    function setTransactionLimit(uint256 publicSaleLimit)
        external
        operatorOnly
    {
        require(publicSaleLimit > 0);
        maxPublicSalePerTx = publicSaleLimit;
        emit AssignTransactionLimit(publicSaleLimit);
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

    function isPublicSaleSoldOut() external view returns (bool) {
        return supplyWithoutReserve() == totalPublicMinted;
    }

    function enablePublicSale() external operatorOnly {
        salePhase = SalePhase.Public;
        emit EnablePublicSale();
    }

    function setSubsequentSaleBlock(uint256 b) external operatorOnly {
        require(b > 0, "Block number must be greater than 0");
        require(
            b > publicSale.beginBlock,
            "Cannot start before public sale start"
        );
        nextSubsequentSale = b;
        emit AssignSubsequentSaleNextBlockByOperator(b);
    }

    function supplyWithoutReserve() internal view returns (uint256) {
        return (maxReserve > maxSupply) ? 0 : maxSupply.sub(maxReserve);
    }

    function getState() public view virtual returns (SaleState) {
        uint256 mintedWithoutReserve = totalPublicMinted;

        if (
            salePhase != SalePhase.None &&
            overridedSaleState == OverrideSaleState.Close
        ) {
            return SaleState.AllSalesEnd;
        }

        if (
            salePhase != SalePhase.None &&
            overridedSaleState == OverrideSaleState.Pause
        ) {
            return SaleState.PauseSale;
        }

        if (
            salePhase == SalePhase.Public &&
            mintedWithoutReserve == supplyWithoutReserve()
        ) {
            return SaleState.PublicSaleEndSoldOut;
        }

        if (salePhase == SalePhase.None) {
            return SaleState.NotStarted;
        }

        if (
            salePhase == SalePhase.Public &&
            publicSale.endBlock > 0 &&
            block.number > publicSale.endBlock
        ) {
            return SaleState.PublicSaleEnd;
        }

        if (
            salePhase == SalePhase.Public &&
            publicSale.beginBlock > 0 &&
            block.number >= publicSale.beginBlock
        ) {
            if (!isSubsequenceSale()) {
                return SaleState.PublicSaleDuring;
            } else {
                return
                    block.number >= nextSubsequentSale
                        ? SaleState.PublicSaleDuring
                        : SaleState.PublicSaleBeforeWithBlock;
            }
        }

        if (
            (salePhase == SalePhase.Public &&
                publicSale.beginBlock > 0 &&
                block.number < publicSale.beginBlock) ||
            (salePhase == SalePhase.Public &&
                publicSale.beginBlock > 0 &&
                block.number > publicSale.beginBlock &&
                isSubsequenceSale() &&
                block.number < nextSubsequentSale)
        ) {
            return SaleState.PublicSaleBeforeWithBlock;
        }

        if (salePhase == SalePhase.Public && publicSale.beginBlock == 0) {
            return SaleState.PublicSaleBeforeWithoutBlock;
        }

        return SaleState.NotStarted;
    }

    function setPublicSaleCap(uint256 cap) external operatorOnly {
        publicSaleCap = cap;
        emit AssignPrivateSapeCap(cap);
    }

    function isSubsequenceSale() public view returns (bool) {
        return (totalPublicMinted >= publicSaleCap);
    }

    function getStartSaleBlock() external view returns (uint256) {
        if (
            SaleState.PublicSaleBeforeWithBlock == getState() ||
            SaleState.PublicSaleDuring == getState()
        ) {
            return
                isSubsequenceSale()
                    ? nextSubsequentSale
                    : publicSale.beginBlock;
        }

        return 0;
    }

    function getEndSaleBlock() external view returns (uint256) {
        if (
            SaleState.PublicSaleBeforeWithBlock == getState() ||
            SaleState.PublicSaleDuring == getState()
        ) {
            return publicSale.endBlock;
        }

        return 0;
    }

    function getMaxSupplyByMode() public view returns (uint256) {
        if (getState() == SaleState.PublicSaleDuring) {
            if (isSubsequenceSale()) {
                return 1;
            }
            return publicSaleCap;
        }

        return 0;
    }

    function getMintedByMode() external view returns (uint256) {
        if (getState() == SaleState.PublicSaleDuring) {
            if (isSubsequenceSale()) {
                return 0;
            }
            return totalPublicMinted;
        }
        return 0;
    }

    function getTransactionCappedByMode() external pure returns (uint256) {
        return 1;
    }

    function enableDutchAuction() external operatorOnly {
        dutchEnabled = true;
        emit EnableDucthAuction();
    }

    function disableDutchAuction() external operatorOnly {
        dutchEnabled = false;
        emit DisableDutchAuction();
    }

    function getPriceByMode() public view returns (uint256) {
        if (getState() == SaleState.PublicSaleDuring) {
            if (!dutchEnabled) {
                return publicSalePrice;
            }

            uint256 passedBlock = block.number - publicSale.beginBlock;
            uint256 discountPrice = passedBlock.mul(priceFactor).div(
                discountBlockSize
            );

            if (discountPrice >= publicSalePrice.sub(lowerBoundPrice)) {
                return lowerBoundPrice;
            } else {
                return publicSalePrice.sub(discountPrice);
            }
        }

        return publicSalePrice;
    }

    function availableReserve() public view returns (uint256) {
        return maxReserve - totalReserveMinted;
    }
}