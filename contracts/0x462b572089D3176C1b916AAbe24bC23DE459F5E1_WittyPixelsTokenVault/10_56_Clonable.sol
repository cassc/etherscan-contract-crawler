// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./Initializable.sol";

abstract contract Clonable
    is
        Initializable
{
    address immutable internal _SELF = address(this);

    event Cloned(address indexed by, address indexed self, address indexed clone);

    modifier onlyDelegateCalls virtual {
        require(address(this) != _SELF, "Clonable: not a delegate call");
        _;
    }

    modifier wasInitialized {
        require(initialized(), "Clonable: not initialized");
        _;
    }

    /// @notice Tells whether this contract is a clone of `self()`
    function cloned()
        public view
        returns (bool)
    {
        return (
            address(this) != self()
        );
    }

    /// @notice Tells whether this instance has been initialized.
    function initialized() virtual public view returns (bool);

    /// @notice Contract address to which clones will be re-directed.
    function self() virtual public view returns (address) {
        return _SELF;
    }

    /// Deploys and returns the address of a minimal proxy clone that replicates contract
    /// behaviour while using its own EVM storage.
    /// @dev This function should always provide a new address, no matter how many times 
    /// @dev is actually called from the same `msg.sender`.
    /// @dev See https://eips.ethereum.org/EIPS/eip-1167.
    /// @dev See https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/.
    function _clone()
        internal
        returns (address _instance)
    {
        bytes memory ptr = _cloneBytecodePtr();
        assembly {
            // CREATE new instance:
            _instance := create(0, ptr, 0x37)
        }        
        require(_instance != address(0), "Clonable: CREATE failed");
        emit Cloned(msg.sender, self(), _instance);
    }

    /// @notice Returns minimal proxy's deploy bytecode.
    function _cloneBytecode()
        virtual internal view
        returns (bytes memory)
    {
        return abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            bytes20(self()),
            hex"5af43d82803e903d91602b57fd5bf3"
        );
    }

    /// @notice Returns mem pointer to minimal proxy's deploy bytecode.
    function _cloneBytecodePtr()
        virtual internal view
        returns (bytes memory ptr)
    {
        address _base = self();
        assembly {
            // ptr to free mem:
            ptr := mload(0x40)
            // begin minimal proxy construction bytecode:
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            // make minimal proxy delegate all calls to `self()`:
            mstore(add(ptr, 0x14), shl(0x60, _base))
            // end minimal proxy construction bytecode:
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
        }
    }

    /// Deploys and returns the address of a minimal proxy clone that replicates contract 
    /// behaviour while using its own EVM storage.
    /// @dev This function uses the CREATE2 opcode and a `_salt` to deterministically deploy
    /// @dev the clone. Using the same `_salt` multiple times will revert, since
    /// @dev no contract can be deployed more than once at the same address.
    /// @dev See https://eips.ethereum.org/EIPS/eip-1167.
    /// @dev See https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/.
    function _cloneDeterministic(bytes32 _salt)
        internal
        returns (address _instance)
    {
        bytes memory ptr = _cloneBytecodePtr();
        assembly {
            // CREATE2 new instance:
            _instance := create2(0, ptr, 0x37, _salt)
        }
        require(_instance != address(0), "Clonable: CREATE2 failed");
        emit Cloned(msg.sender, self(), _instance);
    }
}