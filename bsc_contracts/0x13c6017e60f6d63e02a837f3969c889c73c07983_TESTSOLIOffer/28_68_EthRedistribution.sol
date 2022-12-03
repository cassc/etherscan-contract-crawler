/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

/**
 * @dev Distributes Eth to specified addresses
 * @notice Automaticamente envia Ether para os endereços especificados na função enableRedistribution.
 * Esse contrato é um experimento para eliminação de taxas na transferência de Ether para multiplos usuários.
 * A primeira vez que invoca enableRedistribution com 64 endereços custa mais caro, mas o preço é otimizado
 * a partir da segunda para extremamente próximo do valor puro de transferência.
 * A principal vantagem desse contrato é que conseguimos fazer 64 transferências em apenas 2 transações.
 **/
contract EthRedistribution {
    struct Payment {
        uint256 amount;
        address destination;
    }

    Payment[64] private payments;
    uint256 toPay;

    /**
     * @dev Enable redistribution
     * @notice Prepara a redistribuição para a próxima vez que o contrato receber Ether
     */
    function enableRedistribution(
        uint256[] calldata _amounts,
        address[] calldata _destinations
    ) external {
        toPay = _amounts.length;

        for (uint256 i = 0; i < _amounts.length; i++) {
            uint256 amount = _amounts[i];
            address destination = _destinations[i];

            payments[i].amount = amount;
            payments[i].destination = destination;
        }
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        //require(toPay != 0, "Nothing to pay");

        for (uint256 i = 0; i < toPay; i++){
            Payment memory payment = payments[i];

            address payable addr2 = address(uint160(payment.destination));
            //address payable addr3 = payable(addr1);
            addr2.transfer(payment.amount);
        }
        toPay = 0;
    }
}