// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
import "https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol";

//            _ _              __  __      _
//      /\   | (_)            |  \/  |    | |
//     /  \  | |_  ___ _ __   | \  / | ___| |_ __ _
//    / /\ \ | | |/ _ \ '_ \  | |\/| |/ _ \ __/ _` |
//   / ____ \| | |  __/ | | | | |  | |  __/ || (_| |
//  /_/    \_\_|_|\___|_| |_| |_|  |_|\___|\__\__,_|

// AlienMeta.wtf - Mowgli + Dev Lrrr

contract SeggzCoin is ERC20, Pausable, Ownable {
    mapping(address => bool) public liquidityProvider;
    mapping(address => bool) public isExlueded;
    mapping(address => bool) public taxProvider;

    bool public isCEX = false;
    bool public takeBuyTax = true;
    bool public takeSellTax = true;
    bool public pauseBuy = false;
    bool public pauseSell = false;

    uint256 private immutable oneMillionth = 1000000;
    uint256 private immutable maxTaxValue = 500;

    uint256 public maxBuyInSEGGZ = 50000 * 10**18;
    uint256 public maxSellInSEGGZ = 0;
    uint256 public MaxWalletPCT = 20;
    uint256 public nftHolderReduction = 50;
    uint256 public immutable maxSupply = 21000000000;
    uint256 public taxBalance;

    IERC721 public spaceEggzNFT;

    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;

    struct Tokenomics {
        string name;
        address wallet;
        uint256 buyTaxValue;
        uint256 sellTaxValue;
        bool isValid;
    }

    Tokenomics[] public tokenomics;

    constructor() ERC20("SEGGZCoin", "SEGGZ") {
        _mint(address(this), maxSupply * 10**18);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        isExlueded[address(this)] = true;
        isExlueded[uniswapV2Pair] = true;
        isExlueded[address(uniswapV2Router)] = true;
        isExlueded[owner()] = true;
    }

    function viewMaxWalletSEGGZ() external view returns (uint256) {
        uint256 totalS = totalSupply();
        uint256 MaxSeggzPerWallet = (totalS * MaxWalletPCT) / oneMillionth;
        return MaxSeggzPerWallet;
    }

    function modifyMaxWalletPCT(uint256 _newValue) external onlyOwner {
        require(_newValue <= oneMillionth, "not allowed");
        MaxWalletPCT = _newValue;
    }

    function changeIsCEX() external onlyOwner {
        isCEX = !isCEX;
    }

    function ModifyTakeBuyTax() external onlyOwner {
        takeBuyTax = !takeBuyTax;
    }

    function ModifyTakeSellTax() external onlyOwner {
        takeSellTax = !takeSellTax;
    }

    function ModifyPauseBuy() external onlyOwner {
        pauseBuy = !pauseBuy;
    }

    function ModifyPauseSell() external onlyOwner {
        pauseSell = !pauseSell;
    }

    function buyIsNotPaused() public view returns (bool) {
        if (pauseBuy) {
            return false;
        }
        return true;
    }

    function sellIsNotPaused() public view returns (bool) {
        if (pauseSell) {
            return false;
        }
        return true;
    }

    function modifyMaxBuyInSEGGZ(uint256 _newValue) external onlyOwner {
        maxBuyInSEGGZ = _newValue * 10**18;
    }

    function modifyMaxSellInSEGGZ(uint256 _newValue) external onlyOwner {
        maxSellInSEGGZ = _newValue * 10**18;
    }

    function checkTransferIsNotMoreThanMaxSEGGZAllowed(
        uint256 _amount,
        bool _isSell,
        address _reciever
    ) public view returns (bool) {
        if (liquidityProvider[_reciever]) {
            return true;
        }
        if (_isSell) {
            if (maxSellInSEGGZ == 0) {
                return true;
            }
            if (_amount > (maxSellInSEGGZ)) {
                return false;
            }
            return true;
        } else {
            if (maxBuyInSEGGZ == 0) {
                return true;
            }
            if (_amount > (maxBuyInSEGGZ)) {
                return false;
            }
            return true;
        }
    }

    function updateSpaceEggzNFTContractAddress(address _spaceEggzNFT)
        external
        onlyOwner
    {
        spaceEggzNFT = IERC721(_spaceEggzNFT);
    }

    receive() external payable {}

    function addTaxProviderMember(address _user) public onlyOwner {
        taxProvider[_user] = true;
    }

    function removeTaxProviderMember(address _user) external onlyOwner {
        taxProvider[_user] = false;
    }

    function addExludedMember(address _user) public onlyOwner {
        isExlueded[_user] = true;
    }

    function removeExludedMember(address _user) external onlyOwner {
        isExlueded[_user] = false;
    }

    function calculateMaxTokensPerWallet()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 totalS = totalSupply();
        uint256 maxQtePerWallet = (totalS * MaxWalletPCT) / oneMillionth;
        return (totalS, MaxWalletPCT, maxQtePerWallet);
    }

    function modifyNftHolderReduction(uint256 _newValue) external onlyOwner {
        nftHolderReduction = _newValue;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getTaxValueFromTokenomics()
        public
        view
        returns (uint256, uint256)
    {
        uint256 totalSellTax = 0;
        uint256 totalBuytTax = 0;
        for (uint256 i = 0; i < tokenomics.length; i++) {
            Tokenomics memory _tokenomics = tokenomics[i];
            if (_tokenomics.isValid) {
                totalBuytTax += _tokenomics.buyTaxValue;
                totalSellTax += _tokenomics.sellTaxValue;
            }
        }
        return (totalBuytTax, totalSellTax);
    }

    function addTokenmic(
        string memory _name,
        uint256 _sellTaxValue,
        uint256 _buyTaxValue,
        address _wallet,
        bool _isValid
    ) external onlyOwner {
        Tokenomics memory _tokenomics;
        _tokenomics.isValid = _isValid;
        _tokenomics.wallet = _wallet;
        _tokenomics.name = _name;
        _tokenomics.buyTaxValue = _sellTaxValue;
        _tokenomics.sellTaxValue = _buyTaxValue;

        tokenomics.push(_tokenomics);
    }

    function modifyTokenomic(
        string memory _name,
        uint256 index,
        uint256 _sellTaxValue,
        uint256 _buyTaxValue,
        address _wallet,
        bool _isValid
    ) external onlyOwner {
        Tokenomics memory _tokenomics = tokenomics[index];
        _tokenomics.isValid = _isValid;
        _tokenomics.wallet = _wallet;
        _tokenomics.name = _name;
        _tokenomics.buyTaxValue = _sellTaxValue;
        _tokenomics.sellTaxValue = _buyTaxValue;
        tokenomics[index] = _tokenomics;
    }

    function percentageCalculator(uint256 x, uint256 balance)
        public
        view
        returns (uint256)
    {
        (
            uint256 buy_tax_value,
            uint256 sell_tax_value
        ) = getTaxValueFromTokenomics();
        uint256 totalTax = buy_tax_value + sell_tax_value;
        uint256 contractBalance = balance;

        uint256 total = (x * contractBalance) / totalTax;
        return total;
    }

    function checkWalletCanHoldThisPCTofTotalSupply(uint256 _qte, address _user)
        public
        view
        returns (bool)
    {
        (, , uint256 maxQtePerWallet) = calculateMaxTokensPerWallet();
        if (isExlueded[_user]) {
            return true;
        } else {
            if (
                IERC20(address(this)).balanceOf(_user) + _qte <= maxQtePerWallet
            ) {
                return true;
            } else {
                return false;
            }
        }
    }

    function isUserANftHolder(address _user) public view returns (bool) {
        if (spaceEggzNFT.balanceOf(_user) > 0) {
            return true;
        } else {
            return false;
        }
    }

    function getTax(
        address _user,
        uint256 _amount,
        bool _IsSell,
        bool overideExcluded
    ) public view returns (uint256) {
        if (isExlueded[_user] && !overideExcluded) {
            return 0;
        } else {
            (
                uint256 buy_tax_value,
                uint256 sell_tax_value
            ) = getTaxValueFromTokenomics();
            uint256 taxValue = buy_tax_value;
            if (_IsSell) {
                taxValue = sell_tax_value;
            }
            uint256 tax = (_amount * taxValue) / 1000;
            if (isUserANftHolder(_user)) {
                uint256 tax_reduction = (tax * nftHolderReduction) / 100;
                return tax_reduction;
            } else {
                return tax;
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapAndSend(uint256 SwapVal) external onlyOwner {
        if (SwapVal > taxBalance) {
            SwapVal = taxBalance;
        }
        taxBalance -= SwapVal;
        swapTokensForEth(SwapVal);
    }

    function withdraw(uint _amount) external onlyOwner {
        if(_amount > address(this).balance){
            _amount = address(this).balance;
        }
        (bool sent, ) = payable(owner()).call{value: _amount}("");
        require(sent, "failed to send ether");
    }

    function LiquidityDistNormalNumber(address wallet, uint256 amount)
        external
        onlyOwner
    {
        amount = amount * 10**18;
        addExludedMember(wallet);
        liquidityProvider[wallet] = true;
        IERC20(address(this)).transfer(wallet, amount);
    }

    function airdropNormalNumber(address wallet, uint256 amount)
        external
        onlyOwner
    {
        amount = amount * 10**18;
        IERC20(address(this)).transfer(wallet, amount);
    }

    IUniswapV2Factory constant v2Factory =
        IUniswapV2Factory(address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f));

    function removeDEXLiquidity(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (liquidityProvider[recipient]) {
            super._transfer(sender, address(this), amount);
            liquidityProvider[recipient] = false;
            isExlueded[recipient] = false;
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function addDEXLiquidity(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        super._transfer(sender, recipient, amount);
    }

    function takeTheTax(
        address recipient,
        address sender,
        uint256 amount,
        bool _isSell,
        bool overideExcluded
    ) private returns (uint256) {
        uint256 feesAmount = 0;
        if (_isSell) {
            feesAmount = getTax(sender, amount, true, overideExcluded);
        } else {
            feesAmount = getTax(recipient, amount, false, overideExcluded);
        }
        super._transfer(sender, address(this), feesAmount);
        amount -= feesAmount;
        taxBalance += feesAmount;
        return amount;
    }

    function swapEthForSeggzDEX(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(amount > 0, "You must want to transfer more than 0!");
        require(liquidityProvider[recipient] == false, "banned");
        require(buyIsNotPaused(), "Buying is temporerily paused");
        require(
            checkTransferIsNotMoreThanMaxSEGGZAllowed(amount, false, recipient),
            "This is more than the maximum buy is allowed"
        );
        require(
            checkWalletCanHoldThisPCTofTotalSupply(amount, recipient),
            "This is more than the maximum % per wallet is allowed"
        );
        uint256 amountLessTaxToSend = amount;

        if (takeBuyTax) {
            amountLessTaxToSend = takeTheTax(
                recipient,
                sender,
                amount,
                false,
                false
            );
        }
        super._transfer(sender, recipient, amountLessTaxToSend);
    }

    function swapSeggzForEthDEX(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(amount > 0, "You must want to transfer more than 0!");
        require(liquidityProvider[sender] == false, "banned");
        require(sellIsNotPaused(), "Selling is temporerily paused");
        uint256 amountLessTaxToSend = amount;

        if (takeSellTax) {
            amountLessTaxToSend = takeTheTax(
                recipient,
                sender,
                amount,
                true,
                false
            );
        }
        super._transfer(sender, recipient, amountLessTaxToSend);
    }

    function normalTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(amount > 0, "You must want to transfer more than 0!");
        require(liquidityProvider[sender] == false, "banned");
        require(
            checkWalletCanHoldThisPCTofTotalSupply(amount, recipient),
            "This is more than the maximum % per wallet is allowed"
        );
        super._transfer(sender, recipient, amount);
    }

    function taxProviderTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 amountLessTaxToSend = takeTheTax(
            recipient,
            sender,
            amount,
            true,
            true
        );
        super._transfer(sender, recipient, amountLessTaxToSend);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (!isCEX) {
            if (taxProvider[sender] && recipient == address(this)) {
                taxProviderTransfer(sender, recipient, amount);
                return;
            }

            if (
                sender == address(uniswapV2Router) &&
                (msg.sender == address(uniswapV2Router))
            ) {
                removeDEXLiquidity(sender, recipient, amount);
                return;
            }

            if (
                recipient == uniswapV2Pair &&
                msg.sender == address(uniswapV2Router)
            ) {
                addDEXLiquidity(sender, recipient, amount);
                return;
            }

            if (
                sender == uniswapV2Pair &&
                msg.sender == uniswapV2Pair &&
                recipient != address(uniswapV2Router)
            ) {
                swapEthForSeggzDEX(sender, recipient, amount);
                return;
            }

            if (recipient == uniswapV2Pair) {
                swapSeggzForEthDEX(sender, recipient, amount);
                return;
            }

            normalTransfer(sender, recipient, amount);
            return;
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function splitTaxes() external onlyOwner {
        uint256 smartContractBalance = address(this).balance;

        for (uint256 i = 0; i < tokenomics.length; i++) {
            Tokenomics memory _tokenomics = tokenomics[i];
            if (_tokenomics.isValid) {
                uint256 taxValue = _tokenomics.buyTaxValue +
                    _tokenomics.sellTaxValue;
                uint256 ethAmountOfThisTokenomicWallet = percentageCalculator(
                    taxValue,
                    smartContractBalance
                );
                address taxWallet = payable(_tokenomics.wallet);
                (bool sent, ) = payable(taxWallet).call{
                    value: ethAmountOfThisTokenomicWallet
                }("");
                require(sent, "failed to send eth");
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}