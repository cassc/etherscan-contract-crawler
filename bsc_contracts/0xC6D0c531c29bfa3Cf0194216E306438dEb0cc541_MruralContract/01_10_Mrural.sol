/**
 * Develop by CPTRedHawk
 * @ Esse contrato Foi desenvolvido por https://t.me/redhawknfts
 * Caso queira ter uma plataforma similar, gentileza chamar no Telegram!
 * SPDX-License-Identifier: MIT
 * Entrega teu caminho ao senhor, e tudo ele o fará! Salmos 37
 */
pragma solidity ^0.8.17;

import "./interfaceIBEP20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./interfaceIUniswapV2Factory.sol";
import "./interfaceIUniswapV2Pair.sol";
import "./interfaceIUniswapV2Router01.sol";
import "./interfaceIUniswapV2Router02.sol";

contract MruralContract is IBEP20, Ownable  {
    using SafeMath for uint256;
    using Address for address;
    /*
    ---------------------------------
    -       Endereços               -
    ---------------------------------
    */
    address public burnAddress; // Endreço de Burn
    address private addressDistribute; // Distribuidor de Taxas
    IUniswapV2Router02 public  uniswapV2Router; // Endereço Router
    address public  uniswapV2Pair; // Par MRURAL/BNB
    /*
    ---------------------------------
    -         Modifier              -
    ---------------------------------
    */
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    modifier blackList {
        blackUser = true;
        _;
        blackUser = false;
    }
    /*
    ---------------------------------
    -       Mapeamento              -
    ---------------------------------
    */
    mapping (address => uint256) private _balance; // Saldo do Usuario
    mapping (address => mapping(address => uint256)) private _allowances; // Subsidio
    mapping (address => bool) public isExcludedFromFee; // True não paga Taxa
    mapping (address => bool) public automatedMarketMakerPairs; // Armazena o Pair
    mapping (address => bool) public _isBlackListAddress; // Adiciona na Lista Negra

    /*
    ---------------------------------
    -       Booleano                -
    ---------------------------------
    */
    bool private inSwapAndLiquify;
    bool private blackUser;
    bool public tradingOpen = true;
    bool private swapAndLiquifyEnabled = true;
    bool private blackEnabled = true;
    bool private isSendToken = true;
    bool private startSwap = false;
    /*
    ---------------------------------
    -       String                  -
    ---------------------------------
    */
    string private _name = "Mrural";
    string private _symbol =  "MRU";
    /*
    ---------------------------------
    -       Numbers                 -
    ---------------------------------
    */
    uint256 public buyTax = 12; // Taxa de Compra
    uint256 public sellTax = 12; // Taxa de Venda
    uint256 private _previousBuyTax = buyTax; // Aramazena as Taxas de Compra
    uint256 private _previousSellTax = sellTax; // Aramazena as Taxas de Venda
    uint8 private _decimals = 18; //  Decimais
    uint8 public cooldownTimerInterval = 5; // Tempo de espera entre compra e venda
    uint256 private _decimalPlace = 10 ** _decimals; // Casas decimais 10 ** 18
    uint256 private _tTotal = 500000000 * _decimalPlace;
    uint256 public tokenLiquidityPercent = 10; // 10% Dos Tokens do Contrato vai para Liquidez
    uint256 public numberOfTokensToSwapToLiquidity = 1000 * 10 ** 18; // Vende Tokens do ContratO
    /*
    ---------------------------------
    -       Construtor              -
    ---------------------------------
    */
    constructor () {
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // PancakeSwap Router Testnet
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PancakeSwap Router Mainnet
        address pairCreated = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH()); // Gera o Par MRURAL/BNB
        uniswapV2Router = _uniswapV2Router; // Armazena Rota
        uniswapV2Pair = pairCreated; // Armazena Par
        addressDistribute = owner(); // Gera o Endereço Distribuidor de Taxas
        _balance[owner()] = _tTotal; // Armazena Saldo de Mint para Owner
        isExcludedFromFee[owner()] = true; // Owner Livre de Taxas
        isExcludedFromFee[address(this)] = true; // Contrato Livre de Taxas
        isExcludedFromFee[addressDistribute] = true; // Distribuidor Livre de Taxas]
        _isBlackListAddress[uniswapV2Pair] = true; // Adiciona Pair na Blacklist
        burnAddress = address(0); // Define Burn Address
        _setAutomatedMarketMakerPair(pairCreated, true); // Pair é o Automatizador de Transações
        _approve(owner(), address(uniswapV2Router), ~uint256(0)); // Aprova Tokens para Add Liquidez
        emit Transfer(address(0), owner(), _tTotal); // Emite um Evento
    }
    /*
    ---------------------------------
    -         Eventos               -
    ---------------------------------
    */
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event LiquidityAdded(uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity);
    event UpdatedBlackList(address indexed account, bool isExcluded);
    event SentBNB(address usr, uint256 amount);
    /*
    ---------------------------------
    -        receive                -
    ---------------------------------
    */
    receive() external payable {}
    /*
    ---------------------------------
    -         View                  -
    ---------------------------------
    */
    function name() public view override returns(string memory) { return _name; } // Nome do Token
    function symbol() public view override returns(string memory) { return _symbol; } // Simbolo do Token
    function decimals() public view override returns(uint8) { return _decimals; } // Decimais
    function totalSupply() public view override returns(uint256) { return _tTotal; } // Supply Total
    function balanceOf(address account) public view override returns(uint256) { return _balance[account]; } // Retorna o Saldo em Carteira
    function allowance(address owner, address spender) public view override returns(uint256) { return _allowances[owner][spender]; } // Subsidio Restante
    /*
    ---------------------------------
    -      Public/External          -
    ---------------------------------
    */
    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transfer(address to, uint256 amount) public override returns(bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public override returns(bool) {
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
        _approve(_msgSender(), spender, allowance(_msgSender(), spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
        uint256 currentAllowance = allowance(_msgSender(), spender);
        require(currentAllowance >= subtractedValue, "MRURAL: reducao do subsidio abaixo de zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    /*
    ---------------------------------
    -      Private/Internal         -
    ---------------------------------
    */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "MRURAL:Owner nao pode ser Address 0");
        require(spender != address(0), "MRURAL:Spender nao pode ser Address 0");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if(currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "MRURAL: subsidio insuficiente");
            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function _beforeTokenTransfer( address from, address to, uint256 amount ) internal virtual {}
    function _afterTokenTransfer( address from, address to, uint256 amount ) internal virtual {}
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "MRural:From nao pode ser Address 0");
        require(amount > 0, "MRural: Montante precisa ser maior do que 0");

        require(tradingOpen, "MRural: Trading precisa estar ativo");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balance[from];
        require(fromBalance >= amount,"MRural: o valor da transferencia excede o saldo" );
        _balance[from] = fromBalance - amount; 
        
 

        if(blackEnabled && !blackUser) {
           require(!_isBlackFrom(from) && !_isBlackTo(to), "MRural:Voce esta na Lista Negra");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        if (!automatedMarketMakerPairs[from] && automatedMarketMakerPairs[to] && startSwap) {
            liquify( contractTokenBalance, from );
        }

        

        bool takeFee = true;

        if(isExcludedFromFee[from] || isExcludedFromFee[to]){
            takeFee = false;
        }

        if(!takeFee) removeAllFee(); // Remove todas as Taxa
            uint256 fees; // Define taxa de Transferencia do Pair[from] - Pair[to]
            

            if(!automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]) {
                fees = amount.mul(sellTax).div(100); // Define taxa de Venda
            }

            if(automatedMarketMakerPairs[from]) {
                fees = amount.mul(buyTax).div(100); // Define taxa de Compra
            }
            else if(automatedMarketMakerPairs[to]) {
                fees = amount.mul(sellTax).div(100); // Define taxa de Compra
            }


            if(fees != 0) {
                amount = amount.sub(fees);
                _balance[address(this)] += fees;
                emit Transfer(from, address(this), fees); // Emite um Evento de Envio de Taxas
            }
            _balance[to] += amount; // Envia Saldo para To
        
            
            emit Transfer(from, to, amount); // Emite Evento de Envio de Amount
            _afterTokenTransfer(from, to, amount);

        if(!takeFee) restoreAllFee(); // Retorna todas as Taxa
    } 

    function removeAllFee() private {
        if(buyTax == 0 || sellTax == 0) return;
        _previousBuyTax = buyTax; // Armazena Taxa Anterior
        _previousSellTax = sellTax; // Armazena Taxa Anterior
        buyTax = 0; // Taxa 0
        sellTax = 0; // Taxa 0
    }
    function restoreAllFee() private {
        buyTax = _previousBuyTax; // Restaura Taxas
        sellTax = _previousSellTax; // Restaura Taxas
    }  
    function liquify(uint256 contractTokenBalance, address sender) internal {

        if (contractTokenBalance >= numberOfTokensToSwapToLiquidity) contractTokenBalance = numberOfTokensToSwapToLiquidity; // Define se a Quantidade de Tokens para
        
        bool isOverRequiredTokenBalance = ( contractTokenBalance >= numberOfTokensToSwapToLiquidity ); // Booleano
        
        if ( isOverRequiredTokenBalance && swapAndLiquifyEnabled && !inSwapAndLiquify && (!automatedMarketMakerPairs[sender]) ) {
            uint256 tokenLiquidity = contractTokenBalance.mul(tokenLiquidityPercent).div(100); // Quantidade de Tokens que vai para Liquidez
            uint256 toSwapBNB = contractTokenBalance.sub(tokenLiquidity); // Quantidade de Tokens para Venda
            _swapAndLiquify(tokenLiquidity); // Adiciona Liquidez
            _sendBNBToContract(toSwapBNB); // Troca Tokens por BNB
        }
    }
    function _swapAndLiquify(uint256 amount) private lockTheSwap {
        uint256 half = amount.div(2); // Divide para Adicionar Liquidez
        uint256 otherHalf = amount.sub(half); // Divide para Adicionar Liquidez
        uint256 initialBalance = address(this).balance; // Armazena o Saldo Inicial em BNB
        _swapTokensForEth(half); // Efetua a troca de Token por BNB
        uint256 newBalance = address(this).balance.sub(initialBalance); // Saldo atual em BNB - Saldo Antigo
        _addLiquidity(otherHalf, newBalance); // Adiciona Liquidez
        emit SwapAndLiquify(half, newBalance, otherHalf); // Emite Evento de Swap
    }
    function _sendBNBToContract(uint256 tAmount) private lockTheSwap {
        _swapTokensForEth(tAmount); // Vende os Tokens por BNB e envia para o Contrato
        uint256 bAmount = address(this).balance;
        if(isSendToken) {
            if(bAmount > 0) {
                (bool sent, ) = addressDistribute.call{value: address(this).balance}("");
                if(sent) {
                    emit SentBNB(addressDistribute, bAmount);
                    bAmount = 0;
                }
            }
        }
    }
    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2); // Path Memory para inicia a venda dos Tokens
        path[0] = address(this); // Endereço do Contrato
        path[1] = uniswapV2Router.WETH(); // Par de Troca (BNB)
        _approve(address(this), address(uniswapV2Router), tokenAmount); // Aprova os Tokens para Troca
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, // Saldo para Swap
            0, // Amount BNB
            path, // Path [address(this), uniswapV2Router.WETH()]
            address(this), // Endereço de Taxa
            block.timestamp // Timestamp
        );
    }
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount, // Saldo para Liquidez
            0, // Slippage 0
            0, // Slippage 0
            owner(), // Owner Adiciona Liquidez
            block.timestamp // Timestamp
        );
        emit LiquidityAdded(tokenAmountSent, ethAmountSent, liquidity); // Emite Evento de Liquidez
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "MRural: O par de AutomatedMarketMakerPair ja esta definido para esse valor");
        automatedMarketMakerPairs[pair] = value; // Booleano
        emit SetAutomatedMarketMakerPair(pair, value); // Emite um Evento para um Novo Automatizador de Trocas
    }
    function _setRouterAddress(address router) private {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router); // PancakeSwap Router Testnet
        address pairCreated = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH()); // Gera o Par MRural/BNB
        uniswapV2Router = _uniswapV2Router; // Armazena Rota
        uniswapV2Pair = pairCreated; // Armazena Par
        _setAutomatedMarketMakerPair(uniswapV2Pair, true); // Armazena o novo Par como o Automatizador de Trocas
    }
    function _isBlackFrom(address from) private blackList returns(bool) {
       return _isBlackListAddress[from]; // Verifica se From esta na Blacklist
    }
    function _isBlackTo(address to) private blackList returns(bool) {
       return _isBlackListAddress[to]; // Verifica se To esta na Blacklist
    }
    function setExcludedAddress(address account, bool isVerify) external onlyOwner {
        isExcludedFromFee[account] = isVerify; // Define se está nas Taxas ou não
    }
    function setIsSwap(bool isTrue) external onlyOwner {
        swapAndLiquifyEnabled = isTrue; // Ativa e Desativa o Swap
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled); // Emite Evento de Swap Ativo/Inativo
    }
    function setSwapAmount(uint256 tAmount) external onlyOwner {
        numberOfTokensToSwapToLiquidity = tAmount * 10 ** 18; // Define a quantidade de Tokens que o Contrato vai Vender
    }
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "MRural:uniswapV2Pair nao pode ser removido de AutomatedMarketMakerPair");
        _setAutomatedMarketMakerPair(pair, value); // Define um Novo Automatizador de Trocas
    }
    function setWalletMarketing(address _addressDistribute) external onlyOwner {
        addressDistribute = _addressDistribute; // Define Endereço de Taxas
    }
    function setRouter(address router) external onlyOwner {
        _setRouterAddress(router); // Define uma Nova Rota (Caso Pancakeswap migre para a RouterV3 e adiante)
    }
    function setTaxFee(uint256 _buyTax, uint256 _sellTax, uint256 _tokenLiquidityPercent) external onlyOwner {
        buyTax = _buyTax; // Taxa de Compra
        sellTax = _sellTax; // Taxa de Venda
        tokenLiquidityPercent = _tokenLiquidityPercent; // Tokens para Liquidez
    }
    function emergencialWithdrawFromContractBNB(address payable recipient) external onlyOwner {
        uint256 amount = address(this).balance; 
        if(amount > 0) {
            (bool sent, ) = recipient.call{value: amount}("");
            if(sent) {
                emit SentBNB(addressDistribute, amount);
            }
            amount = 0;
        }
    }
    function updateBlackList(address account, bool state) external onlyOwner {
        _isBlackListAddress[account] = state; // Adiciona ou Remove da Blacklist
        emit UpdatedBlackList(account, state); // Emite Evento de BlackList
    }
    function setBlackList(bool _blackEnabled) external onlyOwner {
        blackEnabled = _blackEnabled; // Ativa Blacklist
    }
    function initTrade(bool _tradingOpen) external onlyOwner {
        tradingOpen = _tradingOpen; // Inicia o Trade do Contrato
    }
    function activeSendDividends(bool _isSendToken) external onlyOwner {
        isSendToken = _isSendToken;
    }
    function burn(uint256 bAmount) external onlyOwner {
        _transfer(_msgSender(), burnAddress, bAmount);
    }
    function withdrawMrural(uint256 rAmount) external onlyOwner {
        _transfer(address(this), _msgSender(), rAmount);
    }
    function initSwapLiquify(bool _startSwap) external onlyOwner {
        startSwap = _startSwap;
    }
}
