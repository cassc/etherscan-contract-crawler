// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {UD60x18, intoUint256, ud} from "@prb/math/src/UD60x18.sol";

contract Taxable is Ownable {
    // ==================== STRUCTURE ==================== //

    uint256 public tax = 5 * 1e18; // 5%
    uint256 public threshold = 2 * 1e18; // in WETH

    address public priceFeed;

    uint256 private HUNDRED = 100 * 1e18;

    uint256 private swapSlippage = 80e4;

    uint256 public currentTaxAmount = 0;

    mapping(address => bool) public taxExempts;
    mapping(address => uint256) public taxPercentages;
    address[] taxReceiverList;

    mapping(address => bool) private taxAddressReciever;

    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 

    mapping(address => bool) public dexAddress;
    address[] dexAddressList;

    // ==================== EVENTS ==================== //

    event AddDEXAddress(address dex);
    event RemoveDEXAddress(address dex);
    event UpdateTax(uint256 oldPercentage, uint256 newPercentage);
    event UpdateReceiverTax(
        address receiver,
        uint256 oldPercentage,
        uint256 newPercentage
    );
    event AddTaxReceiver(address receiver, uint256 percentage);
    event RemoveTaxReceiver(address receiver);
    event SetSwapSlippage(uint256 _swapSlippage);
    event UpdateThreshold(uint256 _threshold);
    event SetPriceFeedAddress(address _priceFeedAddress);
    event RewardAddress(address _rewardAddress);
    event SetRouterAddress(address _routerAddress);
    event AddTaxExemption(address _user);
    event RemoveTaxExemption(address _user);


    // ==================== MODIFIERS ==================== //

    modifier isValidAddress(address account) {
        require(account != address(0), "Invalid address");
        _;
    }

    // ==================== FUNCTIONS ==================== //

    function getAllDexAddresses() external view returns (address[] memory) {
        return dexAddressList;
    }

    function getAllTaxReceivers() external view returns (address[] memory) {
        return taxReceiverList;
    }

    function addDEXAddress(address _dex) external onlyOwner {
        require(_dex != address(0), "Invalid DEX address");
        require(!dexAddress[_dex], "DEX already exists");
        dexAddress[_dex] = true;
        dexAddressList.push(_dex);

        emit AddDEXAddress(_dex);
    }

    function removeDEXAddress(uint _index) external onlyOwner {
        require(_index < dexAddressList.length, "Dex address not on the list");
        emit RemoveDEXAddress(dexAddressList[_index]);
        dexAddress[dexAddressList[_index]] = false;
        dexAddressList[_index] = dexAddressList[dexAddressList.length - 1];
        dexAddressList.pop();
    }

    function addTaxReceiver(
        address _receiver,
        uint256 _percentage
    ) external onlyOwner {
        require(taxAddressReciever[_receiver] == false, "Receiver already exists");
        taxPercentages[_receiver] = _percentage;
        taxAddressReciever[_receiver] = true;
        taxReceiverList.push(_receiver);

        emit AddTaxReceiver(_receiver, _percentage);
    }

    function updateReceiverTax(
        address _receiver,
        uint256 _percentage
    ) external onlyOwner {
        require(taxAddressReciever[_receiver] == true, "Receiver doesn't exists");
        emit UpdateReceiverTax(
            _receiver,
            taxPercentages[_receiver],
            _percentage
        );
        taxPercentages[_receiver] = _percentage;
    }

    function removeTaxReceiver(uint256 _index, address _receiver) external onlyOwner {
        require(_index < taxReceiverList.length,"Incorrect Index");
        require(taxAddressReciever[_receiver] == true, "Receiver doesn't exists");
        emit RemoveTaxReceiver(taxReceiverList[_index]);
        taxPercentages[taxReceiverList[_index]] = 0;
        taxReceiverList[_index] = taxReceiverList[taxReceiverList.length - 1];
        taxAddressReciever[_receiver] = false;
        taxReceiverList.pop();
    }

    function updateThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold > 0, "Value must be greater than 0");
        threshold = _threshold;
        emit UpdateThreshold( _threshold);
    }

    function updateTax(uint256 _tax) external onlyOwner {
        require(_tax <= 10 * 1e18, "Tax should not be greater than 10 %");

        emit UpdateTax(tax, _tax);
        tax = _tax;
    }

    function getPrice() public view returns (uint256) {
        (, int price, , , ) = AggregatorV3Interface(priceFeed)
            .latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }

    function calculateFeeAmount(
        uint256 _amount,
        uint256 _fee
    ) public view returns (uint256) {
        return (_amount * _fee) / HUNDRED;
    }

    function calculateTaxAmount(uint256 _amount) public view returns (uint256) {
        return calculateFeeAmount(_amount, tax);
    }

    function calculateTransferAmount(
        uint256 _amount,
        uint256 _tax
    ) public pure returns (uint256) {
        return _amount - _tax;
    }

    function _calculateAmountOutMin(
    address _tokenIn,
    uint256 _amountIn,
    uint256 _slippage
    ) internal view returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _tokenIn;

    uint256[] memory amountsOut = IUniswapV2Router02(routerAddress).getAmountsOut(_amountIn, path);
    uint256 amount = amountsOut[amountsOut.length - 1];

    return (amount - intoUint256(ud(amount) * ud((_slippage * 1e14) / 100)));
    }


    function setPriceFeed(
        address _priceFeedAddress
    ) public onlyOwner isValidAddress(_priceFeedAddress) {
        priceFeed = _priceFeedAddress;
        emit SetPriceFeedAddress(_priceFeedAddress);
    }

    function setRewardAddress(
        address _rewardAddress
    ) external onlyOwner isValidAddress(_rewardAddress) {
        WETH = _rewardAddress;
        emit RewardAddress( _rewardAddress);
    }

    function setRouter(
        address _routerAddress
    ) external onlyOwner isValidAddress(_routerAddress) {
        routerAddress = _routerAddress;
        emit SetRouterAddress(_routerAddress);
    }

    function addTaxExempts(
        address _user
    ) external onlyOwner isValidAddress(_user) {
        taxExempts[_user] = true;
        emit AddTaxExemption(_user);
    }

    function removeTaxExempts(
        address _user
    ) external onlyOwner isValidAddress(_user) {
        taxExempts[_user] = false;
        emit RemoveTaxExemption(_user);
    }
    
    function setSwapSlippage(uint256 _swapSlippage) external onlyOwner {
    require(_swapSlippage >= 1e3 && _swapSlippage <= 100e4, "slippage must be between 0.1 to 100");
    swapSlippage = _swapSlippage;
    emit SetSwapSlippage(_swapSlippage);
    }

    function _swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _to,
        uint256 _minAmount
    ) internal {
        IERC20(_tokenIn).approve(routerAddress, _amountIn);

        address[] memory path;
        if (_tokenIn != address(WETH) && _tokenOut != address(WETH)) {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        } else {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        }

        // Make the swap
        IUniswapV2Router02(routerAddress)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amountIn,
                _minAmount,
                path,
                _to,
                block.timestamp + 10 minutes
            );
    }

    function _distribute() internal {
        for (uint256 i = 0; i < taxReceiverList.length; i++) {
            address account = taxReceiverList[i];
            uint256 toSendAmount = calculateFeeAmount(
                currentTaxAmount,
                taxPercentages[account]
            );
            uint256 minAmount = _calculateAmountOutMin(WETH, toSendAmount, swapSlippage);
            _swap(address(this), WETH, toSendAmount, account, minAmount);
        }

        currentTaxAmount = 0;
    }

    function _taxEqualsHundred() internal view returns (bool) {
        uint256 sum = 0;
        for (uint256 i = 0; i < taxReceiverList.length; i++) {
            address account = taxReceiverList[i];
            sum += taxPercentages[account];
        }

        return (sum == HUNDRED);
    }
}