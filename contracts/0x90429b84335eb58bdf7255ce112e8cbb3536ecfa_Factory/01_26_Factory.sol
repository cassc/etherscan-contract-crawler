// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./NFT.sol";
import "./interfaces/IStorageContract.sol";

contract Factory is OwnableUpgradeable {

    struct InstanceInfo {
        string name;    // name of a new collection
        string symbol;  // symbol of a new collection
        string contractURI; // contract URI of a new collection
        address payingToken;    // paying token of a new collection
        uint256 mintPrice;  // mint price of a token from a new collection
        uint256 whitelistMintPrice;  // mint price of a token from a new collection for whitelisted users
        bool transferable;  // shows if tokens will be transferrable or not
        uint256 maxTotalSupply; // max total supply of a new collection
        uint96 feeNumerator;    // total fee amount (in BPS) of a new collection
        address feeReceiver; // royalties receiver address
        uint256 collectionExpire;   // The period of time in which collection is expired (for the BE)
        bytes signature;    // BE's signature
    }

    address public platformAddress; // Address which is allowed to collect platform fee
    address public storageContract; // Storage contract address 
    address public signerAddress;   // Signer address
    uint8 public platformCommission;    // Platform comission BPs

    event InstanceCreated(
        string name,
        string symbol,
        address instance,
        uint256 length
    );

    event SignerSet(address newSigner);
    event PlatformComissionSet(uint8 newComission);
    event PlatformAddressSet(address newPlatformAddress);

    /**
     * @notice Initializes the contract
     * @param _signer The signer address
     * @param _platformAddress The platform address
     * @param _platformCommission The platform comission (BPs)
     * @param _storageContract The storage contract address
     */
    function initialize(
        address _signer,
        address _platformAddress,
        uint8 _platformCommission,
        address _storageContract
    ) external initializer {
        __Ownable_init();
        require(_signer != address(0), "incorrect signer address");
        require(_platformAddress != address(0), "incorrect platform address");
        require(_storageContract != address(0), "incorrect storage contract address");
        signerAddress = _signer;
        platformAddress = _platformAddress;
        platformCommission = _platformCommission;
        storageContract = _storageContract;
    }

    /**
     * @notice Sets new platform comission
     * @dev Only owner can call it
     * @param _platformCommission - The platform comission
     */
    function setPlatformCommission(uint8 _platformCommission) external onlyOwner {
        platformCommission = _platformCommission;
        emit PlatformComissionSet(_platformCommission);
    }

    /**
     * @notice Sets new platform address
     * @dev Only owner can call it
     * @param _platformAddress - The platform address
     */
    function setPlatformAddress(address _platformAddress) external onlyOwner {
        require(_platformAddress != address(0), "incorrect address");
        platformAddress = _platformAddress;
        emit PlatformAddressSet(_platformAddress);
    }

    /**
     * @notice Sets new signer address
     * @dev Only owner can call it
     * @param _signer - The signer address
     */
    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "incorrect address");
        signerAddress = _signer;
        emit SignerSet(_signer);
    }

    /**
     * @notice produces new instance with defined name and symbol
     * @param _info New instance's info
     * @return instance address of new contract
     */
    function produce(
        InstanceInfo memory _info
    ) external returns (address) {
        require(
            _verifySignature(
                _info.name, 
                _info.symbol, 
                _info.contractURI,
                _info.feeNumerator, 
                _info.feeReceiver, 
                _info.signature
            ),
            "Invalid signature"
        );
        _createInstanceValidate(_info.name, _info.symbol);
        address instanceCreated = _createInstance(_info.name, _info.symbol);
        require(
            instanceCreated != address(0),
            "Factory: INSTANCE_CREATION_FAILED"
        );
        NFT.Parameters memory params = NFT.Parameters(
            storageContract,
            _info.payingToken,
            _info.mintPrice,
            _info.whitelistMintPrice,
            _info.contractURI,
            _info.name,
            _info.symbol,
            _info.transferable,
            _info.maxTotalSupply,
            _info.feeReceiver,
            _info.feeNumerator,
            _info.collectionExpire,
            _msgSender()
        );
        NFT(payable(instanceCreated)).initialize(params);
        return instanceCreated;
    }

    /**
     * @dev Creates a new instance of NFT and adds the info 
     * into the Storage contract
     * @param name New instance's name
     * @param symbol New instance's symbol
     * @return instanceAddress Instance address of new contract
     */
    function _createInstance(string memory name, string memory symbol)
        internal
        returns (address instanceAddress)
    {
        NFT instance = new NFT();
        instanceAddress = address(instance);
        uint256 id = IStorageContract(storageContract).addInstance(
            instanceAddress,
            _msgSender(),
            name,
            symbol
        );
        emit InstanceCreated(name, symbol, instanceAddress, id);
    }

    /**
     * @dev Checks if instance with specified name and symbol already exists
     * @param name New instance's name
     * @param symbol New instance's symbol
     */
    function _createInstanceValidate(string memory name, string memory symbol)
        internal
        view
    {
        require((bytes(name)).length != 0, "Factory: EMPTY NAME");
        require((bytes(symbol)).length != 0, "Factory: EMPTY SYMBOL");
        require(
            IStorageContract(storageContract).getInstance(
                keccak256(abi.encodePacked(name, symbol))
            ) == address(0),
            "Factory: ALREADY_EXISTS"
        );
    }

    /**
     * @dev Verifies if the signature belongs to the current signer address
     * @param name New instance's name
     * @param symbol New instance's symbol
     * @param contractURI New instance's contract URI 
     * @param feeNumerator Fee numerator for ERC2981
     * @param feeReceiver Fee receiver for ERC2981
     * @param signature The signature to check
     */
    function _verifySignature(
        string memory name,
        string memory symbol,   
        string memory contractURI,
        uint96 feeNumerator,
        address feeReceiver,
        bytes memory signature
    ) internal view returns (bool) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        name, 
                        symbol,
                        contractURI,
                        feeNumerator,
                        feeReceiver,
                        block.chainid
                    )
                ), signature
            ) == signerAddress;
    }

    uint256[49] private __gap;

}