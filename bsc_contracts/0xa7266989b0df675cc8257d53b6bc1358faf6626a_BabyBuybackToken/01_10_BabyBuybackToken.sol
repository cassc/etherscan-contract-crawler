// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract BabyBuybackToken is ERC20Burnable, Ownable {
    uint16 private constant HUNDRED_PERCENT = 1e3;
    uint16 private constant MAX_FEE_TOTAL_PERCENTAGE = 3e2; 
    uint16 private constant MAX_FEE_PERCENTAGE = 1e2; 

    address public feeWallet;
    uint16 public swapPercentage;
    uint16 public burnPercentage;
    uint16 public feePercentage;
    bool private swappingForMotherToken;

    IUniswapV2Router02 public router;
    address[] public swapPath;
    mapping(address => bool) public isAmmPair;
    mapping(address => bool) public isExcludedFromFees;

    event TakeFee(address indexed from, uint256 swapAmount, uint256 burnAmount, uint256 feeAmount);
    event SetAmmPair(address pair, bool state);
    event SetFeePercentages(uint256 swapPercentage, uint256 burnPercentage, uint256 feePercentage);
    event SetFeeWallet(address newFeeWallet);
    event ExcludeFromFees(address excludedAddress);

    constructor(
        string memory _name, 
        string memory _symbol,
        IUniswapV2Router02 _router,
        address _pairToken,
        address[] memory _swapPath,
        uint16 _swapPercentage,
        uint16 _burnPercentage,
        uint16 _feePercentage,
        address _feeWallet,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) {
        require(_swapPercentage + _burnPercentage + _feePercentage <= MAX_FEE_TOTAL_PERCENTAGE, "fee percentages too high");
        require(_feePercentage <= MAX_FEE_PERCENTAGE, "fee percentage too high");
        
        require(_swapPath.length > 0, "empty swap path");
        if (_feeWallet == address(0)) {
            _feeWallet = msg.sender;
        }

        router = _router;
        address pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _pairToken);
        isAmmPair[pair] = true;
        swapPath = [address(this), _pairToken];
        for (uint256 i; i < _swapPath.length; i++) {
            swapPath.push(_swapPath[i]);
        }

        swapPercentage = _swapPercentage;
        burnPercentage = _burnPercentage;
        feePercentage = _feePercentage;
        feeWallet = _feeWallet;

        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[address(0)] = true;
        isExcludedFromFees[_feeWallet] = true;

        _mint(msg.sender, _totalSupply);
    }

    // ================ OWNER FUNCTIONS ================ //

    function setAmmPair(address pair, bool state) external onlyOwner {
        isAmmPair[pair] = state;
        emit SetAmmPair(pair, state);
    }

    function excludeFromFees(address addressToExclude) external onlyOwner {
        isExcludedFromFees[addressToExclude] = true;
        emit ExcludeFromFees(addressToExclude);
    }

    function setFeePercentages(uint16 _swapPercentage, uint16 _burnPercentage, uint16 _feePercentage) external onlyOwner {
        require(_swapPercentage + _burnPercentage + _feePercentage <= MAX_FEE_TOTAL_PERCENTAGE, "fee percentages too high");
        require(_feePercentage <= MAX_FEE_PERCENTAGE, "fee percentage too high");

        swapPercentage = _swapPercentage;
        burnPercentage = _burnPercentage;
        feePercentage = _feePercentage;
        emit SetFeePercentages(_swapPercentage, _burnPercentage, _feePercentage);
    }
    
    function setFeeWallet(address newFeeWallet) external {
        require(msg.sender == feeWallet, "only the old fee wallet");
        require(newFeeWallet != address(0), "zero address");

        isExcludedFromFees[feeWallet] = false;
        isExcludedFromFees[newFeeWallet] = true;
        feeWallet = newFeeWallet;
        emit SetFeeWallet(newFeeWallet);
    }

    // ================ INTERNAl FUNCTIONS ================ //

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        amount -= _takeFee(sender, recipient, amount);
        super._transfer(sender, recipient, amount);
    }

    function _takeFee(address sender, address recipient, uint256 amount) internal returns (uint256 totalFee) {
        if (isExcludedFromFees[sender] || isExcludedFromFees[recipient]) {
            return 0;
        }

        uint256 swapAmount;
        uint256 burnAmount;
        uint256 feeAmount;

        if (isAmmPair[recipient] && !swappingForMotherToken) {
            swapAmount = _swapForMotherToken(sender, amount);
            totalFee += swapAmount;
        }

        burnAmount = amount * burnPercentage / HUNDRED_PERCENT;
        totalFee += burnAmount;
        if (burnAmount > 0) {
            _burn(sender, burnAmount);
        }

        feeAmount = amount * feePercentage / HUNDRED_PERCENT;
        totalFee += feeAmount;
        if (feeAmount > 0) {
            super._transfer(sender, feeWallet, feeAmount);
        }

        emit TakeFee(sender, swapAmount, burnAmount, feeAmount);
    }
    
    function _swapForMotherToken(address sender, uint256 amount) internal returns (uint256 swapAmount) {
        swapAmount = amount * swapPercentage / HUNDRED_PERCENT;
        if (swapAmount == 0) return 0;

        swappingForMotherToken = true;

        super._transfer(sender, address(this), swapAmount);
        _approve(address(this), address(router), swapAmount);

        try 
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmount,
                0,
                swapPath,
                sender,
                block.timestamp
            )
        {
        } catch {
            super._transfer(address(this), sender, swapAmount);
            _approve(address(this), address(router), 0);
            swapAmount = 0; 
        }

        swappingForMotherToken = false;
    }
}