// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./deps/IUniswapV2Router02.sol";
import "./deps/IUniswapV2Pair.sol";
import "./deps/IUniswapV2Factory.sol";


contract Chaos is 
    ERC20, 
    Ownable, 
    Pausable
    {

    using SafeMath for uint256;

    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public treasuryWallet;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public tax;
    uint256 public buyTax;
    uint256 public sellTax;

    uint256 public bDaoTax;
    uint256 public bTeamTax;
    uint256 public bLiquidityTax;

    uint256 public sDaoTax;
    uint256 public sTeamTax;
    uint256 public sLiquidityTax;

    uint256 public maxWalletSize;

    mapping(address => bool) public whitelistedAddress;

    event WhitelistAddressUpdated(address whitelistAccount, bool value);
    event TaxUpdated(uint256 taxAmount);
    event TaxPaid(uint256 taxAmount);

        constructor(        
        address initialHolder,
        uint256 initialSupply,
        uint256[] memory bTax,
        uint256[] memory sTax
        ) ERC20("CHAOS DAO", "CHAOS") {

        _mint(initialHolder, initialSupply);

        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            USDT
        );

        bDaoTax = bTax[0];
        bTeamTax = bTax[1];
        bLiquidityTax = bTax[2];

        sDaoTax = sTax[0];
        sTeamTax = sTax[1];
        sLiquidityTax = sTax[2];
        
        buyTax = bDaoTax.add(bTeamTax).add(bLiquidityTax);
        sellTax = sDaoTax.add(sTeamTax).add(sLiquidityTax);
        /// 5% of the initial supply
        maxWalletSize = initialSupply.mul(2).div(100);

    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    function _mint(address to, uint256 amount)
        internal
        override
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override
    {
        super._burn(account, amount);
    }

    function setWhitelistAddress(address _whitelist, bool _status) external onlyOwner{
        require(_whitelist != address(0), "setWhitelistAddress: Zero address");
        whitelistedAddress[_whitelist] = _status;
        emit WhitelistAddressUpdated(_whitelist, _status);
    }


    function setMaxWallet(uint256 amount) external onlyOwner {
        maxWalletSize = amount;
    }

    function setTreasuryAddress(address newAddr) external onlyOwner {
        treasuryWallet = newAddr;
    }
    
    function setUniswapPair(address pairAddress) external onlyOwner {
        require(pairAddress != address(0), "ERROR");
        uniswapV2Pair = pairAddress;
    }
    
    function setUniswapRouter(address routerAddress) external onlyOwner {
        require(routerAddress != address(0), "ERROR");
        uniswapV2Router = IUniswapV2Router02(routerAddress);
    }

    function setBuyTax(uint256 daoTax, uint256 teamTax, uint256 liquidityTax) external onlyOwner{
        bDaoTax = daoTax;
        bTeamTax = teamTax;
        bLiquidityTax = liquidityTax;
        buyTax = bDaoTax.add(bTeamTax).add(bLiquidityTax);
        emit TaxUpdated(buyTax);
    }

    function setSellTax(uint256 daoTax, uint256 teamTax, uint256 liquidityTax) external onlyOwner{
        sDaoTax = daoTax;
        sTeamTax = teamTax;
        sLiquidityTax = liquidityTax;
        sellTax = sDaoTax.add(sTeamTax).add(sLiquidityTax);
        emit TaxUpdated(sellTax);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {    
        uint256 taxAmount;
        if(whitelistedAddress[sender] || whitelistedAddress[recipient]){
            super._transfer(sender,recipient,amount);
        } else {
            require(
            balanceOf(recipient).add(amount) <= maxWalletSize,
            "MAX WALLET SIZE EXCEEDED"
            );
            if (recipient == uniswapV2Pair){
                taxAmount = takeTransactionTax(sender, amount, true);
            }
            else if (sender == uniswapV2Pair){
                taxAmount = takeTransactionTax(sender, amount, false);
            }
            super._transfer(sender, recipient, amount.sub(taxAmount));
        }
    }


    function takeTransactionTax(address from, uint256 amountToken, bool sell) internal returns(uint256) {
        uint256 daoTax;
        uint256 teamTax;
        uint256 liquidityTax; 
        if (sell) {
            daoTax = amountToken.mul(sDaoTax).div(100);
            teamTax = amountToken.mul(sTeamTax).div(100);
            liquidityTax = amountToken.mul(sLiquidityTax).div(100);
        }
        else {
            daoTax = amountToken.mul(bDaoTax).div(100);
            teamTax = amountToken.mul(bTeamTax).div(100);
            liquidityTax = amountToken.mul(bLiquidityTax).div(100);
        }

        uint256 totalPaid = daoTax.add(teamTax).add(liquidityTax);
        super._transfer(from, treasuryWallet, totalPaid);

        emit TaxPaid(totalPaid);
        return totalPaid;
    }
}