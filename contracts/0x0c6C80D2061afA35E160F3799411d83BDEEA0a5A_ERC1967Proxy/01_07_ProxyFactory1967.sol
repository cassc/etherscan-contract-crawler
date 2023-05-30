pragma solidity >=0.8;

import "openzeppelin-solidity/contracts/proxy/Proxy.sol";
import "openzeppelin-solidity/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";

contract ERC1967Proxy is Proxy, ERC1967Upgrade {
	/**
	 * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
	 *
	 * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
	 * function call, and allows initializating the storage of the proxy like a Solidity constructor.
	 */
	function initialize(address _logic, bytes calldata _data) external payable {
		require(_getImplementation() == address(0), "initialized");
		assert(
			_IMPLEMENTATION_SLOT ==
				bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
		);
		_upgradeToAndCall(_logic, _data, false);
	}

	/**
	 * @dev Returns the current implementation address.
	 */
	function _implementation()
		internal
		view
		virtual
		override
		returns (address impl)
	{
		return ERC1967Upgrade._getImplementation();
	}
}

contract ProxyFactory1967 {
	event ProxyCreated(address proxy);
	event ContractCreated(address addr);

	bytes32 private contractCodeHash;

	constructor() public {
		contractCodeHash = keccak256(type(ERC1967Proxy).creationCode);
	}

	function deployMinimal(address _logic, bytes memory _data)
		public
		returns (address proxy)
	{
		// Adapted from https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
		bytes20 targetBytes = bytes20(_logic);
		assembly {
			let clone := mload(0x40)
			mstore(
				clone,
				0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
			)
			mstore(add(clone, 0x14), targetBytes)
			mstore(
				add(clone, 0x28),
				0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
			)
			proxy := create(0, clone, 0x37)
		}

		emit ProxyCreated(address(proxy));

		if (_data.length > 0) {
			(bool success, ) = proxy.call(_data);
			require(success);
		}
	}

	function deployProxy(
		uint256 _salt,
		address _logic,
		bytes memory _data
	) public returns (address) {
		return _deployProxy(_salt, _logic, _data, msg.sender);
	}

	function deployCode(uint256 _salt, bytes calldata _bytecode)
		external
		returns (address)
	{
		address addr = _deployCode(_salt, msg.sender, _bytecode);
		emit ContractCreated(addr);
		return addr;
	}

	function getDeploymentAddress(uint256 _salt, address _sender)
		public
		view
		returns (address)
	{
		return getDeploymentAddress(_salt, _sender, contractCodeHash);
	}

	function getDeploymentAddress(
		uint256 _salt,
		address _sender,
		bytes32 _contractCodeHash
	) public view returns (address) {
		// Adapted from https://github.com/archanova/solidity/blob/08f8f6bedc6e71c24758d20219b7d0749d75919d/contracts/contractCreator/ContractCreator.sol
		bytes32 salt = _getSalt(_salt, _sender);
		bytes32 rawAddress = keccak256(
			abi.encodePacked(bytes1(0xff), address(this), salt, _contractCodeHash)
		);

		return address(bytes20(rawAddress << 96));
	}

	function _deployProxy(
		uint256 _salt,
		address _logic,
		bytes memory _data,
		address _sender
	) internal returns (address) {
		bytes memory code = type(ERC1967Proxy).creationCode;

		address payable addr = _deployCode(_salt, _sender, code);

		ERC1967Proxy proxy = ERC1967Proxy(addr);

		proxy.initialize(_logic, _data);
		emit ProxyCreated(address(proxy));
		return address(proxy);
	}

	function _deployCode(
		uint256 _salt,
		address _sender,
		bytes memory _code
	) internal returns (address payable) {
		address payable addr;
		bytes32 salt = _getSalt(_salt, _sender);
		assembly {
			addr := create2(0, add(_code, 0x20), mload(_code), salt)
			if iszero(extcodesize(addr)) {
				revert(0, 0)
			}
		}
		return addr;
	}

	function _getSalt(uint256 _salt, address _sender)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked(_salt, _sender));
	}
}