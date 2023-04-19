// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./SparkbloxRegistry.sol";
import "./interfaces/ISparkbloxContract.sol";
import "./extensions/interfaces/IPlatformFee.sol";

contract SparkbloxFactory is Multicall, ERC2771Context, AccessControlEnumerable {
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    address public defaultPlatformRecip;
    uint256 public defaultPlatformFee;

    SparkbloxRegistry public immutable registry;

    mapping(address => bool) public approval;
    mapping(bytes32 => uint256) public currentVersion;
    mapping(bytes32 => mapping(uint256 => address)) public implementation;
    mapping(address => address) public deployer;
    
    event ProxyDeployed(address indexed implementation, address proxy, address indexed deployer);
    event ERC1967ProxyDeployed(address indexed implementation, address proxy, address indexed deployer);
    event ImplementationAdded(address implementation, bytes32 indexed contractType, uint256 version);
    event ImplementationApproved(address implementation, bool isApproved);
    event ImplementationRemoved(address implementation, bytes32 indexed contractType, uint256 version);
    event DefaultPlatformFeeUpdated(address _platformFeeRecip, uint256 _platformFee);

    constructor(address _trustedForwarder, address _registry) ERC2771Context(_trustedForwarder) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FACTORY_ROLE, _msgSender());

        registry = SparkbloxRegistry(_registry);
    }

    function deployProxy(bytes32 _type, bytes memory _data) external returns (address) {
        bytes32 salt = bytes32(registry.count(_msgSender()));
        return deployProxyDeterministic(_type, _data, salt);
    }

    function deployProxyDeterministic(
        bytes32 _type,
        bytes memory _data,
        bytes32 _salt
    ) public returns (address) {
        address _implementation = implementation[_type][currentVersion[_type]];
        return deployProxyByImplementation(_implementation, _data, _salt);
    }

    function deployProxyByImplementation(
        address _implementation,
        bytes memory _data,
        bytes32 _salt
    ) public returns (address deployedProxy) {
        require(approval[_implementation], "implementation not approved");

        bytes32 salthash = keccak256(abi.encodePacked(_msgSender(), _salt));
        deployedProxy = Clones.cloneDeterministic(_implementation, salthash);

        deployer[deployedProxy] = _msgSender();

        emit ProxyDeployed(_implementation, deployedProxy, _msgSender());

        registry.add(_msgSender(), deployedProxy, block.chainid);

        if (_data.length > 0) {
            // slither-disable-next-line unused-return
            Address.functionCall(deployedProxy, _data);
        }
    }

    function deployERC1967Proxy(
        bytes32 _type,
        bytes memory _data
    ) public returns (address deployedProxy) {
        address _implementation = implementation[_type][currentVersion[_type]];
        deployedProxy = address(new ERC1967Proxy(_implementation, _data));

        emit ERC1967ProxyDeployed(_implementation, deployedProxy, _msgSender());

        try IPlatformFee(deployedProxy).setPlatformFeeInfo(defaultPlatformRecip, defaultPlatformFee) {

        } catch {

        }
        
        registry.add(_msgSender(), deployedProxy, block.chainid);

    }
    
    function setDefaultPlatformFee(address _platformFeeRecip, uint256 _platformFee) public {
        require(hasRole(FACTORY_ROLE, _msgSender()), "not admin.");
        
        defaultPlatformFee = _platformFee;
        defaultPlatformRecip = _platformFeeRecip;
        emit DefaultPlatformFeeUpdated(_platformFeeRecip, _platformFee);
    }

    function setPlatformFee(address contractAddr, address _platformFeeRecipient, uint256 _platformFeeBps) public {
        require(hasRole(FACTORY_ROLE, _msgSender()), "not admin.");
        
        IPlatformFee module = IPlatformFee(contractAddr);
        module.setPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
    }

    function addImplementation(address _implementation) external {
        require(hasRole(FACTORY_ROLE, _msgSender()), "not admin.");

        ISparkbloxContract module = ISparkbloxContract(_implementation);

        bytes32 ctype = module.contractType();
        require(ctype.length > 0, "invalid module");

        uint8 version = module.contractVersion();
        uint8 currentVersionOfType = uint8(currentVersion[ctype]);
        require(version >= currentVersionOfType, "wrong module version");

        currentVersion[ctype] = version;
        implementation[ctype][version] = _implementation;
        approval[_implementation] = true;

        emit ImplementationAdded(_implementation, ctype, version);
    }

    function removeImplementation(address _implementation) external {
        require(hasRole(FACTORY_ROLE, _msgSender()), "not admin.");

        ISparkbloxContract module = ISparkbloxContract(_implementation);

        bytes32 ctype = module.contractType();
        require(ctype.length > 0, "invalid module");

        uint8 version = module.contractVersion();
        require(version > 0, "invalid module");
        
        require(implementation[ctype][version] == _implementation, "No match implementation");

        uint8 currentVersionOfType = uint8(currentVersion[ctype]);
        require(currentVersionOfType == version, "Not current version");

        if(currentVersionOfType > 0) {
            currentVersion[ctype] = currentVersionOfType - 1;
        }

        delete implementation[ctype][version];
        approval[_implementation] == false;

        emit ImplementationRemoved(_implementation, ctype, version);
    }

    /// @dev Lets a contract admin approve a specific contract for deployment.
    function approveImplementation(address _implementation, bool _toApprove) external {
        require(hasRole(FACTORY_ROLE, _msgSender()), "not admin.");

        approval[_implementation] = _toApprove;

        emit ImplementationApproved(_implementation, _toApprove);
    }

    /// @dev Returns the implementation given a contract type and version.
    function getImplementation(bytes32 _type, uint256 _version) external view returns (address) {
        return implementation[_type][_version];
    }

    /// @dev Returns the latest implementation given a contract type.
    function getLatestImplementation(bytes32 _type) external view returns (address) {
        return implementation[_type][currentVersion[_type]];
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}