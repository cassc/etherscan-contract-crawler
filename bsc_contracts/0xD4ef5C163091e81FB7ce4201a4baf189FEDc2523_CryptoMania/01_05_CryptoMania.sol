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
    mapping(address => uint256) valoresPremios;
    mapping(address => uint256) valoresDistribuicao;
    uint256 totalDoContratoParaPremio;
    uint256 totalDoContratoParaDistribuicao;
    uint256 totalDoContratoParaDoacao;
    uint256 totalDistribuido;
    uint256 totalPremio;
    uint256 totalDoado;
    uint256 private taxaDistribuicao = 20;
    uint256 private taxaPremio = 30;

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

        uint256 valorPosDistribuicao = distribuirValorDistribuicao(msg.value);

        uint256 valorPosPremio = distribuirValorPremio(msg.value);

        uint256 valorDoacao = msg.value -
            (valorPosDistribuicao + valorPosPremio);

        totalDoContratoParaDoacao += valorDoacao;

        ultimaCartelaVendida++;

        emit comprouCartela(msg.sender, ultimaCartelaVendida, rodada);
    }

    function distribuirValorPremio(uint256 valor) internal returns (uint256) {
        uint256 taxFull = 100 + taxaPremio;

        uint256 taxValue = taxFull * valor;

        uint256 finalValue = valor - (valor - ((taxValue / 100) - valor));

        totalDoContratoParaPremio += finalValue;
        totalPremio += finalValue;

        return finalValue;
    }

    function distribuirValorDistribuicao(uint256 valor)
        internal
        returns (uint256)
    {
        uint256 taxFull = 100 + taxaDistribuicao;

        uint256 taxValue = taxFull * valor;

        uint256 finalValue = valor - (valor - ((taxValue / 100) - valor));

        totalDoContratoParaDistribuicao += finalValue;
        totalPremio += finalValue;

        return finalValue;
    }

    function alterarValorCartela(uint256 valorCartela_)
        public
        onlyOwner
        nonReentrant
    {
        valorCartela = valorCartela_;
    }

    function alterarTaxaDistribuicao(uint256 taxaDistribuicao_)
        public
        onlyOwner
        nonReentrant
    {
        taxaDistribuicao = taxaDistribuicao_;
    }

    function alterarTaxaPremio(uint256 taxaPremio_)
        public
        onlyOwner
        nonReentrant
    {
        taxaPremio = taxaPremio_;
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

    function sacarValorPremio() public nonReentrant {
        require(valoresPremios[msg.sender] > 0, "Nenhum valor disponivel");
        enviaValor(msg.sender, valoresPremios[msg.sender]);

        valoresPremios[msg.sender] = 0;
    }

    function obtemValorDisponivelUsuarioPremio() public view returns (uint256) {
        return valoresPremios[msg.sender];
    }

    function sacarValorDistribuicao() public nonReentrant {
        require(valoresDistribuicao[msg.sender] > 0, "Nenhum valor disponivel");
        enviaValor(msg.sender, valoresDistribuicao[msg.sender]);
        totalDistribuido += valoresDistribuicao[msg.sender];

        valoresDistribuicao[msg.sender] = 0;
    }

    function obtemValorDisponivelUsuarioDistribuicao()
        public
        view
        returns (uint256)
    {
        return valoresDistribuicao[msg.sender];
    }

    function obtemValorDisponivelContratoPremio()
        public
        view
        returns (uint256)
    {
        return totalDoContratoParaPremio;
    }

    function obtemValorDisponivelContratoDistribuicao()
        public
        view
        returns (uint256)
    {
        return totalDoContratoParaDistribuicao;
    }

    function adicionarTotalDoContratoParaDistribuicao() public payable {
        require(msg.value > 0, "Valor insuficiente");

        totalDoContratoParaDistribuicao += msg.value;
    }

    function obtemValorDisponivelContratoDoacao()
        public
        view
        returns (uint256)
    {
        return totalDoContratoParaDoacao;
    }

    function obtemJogoIniciado() public view returns (bool) {
        return jogoIniciado;
    }

    function enviaDoacaoParaContratoPrincipal()
        public
        payable
        onlyOwner
        nonReentrant
    {
        require(totalDoContratoParaDoacao > 0);
        ICryptoWorldContract(cryptoWorldContract).donation{
            value: totalDoContratoParaDoacao
        }();
        totalDoado += totalDoContratoParaDoacao;
        totalDoContratoParaDoacao = 0;
    }

    function enviaParaGanhador(address ganhador, uint256 valor)
        public
        onlyOwner
        nonReentrant
    {
        require(totalDoContratoParaPremio >= valor);
        valoresPremios[ganhador] += valor;
        totalDoContratoParaPremio -= valor;
    }

    function enviaParaDistribuidor(address distribuidor, uint256 valor)
        public
        onlyOwner
        nonReentrant
    {
        require(
            totalDoContratoParaDistribuicao >= valor,
            "valor de distribuicao insuficiente"
        );
        valoresDistribuicao[distribuidor] += valor;

        totalDoContratoParaDistribuicao -= valor;
    }

    function fullWithdraw() public onlyOwner nonReentrant {
        enviaValor(msg.sender, address(this).balance);
    }

    function withdrawPartial(uint256 value) public onlyOwner nonReentrant {
        require(totalDoContratoParaDoacao > 0);
        totalDoContratoParaDoacao -= value;
        enviaValor(msg.sender, value);
        totalDoado += totalDoContratoParaDoacao;
    }
}