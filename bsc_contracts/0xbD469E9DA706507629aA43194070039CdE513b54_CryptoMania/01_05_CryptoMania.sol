// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoWorldContract.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CryptoMania is Ownable, ReentrancyGuard {
    address cryptoWorldContract;
    uint256 ultimaCartelaVendida;
    uint256 valorCartela;
    bool jogoIniciado;
    uint256 rodada;
    mapping(address => uint256) valoresAcumulados;
    uint256 totalDoContratoParaSaque;
    uint256 totalDoContratoParaDistribuicao;
    uint256 totalDoadoParaContratoPrincipal;
    uint256 totalDistribuido;

    event comprouCartela(address owner, uint256 id, uint256 rodada);

    constructor(address cryptoWorldContract_, uint256 valorCartela_)
        ReentrancyGuard()
    {
        cryptoWorldContract = cryptoWorldContract_;
        ultimaCartelaVendida = 0;
        valorCartela = valorCartela_;
        jogoIniciado = false;
        rodada = 0;
    }

    function renounceOwnership() public virtual override onlyOwner {
        revert("RenounceOwnership: property cannot be surrendered");
    }

    function comprarCartela() public payable {
        require(msg.value == valorCartela, "Valor insuficiente");
        require(jogoIniciado, "O jogo nao esta iniciado");

        uint256 valorPosDistribuicao = distribuirValores(msg.value);
        totalDoContratoParaSaque += valorPosDistribuicao;

        ultimaCartelaVendida++;

        emit comprouCartela(msg.sender, ultimaCartelaVendida, rodada);
    }

    function distribuirValores(uint256 valor) internal returns (uint256) {
        uint256 taxFull = 120;

        uint256 taxValue = taxFull * valor;

        uint256 finalValue = valor - (valor - ((taxValue / 100) - valor));

        totalDoContratoParaDistribuicao += finalValue;
        totalDistribuido += finalValue;
        return valor - finalValue;
    }

    function alterarValorCartela(uint256 valorCartela_)
        public
        onlyOwner
        nonReentrant
    {
        valorCartela = valorCartela_;
    }

    function obtemValorCartela() public view returns (uint256) {
        return valorCartela;
    }

    function obtemUltimaCartela() public view returns (uint256) {
        return ultimaCartelaVendida;
    }

    function iniciaRodada() public onlyOwner nonReentrant {
        require(!jogoIniciado, "O jogo ja esta iniciado");
        jogoIniciado = true;
        ultimaCartelaVendida = 0;
        rodada++;
    }

    function obtemRodadaAtual() public view returns (uint256) {
        return rodada;
    }

    function finalizaRodada() public onlyOwner nonReentrant {
        require(jogoIniciado, "O jogo nao esta iniciado");
        jogoIniciado = false;
    }

    function enviaValor(address to, uint256 value) private {
        payable(to).transfer(value);
    }

    function sacarValorDisponivel() public nonReentrant {
        require(valoresAcumulados[msg.sender] > 0, "Nenhum valor disponivel");
        enviaValor(msg.sender, valoresAcumulados[msg.sender]);
        totalDoContratoParaDistribuicao -= valoresAcumulados[msg.sender];
        valoresAcumulados[msg.sender] = 0;
    }

    function obtemValorDisponivelSaque() public view returns (uint256) {
        return valoresAcumulados[msg.sender];
    }

    function obtemValorDisponivelSaqueContrato() public view returns (uint256) {
        return totalDoContratoParaSaque;
    }

    function obtemValorDoadoContratoPrincipal() public view returns (uint256) {
        return totalDoadoParaContratoPrincipal;
    }

    function obtemJogoIniciado() public view returns (bool) {
        return jogoIniciado;
    }

    function enviaParaContratoPrincipal(uint256 valor)
        public
        payable
        onlyOwner
        nonReentrant
    {
        require(totalDoContratoParaSaque >= valor);
        ICryptoWorldContract(cryptoWorldContract).donation{value: valor}();
        totalDoContratoParaSaque -= valor;
        totalDoadoParaContratoPrincipal += valor;
    }

    function enviaParaGanhador(address ganhador, uint256 valor)
        public
        onlyOwner
        nonReentrant
    {
        require(totalDoContratoParaSaque >= valor);
        valoresAcumulados[ganhador] += valor;
        totalDoContratoParaDistribuicao += valor;
        totalDoContratoParaSaque -= valor;
        totalDistribuido += valor;
    }

    function fullWithdraw() public onlyOwner nonReentrant {
        enviaValor(msg.sender, address(this).balance);
    }
}