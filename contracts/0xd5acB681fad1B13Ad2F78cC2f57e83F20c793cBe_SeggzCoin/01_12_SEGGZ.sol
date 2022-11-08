// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

//            _ _              __  __      _
//      /\   | (_)            |  \/  |    | |
//     /  \  | |_  ___ _ __   | \  / | ___| |_ __ _
//    / /\ \ | | |/ _ \ '_ \  | |\/| |/ _ \ __/ _` |
//   / ____ \| | |  __/ | | | | |  | |  __/ || (_| |
//  /_/    \_\_|_|\___|_| |_| |_|  |_|\___|\__\__,_|

// AlienMeta.wtf - Mowgli + Dev Lrrr

contract SeggzCoin is ERC20, Pausable, Ownable {
    bool public takeTax = true;
    uint256 private immutable maxTaxValue = 500;
    uint256 public MaxWalletPCT = 2;
    uint256 public nftHolderReduction = 50;
    uint256 public maxSupply = 21000000000;
    uint256 public taxBalance;
    bool public requireValidBalanceSwitch = true;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    IERC721 public spaceEggzNFT;

    mapping(address => bool) public isExlueded;

    struct Tokenomics {
        string name;
        address wallet;
        uint256 buyTaxValue;
        uint256 sellTaxValue;
        bool isValid;
    }
    Tokenomics[] public tokenomics;

    constructor(address _spaceEggzNFT) ERC20("SEGGZCoin", "SEGGZ") {
        _mint(address(this), maxSupply * 10**18);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        spaceEggzNFT = IERC721(_spaceEggzNFT);
        isExlueded[address(this)] = true;
        isExlueded[uniswapV2Pair] = true;
        isExlueded[address(uniswapV2Router)] = true;
    }

    receive() external payable {}

    function addExludedMember(address _user) external onlyOwner {
        isExlueded[_user] = true;
    }

    function removeExludedMember(address _user) external onlyOwner {
        isExlueded[_user] = false;
    }

    function modifyRequireValidBalanceSwitch(bool _newValue)
        external
        onlyOwner
    {
        requireValidBalanceSwitch = _newValue;
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
        uint256 maxQtePerWallet = (totalS * MaxWalletPCT) / 100000;
        return (totalS, MaxWalletPCT, maxQtePerWallet);
    }

    function modifyMaxWalletPCT(uint256 _newValue) external onlyOwner {
        require(_newValue <= 10000, "not allowed");
        MaxWalletPCT = _newValue;
    }

    function modifyNftHolderReduction(uint256 _newValue) external onlyOwner {
        nftHolderReduction = _newValue;
    }

    function changeTakeTax() external onlyOwner {
        takeTax = !takeTax;
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

    function modifyBuyTokenomic(
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

    function checkBalanceIfValid(uint256 _qte, address _user)
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
        bool _IsSell
    ) public view returns (uint256) {
        if (isExlueded[_user]) {
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

    function LiquidityDist(address wallet, uint256 amount) external onlyOwner {
        IERC20(address(this)).transfer(wallet, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(amount > 0, "not allowed amount ");
        if (takeTax) {
            if (msg.sender != address(uniswapV2Router)) {
                if (sender == uniswapV2Pair) {
                    if (requireValidBalanceSwitch) {
                        require(
                            checkBalanceIfValid(amount, recipient),
                            "user can't receive this amount"
                        );
                    }
                    uint256 feesAmount = getTax(recipient, amount, false);
                    super._transfer(sender, address(this), feesAmount);
                    amount -= feesAmount;
                    taxBalance += feesAmount;
                } else {
                    uint256 feesAmount = getTax(sender, amount, true);
                    super._transfer(sender, address(this), feesAmount);
                    amount -= feesAmount;
                    taxBalance += feesAmount;
                }
            }
        }

        super._transfer(sender, recipient, amount);
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