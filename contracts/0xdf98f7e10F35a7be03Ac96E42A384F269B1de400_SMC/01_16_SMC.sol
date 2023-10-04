// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachineportal
// https://twitter.com/erc_arcade

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/external/IWETH9.sol";
import "./interfaces/external/INonfungiblePositionManager.sol";
import "./interfaces/ILPFeeReceiver.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract SMC is ERC20, IERC721Receiver, Ownable, ReentrancyGuard {
    uint256 private constant PERCENT_DENOMENATOR = 1000;
    address private constant DEAD = address(0xdead);

    uint64 public deadblocks = 0;
    bool private _addingLP;

    address public _lpReceiver;
    address public _treasury;
    address public _houseLiquidity;
    address public _smcWallet;

    mapping(address => bool) private _isTaxExcluded;
    mapping(address => bool) private _isLimitless;

    uint256 public taxLp = (PERCENT_DENOMENATOR * 0) / 100;
    uint256 public taxTreasury = (PERCENT_DENOMENATOR * 4) / 100;
    uint256 public taxSMC = (PERCENT_DENOMENATOR * 1) / 100;
    uint256 public taxHouse = (PERCENT_DENOMENATOR * 1) / 100;
    uint256 public additionalSellTax = (PERCENT_DENOMENATOR * 0) / 100;

    uint256 public maxTx = (PERCENT_DENOMENATOR * 2) / 1000;
    uint256 public maxWallet = (PERCENT_DENOMENATOR * 2) / 1000;
    bool public enableLimits = true;

    uint256 private _totalTax;


    uint256 private _liquifyRate = (PERCENT_DENOMENATOR * 1) / 100;
    uint256 public launchTime;
    uint256 private _launchBlock;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) private _isBot;

    bool private _swapEnabled = true;
    bool private _swapping = false;

    modifier swapLock() {
        _swapping = true;
        _;
        _swapping = false;
    }


    error TokenIdNotSet();

    address public immutable WETH;
    IWETH9 public immutable weth;
    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    ILPFeeReceiver public lpFeeReceiver;

    uint256 public tokenId;

    uint256 public amount0Collected;
    uint256 public amount1Collected;

    event FeesCollected(uint256 indexed _amount0, uint256 indexed _amount1, address _lpFeeReceiver, uint256 indexed _timestamp);

    constructor (address _WETH, address _nonfungiblePositionManager) ERC20(unicode"Street Machine 街道机器", "SMC") {
        WETH = _WETH;
        weth = IWETH9(_WETH);
        nonfungiblePositionManager = INonfungiblePositionManager(_nonfungiblePositionManager);


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _treasury = address(0x242C5D0E38b856c0C6AA1D889A31E536483e2e92);
        _houseLiquidity = address(0x37DE7Be917F70800a3490B9dF5D705F0136D0aD7);
        _smcWallet = address(0x03E07F496ecb6EFAC29299E733d2056EB35ac3A2);
        uniswapV2Router = _uniswapV2Router;
        _setTotalTax();
        _lpReceiver = owner();
        _isTaxExcluded[address(this)] = true;
        _isTaxExcluded[msg.sender] = true;
        _isLimitless[address(this)] = true;
        _isLimitless[msg.sender] = true;


        setIsTaxExcluded(0x356815f53d5DFa738E5a38ffB261afa8731e45Be, true); //fostering partnership synergies
        setIsTaxExcluded(0x60e18f804FF8aB716b83ee65D2893B292481911F, true); //cross-chain bridging
        setIsTaxExcluded(0x25d2FCd5759C3B822672B4d78faf1e7DC350b2B5, true); //philanthropy
        setIsTaxExcluded(0x8Bf164d2aDf1167f9611B8067D1a845f89cdeA61, true); //House Wallet 1
        setIsTaxExcluded(0x7B85429fa9E1c7F83B2Cb3Ca4Be367Decb708886, true); //House Wallet 2
        setIsTaxExcluded(0x49Fb0C8877BE9D3661c5aD96b64abD5918fC18Aa, true); //Shills
        setIsTaxExcluded(0x242C5D0E38b856c0C6AA1D889A31E536483e2e92, true); //Treasury


        _isBot[0xdB5889E35e379Ef0498aaE126fc2CCE1fbD23216] = true;
        _isBot[0x3999D2c5207C06BBC5cf8A6bEa52966cabB76d41] = true;

        _mint(_msgSender(), 100_000_000 * (10**18));
    }

    function launch() external onlyOwner {
        require(launchTime == 0, 'already launched');
        deadblocks = 0;
        launchTime = block.timestamp;
        _launchBlock = block.number;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        bool _isOwner = sender == owner() || recipient == owner();
        if (launchTime == 0) {
            require(_isLimitless[sender], "Token not launched");
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool _isBuy = sender == uniswapV2Pair && recipient != address(uniswapV2Router);
        bool _isSell = recipient == uniswapV2Pair;
        bool _isSwap = _isBuy || _isSell;
        if (_isSwap && enableLimits) {
            bool _skipCheck = _addingLP || _isLimitless[recipient] || _isLimitless[sender];
            uint256 _maxTx = totalSupply() * maxTx / PERCENT_DENOMENATOR;
            require(_maxTx >= amount || _skipCheck, "Tx amount exceed limit");
            if (_isBuy) {
                uint256 _maxWallet = totalSupply() * maxWallet / PERCENT_DENOMENATOR;
                require(_maxWallet >= balanceOf(recipient) + amount || _skipCheck, "Total amount exceed wallet limit");
            }
        }
        if (_isBuy) {
            if (block.number < _launchBlock + deadblocks) {
                _isBot[recipient] = true;
            }
        } else {
            require(!_isBot[recipient], 'Stop botting!');
            require(!_isBot[sender], 'Stop botting!');
            require(!_isBot[_msgSender()], 'Stop botting!');
        }
        uint256 _minSwap = (balanceOf(uniswapV2Pair) * _liquifyRate) / PERCENT_DENOMENATOR;
        bool _overMin = contractTokenBalance >= _minSwap;
        if (_swapEnabled && !_swapping && !_isOwner && _overMin && launchTime != 0 && sender != uniswapV2Pair) {
            _swap(_minSwap, _isSell);
        }
        uint256 tax = 0;
        if (launchTime != 0 && _isSwap && !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])) {
            tax = (amount * calcTotalTax(_isSell)) / PERCENT_DENOMENATOR;
            if (tax > 0) {
                super._transfer(sender, address(this), tax);
            }
        }
        super._transfer(sender, recipient, amount - tax);
    }

    function _swap(uint256 _amountToSwap, bool isSell) private swapLock {
        uint256 balBefore = address(this).balance;
        uint256 liquidityTokens = 0;
        if (calcTotalTax(isSell) > 0) {
            liquidityTokens = (_amountToSwap * taxLp) / calcTotalTax(isSell) / 2;
        }
        uint256 tokensToSwap = _amountToSwap - liquidityTokens;

        _swapTokensForEth(tokensToSwap);

        uint256 balToProcess = address(this).balance - balBefore;
        if (balToProcess > 0) {
            _processFees(balToProcess, liquidityTokens, isSell);
        }
    }

    function _swapTokensForEth(uint256 tokensToSwap) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokensToSwap);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLp(uint256 tokenAmount, uint256 ethAmount, address receiver) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            receiver,
            block.timestamp
        );
    }


    function _processFees(uint256 amountETH, uint256 amountLpTokens, bool isSell) private {
        uint256 lpETH = 0;
        if (calcTotalTax(isSell) > 0) {
            lpETH = (amountETH * taxLp) / calcTotalTax(isSell);
        }
        if (amountLpTokens > 0 && lpETH > 0) {
            _addLp(amountLpTokens, lpETH, _lpReceiver);
        }
        if (address(this).balance > 0) {
            uint256 totalTax = taxTreasury + taxHouse + taxSMC;
            uint256 balance = address(this).balance;
            uint256 taxTreasuryAmount = balance * taxTreasury / totalTax;
            uint256 taxSMCAmount = balance * taxSMC / totalTax;
            uint256 taxHouseAmount = balance * taxHouse / totalTax;
            payable(_treasury).transfer(taxTreasuryAmount);
            payable(_houseLiquidity).transfer(taxHouseAmount);
            payable(_smcWallet).transfer(taxSMCAmount);
        }
    }

    function isBotBlacklisted(address account) external view returns (bool) {
        return _isBot[account];
    }

    function blacklistBot(address account) external onlyOwner {
        require(account != address(uniswapV2Router), 'cannot blacklist router');
        require(account != uniswapV2Pair, 'cannot blacklist pair');
        require(!_isBot[account], 'user is already blacklisted');
        _isBot[account] = true;
    }

    function forgiveBot(address account) external onlyOwner {
        _isBot[account] = false;
    }

    function calcTotalTax(bool isSell) private returns (uint256) {
        if (isSell) {
            return _totalTax + additionalSellTax;
        }
        return _totalTax;
    }

    function _setTotalTax() private {
        if (taxLp + taxTreasury + taxHouse + taxSMC >= _totalTax) {
            require(taxLp + taxTreasury + taxHouse + taxSMC <= (PERCENT_DENOMENATOR * 25) / 100, 'tax cannot be above 25%');
        }
        _totalTax = taxLp + taxTreasury + taxHouse + taxSMC;
    }

    function setAdditionalSellTax(uint256 _tax) external onlyOwner {
        if (_tax >= additionalSellTax) {
            require(_tax <= (PERCENT_DENOMENATOR * 25) / 100, 'additionalSellTax cannot be above 25%');
        }
        additionalSellTax = _tax;
    }

    function setTaxLp(uint256 _tax) external onlyOwner {
        taxLp = _tax;
        _setTotalTax();
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet >= 1, 'max wallet cannot be below 0.1%');
        maxWallet = _maxWallet;
    }

    function setMaxTx(uint256 _maxTx) external onlyOwner {
        require(_maxTx >= 1, 'max tx cannot be below 0.1%');
        maxTx = _maxTx;
    }

    function setTax(uint256 _taxTreasury, uint256 _taxHouse, uint256 _taxSMC) external onlyOwner {
        taxTreasury = _taxTreasury;
        taxHouse = _taxHouse;
        taxSMC = _taxSMC;
        _setTotalTax();
    }

    function setLpReceiver(address _wallet) external onlyOwner {
        _lpReceiver = _wallet;
    }

    function setEnableLimits(bool _enable) external onlyOwner {
        enableLimits = _enable;
    }

    function setLiquifyRate(uint256 _rate) external onlyOwner {
        require(_rate <= PERCENT_DENOMENATOR / 10, 'cannot be more than 10%');
        _liquifyRate = _rate;
    }

    function setIsTaxExcluded(address _wallet, bool _isExcluded) public onlyOwner {
        _isTaxExcluded[_wallet] = _isExcluded;
        _isLimitless[_wallet] = _isExcluded;
    }


    function setSwapEnabled(bool _enabled) external onlyOwner {
        _swapEnabled = _enabled;
    }

    function forceSwap() external swapLock {
        _swapTokensForEth(balanceOf(address(this)));
        (bool success,) = address(_treasury).call{value : address(this).balance}("");
    }

    function forceSend() external {
        (bool success,) = address(_treasury).call{value : address(this).balance}("");
    }

    function claim() external nonReentrant {
        if (tokenId == 0) {
            revert TokenIdNotSet();
        }

        (uint256 _amount0, uint256 _amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        }));

        _burn(address(this), _amount0);
        weth.withdraw(_amount1);

        lpFeeReceiver.depositYield{value: address(this).balance}();

        amount0Collected += _amount0;
        amount1Collected += _amount1;
        emit FeesCollected(_amount0, _amount1, address(lpFeeReceiver), block.timestamp);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function setLPFeeReceiver(address _lpFeeReceiver) external nonReentrant onlyOwner {
        lpFeeReceiver = ILPFeeReceiver(_lpFeeReceiver);
    }

    function setTokenId(uint256 _tokenId) external nonReentrant onlyOwner {
        tokenId = _tokenId;
    }

    function getLPFeeReceiver() external view returns (address) {
        return address(lpFeeReceiver);
    }

    function getTokenId() external view returns (uint256) {
        return tokenId;
    }

    function getAmount0Collected() external view returns (uint256) {
        return amount0Collected;
    }

    function getAmount1Collected() external view returns (uint256) {
        return amount1Collected;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}