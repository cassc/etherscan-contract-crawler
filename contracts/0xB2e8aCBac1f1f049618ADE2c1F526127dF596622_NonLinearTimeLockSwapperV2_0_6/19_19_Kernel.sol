// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This contains proxy initialization data
 */
abstract contract Kernel {
    bytes32 private constant INITIALIZED = bytes32(uint256(keccak256("Kernel.INITIALIZED")) - 1);

    // initialized for the version
    mapping(bytes32 => bool) private _initialized;

    modifier onlyKernelInitialized() {
        require(kernelInitialized(), "Kernel: no-init");
        _;
    }

    modifier onlyKernelInitializedWithVersion(string memory version) {
        require(kernelInitialized(getVersionHash(version)), "Kernel: no-init");
        _;
    }

    /// @dev Each implementation contract must implement `implementationVersion` with unique return value for a proxy.
    function implementationVersion() public view virtual returns (string memory);

    /// @dev External function to initialize proxy, with specific `_initializeKernel`
    ///      implemented in each implementation contract.
    function initializeKernel(bytes calldata data) external returns (bool) {
        require(!kernelInitialized(), "Kernel: already-init");

        bytes32 h = getVersionHash();
        _initialized[h] = true;

        _initializeKernel(data);

        return true;
    }

    /// @dev Implementation contract have to override `_initializeKernel` to initialize after proxy upgraded.
    function _initializeKernel(bytes memory data) internal virtual;

    function kernelInitialized() public view returns (bool) {
        bytes32 h = getVersionHash();
        return _initialized[h];
    }

    /// @dev Return whether kernel is initialized with version hash.
    function kernelInitialized(bytes32 h) public view returns (bool) {
        return _initialized[h];
    }

    /// @dev Return hash of current implementation version.
    function getVersionHash() public view returns (bytes32) {
        return getVersionHash(implementationVersion());
    }

    /// @dev Return hash of given implementation version.
    function getVersionHash(string memory version) public pure returns (bytes32) {
        bytes32 h = keccak256(abi.encode(INITIALIZED, version));
        return h;
    }
}