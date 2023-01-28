// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../owner/Operator.sol";
import "../lib/SafeMath8.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Router02.sol";

contract Crystals is ERC20Burnable, Operator {
    using SafeMath8 for uint8;
    using SafeMath for uint256;

    // CRS-BUSD pair address
    address public busdPair;

    // Distribution for the Treasury wallet
    uint256 public constant INITIAL_TREASURY_DISTRIBUTION = 5000 ether;
    // Distribution for the 7 days Genesis pools
    uint256 public constant INITIAL_GENESIS_POOL_DISTRIBUTION = 6000 ether;

    // Have the rewards been distributed
    bool public rewardDistributed = false;

    /* ================= Taxation =============== */
    // Address of the Oracle
    address public oracle;
    // Address of the Tax Office
    address public taxOffice;

    // Flat trading fee
    uint256 public flatBuyFee;
    uint256 public flatSellFee;
    // Current tax rate
    uint256 public taxRate;
    // Address of the tax collector wallet
    address public taxCollectorAddress;

    // Should the taxes be calculated using the tax tiers
    bool public autoCalculateTax;

    // Tax Tiers
    uint256[] public taxTiersTwaps = [
        0, 1e17, 2e17, 3e17, 4e17, 5e17, 6e17, 7e17, 8e17, 9e17, 9.8e17
    ];
    uint256[] public taxTiersRates = [
        8000, 5000, 4500, 4000, 3500, 3000, 2500, 2000, 1500, 500, 0
    ];

    // Addresses include or excluded from Tax
    mapping (address => bool) public isExcludedFromFee;
    // Pair addresses 
    mapping (address => bool) public pairs;

    event TaxOfficeTransferred(address oldAddress, address newAddress);
    event SetPair(address indexed pair, bool indexed value);

    modifier onlyTaxOffice() {
        require(taxOffice == msg.sender, "Caller should be the tax office");
        _;
    }

    modifier onlyOperatorOrTaxOffice() {
        require(
            isOperator() || taxOffice == msg.sender,
            "Caller should be the operator or the tax office"
        );
        _;
    }

    /**
     * @notice Constructs the $CRS token contract.
     */
    constructor(
        uint256 _taxRate, 
        address _taxCollectorAddress
    ) ERC20("CRYSTALS", "CRS") {
        // Mints 1 CRS to contract creator for initial pool setup
        require(_taxRate < 10000, "Tax rate should be less than 10000");
        require(
            _taxCollectorAddress != address(0),
            "Tax collector address should be non-zero address"
        );

        setExcludeFromFee(msg.sender, true);
        _mint(msg.sender, 1 ether);

        flatBuyFee = 15;
        flatSellFee = 45;
        taxRate = _taxRate;
        taxCollectorAddress = _taxCollectorAddress;

        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        busdPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56));
        setPair(busdPair, true);
    }

    /* ============= Taxation ============= */

    function getTaxTiersTwapsCount() public view returns (uint256 count) {
        return taxTiersTwaps.length;
    }

    function getTaxTiersRatesCount() public view returns (uint256 count) {
        return taxTiersRates.length;
    }

    function setTaxTiersTwap(uint8 _index, uint256 _value)
        public
        onlyTaxOffice
        returns (bool)
    {
        require(_index >= 0, "Index should be higher than 0");
        require(
            _index < getTaxTiersTwapsCount(),
            "Index should be lower than count of tax tiers"
        );
        if (_index > 0) {
            require(_value > taxTiersTwaps[_index - 1]);
        }
        if (_index < getTaxTiersTwapsCount().sub(1)) {
            require(_value < taxTiersTwaps[_index + 1]);
        }
        taxTiersTwaps[_index] = _value;
        return true;
    }

    function setTaxTiersRate(uint8 _index, uint256 _value)
        public
        onlyTaxOffice
        returns (bool)
    {
        require(_index >= 0, "Index should be higher than 0");
        require(
            _index < getTaxTiersRatesCount(),
            "Index should be lower than count of tax tiers"
        );
        taxTiersRates[_index] = _value;
        return true;
    }

    function _getCRSPrice() internal view returns (uint256 _crystalPrice) {
        try IOracle(oracle).consult(address(this), 1e18) returns (
            uint144 _price
        ) {
            return uint256(_price);
        } catch {
            revert("Failed to fetch $CRS price from Oracle");
        }
    }

    function _updateTaxRate(uint256 _crystalPrice) internal {
        if (autoCalculateTax) {
            for (
                uint8 tierId = uint8(getTaxTiersTwapsCount()).sub(1);
                tierId >= 0;
                --tierId
            ) {
                if (_crystalPrice >= taxTiersTwaps[tierId]) {
                    require(
                        taxTiersRates[tierId] < 10000,
                        "tax equal or bigger to 100%"
                    );
                    taxRate = taxTiersRates[tierId];
                    break;
                }
            }
        }
    }

    function enableAutoCalculateTax() public onlyTaxOffice {
        autoCalculateTax = true;
    }

    function disableAutoCalculateTax() public onlyTaxOffice {
        autoCalculateTax = false;
    }

    function setOracle(address _oracle) public onlyOperatorOrTaxOffice {
        require(
            _oracle != address(0),
            "Oracle address should be non-zero address"
        );
        oracle = _oracle;
    }

    function setTaxOffice(address _taxOffice) public onlyOperatorOrTaxOffice {
        require(
            _taxOffice != address(0),
            "Tax office address should be non-zero address"
        );
        emit TaxOfficeTransferred(taxOffice, _taxOffice);
        taxOffice = _taxOffice;
    }

    function setTaxCollectorAddress(address _taxCollectorAddress)
        public
        onlyTaxOffice
    {
        require(
            _taxCollectorAddress != address(0),
            "Tax collector address should be non-zero address"
        );
        taxCollectorAddress = _taxCollectorAddress;
    }

    function setBuyFee(uint16 _buyFee) public onlyTaxOffice {
        require( _buyFee <= 10000, "Buy Fee can't exceed 100%" );
        flatBuyFee = _buyFee;
    }

    function setSellFee(uint16 _sellFee) public onlyTaxOffice {
        require( _sellFee <= 10000, "Sell Fee can't exceed 100%");
        flatSellFee = _sellFee;
    }

    function setTaxRate(uint256 _taxRate) public onlyTaxOffice {
        require(!autoCalculateTax, "Auto calculate tax should be disabled");
        require(_taxRate < 10000, "Tax rate should be less than 10000");
        taxRate = _taxRate;
    }

    function setPair(address _pair, bool _value) public onlyOperatorOrTaxOffice {
        pairs[_pair] = _value;

        emit SetPair(_pair, _value);
    }

    function setExcludeFromFee(address _account, bool _bool) public onlyOperatorOrTaxOffice {
        isExcludedFromFee[_account] = _bool;
    }

    /**
     * @notice Operator mints CRS to a recipient
     * @param _recipient The address of recipient
     * @param _amount The amount of CRS to mint to
     * @return whether the process has been done
     */
    function mint(address _recipient, uint256 _amount)
        public
        onlyOperator
        returns (bool)
    {
        uint256 balanceBefore = balanceOf(_recipient);
        _mint(_recipient, _amount);
        uint256 balanceAfter = balanceOf(_recipient);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 _amount) public override {
        super.burn(_amount);
    }

    function burnFrom(address _account, uint256 _amount)
        public
        override
        onlyOperator
    {
        super.burnFrom(_account, _amount);
    }

    function _transfer(
        address _sender, 
        address _recipient, 
        uint256 _amount
    ) internal virtual override {
        if (autoCalculateTax) {
            uint256 currentCRSPrice = _getCRSPrice();
            _updateTaxRate(currentCRSPrice);
        }

        if (isExcludedFromFee[_sender] || isExcludedFromFee[_recipient]) {
            super._transfer(_sender, _recipient, _amount);
        } else {
            uint256 taxAmount;
            uint256 amountAfterTax = _amount;

            if (pairs[_sender] && flatBuyFee > 0) {
                taxAmount = _amount.mul(flatBuyFee).div(10000);
                amountAfterTax = _amount.sub(taxAmount);
            }
            
            if (pairs[_recipient] && flatSellFee > 0) {
                taxAmount = _amount.mul(taxRate.add(flatSellFee)).div(10000);
                amountAfterTax = _amount.sub(taxAmount);
            }

            if (taxAmount > 0) {
                // Transfer tax to tax collector
                super._transfer(_sender, taxCollectorAddress, taxAmount);
            }

            // Transfer amount after tax to recipient
            super._transfer(_sender, _recipient, amountAfterTax);
        }
    }

    /**
     * @notice distribute to reward pool (only once)
     */
    function distributeReward(
        address _genesisPool,
        address _treasuryWallet
    ) external onlyOperator {
        require(!rewardDistributed, "Distribution had already done!");
        require(_genesisPool != address(0),"Genesis pool should be non-zero address");
        require(_treasuryWallet != address(0),"Treasury wallet should be non-zero address");
        rewardDistributed = true;
        _mint(_genesisPool, INITIAL_GENESIS_POOL_DISTRIBUTION);
        _mint(_treasuryWallet, INITIAL_TREASURY_DISTRIBUTION);
    }

    /**
     * @notice recover unsupported tokens
     */
    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        _token.transfer(_to, _amount);
    }
}