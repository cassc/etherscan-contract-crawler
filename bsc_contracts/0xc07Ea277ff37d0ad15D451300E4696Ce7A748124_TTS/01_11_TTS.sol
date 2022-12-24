// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/IAddLiquidityContract.sol";
import "./TTSFeeWallet.sol";

contract TTS is ERC20, Ownable {
    // address private feeWallet;
    uint256 public feeSizeBurn;
    IUniswapV2Router02 public router;
    address[] public path = [address(this), 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56]; //@todo changes
    bool public status = false;
    address public immutable pairAddress;
    IAddLiquidityContract public addLiquidityContract; //@todo changes
    address public oldContract = 0x2F9315577D7f45025a50ca744F474069EbB2b1F3;
    address private feewallet;
    address public marketing;
    IERC20 public busd;

    TTSFeeWallet private feeWallet;

    receive() external payable {}

    fallback() external payable {}

    ///////====>//////
    uint256 private _tokenFarmingTreasury = 80 * 10**10 * 10**18; // 80%
    uint256 private _tokenPreSale = 10 * 10**10 * 10**18; //10%
    uint256 private _tokenTeam = 5 * 10**10 * 10**18; //5%
    uint256 private _tokenAirDrop = 4 * 10**10 * 10**18; // 4% //@todo bajanel erku masi
    uint256 private _tokenLiquidity = 1 * 10**10 * 10**18; // 1%
    uint256 private _tokenTotal = _tokenTeam + _tokenAirDrop + _tokenPreSale + _tokenFarmingTreasury + _tokenLiquidity;
    address private lpAddress;

    constructor(
        address _marketing,
        address _farming,
        address _preSale,
        address _airDrop, //@todo contracty jnjveluya
        address _team,
        address _liqudityAdder
    ) ERC20("ToTheStart", "TTS") {
        feeWallet = new TTSFeeWallet();
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        feeSizeBurn = 25;
        marketing = _marketing;
        busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        feewallet = 0x116422da50f39287d4a13a06c321B44111f66424;
        _mint(msg.sender, 1e10 * 1e18); //@todo delete this line
        pairAddress = IUniswapV2Factory(router.factory()).createPair(address(this), address(busd));
        _approve(address(this), address(router), 2**256 - 1);

        _mint(_farming, _tokenFarmingTreasury);
        _mint(_preSale, _tokenPreSale);
        _mint(_airDrop, _tokenAirDrop);
        _mint(_team, _tokenTeam);
        _mint(_liqudityAdder, _tokenLiquidity);
    }

    ///////====>//////

    function setLpAddress(address newLpAddress) external onlyOwner {
        lpAddress = newLpAddress;
    }

    function getFee(bool _status) public onlyOwner {
        _getFee(_status);
    }

    function setLiquidityContract(address _addLiquidityContract) external onlyOwner {
        addLiquidityContract = IAddLiquidityContract(_addLiquidityContract);
    }

    function giveMaximalApproval() external onlyOwner {
        feeWallet.giveApproveForever(address(this));
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount >= 100, "Amount need be more");
        uint256 feeAmountForSwap = 0;
        uint256 feeAmountInToken = 0;
        uint256 feeAmountForBurn = 0;
        if (status && (to == pairAddress)) {
            //sell
            feeAmountForBurn = (amount * feeSizeBurn) / 1000; // 2.5%
            feeAmountInToken = (amount * 125) / 10000; // 1.25%
            feeAmountForSwap = (amount * 825) / 10000; // 8.25%
            super._burn(from, feeAmountForBurn); //2.5% burn
            super._transfer(from, address(addLiquidityContract), feeAmountInToken); //1.25% to liquidity contract
            super._transfer(from, address(this), feeAmountForSwap); //8.25% to swap
            _swapBack(balanceOf(address(this)));
        } else if (status && (from == pairAddress)) {
            //buy
            feeAmountForBurn = (amount * feeSizeBurn) / 1000;
            feeAmountInToken = (amount * 125) / 10000;
            feeAmountForSwap = (amount * 825) / 10000; // 8.25%
            super._burn(from, feeAmountForBurn); //2.5% burn
            super._transfer(from, address(addLiquidityContract), feeAmountInToken); //1.25% to liquidity contract
            super._transfer(from, address(this), feeAmountForSwap); //8.25% to swap
        }

        super._transfer(from, to, amount - feeAmountInToken - feeAmountForSwap - feeAmountForBurn);
    }

    function _getFee(bool _status) private {
        status = _status;
    }

    function _swapBack(uint256 amountToSwap) private {
        _getFee(false);
        router.swapExactTokensForTokens(amountToSwap, 0, path, address(feeWallet), block.timestamp);

        uint256 oldContractPart = (busd.balanceOf(address(feeWallet)) * 500) / 825;
        uint256 liquidityPart = (busd.balanceOf(address(feeWallet)) * 125) / 825;
        uint256 marketingPart = busd.balanceOf(address(feeWallet)) - oldContractPart - liquidityPart;

        busd.transferFrom(address(feeWallet), oldContract, oldContractPart);
        busd.transferFrom(address(feeWallet), marketing, marketingPart);
        busd.transferFrom(address(feeWallet), address(addLiquidityContract), liquidityPart);
        addLiquidityContract.addLiquidity(
            balanceOf(address(addLiquidityContract)),
            busd.balanceOf(address(addLiquidityContract)),
            feewallet,
            block.timestamp + 5
        );
        _getFee(true);
    }
}