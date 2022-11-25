// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "Witnet.sol";
import "Clonable.sol";
import "Ownable.sol";
import "Proxiable.sol";

abstract contract WitnetRequestMalleableBase
    is
        IWitnetRequest,
        Clonable,
        Ownable,
        Proxiable
{
    using Witnet for bytes;

    event WitnessingParamsChanged(
        address indexed by,
        uint8 numWitnesses,
        uint8 minWitnessingConsensus,
        uint64 witnssingCollateral,
        uint64 witnessingReward,
        uint64 witnessingUnitaryFee
    );

    error requestAlreadyInitialized();
    error noWitnessingReward();
    error invalidNumWitnesses(uint8 _numWitnesses);
    error invalidWitnessingConsensus(uint8 _minWitnessingConsensus);
    error invalidWitnessingCollateral(uint64 _witnessingCollateral);

    struct WitnetRequestMalleableBaseContext {
        /// Contract owner address.
        address owner;
        /// Immutable bytecode template.
        bytes template;
        /// Current request bytecode.
        bytes bytecode;
        /// Current request hash.
        bytes32 hash;
        /// Current request witnessing params.
        WitnetRequestWitnessingParams params;
    }

    struct WitnetRequestWitnessingParams {
        /// Number of witnesses required to be involved for solving this Witnet Data Request.
        uint8 numWitnesses;

        /// Threshold percentage for aborting resolution of a request if the witnessing nodes did not arrive to a broad consensus.
        uint8 minWitnessingConsensus;

        /// Amount of nanowits that a witness solving the request will be required to collateralize in the commitment transaction.
        uint64 witnessingCollateral;

        /// Amount of nanowits that every request-solving witness will be rewarded with.
        uint64 witnessingReward;

        /// Amount of nanowits that will be earned by Witnet miners for each each valid commit/reveal transaction they include in a block.
        uint64 witnessingUnitaryFee;
    }

    /// Returns current Witnet Data Request bytecode, encoded using Protocol Buffers.
    function bytecode() external view override returns (bytes memory) {
        return _request().bytecode;
    }

    /// Returns SHA256 hash of current Witnet Data Request bytecode.
    function hash() external view override returns (bytes32) {
        return _request().hash;
    }

    /// Specifies how much you want to pay for rewarding each of the Witnet nodes.
    /// @param _witnessingCollateral Sets amount of nanowits that a witness solving the request will be required to collateralize.
    /// @param _witnessingReward Amount of nanowits that every request-solving witness will be rewarded with.
    /// @param _witnessingUnitaryFee Amount of nanowits that will be earned by Witnet miners for each each valid 
    /// commit/reveal transaction they include in a block.
    function setWitnessingMonetaryPolicy(uint64 _witnessingCollateral, uint64 _witnessingReward, uint64 _witnessingUnitaryFee)
        public
        virtual
        onlyOwner
    {
        WitnetRequestWitnessingParams storage _params = _request().params;
        _params.witnessingCollateral = _witnessingCollateral;
        _params.witnessingReward = _witnessingReward;
        _params.witnessingUnitaryFee = _witnessingUnitaryFee;
        _malleateBytecode(
            _params.numWitnesses,
            _params.minWitnessingConsensus,
            _witnessingCollateral,
            _witnessingReward,
            _witnessingUnitaryFee
        );
    }

    /// Sets how many Witnet nodes will be "hired" for resolving the request.
    /// @param _numWitnesses Number of witnesses required to be involved for solving this Witnet Data Request.
    /// @param _minWitnessingConsensus Threshold percentage for aborting resolution of a request if the witnessing 
    /// nodes did not arrive to a broad consensus.
    function setWitnessingQuorum(uint8 _numWitnesses, uint8 _minWitnessingConsensus)
        public
        virtual
        onlyOwner
    {
        WitnetRequestWitnessingParams storage _params = _request().params;
        _params.numWitnesses = _numWitnesses;
        _params.minWitnessingConsensus = _minWitnessingConsensus;
        _malleateBytecode(
            _numWitnesses,
            _minWitnessingConsensus,
            _params.witnessingCollateral,
            _params.witnessingReward,
            _params.witnessingUnitaryFee
        );
    }

    /// Sets all witness parameters for a request
    /// @param _witnessingCollateral: Amount of nanowits that a witness solving the request will be required to collateralize in the commitment transaction.
    /// @param _witnessingReward Amount of nanowits that every request-solving witness will be rewarded with.
    /// @param _witnessingUnitaryFee Amount of nanowits that will be earned by Witnet miners for each each valid 
    /// commit/reveal transaction they include in a block.
    /// @param _numWitnesses Number of witnesses required to be involved for solving this Witnet Data Request.
    /// @param _minWitnessingConsensus Threshold percentage for aborting resolution of a request if the witnessing 
    /// nodes did not arrive to a broad consensus.
    function setWitnessingParameters(uint64 _witnessingCollateral, uint64 _witnessingReward, uint64 _witnessingUnitaryFee, uint8 _numWitnesses, uint8 _minWitnessingConsensus)
        public
        virtual
        onlyOwner
    {
        WitnetRequestWitnessingParams storage _params = _request().params;
        _params.witnessingCollateral = _witnessingCollateral;
        _params.witnessingReward = _witnessingReward;
        _params.witnessingUnitaryFee = _witnessingUnitaryFee;
        _params.numWitnesses = _numWitnesses;
        _params.minWitnessingConsensus = _minWitnessingConsensus;
        _malleateBytecode(
            _numWitnesses,
            _minWitnessingConsensus,
            _witnessingCollateral,
            _witnessingReward,
            _witnessingUnitaryFee
        );
    }

    /// Returns immutable template bytecode: actual CBOR-encoded data request at the Witnet protocol
    /// level, including no witnessing parameters at all.
    function template()
        external view
        returns (bytes memory)
    {
        return _request().template;
    }

    /// Returns total amount of nanowits that witnessing nodes will need to collateralize all together.
    function totalWitnessingCollateral()
        external view
        returns (uint128)
    {
        WitnetRequestWitnessingParams storage _params = _request().params;
        return _params.numWitnesses * _params.witnessingCollateral;
    }

    /// Returns total amount of nanowits that will have to be paid in total for this request to be solved.
    function totalWitnessingFee()
        external view
        returns (uint128)
    {
        WitnetRequestWitnessingParams storage _params = _request().params;
        return _params.numWitnesses * (2 * _params.witnessingUnitaryFee + _params.witnessingReward);
    }

    /// Returns witnessing parameters of current Witnet Data Request.
    function witnessingParams()
        external view
        returns (WitnetRequestWitnessingParams memory)
    {
        return _request().params;
    }


    // ================================================================================================================
    // --- 'Clonable' overriden functions -----------------------------------------------------------------------------

    /// Deploys and returns the address of a minimal proxy clone that replicates contract
    /// behaviour while using its own EVM storage.
    /// @dev This function should always provide a new address, no matter how many times 
    /// @dev is actually called from the same `msg.sender`.
    function clone()
        public
        virtual override
        returns (Clonable _instance)
    {
        _instance = super.clone();
        _instance.initialize(_request().template);
        Ownable(address(_instance)).transferOwnership(msg.sender);
    }

    /// Deploys and returns the address of a minimal proxy clone that replicates contract 
    /// behaviour while using its own EVM storage.
    /// @dev This function uses the CREATE2 opcode and a `_salt` to deterministically deploy
    /// @dev the clone. Using the same `_salt` multiple time will revert, since
    /// @dev no contract can be deployed more than once at the same address.
    function cloneDeterministic(bytes32 _salt)
        public
        virtual override
        returns (Clonable _instance)
    {
        _instance = super.cloneDeterministic(_salt);
        _instance.initialize(_request().template);
        Ownable(address(_instance)).transferOwnership(msg.sender);
    }


    // ================================================================================================================
    // --- 'Initializable' overriden functions ------------------------------------------------------------------------

    /// @dev Initializes contract's storage context.
    function initialize(bytes memory _template)
        public
        virtual override
    {
        if (_request().template.length > 0)
            revert requestAlreadyInitialized();
        _initialize(_template);
        _transferOwnership(_msgSender());
    }

    // ================================================================================================================
    // --- 'Ownable' overriden functions ------------------------------------------------------------------------------

    /// Returns the address of the current owner.
    function owner()
        public view
        virtual override
        returns (address)
    {
        return _request().owner;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    function _transferOwnership(address newOwner)
        internal
        virtual override
    {
        address oldOwner = _request().owner;
        _request().owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // ================================================================================================================
    // --- 'Proxiable 'overriden functions ----------------------------------------------------------------------------

    /// @dev Complying with EIP-1822: Universal Upgradable Proxy Standard (UUPS)
    /// @dev See https://eips.ethereum.org/EIPS/eip-1822.
    function proxiableUUID()
        external pure
        virtual override
        returns (bytes32)
    {
        return (
            /* keccak256("io.witnet.requests.malleable") */
            0x851d0a92a3ad30295bef33afc69d6874779826b7789386b336e22621365ed2c2
        );
    }


    // ================================================================================================================
    // --- INTERNAL FUNCTIONS -----------------------------------------------------------------------------------------    

    /// @dev Initializes witnessing params and template bytecode.
    function _initialize(bytes memory _template)
        internal
    {
        assert(_template.length > 0);
        _request().template = _template;

        WitnetRequestWitnessingParams storage _params = _request().params;
        _params.numWitnesses = 2;
        _params.minWitnessingConsensus = 51;
        _params.witnessingCollateral = 10 ** 9;      // 1 WIT
        _params.witnessingReward = 5 * 10 ** 5;      // 0.5 milliWITs
        _params.witnessingUnitaryFee = 25 * 10 ** 4; // 0.25 milliWITs

        _malleateBytecode(
            _params.numWitnesses,
            _params.minWitnessingConsensus,
            _params.witnessingCollateral,
            _params.witnessingReward,
            _params.witnessingUnitaryFee
        );
    }

    /// @dev Serializes new `bytecode` by combining immutable template with given parameters.
    function _malleateBytecode(
            uint8 _numWitnesses,
            uint8 _minWitnessingConsensus,
            uint64 _witnessingCollateral,
            uint64 _witnessingReward,
            uint64 _witnessingUnitaryFee
        )
        internal
        virtual
    {
        if (_witnessingReward == 0)
            revert noWitnessingReward();
        if (_numWitnesses > 125 || _numWitnesses == 0)
            revert invalidNumWitnesses(_numWitnesses);
        if (_minWitnessingConsensus < 51 || _minWitnessingConsensus > 99)
            revert invalidWitnessingConsensus(_minWitnessingConsensus);
        if (_witnessingCollateral < 10 ** 9)
            revert invalidWitnessingCollateral(_witnessingCollateral);

        _request().bytecode = abi.encodePacked(
            _request().template,
            _uint64varint(bytes1(0x10), _witnessingReward),
            _uint8varint(bytes1(0x18), _numWitnesses),
            _uint64varint(0x20, _witnessingUnitaryFee),
            _uint8varint(0x28, _minWitnessingConsensus),
            _uint64varint(0x30, _witnessingCollateral)
        );
        _request().hash = _request().bytecode.hash();
        emit WitnessingParamsChanged(
            msg.sender,
            _numWitnesses,
            _minWitnessingConsensus,
            _witnessingCollateral,
            _witnessingReward,
            _witnessingUnitaryFee
        );
    }

    /// @dev Returns pointer to storage slot where State struct is located.
    function _request()
        internal pure
        virtual
        returns (WitnetRequestMalleableBaseContext storage _ptr)
    {
        assembly {
            _ptr.slot :=
                /* keccak256("io.witnet.requests.malleable.context") */
                0x375930152e1d0d102998be6e496b0cee86c9ecd0efef01014ecff169b17dfba7
        }
    }

    /// @dev Encode uint64 into tagged varint.
    /// @dev See https://developers.google.com/protocol-buffers/docs/encoding#varints.
    /// @param t Tag
    /// @param n Number
    /// @return Marshaled bytes
    function _uint64varint(bytes1 t, uint64 n)
        internal pure
        returns (bytes memory)
    {
        // Count the number of groups of 7 bits
        // We need this pre-processing step since Solidity doesn't allow dynamic memory resizing
        uint64 tmp = n;
        uint64 numBytes = 2;
        while (tmp > 0x7F) {
            tmp = tmp >> 7;
            unchecked {
                numBytes += 1;
            }
        }
        bytes memory buf = new bytes(numBytes);
        tmp = n;
        buf[0] = t;
        for (uint64 i = 1; i < numBytes;) {
            // Set the first bit in the byte for each group of 7 bits
            buf[i] = bytes1(0x80 | uint8(tmp & 0x7F));
            tmp = tmp >> 7;
            unchecked {
                i++;
            }
        }
        // Unset the first bit of the last byte
        buf[numBytes - 1] &= 0x7F;
        return buf;
    }

    /// @dev Encode uint8 into tagged varint.
    /// @param t Tag
    /// @param n Number
    /// @return Marshaled bytes
    function _uint8varint(bytes1 t, uint8 n)
        internal pure
        returns (bytes memory)
    {
        return _uint64varint(t, uint64(n));
    }
}