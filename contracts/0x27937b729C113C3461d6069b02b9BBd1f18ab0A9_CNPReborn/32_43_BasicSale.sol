// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./Sale.sol";
import "./IBasicSale.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract BasicSale is IBasicSale, Pausable {
    using Address for address payable;
    // ==================================================================
    // Event
    // ==================================================================
    event ChangeSale(uint8 oldId, uint8 newId);

    // ==================================================================
    // Variables
    // ==================================================================
    address payable public withdrawAddress;
    uint256 public maxSupply;
    Sale internal _currentSale;
    uint256 internal _soldCount = 0;

    // ==================================================================
    // Modifier
    // ==================================================================
    modifier isNotOverMaxSaleSupply(uint256 amount) {
        require(
            amount + _soldCount <= _currentSale.maxSupply,
            "claim is over the max sale supply."
        );
        _;
    }
    
    modifier isNotOverMaxSupply(uint256 amount) {
        require(
            amount + _totalSupply() <= maxSupply,
            "claim is over the max supply."
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
        require(
            _currentSale.saleType == SaleType.EXCHANGE,
            "not exchange sale now."
        );
        _;
    }

    // ==================================================================
    // Functions
    // ==================================================================
    function getCurrentSale()
        external
        view
        virtual
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

    function _withdraw() internal virtual {
        require(
            withdrawAddress != address(0),
            "withdraw address is 0 address."
        );
        withdrawAddress.sendValue(address(this).balance);
    }

    function _setCurrentSale(Sale calldata sale) internal virtual {
        uint8 oldId = _currentSale.id;
        _currentSale = sale;
        _soldCount = 0;

        emit ChangeSale(oldId, sale.id);
    }

    function _totalSupply() internal view virtual returns (uint256);
}