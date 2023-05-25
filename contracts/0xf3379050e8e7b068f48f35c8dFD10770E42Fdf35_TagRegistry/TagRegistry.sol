/**
 *Submitted for verification at Etherscan.io on 2020-05-08
*/

pragma solidity >=0.4.21 <0.6.0;


/**
 * @title TagRegistry
 * @dev Keeps the wine tags information groupped into batches.
 *   The contract stores only the basic info, plus a reference to IPFS file with detailed info.
 *   No modification is supposed to be done after registering any of the batches.
 */
contract TagRegistry {
    /**
     * @dev From which account the contract was registered.
     * The only account that has full access to the data.
     */
    address private owner;

    /**
     * @dev A group of items with same set of features.
     *   The actual information is stored in IPFS file storage,
     *   here, we have only the references to the info.
     */
    struct Batch {
        string ipfsSummaryHash;
        string ipfsItemsHash;
        address registeredBy;
    }

    /**
     * @dev All the registered batches to find them later by ID or index.
     */
    mapping(bytes32 => Batch) batchesByIds;
    bytes32[] batchIds;

    /**
     * @dev The owner can arbitrary allow (or deny) any account to register batches.
     *     The expected registrars are producers of the products.
     */
    struct Registrar {
        address ethAddress;
        string name;
        bool isActive;
    }

    /**
     * @dev Producers may have their own accounts and register bathces on their own,
     *   it increases credibility - producers themselves assert that the information is correct.
     */
    mapping(address => uint256) registrarIndexesByAddresses;
    Registrar[] registrars;

    /**
     * @dev The public host to get the IPFS file following our stored file hash.
     */
    mapping(string => string) configParams;

    event BatchRegistered(bytes32 batchId);
    event RegistrarAdded(address ethAddress);

    constructor() public {
        owner = msg.sender;
        addRegistrar(address(0), "unused", false);
        addRegistrar(msg.sender, "Contract Owner", true);
        configParams["ipfsHost"] = "https://gateway.ipfs.io/ipfs/";
        configParams["registeredBatchDescr"] = "The batch is blockchain-protected.";
        configParams["notRegisteredBatchDescr"] = "The batch is not registered!";
    }

    /**
     * @dev Requires a method to be called by owner only.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied");
        _;
    }

    /**
     * @dev Requires a method to be called by owner any of the registered producers.
     */
    modifier onlyActiveRegistrar() {
        uint256 registrarIndex = registrarIndexesByAddresses[msg.sender];
        require(registrarIndex > 0, "Access denied: Unknown registrar");
        require(
            registrars[registrarIndex].isActive == true,
            "Access denied: inactive registrar"
        );
        _;
    }

    /**
     * @dev For consumers to validate the batch protection with public explorers (etherscan, or similar).
     */
    function getBatchInfo(string calldata batchId)
        external
        view
        returns (
            string memory description,
            string memory summaryInfoLink,
            string memory itemsInfoLink,
            address registeredByAddress,
            string memory registeredByName
        )
    {
        require(bytes(batchId).length <= 32, "Incorrect batch ID format");

        bytes32 batchIdBytes = stringToBytes32(batchId);
        if (isBatchRegistered(batchIdBytes)) {
            Batch memory batch = batchesByIds[batchIdBytes];
            uint256 registrarIndex = registrarIndexesByAddresses[batch.registeredBy];
            return (
                configParams["registeredBatchDescr"],
                strConcat(configParams["ipfsHost"], batch.ipfsSummaryHash),
                strConcat(configParams["ipfsHost"], batch.ipfsItemsHash),
                batch.registeredBy,
                registrars[registrarIndex].name
            );
        } else {
            return (
                configParams["notRegisteredBatchDescr"],
                "",
                "",
                address(0),
                ""
            );
        }
    }

    /**
     * @dev Used by the contract itself or by client scripts.
     */
    function isBatchRegistered(bytes32 batchId)
        public
        view
        returns (bool isRegistered)
    {
        return bytes(batchesByIds[batchId].ipfsSummaryHash).length != 0;
    }

    /**
     * @dev To iterate the batches and check for item duplicates.
     */
    function getBatchesCount() public view returns (uint256 batchesCount) {
        return batchIds.length;
    }

    /**
     * @dev To check there are no item duplicates.
     *   Each batch has a text file with item IDs related (SHA256 encrypted).
     *   It gives the ability to automatically iterate the files and check for item duplicates.
     */
    function getBatchItemsLinkByIndex(uint256 batchIndex)
        public
        view
        returns (string memory ipfsItemsHash)
    {
        require(
            batchIndex < batchIds.length,
            "Attempt to access a non-existent Batch"
        );
        return batchesByIds[batchIds[batchIndex]].ipfsItemsHash;
    }

    /**
     * @dev Allows specific account to register batches.
     */
    function addRegistrar(
        address registrarAddress,
        string memory registrarName,
        bool isActive
    ) public onlyOwner {
        require(
            bytes(registrarName).length > 0,
            "registrarName must not be blank"
        );

        require(
            registrarIndexesByAddresses[registrarAddress] == 0,
            "Registrar already exists"
        );

        Registrar memory registrar = Registrar({
            ethAddress: registrarAddress,
            name: registrarName,
            isActive: isActive
        });

        registrars.push(registrar);
        uint256 registrarIndex = registrars.length - 1;
        registrarIndexesByAddresses[registrarAddress] = registrarIndex;

        emit RegistrarAdded(registrarAddress);
    }

    /**
     * @dev Used to either update the name of the registrar (for case the producer brand name changes, or so),
     *     or, it can be used to de-activate the registrar (e.g., disallow to register new batches).
     * Providing blank registrarName leaves the name as it was before.
     */
    function updateRegistrar(
        address registrarAddress,
        string calldata registrarName,
        bool isActive
    ) external onlyOwner {
        uint256 registrarIndex = registrarIndexesByAddresses[registrarAddress];
        require(registrarIndex > 0, "Registrar not found");

        Registrar storage registrar = registrars[registrarIndex];
        if (bytes(registrarName).length > 0) {
            registrar.name = registrarName;
        }
        registrar.isActive = isActive;
    }

    /**
     * @dev Keeping the registrars public,
     *   so anyone can check who is involved into the counterfeit-proof activity
     */
    function getRegistrarsCount()
        public
        view
        returns (uint256 registrarsCount)
    {
        return registrars.length;
    }

    /**
     * @dev Keeping the registrars public,
     *   so anyone can check who is involved into the counterfeit-proof activity
     */
    function getRegistrarByIndex(uint256 registrarIndex)
        external
        view
        returns (address ethAddress, string memory name, bool isActive)
    {
        require(
            registrarIndex < registrars.length,
            "Attempt to access a non-existent Registrar"
        );
        Registrar memory registrar = registrars[registrarIndex];

        return (registrar.ethAddress, registrar.name, registrar.isActive);
    }

    /**
     * @dev Let's keep some flexibility for params that can change (like public IPFS URL)
     */
    function setConfigParam(
        string calldata paramKey,
        string calldata paramValue
    ) external onlyOwner {
        configParams[paramKey] = paramValue;
    }

    /**
     * @dev For management purposes generaly.
     */
    function getConfigParam(string calldata paramKey)
        external
        view
        onlyOwner
        returns (string memory paramValue)
    {
        return configParams[paramKey];
    }

    /*
     * @dev The stored batch information is immutable,
     *   there is no interface to update or remove any of the registered batches.
     *  The main information is kept in IPFS file storage, here we store only the references.
     */
    function registerBatch(
        bytes32 batchId,
        string calldata ipfsSummaryHash,
        string calldata ipfsItemsHash
    ) external onlyActiveRegistrar {
        require(!isBatchRegistered(batchId), "The batch is already registered");

        uint256 summLen = bytes(ipfsSummaryHash).length;
        require(
            summLen > 0 && summLen <= 128,
            "Incorrect IPFS Summary hash format"
        );

        uint256 itemsLen = bytes(ipfsItemsHash).length;
        require(
            itemsLen > 0 && itemsLen <= 128,
            "Incorrect IPFS Items hash format"
        );

        Batch memory batch = Batch({
            ipfsSummaryHash: ipfsSummaryHash,
            ipfsItemsHash: ipfsItemsHash,
            registeredBy: msg.sender
        });
        batchesByIds[batchId] = batch;
        batchIds.push(batchId);

        emit BatchRegistered(batchId);
    }

    function strConcat(string memory s1, string memory s2)
        internal
        pure
        returns (string memory resStr)
    {
        bytes memory bytesS1 = bytes(s1);
        bytes memory bytesS2 = bytes(s2);
        bytes memory res = new bytes(bytesS1.length + bytesS2.length);

        uint256 k = 0;
        uint256 i = 0;
        for (i = 0; i < bytesS1.length; i++) res[k++] = bytesS1[i];
        for (i = 0; i < bytesS2.length; i++) res[k++] = bytesS2[i];

        return string(res);
    }

    function stringToBytes32(string memory source)
        internal
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}