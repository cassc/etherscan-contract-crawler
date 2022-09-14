// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.13;

interface IWriteDeferral {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Event raised when the default chainId is changed for the corresponding L2 handler.
    event L2HandlerDefaultChainIdChanged(uint256 indexed previousChainId, uint256 indexed newChainId);
    /// @notice Event raised when the contractAddress is changed for the L2 handler corresponding to chainId.
    event L2HandlerContractAddressChanged(uint256 indexed chainId, address indexed previousContractAddress, address indexed newContractAddress);

    /// @notice Event raised when the url is changed for the corresponding Off-Chain Database handler.
    event OffChainDatabaseHandlerURLChanged(string indexed previousUrl, string indexed newUrl);

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Struct used to define the domain of the typed data signature, defined in EIP-712.
     * @param name The user friendly name of the contract that the signature corresponds to.
     * @param version The version of domain object being used.
     * @param chainId The ID of the chain that the signature corresponds to (ie Ethereum mainnet: 1, Goerli testnet: 5, ...). 
     * @param verifyingContract The address of the contract that the signature pertains to.
     */
    struct domainData {
        string name;
        string version;
        uint64 chainId;
        address verifyingContract;
    }    

    /**
     * @notice Struct used to define the message context used to construct a typed data signature, defined in EIP-712, 
     * to authorize and define the deferred mutation being performed.
     * @param functionSelector The function selector of the corresponding mutation.
     * @param sender The address of the user performing the mutation (msg.sender).
     * @param parameter[] A list of <key, value> pairs defining the inputs used to perform the deferred mutation.
     */
    struct messageData {
        bytes4 functionSelector;
        address sender;
        parameter[] parameters;
        uint256 expirationTimestamp;
    }

    /**
     * @notice Struct used to define a parameter for off-chain Database Handler deferral.
     * @param name The variable name of the parameter.
     * @param value The string encoded value representation of the parameter.
     */
    struct parameter {
        string name;
        string value;
    }


    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Error to raise when mutations are being deferred to an L2.
     * @param chainId Chain ID to perform the deferred mutation to.
     * @param contractAddress Contract Address at which the deferred mutation should transact with.
     */
    error StorageHandledByL2(
        uint256 chainId, 
        address contractAddress
    );

    /**
     * @dev Error to raise when mutations are being deferred to an Off-Chain Database.
     * @param sender the EIP-712 domain definition of the corresponding contract performing the off-chain database, write 
     * deferral reversion.
     * @param url URL to request to perform the off-chain mutation.
     * @param data the EIP-712 message signing data context used to authorize and instruct the mutation deferred to the 
     * off-chain database handler. 
     * In order to authorize the deferred mutation to be performed, the user must use the domain definition (sender) and message data 
     * (data) to construct a type data signature request defined in EIP-712. This signature, message data (data), and domainData (sender) 
     * are then included in the HTTP POST request, denoted sender, data, and signature.
     * 
     * Example HTTP POST request:
     *  {
     *      "sender": <abi encoded domainData (sender)>,
     *      "data": <abi encoded message data (data)>,
     *      "signature": <EIP-712 typed data signature of corresponding message data & domain definition>
     *  }
     * 
     */
    error StorageHandledByOffChainDatabase(
        domainData sender, 
        string url, 
        messageData data
    );     
}