// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./DeNFT.sol";
import "./DeNftProxy.sol";
import "./libraries/DeNftConstants.sol";

contract DeNftDeployer is Initializable, AccessControlUpgradeable {
    /* ========== STATE VARIABLES ========== */

    /// @dev DeBridgeGate contract's address on the current chain
    address public nftBridgeAddress;

    /// @dev Stores DeNFT contracts' addresses deployed by this contract
    ///         and identified by the corresponding debridgeId's
    mapping(bytes32 => address) public deployedAssetAddresses;

    /// @dev type of NFT (ERC721/ERC721Votes/etc.) -> beacons address (Beacon contract address for the DeNFT instances on the current chain)
    mapping(uint256 => address) public beacons;

    /// @dev Tracks the number of deNFT contracts deployed
    uint256 nonce;

    /* ========== ERRORS ========== */

    error NotFoundBeacon();
    error WrongArgument();
    error DeployedAlready();

    error AdminBadRole();
    error NFTBridgeBadRole();
    error DuplicateDebridgeId();

    error ZeroAddress();

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
        _;
    }

    /// @dev Only NFTBridge contract can call the method
    modifier onlyNFTBridge() {
        if (msg.sender != nftBridgeAddress) revert NFTBridgeBadRole();
        _;
    }

    /* ========== EVENTS ========== */

    event NFTDeployed(address asset, string name, string symbol, string baseUri, uint256 nonce);
    event UpdatedBeacon(uint256 tokenType, address oldBeacon, address newBeacon);

    /* ========== CONSTRUCTOR  ========== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _beacon,
        address _nftBridgeAddress
    ) public initializer {
        if (
            _beacon == address(0) ||
            _nftBridgeAddress == address(0)
        ) revert ZeroAddress();

        beacons[DeNftConstants.DENFT_TYPE_BASIC] = _beacon;
        nftBridgeAddress = _nftBridgeAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== METHODS  ========== */

    /// @dev Deploys a wrapper collection identified by deBridgeId
    function deployAsset(
        uint256 _tokenType,
        bytes32 _debridgeId,
        string memory _name,
        string memory _symbol
    ) external onlyNFTBridge returns (address deNFTContractAddress) {
        if (deployedAssetAddresses[_debridgeId] != address(0)) revert DeployedAlready();

        address[] memory minters = new address[](1);
        minters[0] = nftBridgeAddress;
        deNFTContractAddress = _deployDeNFTContract(
            _tokenType,
            address(0), // owner
            minters, // minters
            _name,
            _symbol,
            "",
            _debridgeId
        );

        deployedAssetAddresses[_debridgeId] = deNFTContractAddress;
    }

    /// @dev Deploys an original collection based on DeNFT contract code
    function createNFT(
        uint256 _tokenType,
        address _owner,
        address[] memory _minters,
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    ) external onlyNFTBridge returns (address deNFTContractAddress) {
        deNFTContractAddress = _deployDeNFTContract(
            _tokenType,
            _owner,
            _minters,
            _name,
            _symbol,
            _baseUri,
            keccak256(abi.encodePacked(nonce, getChainId()))
        );
        bytes32 debridgeId = getDebridgeId(getChainId(), deNFTContractAddress);
        if (deployedAssetAddresses[debridgeId] != address(0)) revert DuplicateDebridgeId();
        deployedAssetAddresses[debridgeId] = deNFTContractAddress;
    }

    /* ========== ADMIN ========== */

    function setNftBridgeAddress(address _nftBridgeAddress) external onlyAdmin {
        if (_nftBridgeAddress == address(0)) revert WrongArgument();
        nftBridgeAddress = _nftBridgeAddress;
    }


    /// @dev Sets a new beacon for the particular token type (DeNFT type), which will
    ///      be used for newly deployed DeNFT collections (both primary and secondary)
    /// @notice Important: that all existing secondary collections won't be affected
    function setDeNftBeacon(uint256 _tokenType, address _newBeacon) external onlyAdmin {
        address oldBeacon = beacons[_tokenType];
        beacons[_tokenType] = _newBeacon;
        emit UpdatedBeacon(_tokenType, oldBeacon, _newBeacon);
    }

    // ============ Private methods ============

    function _deployDeNFTContract(
        uint256 _tokenType,
        address _owner,
        address[] memory _minters,
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        bytes32 salt
    ) internal returns (address deNFTContractAddress) {
        // Initialize args
        bytes memory initializationArgs = abi.encodeWithSelector(
            DeNFT.initialize.selector,
            _owner,
            _minters,
            nftBridgeAddress,
            _name,
            _symbol,
            _baseUri
        );

        address beacon = beacons[_tokenType];
        if (beacon == address(0)) revert NotFoundBeacon();

        // initialize Proxy
        bytes memory constructorArgs = abi.encode(beacon, initializationArgs);

        // deployment code
        bytes memory bytecode = abi.encodePacked(
            type(DeNftProxy).creationCode,
            constructorArgs
        );

        assembly {
            // debridgeId is a salt
            deNFTContractAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)

            if iszero(extcodesize(deNFTContractAddress)) {
                revert(0, 0)
            }
        }

        emit NFTDeployed(deNFTContractAddress, _name, _symbol, _baseUri, nonce);
        nonce++;
    }

    // ============ VIEWS ============

    /// @dev Cross-chain identifier of a native NFT collection
    function getDebridgeId(uint256 _chainId, address _nftCollectionAddress)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_chainId, _nftCollectionAddress));
    }

    /// @dev Gets the current chain id
    function getChainId() public view virtual returns (uint256 cid) {
        assembly {
            cid := chainid()
        }
    }

    // ============ Version Control ============

    /// @dev Get this contract's version
    function version() external pure returns (uint256) {
        return 100; // 1.0.0
    }
}