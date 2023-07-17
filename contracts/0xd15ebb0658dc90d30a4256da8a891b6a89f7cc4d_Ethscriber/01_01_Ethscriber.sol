// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

error EmptyDataField();
error InvalidFunctionCall();

/**
 * @title Ethscriber v0.0.1
 * @author @ownerlessInc
 * @notice - Ethscriber is a decentralized subscription service following the Ethscription standard.
 *
 * IMPORTANT! The standard tells us that Ethscriptions are the hexadecimals in the data field of a
 * transaction, while the tokenId is the txHash of said data field. While this approach can be easy
 * to compreehend and might match the visual aspects of how etherscan displays transaction details,
 * it does rely on faith or centralized entities to ensure that the value of Ethscriptions can be
 * negotiated.
 *
 * The best parts of Ethscriptions is how lightweight they can be. But yet, they sit wondering at
 * how they can be monetized without relying on a third party indexing their every move and current
 * ownership status. The faith system won't work, and more than just POAPs or Phigitals are needed
 * when it comes to adding more complex mechanics that open the gateway of possibilities.
 *
 * Imagine that for every single `msg.data` field that was ever used to call a contract, there is a
 * unique data field, that represents that execution at certain point, and in theory, those are all
 * Ethscriptions of the contract which received the call. Because all of the contracts instructions
 * are written in the `msg.data` field. Properly indexing the entire history of the blockchain would
 * show that most Ethscriptions today were already created in the past at random points in time.
 *
 * There is another problem relating what are transactions and what are internal transactions on EVM.
 * Internal transactions are transactions that are called by a contract, and they are not considered
 * "transactions" themselves in explorers like Etherscan. But they are indeed transactions and they
 * do carry the option of a data field. More techinical explorers like Tenderly do showcase internal
 * transactions, and they are indeed transactions just like the ones described by the Ethscription
 * standard.
 *
 * Since a single transaction hash (txHash or txId) is allowed to have multiple transactions with
 * different data fields, we shouldn't be referring Ethscriptions IDs as the transaction hash which
 * originated them, but rathe be using keccak256 of the `msg.data` itself as the global identifier.
 *
 * The ID of the content as the hash of the content itself. Appears to be a better novel and more
 * appealing approach to the problem of tokenizing data fields. We believe that this is all about
 * proper indexing and adequate interpretation of the data field. As long as we have the data field
 * stored within the blockchain, we can always create more complex mechanics on top. One is a fact:
 * the interest to monetize will prevail, and there is no way to do it with a 3rd party providing a
 * 'faith' service.
 *
 * We imagine that the best way to take Ethscription out of the faith market while still following
 * the current standard - and that is due to its close to zero trust capabilities when transferring
 * from one to another - is to have the txHash available during the contract execution. This would
 * require a trusted 3rd party anyway, ensuring the correct txHash is stored on-chain, but wouldn't
 * resolve the problem when interpreting transactions from internal transactions and is costly.
 *
 * Current Ethscription standard wasn't focusing on creating utility, it is not solving any issues
 * rather than showcasing that these 'one-time soulbounded NFTs' through the `msg.data` field are
 * cheaper and more friendly for those that will opt-out of the complications of owning an ERC721
 * smart contract.
 *
 * The Lightweight NFTs aren't meant to be a replacement for ERC721, but rather a complement to the
 * tokenization proccess of the data field. Volatility and price will increase eventually, turning
 * the ERC721 standard more costly to operate. Ethscriptions (Light NFTs) might be the solution for
 * those that will opt for a cheaper and more friendly way to operate on the Ethereum Mainnet, even
 * other EVM compatibles.
 *
 * The redundancy of using complex libraries like OpenZeppelin when create simple ERC721 contracts
 * will be realized as newcomers start to enter the space with a new vision for the future and new
 * standards. Right now, we're at a pinpoint moment on how to enable Ethscriptions usefullness to
 * the community. The more we think about it, the more gas we will struggle to invest in indexing
 * and centralization or total monetization in exchange for more gas. Mainnet is keep expanding so
 * as its costs... a lightweight solution is needed and Ethscriptions might be it. We must think
 * about the future and how we can make it more efficient, acessible, trustable and less costly.
 *
 * The Ethscription standard is a great start, but its already becoming legacy...
 *
 * This contract is a proof of concept on how Ethscriptions can be used to create a decentralized
 * Ethscriptions service. It isn;t meant to be owned or profited from. It is meant to be a gateway
 * to easily index new Ethscriptions until a more powerful standard is created. I believe that the
 * current Ethscription standard is not enough to create a decentralized Ethscriptions service and
 * thus, this epoch will be remembered as the Legacy Ethscription standard.
 *
 * This contract doesn't solve the problems regarding IDs and monetization issues... it does raise
 * good philosophical questions about the current state of the Ethscription standard and into what
 * it could become. But for now, we are following the standard.
 *
 * How to Ethscribe and comprehend its mechanics:
 * - Send a transaction to this contract as if it were an EOA;
 * - The `msg.data` will be the content of the Ethscription;
 * - The `msg.sender` will be the creator of the Ethscription;
 * - The `txHash` will be the Ethscription ID;
 * - Any `msg.value` will be refunded
 * - Any `msg.data` will be logged as its hash
 *
 * How to use Ethscriber in your project:
 * - Import the Ethscriber address as a constant;
 * - Use `delegatecall()` to preserve the `msg.sender` when calling the contract;
 * - The `msg.data` will be the content of the Ethscription;
 *
 * How to index Ethscriptions:
 * - Check all the transactions to this contract;
 * - Display the indexation that better fits your client base;
 */
contract Ethscriber {
    /**
     * @dev - The fallback function is used to ethscribe.
     *
     * By sending a transaction to this contract - even with 0 ETH - the `msg.data` will be logged
     * with referring the content to the Ethscription.
     *
     * Requirements:
     * - The `msg.data` field is not empty.
     * - The `msg.data` field is empty and `msg.value` is 0.
     *
     * IMPORTANT! Due to the lack of standardization of how the indexing will properly be done, as
     * well as how the scans currently displays their internal transactions content, we believe that
     * the best case scenario matching the ethscriptions ID's standard is to add a whitespace before
     * the data field, represented by an extra 0x20 in the beginning of `msg.data`.
     *
     * This will guarantee that a unique Ethscription was sent to your address, and it will roll out
     * normaly in a browser because compilers ignore whitespaces. If community disapproves on using
     * contracts to create ethscriptions, we can call this standard Bob and call it a day.
     *
     * We don't have to set events for this contract, because the `msg.data` will be logged on-chain
     * and can be indexed by any service with ease.
     */
    fallback() external payable {
        (bool sent, ) = address(msg.sender).call{value: msg.value}(
            bytes(abi.encodePacked(" ", msg.data))
        );
        if (!sent) revert InvalidFunctionCall();
    }

    /**
     * @dev - The receive function will revert any attemps of sending ETH
     * to the contract with an empty `msg.data` field.
     *
     * Requirements:
     * - The `msg.value` field must be larger than 0.
     * - The `msg.data` field must be empty.
     */
    receive() external payable {
        revert EmptyDataField();
    }
}