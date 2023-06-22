// SPDX-License-Identifier: Business Source License 1.1
pragma solidity 0.8.20;
import "IProxyManager.sol";
import "IUpgradable.sol";
import "Extensible.sol";

interface IBootstrap {
    function bootstrap() external;
}

contract ProxyManager is Extensible {
    event Created(
        bytes32 indexed implementation_id,
        address indexed clone,
        uint256 timestamp
    );

    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @notice mapping of the contract id e.g. keccak256("TestExample") to
    /// @notice its actual deployed implementation address.
    mapping(bytes32 => address) public implementations;

    /// @notice mapping of the contract id e.g. keccak256("TestExample") to
    /// @notice all of its "instances", e.g. proxy contract clones.
    mapping(bytes32 => address[]) public instances;
    mapping(address => bytes32) public secnatsni; // reverse instances

    /// @dev this is a generic proxy contract which is cloned for each instance
    /// @dev to make it super cheap to create new instances.
    address internal owner;

    /// @dev Constructor
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "#B26D413B");
        _;
    }

    function extend(address _extension) external onlyOwner {
        _extend(_extension);
    }

    /// @dev returns the bytes32 representation of a string
    /// @param _string string memory
    /// @return bytes32
    function ID(string memory _string) public pure returns (bytes32) {
        return keccak256(bytes(_string));
    }

    function implementationOfStr(
        string memory id
    ) public view returns (address) {
        return implementations[ID(id)];
    }

    function computeAddress(
        bytes memory _byteCode,
        uint256 _salt
    ) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(_byteCode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function computeSalt(
        bytes32 implementation_id,
        bytes memory init_data
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(address(this), implementation_id, init_data)
            );
    }

    /**
     * @notice Deploys a given master Contract as a clone.
     * @notice Any ETH transferred with this call is forwarded to the new clone.
     * @notice Emits `LogDeploy`.
     * @param masterContract The address of the contract to clone.
     * @param salt bytes32 salt data to use.
     * @return clone_address Address of the created clone contract.
     */
    function _cloneAddress(
        address masterContract,
        bytes32 salt
    ) internal view returns (address) {
        require(masterContract != address(0), "#B798D699");
        bytes memory _byteCode = generateCloneBytecode(masterContract);
        return computeAddress(_byteCode, uint256(salt));
    }

    function generateCloneBytecode(
        bytes20 targetBytes
    ) internal pure returns (bytes memory cloneBytecode) {
        cloneBytecode = new bytes(123);

        assembly {
            let clone := add(cloneBytecode, 0x20) // Adjust pointer for length prefix
            mstore8(clone, 0x73)
            mstore(add(clone, 0x1), targetBytes)
            mstore8(add(clone, 0x15), 0x7f)
            mstore(add(clone, 0x16), _IMPLEMENTATION_SLOT)
            mstore(
                add(clone, 0x36),
                0x553d603a8060413d3981f3363d3d373d3d3d363d7f360894a13ba1a3210667c8
            )
            mstore(add(clone, 0x4b), _IMPLEMENTATION_SLOT)
            mstore(
                add(clone, 0x6b),
                0x545af43d82803e903d91603857fd5bf300000000000000000000000000000000
            )
        }
    }

    function generateCloneBytecode(
        address masterContract
    ) internal pure returns (bytes memory) {
        require(masterContract != address(0), "#B798D699");
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address
        return generateCloneBytecode(targetBytes);
    }

    /**
     * @notice Deploys a given master Contract as a clone.
     * @notice Any ETH transferred with this call is forwarded to the new clone.
     * @notice Emits `LogDeploy`.
     * @param masterContract The address of the contract to clone.
     * @param salt bytes32 salt data to use.
     * @return clone_address Address of the created clone contract.
     */
    function _clone(
        address masterContract,
        bytes32 salt
    ) internal returns (address clone_address) {
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address
        bytes memory cloneBytecode = generateCloneBytecode(targetBytes);

        assembly {
            let clone := add(cloneBytecode, 0x20) // Adjust pointer for length prefix
            switch salt
            case 0 {
                clone_address := create(0, clone, 0x7b)
            }
            default {
                clone_address := create2(0, clone, 0x7b, salt)
            }
        }
        return clone_address;
    }

    /**
     * @notice Instantiate a new logic contract
     * @param implementation_id - bytes32 id of the contract to instantiate.
     * @param init_data - Bytes data that is passed to the contract's constructor.
     * @param salt - Salt used for the CREATE2 opcode if 0 use CREATE opcode
     * @return clone_address Address of the created clone contract.
     */
    function create(
        bytes32 implementation_id,
        bytes memory init_data,
        bytes32 salt
    ) public payable onlyOwner returns (address clone_address) {
        address implementation = implementations[implementation_id];
        require(implementation != address(0), "#F7DE9E64");
        require(implementation.code.length > 0, "#F49B7998");
        clone_address = _clone(implementation, salt);
        require(clone_address != address(0), "#AC7BF371");
        instances[implementation_id].push(clone_address);
        secnatsni[clone_address] = implementation_id;
        IBootstrap(clone_address).bootstrap(); // set _proxyOwner to ourselves
        IUpgradable(clone_address).init{value: msg.value}(init_data);
        emit Created(implementation_id, clone_address, block.timestamp);
    }

    function createAddress(
        bytes32 implementation_id,
        bytes32 salt
    ) public view returns (address) {
        address implementation = implementations[implementation_id];
        require(implementation != address(0), "#F7DE9E64");
        require(implementation.code.length > 0, "#F49B7998");
        return _cloneAddress(implementation, salt);
    }

    function setImplementation(
        bytes32 implementation_id,
        address implementation,
        bytes calldata upgrade_data
    ) public onlyOwner {
        setImplementation(
            implementation_id,
            implementation,
            upgrade_data,
            true
        );
    }

    function setImplementationStr(
        string memory implementation_id,
        address implementation,
        bytes calldata upgrade_data
    ) public onlyOwner {
        return
            setImplementation(
                ID(implementation_id),
                implementation,
                upgrade_data
            );
    }

    /**
     * @notice Instantiate a new logic contract
     * @param implementation_id - bytes32 id of the contract to instantiate.
     * @param init_data - Bytes data that is passed to the contract's constructor.
     * @return clone_address Address of the created clone contract.
     */
    function create(
        bytes32 implementation_id,
        bytes memory init_data
    ) public payable onlyOwner returns (address clone_address) {
        return
            create(
                implementation_id,
                init_data,
                computeSalt(implementation_id, init_data)
            );
    }

    function createAddress(
        bytes32 implementation_id,
        bytes memory init_data
    ) public view returns (address) {
        return
            createAddress(
                implementation_id,
                computeSalt(implementation_id, init_data)
            );
    }

    function createStr(
        string memory impl_str,
        bytes memory init_data
    ) public payable onlyOwner returns (address clone_address) {
        bytes32 implementation_id = ID(impl_str);
        return create(implementation_id, init_data);
    }

    function createStrAddress(
        string memory impl_str,
        bytes memory init_data
    ) public view returns (address) {
        bytes32 implementation_id = ID(impl_str);
        return createAddress(implementation_id, init_data);
    }

    /**
     * @notice When a master logic contract is deployed, it should register itself. Each clone
     * @notice can then request a logic of this type using getlogic(address(this), logic_id)
     * @param implementation_id bytes32 identifier of logic type, e.g. keccak256(abi.encodePacked("String"))
     * @param implementation address of the master contract implementing that type.
     */
    function setImplementation(
        bytes32 implementation_id,
        address implementation,
        bytes calldata upgrade_data,
        bool callUpdate
    ) public onlyOwner {
        require(implementation.code.length > 0, "#075051C6");
        implementations[implementation_id] = implementation;

        // for each item in instances, change the implementation
        for (uint i = 0; i < instances[implementation_id].length; i++) {
            IUpgradable(instances[implementation_id][i]).updateImplementation(
                implementation
            );
            if (callUpdate)
                IUpgradable(instances[implementation_id][i]).upgrade(
                    upgrade_data
                );
        }
    }

    function upgradeContract(
        address clone_address,
        bytes calldata upgrade_data
    ) external onlyOwner {
        require(secnatsni[clone_address] != 0, "#85494455");
        IUpgradable(clone_address).upgrade(upgrade_data);
    }
}