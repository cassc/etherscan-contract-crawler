// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IERC721MultiSale.sol";
import "./Sale.sol";
import "./SalesRecord.sol";

abstract contract ERC721MultiSale is IERC721MultiSale, Pausable {
    using Address for address payable;

    // ==================================================================
    // Event
    // ==================================================================
    event ChangeSale(uint8 oldId, uint8 newId);

    // ==================================================================
    // Variables
    // ==================================================================
    uint256 private _soldCount = 0;
    
    Sale internal _currentSale;
    mapping(address => SalesRecord) internal _salesRecordByBuyer;

    address payable public withdrawAddress;
    uint256 public maxSupply;

    // ==================================================================
    // Modifier
    // ==================================================================
    modifier isNotOverMaxSupply(uint256 amount) {
        require(
            amount + _totalSupply() <= maxSupply,
            "claim is over the max supply."
        );
        _;
    }

    modifier isNotOverMaxSaleSupply(uint256 amount) {
        require(
            amount + _soldCount <=
                _currentSale.maxSupply,
            "claim is over the max sale supply."
        );
        _;
    }

    modifier isNotOverAllowedAmount(uint256 amount, uint256 allowedAmount) {
        require(
            getBuyCount() + amount <= allowedAmount,
            "claim is over allowed amount."
        );
        _;
    }

    modifier enoughEth(uint256 amount) {
        require(msg.value >= _currentSale.mintCost * amount, "not enough eth.");
        _;
    }

    modifier whenClaimSale() {
        require(_currentSale.saleType == SaleType.CLAIM, "not claim sale now.");
        _;
    }

    modifier whenExcahngeSale() {
        require(_currentSale.saleType == SaleType.EXCHANGE, "not exchange sale now.");
        _;
    }

    // ==================================================================
    // Function
    // ==================================================================
    // ------------------------------------------------------------------
    // external & public
    // ------------------------------------------------------------------
    function getCurrentSale()
        external
        view
        returns (
            uint8,
            SaleType,
            uint256,
            uint256
        )
    {
        return (
            _currentSale.id,
            _currentSale.saleType,
            _currentSale.mintCost,
            _currentSale.maxSupply
        );
    }

    function withdraw() external {
        require(withdrawAddress != address(0), "withdraw address is 0 address.");
        withdrawAddress.sendValue(address(this).balance);
    }

    function getBuyCount() public view returns(uint256){
        SalesRecord storage record = _salesRecordByBuyer[msg.sender];

        if (record.id == _currentSale.id) {
            return record.amount;
        } else {
            return 0;
        }
    }

    // ------------------------------------------------------------------
    // internal & private
    // ------------------------------------------------------------------
    function _claim(uint256 amount, uint256 allowedAmount)
        internal
        virtual
        whenNotPaused
        isNotOverMaxSupply(amount)
        isNotOverMaxSaleSupply(amount)
        isNotOverAllowedAmount(amount, allowedAmount)
        whenClaimSale
    {
        _record(amount);
    }

    function _exchange(uint256[] calldata burnTokenIds, uint256 allowedAmount)
        internal
        virtual
        whenNotPaused
        isNotOverMaxSaleSupply(burnTokenIds.length)
        isNotOverAllowedAmount(burnTokenIds.length, allowedAmount)
        whenExcahngeSale
    {
        _record(burnTokenIds.length);
    }

    function _record(uint256 amount) private {
        SalesRecord storage record = _salesRecordByBuyer[msg.sender];

        if (record.id == _currentSale.id) {
            record.amount += amount;
        } else {
            record.id = _currentSale.id;
            record.amount = amount;
        }

        _soldCount += amount;
    }

    function _setCurrentSale(Sale calldata sale) internal virtual {
        uint8 oldId = _currentSale.id;
        _currentSale = sale;
        _soldCount = 0;

        emit ChangeSale(oldId, sale.id);
    }

    function _totalSupply() internal virtual view returns(uint256);
}