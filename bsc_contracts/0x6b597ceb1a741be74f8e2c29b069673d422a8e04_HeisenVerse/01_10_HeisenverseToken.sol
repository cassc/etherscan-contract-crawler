// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract HeisenVerse is ERC20, ERC20Burnable, Ownable {
    IUniswapV2Router02 public uniswapV2Router;

    address payable private priceKeeper = payable(0x34390458758b6eFaAC5680fBEAb8DE17F2951Ad0);
    address payable private heisenVerse = payable(0xF48f13E10d8B1721E5af72A89E842FbFe47F8F77);
    uint256 private heisenVersePool = 0;
    address private BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private automatedMarketMakerPairs;

    bool private liquidityEnabled;

    event Deposit(address indexed sender, uint256 amount);
    event LiquidityEnabled(bool status);
    event RecoverUnsafeTokens(address indexed token);
    event HeisenVerseTake(uint256 amount);
    event AddressesUpdated(address indexed priceKeeper, address indexed heisenVerse);

    constructor() ERC20("Heisenverse Token", "HSV") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        automatedMarketMakerPairs[_uniswapV2Pair] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[priceKeeper] = true;
        _isExcludedFromFees[heisenVerse] = true;
        _isExcludedFromFees[_msgSender()] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        liquidityEnabled = false;
        _mint(address(this), 9000000000000000000000000);
        _mint(priceKeeper, 1000000000000000000000000);
    }

    /// @dev Fallback function allows to deposit ether.
    receive() external payable {
        if (msg.value > 0) {
            if (liquidityEnabled) {
                swapETHForBUSD(msg.value);
                uint256 liquidityTokens = balanceOf(address(this));
                addLiquidity(liquidityTokens);
            } else {
                (bool sent, ) = priceKeeper.call{value: msg.value}("");
                require(sent, "Failed to send BNB");
            }
            emit Deposit(_msgSender(), msg.value);
        }
    }


    function addLiquidity(uint256 tokens) private {
        IERC20 busd_contract = IERC20(BUSD);
        uint256 busd_balance = busd_contract.balanceOf(address(this));
        busd_contract.approve(address(uniswapV2Router), busd_balance);
        _approve(address(this), address(uniswapV2Router), balanceOf(address(this)));
        uniswapV2Router.addLiquidity(
            address(this),
            BUSD,
            tokens,
            busd_balance,
            0,
            0,
            address(this),
            block.timestamp + 10000
        );
    }

    function recoverUnsafeTokens(address _contractAddress) external onlyOwner {
        require(_contractAddress != address(this), "Can't extract heisenVerse Tokens");
        IERC20 _token = IERC20(_contractAddress);
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(priceKeeper, balance);
        emit RecoverUnsafeTokens(_contractAddress);
    }

    function swapETHForBUSD(uint256 bnb) private {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = BUSD;
        uniswapV2Router.swapExactETHForTokens{value : bnb}(
            0,
            path,
            address(this),
            block.timestamp + 10000
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        bool takeFee = !(_isExcludedFromFees[from] || _isExcludedFromFees[to]);

        if (takeFee) {
            uint256 heisenVerseFee = amount * 10 / 100;
            heisenVersePool = heisenVersePool + heisenVerseFee;
            emit HeisenVerseTake(heisenVerseFee);
        }
        super._transfer(from, to, amount);
    }

    function heisenVerseTake() external onlyOwner {
        super._transfer(address(this), heisenVerse, heisenVersePool);
        heisenVersePool = 0;
        emit HeisenVerseTake(heisenVersePool);
    }

    function updateLiquidityEnabled(bool liquidityEnabled_) external onlyOwner {
        liquidityEnabled = liquidityEnabled_;
        emit LiquidityEnabled(liquidityEnabled_);
    }

    function updateAddresses(address priceKeeper_, address heisenVerse_) external onlyOwner {
        priceKeeper = payable(priceKeeper_);
        heisenVerse = payable(heisenVerse_);
        _isExcludedFromFees[priceKeeper] = true;
        _isExcludedFromFees[heisenVerse] = true;
        emit AddressesUpdated(priceKeeper, heisenVerse);
    }

}