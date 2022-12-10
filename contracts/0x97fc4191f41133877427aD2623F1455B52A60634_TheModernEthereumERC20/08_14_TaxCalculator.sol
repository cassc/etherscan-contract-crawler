// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "./PriceCalculator.sol";

contract TaxCalculator is PriceCalculator {
    struct MarketcapStageForTax {
        uint256 firstStage;
        uint256 secondStage;
        uint256 thirdStage;
        uint256 forthStage;
        uint256 fifthStage;
    }

    IUniswapV2Router02 private dexRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    MarketcapStageForTax public mcStage;

    address private admin;

    mapping(uint256 => Taxes) public buyTaxPerStage;
    mapping(uint256 => Taxes) public sellTaxPerStage;

    modifier onlyAdmin {
        require(msg.sender == admin, 'no permission');
        _;
    }

    constructor() {
        admin = msg.sender;

        // initialize the mc stage
        mcStage.firstStage = 0;
        mcStage.secondStage = 80000;
        mcStage.thirdStage = 200000;
        mcStage.forthStage = 500000;
        mcStage.fifthStage = 2000000;

        // initialize the tax strategy
        buyTaxPerStage[mcStage.firstStage] = Taxes(3, 1, 1);
        buyTaxPerStage[mcStage.secondStage] = Taxes(3, 1, 1);
        buyTaxPerStage[mcStage.thirdStage] = Taxes(3, 1, 1);
        buyTaxPerStage[mcStage.forthStage] = Taxes(1, 1, 1);
        buyTaxPerStage[mcStage.fifthStage] = Taxes(1, 0, 0);

        sellTaxPerStage[mcStage.firstStage] = Taxes(8, 3, 6);
        sellTaxPerStage[mcStage.secondStage] = Taxes(4, 1, 2);
        sellTaxPerStage[mcStage.thirdStage] = Taxes(3, 2, 1);
        sellTaxPerStage[mcStage.forthStage] = Taxes(1, 1, 1);
        sellTaxPerStage[mcStage.fifthStage] = Taxes(0, 1, 1);
    }

    function getCurrentTaxes() public view returns (Taxes memory, Taxes memory) {
        return _getCurrentTaxes();
    }

    function _getCurrentTaxes() internal view returns (Taxes memory buyTax, Taxes memory sellTax) {
        uint256 tokenPrice = getTokenPriceInEthPair(dexRouter, address(this));
        uint256 totalSupply = IERC20(address(this)).totalSupply();
        uint256 marketcap = totalSupply / 1e18 * tokenPrice / 1e18;

        if (marketcap < mcStage.secondStage) {    // first stage of tax
            buyTax = buyTaxPerStage[mcStage.firstStage];
            sellTax = sellTaxPerStage[mcStage.firstStage];
        } else if (marketcap < mcStage.thirdStage) {
            buyTax = buyTaxPerStage[mcStage.secondStage];
            sellTax = sellTaxPerStage[mcStage.secondStage];
        } else if (marketcap < mcStage.forthStage) {
            buyTax = buyTaxPerStage[mcStage.thirdStage];
            sellTax = sellTaxPerStage[mcStage.thirdStage];
        } else if (marketcap < mcStage.fifthStage) {
            buyTax = buyTaxPerStage[mcStage.forthStage];
            sellTax = sellTaxPerStage[mcStage.forthStage];
        } else {
            buyTax = buyTaxPerStage[mcStage.fifthStage];
            sellTax = sellTaxPerStage[mcStage.fifthStage];
        }
    }

    function updateMcStage(uint256 _first, uint256 _second, uint256 _third, uint256 _forth, uint256 _fifth) external onlyAdmin {
        Taxes memory _buyFirstStageTax = buyTaxPerStage[mcStage.firstStage];
        Taxes memory _buySecondStageTax = buyTaxPerStage[mcStage.secondStage];
        Taxes memory _buyThirdStageTax = buyTaxPerStage[mcStage.thirdStage];
        Taxes memory _buyForthStageTax = buyTaxPerStage[mcStage.forthStage];
        Taxes memory _buyFifthStageTax = buyTaxPerStage[mcStage.fifthStage];
        
        Taxes memory _sellFirstStageTax = sellTaxPerStage[mcStage.firstStage];
        Taxes memory _sellSecondStageTax = sellTaxPerStage[mcStage.secondStage];
        Taxes memory _sellThirdStageTax = sellTaxPerStage[mcStage.thirdStage];
        Taxes memory _sellForthStageTax = sellTaxPerStage[mcStage.forthStage];
        Taxes memory _sellFifthStageTax = sellTaxPerStage[mcStage.fifthStage];

        mcStage.firstStage = _first;
        mcStage.secondStage = _second;
        mcStage.thirdStage = _third;
        mcStage.forthStage = _forth;
        mcStage.fifthStage = _fifth;

        buyTaxPerStage[mcStage.firstStage] = _buyFirstStageTax;
        buyTaxPerStage[mcStage.secondStage] = _buySecondStageTax;
        buyTaxPerStage[mcStage.thirdStage] = _buyThirdStageTax;
        buyTaxPerStage[mcStage.forthStage] = _buyForthStageTax;
        buyTaxPerStage[mcStage.fifthStage] = _buyFifthStageTax;

        sellTaxPerStage[mcStage.firstStage] = _sellFirstStageTax;
        sellTaxPerStage[mcStage.secondStage] = _sellSecondStageTax;
        sellTaxPerStage[mcStage.thirdStage] = _sellThirdStageTax;
        sellTaxPerStage[mcStage.forthStage] = _sellForthStageTax;
        sellTaxPerStage[mcStage.fifthStage] = _sellFifthStageTax;
    }

    function updateBuyTaxPerStage(uint256 _stage, uint256 _marketingFee, uint256 _treasuryFee, uint256 _devFee) external onlyAdmin {
        buyTaxPerStage[_stage] = Taxes(_marketingFee, _treasuryFee, _devFee);
        require(_marketingFee + _treasuryFee + _devFee <= 15, "high tax set");
    }

    function updateSellTaxPerStage(uint256 _stage, uint256 _marketingFee, uint256 _treasuryFee, uint256 _devFee) external onlyAdmin {
        sellTaxPerStage[_stage] = Taxes(_marketingFee, _treasuryFee, _devFee);
        require(_marketingFee + _treasuryFee + _devFee <= 20, "high tax set");
    }

    function updateAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }
}