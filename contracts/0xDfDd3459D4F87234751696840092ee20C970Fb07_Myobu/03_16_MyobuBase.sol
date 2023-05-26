// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Utils/MyobuLib.sol";
import "./Utils/Ownable.sol";
import "./Interfaces/IUniswapV2Router.sol";
import "./Interfaces/IUniswapV2Factory.sol";
import "./Interfaces/IUniswapV2Pair.sol";
import "./Interfaces/IMyobu.sol";

abstract contract MyobuBase is IMyobu, Ownable, ERC20 {
    uint256 internal constant MAX = type(uint256).max;

    uint256 private constant SUPPLY = 1000000000000 * 10**9;
    string internal constant NAME = unicode"Myōbu";
    string internal constant SYMBOL = "MYOBU";
    uint8 internal constant DECIMALS = 9;

    // pair => router
    mapping(address => address) internal _routerFor;
    mapping(address => bool) private taxedTransfer;

    Fees private fees;

    address payable internal _taxAddress;

    IUniswapV2Router internal uniswapV2Router;
    address internal uniswapV2Pair;

    bool private tradingOpen;
    bool private liquidityAdded;
    bool private inSwap;
    bool private swapEnabled;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address payable addr1) ERC20(NAME, SYMBOL) {
        _taxAddress = addr1;
        _mint(_msgSender(), SUPPLY);
    }

    function decimals() public pure virtual override returns (uint8) {
        return DECIMALS;
    }

    function taxedPair(address pair)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _routerFor[pair] != address(0);
    }

    // Transfer tokens without emmiting events from an address to this address, used for taking fees
    function transferFee(address from, uint256 amount) internal {
        _balances[from] -= amount;
        _balances[address(this)] += amount;
    }

    function takeFee(
        address from,
        uint256 amount,
        uint256 teamFee
    ) internal returns (uint256) {
        if (teamFee == 0) return 0;
        uint256 tTeam = MyobuLib.percentageOf(amount, teamFee);
        transferFee(from, tTeam);
        emit FeesTaken(tTeam);
        return tTeam;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // If no fee, it is 0 which will take no fee
        uint256 _teamFee;
        if (from != owner() && to != owner()) {
            if (swapEnabled && !inSwap) {
                if (taxedPair(from) && !taxedPair(to)) {
                    require(tradingOpen);
                    _teamFee = fees.buyFee;
                } else if (taxedTransfer[from] || taxedTransfer[to]) {
                    _teamFee = fees.transferFee;
                } else if (taxedPair(to)) {
                    require(tradingOpen);
                    require(amount <= (balanceOf(to) * fees.impact) / 100);
                    swapTokensForEth(balanceOf(address(this)));
                    sendETHToFee(address(this).balance);
                    _teamFee = fees.sellFee;
                }
            }
        }

        uint256 fee = takeFee(from, amount, _teamFee);
        super._transfer(from, to, amount - fee);
    }

    function swapTokensForEth(uint256 tokenAmount) internal lockTheSwap {
        MyobuLib.swapForETH(uniswapV2Router, tokenAmount, address(this));
    }

    function sendETHToFee(uint256 amount) internal {
        _taxAddress.transfer(amount);
    }

    function openTrading() external virtual onlyOwner {
        require(liquidityAdded);
        tradingOpen = true;
    }

    function addDEX(address pair, address router) public virtual onlyOwner {
        require(!taxedPair(pair), "DEX already exists");
        address tokenFor = MyobuLib.tokenFor(pair);
        _routerFor[pair] = router;
        _approve(address(this), router, MAX);
        IERC20(tokenFor).approve(router, MAX);
        IERC20(pair).approve(router, MAX);
    }

    function removeDEX(address pair) external virtual onlyOwner {
        require(taxedPair(pair), "DEX does not exist");
        address tokenFor = MyobuLib.tokenFor(pair);
        address router = _routerFor[pair];
        delete _routerFor[pair];
        _approve(address(this), router, 0);
        IERC20(tokenFor).approve(router, 0);
        IERC20(pair).approve(router, 0);
    }

    function addLiquidity() external virtual onlyOwner lockTheSwap {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        addDEX(uniswapV2Pair, address(_uniswapV2Router));
        MyobuLib.addLiquidityETH(
            uniswapV2Router,
            balanceOf(address(this)),
            address(this).balance,
            owner()
        );
        liquidityAdded = true;
    }

    function setTaxAddress(address payable newTaxAddress) external onlyOwner {
        _taxAddress = newTaxAddress;
        emit TaxAddressChanged(newTaxAddress);
    }

    function setTaxedTransferFor(address[] calldata taxedTransfer_)
        external
        virtual
        onlyOwner
    {
        for (uint256 i; i < taxedTransfer_.length; i++) {
            taxedTransfer[taxedTransfer_[i]] = true;
        }
        emit TaxedTransferAddedFor(taxedTransfer_);
    }

    function removeTaxedTransferFor(address[] calldata notTaxed)
        external
        virtual
        onlyOwner
    {
        for (uint256 i; i < notTaxed.length; i++) {
            taxedTransfer[notTaxed[i]] = false;
        }
        emit TaxedTransferRemovedFor(notTaxed);
    }

    function manualswap() external onlyOwner {
        swapTokensForEth(balanceOf(address(this)));
    }

    function manualsend() external onlyOwner {
        sendETHToFee(address(this).balance);
    }

    function setSwapRouter(IUniswapV2Router newRouter) external onlyOwner {
        require(liquidityAdded, "Add liquidity before doing this");

        address weth = uniswapV2Router.WETH();
        address newPair = IUniswapV2Factory(newRouter.factory()).getPair(
            address(this),
            weth
        );
        require(
            newPair != address(0),
            "WETH Pair does not exist for that router"
        );
        require(taxedPair(newPair), "The pair must be a taxed pair");

        (uint256 reservesOld, , ) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        (uint256 reservesNew, , ) = IUniswapV2Pair(newPair).getReserves();
        require(
            reservesNew > reservesOld,
            "New pair must have more WETH Reserves"
        );

        uniswapV2Router = newRouter;
        uniswapV2Pair = newPair;
    }

    function setFees(Fees memory newFees) public onlyOwner {
        require(
            newFees.impact != 0 && newFees.impact <= 100,
            "Impact must be greater than 0 and under or equal to 100"
        );
        require(
            newFees.buyFee < 15 &&
                newFees.sellFee < 15 &&
                newFees.transferFee <= newFees.sellFee,
            "Fees for a buy / sell must be under 15"
        );
        fees = newFees;

        if (newFees.buyFee + newFees.sellFee == 0) {
            swapEnabled = false;
        } else {
            swapEnabled = true;
        }

        emit FeesChanged(newFees);
    }

    function currentFees() external view override returns (Fees memory) {
        return fees;
    }

    // solhint-disable-next-line
    receive() external payable virtual {}
}