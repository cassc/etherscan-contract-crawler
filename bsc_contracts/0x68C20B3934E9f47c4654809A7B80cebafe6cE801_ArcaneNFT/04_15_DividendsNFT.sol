// * SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./SafeMath.sol"; 
import "./Ownable.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./interfaceIBEP20.sol";
import "./BEP20.sol";




contract DividendsPaying is BEP20, Ownable {

    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;
    

    // Magnitude consegue pagar a quantidade de Recompensa mesmo que seja um Saldo Pequeno
    uint256  private  magnitude = 2**128;
    // Multiplicador de Dividendos
    uint256 private magnifiedDividendPerShare;
    // Minimo para Distribuição
    uint256 public minimumDistribute;
    // Distribuição Total
    uint256 public totalDividendsDistributed;
    // Decimal
    uint8 private _decimals = 18;
    // Nome 
    string private _name = "Arcane Dividends";
    // Symbolo
    string private _symbol = "ARCD";
    // Utilizado para Evitar Bugs, Gera um grande Numero (magnifiedDividendCorrections / magnitude)
    mapping(address => int256) private magnifiedDividendCorrections;
    // Armazena Saldo de Retirada dos Dividendos
    mapping(address => uint256) private withdrawnDividends;
    // Tempo de Claim
    mapping(address => uint256) private claimWait;
    // Exclui dos Dividendos
    mapping (address => bool) public excludeDividends; 
    // last claim
    mapping (address => uint256) public lastClaimTimes;
    constructor()  BEP20(_name, _symbol, _decimals) {
        minimumDistribute = 100 * 10**18;
    }

    // Eventos
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
    receive() external payable {
        distributeDividends();
    }
        function distributeDividends() public  payable {
        if(totalSupply() > 0) {
            if(msg.value > 0) {
                // Faz a soma dos Dividendos
                magnifiedDividendPerShare += (msg.value).mul(magnitude).div(totalSupply());
                // Pega o Total de Dividendos já distribuidos
                totalDividendsDistributed += msg.value;
            }
        }
    }
    /*=== Public View ===*/
    function withdrawableDividendOf(address owner) public view returns(uint256) {
        return accumulativeDividendOf(owner).sub(withdrawnDividends[owner]);
    }
    function accumulativeDividendOf(address owner) public view returns(uint256) {
        // Estrutura owner
        uint256 balance = balanceOf(owner);
        return magnifiedDividendPerShare.mul(balance).toInt256Safe().add(magnifiedDividendCorrections[owner]).toUint256Safe().div(magnitude);
    }
    
    /*=== Private/Internal ===*/
    function _transfer(address , address , uint256 ) internal virtual override  {
        require(false, "Nao pode Transfer");
    }
    function _mint(address account, uint256 amount) internal override  {
        super._mint(account, amount);
  
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].sub((magnifiedDividendPerShare.mul(amount)).toInt256Safe());
         emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
 
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].sub((magnifiedDividendPerShare.mul(amount)).toInt256Safe());
        emit Transfer(account, address(0), amount);
    }
    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);
        if(newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance <= currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }

    function withdrawMyReward(address user) public  {
        uint256 balance =  withdrawableDividendOf(user);
        if(balance > 0) {
            withdrawnDividends[user] += balance;
            (bool success, ) = user.call{ value: balance }("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }
    /*=== Funções Administrativas ===*/
    function setBalance(address payable account, uint256 newBalance) public onlyOwner {
        if(excludeDividends[account]) {
            return;
        }
        if(newBalance >= minimumDistribute) {
            _setBalance(account, newBalance);
        }
        else {
            _setBalance(account, 0);
        }

       
    }
    function sendValue(address account) public payable onlyOwner {
        uint256 send = msg.value;
        if(send > 0) {
            (bool success, ) = account.call{ value: send }("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }
    function excludeFromDividends(address account, bool isTrue) external onlyOwner {
        require(!excludeDividends[account], "Ja excluido dos Dividendos");
        excludeDividends[account] = isTrue;
        _setBalance(account, 0);
    }
    function getLostBNB(address admin)external onlyOwner {
        uint256 balance = address(this).balance;
        if(balance > 0) {
            (bool success, ) = admin.call{ value: balance }("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }
    

}
    
