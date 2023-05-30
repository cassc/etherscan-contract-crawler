// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

contract FomoRocket is ERC20, Ownable, ERC20Burnable {

    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    uint256 public maxTrxAmount;
    uint256 public maxHoldingLimit;
    uint256 public buyTax;
    uint256 public sellTax;

    bool public buyEnabled;
    bool public sellEnabled;

    address private taxRecipient;

    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isExcludedFromMaxHold;
    mapping(address => bool) isBlacklisted;
    mapping(address => bool) isExcludedFromFees;
    mapping(address => bool) isWhitelisted;

    uint256 _totalSupply = 500000000 * 10 ** 18;

    constructor() ERC20("Fomo Rocket", "FOMO") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        maxTrxAmount = _totalSupply.mul(10).div(1000); // 1%
        maxHoldingLimit = _totalSupply.mul(10).div(1000); // 1%

        taxRecipient = 0x1e03882B2294F3Cd98398fd17927332130A11999;

        //Exclude uniswapV2Pair, _uniswapV2Router, deployer and contract from limits
        exludeFromTxLimit(msg.sender, true);
        exludeFromTxLimit(address(uniswapV2Router), true);
        exludeFromTxLimit(address(uniswapV2Pair), true);
        exludeFromTxLimit(address(this), true);
        exludeFromTxLimit(taxRecipient, true);
        isTxLimitExempt[0x0000000000000000000000000000000000000000] = true;

        exludeFromMaxHold(msg.sender, true);
        exludeFromMaxHold(address(uniswapV2Router), true);
        exludeFromMaxHold(address(uniswapV2Pair), true);
        exludeFromMaxHold(address(this), true);
        exludeFromMaxHold(taxRecipient, true);

        excludeFromFees(msg.sender, true);
        excludeFromFees(address(uniswapV2Router), true);
        excludeFromFees(address(uniswapV2Pair), true);
        excludeFromFees(address(this), true);
        excludeFromFees(taxRecipient, true);

        isWhitelisted[msg.sender] = true;
        isWhitelisted[address(uniswapV2Router)] = true;
        isWhitelisted[address(uniswapV2Pair)] = true;
        isWhitelisted[address(this)] = true;
        isWhitelisted[taxRecipient] = true;

        //Zero tax
        buyTax = 0;
        sellTax = 0;

        buyEnabled = false;
        sellEnabled = false;


        _mint(msg.sender, 405000000 * 10 ** decimals()); //LP
        _mint(0xeF2cBB5F22AE96B4118175ea7ddB91150b4eEC23, 5000000 * 10 ** decimals()); //M1
        _mint(0x2F0849e63F552F5c827dd8d937553DBcC57e4b1A, 5000000 * 10 ** decimals()); //M2
        _mint(0x1BDbADdf27B94896e81edA5D09bcf8c6fAE46426, 5000000 * 10 ** decimals()); //M3
        _mint(0xA8B8E22305ccbca57ec7925F1bF771bed6D1c9A8, 5000000 * 10 ** decimals()); //M4
        _mint(0xEb71efaFD2f4b647DfBfe64dc9c9336bE878817C, 5000000 * 10 ** decimals()); //M5
        _mint(0x14AB25206abE85F46093f7A4B137291dA58428bE, 5000000 * 10 ** decimals()); //M6
        _mint(0x519E2d0f18eA524Bf388104dF27f1bd5a7B26cA1, 5000000 * 10 ** decimals()); //M7
        _mint(0x611682521d2565519C44d54Ea4A4814143a47089, 5000000 * 10 ** decimals()); //M8

        _mint(0xF4E35578F6aCBe8664bB4bEB0908f2E353b07bC8, 5000000 * 10 ** decimals()); //M9
        _mint(0x66A669755078A4e0AA7cAB5d2b09BB811354EB41, 5000000 * 10 ** decimals()); //M10
        _mint(0x3BD5F8245D784f631c1365dba52362Ec2519E156, 5000000 * 10 ** decimals()); //M11
        _mint(0xdd21779a50FD17C475EcBcc916da86dE4e39077B, 5000000 * 10 ** decimals()); //M12
        _mint(0xb7c33ab937aa94201a406A1044dBa40096b196C2, 5000000 * 10 ** decimals()); //M13
        _mint(0x6902166Ba8a198d8B45D0A00c98CeAc1A63f00fB, 5000000 * 10 ** decimals()); //M14
        _mint(0x8c20E80992c004E41B00De123315c43Cbe6bd115, 5000000 * 10 ** decimals()); //M15


        //Refund from Relaunch
        _mint(0x4E6BC973ac32A5960174b2E378D82c1c278fEE3C, 5000000 * 10 ** decimals()); //R1
        _mint(0xF7d9A9a9461B5E772332280bDEd5E42105b14190, 5000000 * 10 ** decimals()); //R2
        _mint(0x2d18079416BC8E222cDb884ac0e12b76fd529ccD, 5000000 * 10 ** decimals()); //R3
        _mint(0xa8C2e974964F168DbD0E8eE641D7752DB870e528, 5000000 * 10 ** decimals()); //R4
    }

    function exludeFromTxLimit(address _exclude, bool status) public onlyOwner {
        require(_exclude != address(0x0), "Invalid address");

        isTxLimitExempt[_exclude] = status;
    }

    function exludeFromMaxHold(address _exclude, bool status) public onlyOwner {
        require(_exclude != address(0x0), "Invalid address");

        isExcludedFromMaxHold[_exclude] = status;
    }

    function excludeFromFees(address _exclude, bool status) public onlyOwner {
        require(_exclude != address(0x0), "Invalid address");

        isExcludedFromFees[_exclude] = status;
    }

    function setBuyTax(uint256 _tax) public onlyOwner {
        require(_tax > 0, "Invalid amount");

        buyTax = _tax;
    }

    function setSellTax(uint256 _tax) public onlyOwner {
        require(_tax > 0, "Invalid amount");

        sellTax = _tax;
    }

    function setBuyStatus(bool status) public onlyOwner {
        buyEnabled = status;
    }

    function setSellStatus(bool status) public onlyOwner {
        sellEnabled = status;
    }

    function blacklist(address _malicious, bool status) public onlyOwner {
        require(_malicious != address(0x0), "Invalid address");

        isBlacklisted[_malicious] = status;
    }

    function updateMaxTrxLimit(uint256 _limit) public onlyOwner {
        require(_limit <= 100, "Invalid");
        require(_limit > 0, "Invalid amount");

        maxTrxAmount = _totalSupply.mul(_limit).div(1000);
    }

    function updateMaxHoldingLimit(uint256 _limit) public onlyOwner {
        require(_limit <= 100, "Invalid");
        require(_limit > 0, "Invalid amount");

        maxHoldingLimit = _totalSupply.mul(_limit).div(1000);
    }

    function updateTaxRecipient(address _recipient) public onlyOwner {
        require(_recipient != address(0x0), "Invalid address");

        taxRecipient = _recipient;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);

        require(!isBlacklisted[from], "Malicious user banned");
        require(!isBlacklisted[to], "Malicious user banned");

        if(!isTxLimitExempt[from]) {
            require(amount <= maxTrxAmount, "TX Limit Exceeded");
        }

        if(!isExcludedFromMaxHold[to]) {
            uint _balance = balanceOf(to);
            require(_balance.add(amount) <= maxHoldingLimit, "Max Hold Limit Exceeded");
        }
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();

        bool _buyAction =  owner == uniswapV2Pair;
        bool _sellAction = to == uniswapV2Pair;

        if(_buyAction){
            if(!isWhitelisted[to]) {
                require(buyEnabled, "buy is disabled at the moment");
            }

            _transfer(owner, to, amount);

            if(!isExcludedFromFees[to])
            {
                uint256 _buyFee = amount.mul(buyTax).div(1000);

                if(_buyFee > 0) {
                    _burn(to, _buyFee);
                    _mint(taxRecipient, _buyFee);
                }
            }

        }else if(_sellAction){
             if(!isWhitelisted[owner]) {
                require(sellEnabled, "sell is disabled at the moment");
             }

            if(!isExcludedFromFees[owner])
            {
                uint256 _sellFee = amount.mul(buyTax).div(1000);
                amount = amount.sub(_sellFee);

                if(_sellFee > 0){
                    _burn(owner, _sellFee);
                    _mint(taxRecipient, _sellFee);
                }
            }

            _transfer(owner, to, amount);
        }else{
            _transfer(owner, to, amount);
        }

        return true;
    }

    function batchWhitelist(address[] memory _addresses) public onlyOwner {
        for(uint i = 0; i < _addresses.length; i++){
            isWhitelisted[_addresses[i]] = true;
        }
    }

    function unbatchWhitelist(address[] memory _addresses) public onlyOwner {
        for(uint i = 0; i < _addresses.length; i++){
            isWhitelisted[_addresses[i]] = false;
        }
    }

}