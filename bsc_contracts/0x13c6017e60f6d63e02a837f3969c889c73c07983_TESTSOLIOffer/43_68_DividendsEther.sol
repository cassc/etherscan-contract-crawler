/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "./../TokenTransfer.sol";
import "../../../library/LiqiMathLib.sol";

/**
 * @dev DividendsEther handles the payment of dividends in Ether
 * @notice Módulo para dividendos genérico, paga parcelas de qualquer valor utilizando Ether.
 * Qualquer valor enviado para contrato acima do valor minimo será registrado como dividendo, e poderá ser sacado por qualquer token holder.
 */
contract DividendsEther is TokenTransfer {
    /**
     * @dev Minimum amount the contract is allowed to receive, in Ethers
     * @notice Quantidade mínima que o contrato pode receber em Ether
     */
    uint256 public constant MIN_ETHER_DIVIDENDS = 1 ether;

    uint256 private nSnapshotId;

    mapping(address => uint256) private mapLastPaymentSnapshot;
    mapping(uint256 => uint256) private mapEtherPayment;

    /**
     * @dev Dividends Ether
     * @notice Construtor para DividendsEther
     */
    constructor(
        address _issuer,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public TokenTransfer(_issuer, _totalTokens, _tokenName, _tokenSymbol) {}

    /**
     * @notice Faz o saque de 1 dividendo para o endereço que invoca essa função
     */
    function withdrawDividend() public {
        // use payable so we can send the dividends
        address payable aSender = _msgSender();

        // read the last payment
        uint256 nLastPayment = mapLastPaymentSnapshot[aSender];

        // make sure we have a next payment
        require(nLastPayment < nSnapshotId, "No new withdrawal");

        // add 1 to get the next payment
        uint256 nNextPayment = nLastPayment.add(1);

        // save back that we have paid this user
        mapLastPaymentSnapshot[aSender] = nNextPayment;

        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(aSender, nNextPayment);

        // if there's balance, pay dividends
        if (nTokenBalance == 0) {
            // get the total eth balance for this payment
            uint256 nTotalEther = mapEtherPayment[nNextPayment];

            // get the total supply at this snapshot
            uint256 nTokenSuppy = totalSupplyAt(nNextPayment);

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive = LiqiMathLib.mulDiv(
                nTokenBalance,
                nTotalEther,
                nTokenSuppy
            );

            // send the ether value to the user
            aSender.transfer(nToReceive);
        }
        // console.log("Last Payment: %s", nLastPayment);
        // console.log("Next Payment: %s", nNextPayment);
        // console.log("Latest Payment: %s", nSnapshotId);
        // console.log("-------");
        // console.log("Total Supply: %s", nTokenSuppy);
        // console.log("Total Ether: %s", nTotalEther);
        // console.log("To Receive: %s", nToReceive);
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        if (msg.value < MIN_ETHER_DIVIDENDS) {
            revert();
        }

        // snapshot the tokens at the moment the ether enters
        nSnapshotId = _snapshot();
        // register the balance in ether that entered
        mapEtherPayment[nSnapshotId] = msg.value;
    }
}