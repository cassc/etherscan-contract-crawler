// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/proxy/Clones.sol";

import "./Ownable.sol";

interface ITWFactory {
    function deployProxyByImplementation(
        address _implementation,
        bytes memory _data,
        bytes32 _salt
    ) external returns (address);
}

interface ITWTokenERC1155 {
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _primarySaleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external;

    function mintTo(
        address to,
        uint256 tokenId,
        string calldata uri,
        uint256 amount
    ) external;

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function setOwner(address _newOwner) external;

    function setFlatPlatformFeeInfo(
        address _platformFeeRecipient,
        uint256 _flatFee
    ) external;

    enum PlatformFeeType {
        Bps,
        FLAT
    }

    function setPlatformFeeType(PlatformFeeType _feeType) external;
}

interface ISignatureDropDeployer {
    event ProxyDeployed(
        address indexed proxyAddress,
        address indexed admin,
        bytes32 salt
    );

    event NewMinter(address indexed oldMinter, address indexed newMinter);

    struct DeployParams {
        address admin;
        string _name;
        string _symbol;
        string _contractURI;
        string _uri;
        address[] _trustedForwarders;
        address _primarySaleRecipient;
        address _royaltyRecipient;
        uint128 _royaltyBps;
        uint256 _platformFee;
        address _platformFeeRecipient;
        bytes32 salt;
    }

    function setMinter(address _newMinter) external;

    function deploy(DeployParams memory params) external returns (address);

    function predictDeterministicAddress(bytes32 _salt)
        external
        view
        returns (address);
}

contract SignatureDropDeployer is ISignatureDropDeployer, Ownable {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    address public immutable TWFactoryAddress;

    address public immutable TWEditionImplementationAddress;

    address public minter;

    constructor(
        address _owner,
        address _minter,
        address _factory,
        address _implementation
    ) Ownable(_owner) {
        _setMinter(_minter);

        TWFactoryAddress = _factory;
        TWEditionImplementationAddress = _implementation;
    }

    function setMinter(address _newMinter) public override onlyOwner {
        _setMinter(_newMinter);
    }

    function deploy(DeployParams memory params)
        public
        override
        returns (address)
    {
        bytes memory callData = abi.encodeWithSelector(
            ITWTokenERC1155.initialize.selector,
            address(this),
            params._name,
            params._symbol,
            params._contractURI,
            params._trustedForwarders,
            params._primarySaleRecipient,
            params._royaltyRecipient,
            params._royaltyBps,
            0, // no bps fee for platform
            params._platformFeeRecipient
        );

        // Deploy proxy.
        address proxyAddress = _deployProxy(callData, params.salt);

        // Mint token to admin.
        ITWTokenERC1155(proxyAddress).mintTo(
            params.admin,
            type(uint256).max,
            params._uri,
            0
        );

        // Set fees.
        _setFees(
            proxyAddress,
            params._platformFeeRecipient,
            params._platformFee
        );

        // Set roles.
        _setRoles(proxyAddress, params.admin);

        emit ProxyDeployed(proxyAddress, params.admin, params.salt);

        return proxyAddress;
    }

    function predictDeterministicAddress(bytes32 _salt)
        public
        view
        override
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(
                TWEditionImplementationAddress,
                keccak256(abi.encodePacked(address(this), _salt)),
                TWFactoryAddress
            );
    }

    function _setMinter(address _newMinter) internal {
        emit NewMinter(minter, _newMinter);

        minter = _newMinter;
    }

    function _deployProxy(bytes memory callData, bytes32 salt)
        internal
        returns (address)
    {
        return
            ITWFactory(TWFactoryAddress).deployProxyByImplementation(
                TWEditionImplementationAddress,
                callData,
                salt
            );
    }

    function _setFees(
        address proxyAddress,
        address _platformFeeRecipient,
        uint256 _platformFee
    ) internal {
        ITWTokenERC1155(proxyAddress).setFlatPlatformFeeInfo(
            _platformFeeRecipient,
            _platformFee
        );
        ITWTokenERC1155(proxyAddress).setPlatformFeeType(
            ITWTokenERC1155.PlatformFeeType.FLAT
        );
    }

    function _setRoles(address proxyAddress, address admin) internal {
        // Grant minter role to Mirror wallet.
        ITWTokenERC1155(proxyAddress).grantRole(MINTER_ROLE, minter);

        // Set roles for admin.
        ITWTokenERC1155(proxyAddress).grantRole(DEFAULT_ADMIN_ROLE, admin);
        ITWTokenERC1155(proxyAddress).grantRole(MINTER_ROLE, admin);
        ITWTokenERC1155(proxyAddress).grantRole(TRANSFER_ROLE, admin);

        // Remove roles for deployer.
        ITWTokenERC1155(proxyAddress).revokeRole(MINTER_ROLE, address(this));
        ITWTokenERC1155(proxyAddress).revokeRole(TRANSFER_ROLE, address(this));

        // Transfer ownership to admin.
        ITWTokenERC1155(proxyAddress).setOwner(admin);

        ITWTokenERC1155(proxyAddress).revokeRole(
            DEFAULT_ADMIN_ROLE,
            address(this)
        );
    }
}