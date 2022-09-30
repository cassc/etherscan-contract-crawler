//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0;

// Copied and modified from YAM code:
// https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
// https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
// Which is copied and modified from COMPOUND:
// https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

import "../libraries/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// Geometry governance token
contract SynthToken is ERC20("Synth", "SYNTH") {
    using EnumerableSet for EnumerableSet.AddressSet;

    // @notice Checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // Set of addresses which can mint SYNTH
    EnumerableSet.AddressSet private _minters;
 
    /// @dev A record of each accounts delegate
    mapping(address => address) internal _delegates;

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event that's emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event that's emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Synth: not minter");
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Synth: zero address");
        _;
    }

    /// @notice Creates _amount of token to _to.
    function mint(address _to, uint256 _amount)
        external 
        onlyMinter
        returns (bool)
    {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
        return true;
    }

    /// @notice Destroys _amount tokens from _account reducing the total supply
    function burn(address _account, uint256 _amount) external onlyMinter {
        _burn(_account, _amount);
    }

    /// @notice Delegate votes from msg.sender to _delegatee
    /// @param _delegatee The address to delegate votes to
    function delegate(address _delegatee) external {
        return _delegate(msg.sender, _delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param _delegatee The address to delegate votes to
     * @param _nonce The contract state required to match the signature
     * @param _expiry The time at which to expire the signature
     * @param _v The recovery byte of the signature
     * @param _r Half of the ECDSA signature pair
     * @param _s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address _delegatee,
        uint256 _nonce,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                _getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, _delegatee, _nonce, _expiry)
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        address signatory = ecrecover(digest, _v, _r, _s);

        require(signatory != address(0), "Synth: invalid signature");
        require(_nonce == nonces[signatory]++, "Synth: invalid nonce");
        require(block.timestamp <= _expiry, "Synth: signature expired");

        return _delegate(signatory, _delegatee);
    }

    /**
     * @dev used by owner to delete minter of token
     * @param _delMinter address of minter to be deleted.
     * @return true if successful.
     */
    function delMinter(address _delMinter) external onlyOwner onlyValidAddress(_delMinter) returns (bool) {
        return EnumerableSet.remove(_minters, _delMinter);
    }

    /// @notice Delegate votes from msg.sender to _delegatee
    /// @param _delegator The address to get delegatee for
    function delegates(address _delegator) external view returns (address) {
        return _delegates[_delegator];
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param _account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address _account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[_account];
        return
            nCheckpoints > 0 ? checkpoints[_account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param _account The address of the account to check
     * @param _blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address _account, uint256 _blockNumber)
        external
        view
        returns (uint256)
    {
        require(_blockNumber < block.number, "Synth: invalid blockNumber");

        uint32 nCheckpoints = numCheckpoints[_account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[_account][nCheckpoints - 1].fromBlock <= _blockNumber) {
            return checkpoints[_account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[_account][0].fromBlock > _blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[_account][center];
            if (cp.fromBlock == _blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < _blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[_account][lower].votes;
    }

    /**
     * @dev used by get the minter at n location
     * @param _index index of address set
     * @return address of minter at index.
     */
    function getMinter(uint256 _index)
        external
        view
        onlyOwner
        returns (address)
    {
        require(_index <= getMinterLength() - 1, "Synth: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    /**
     * @dev used by owner to add minter of token
     * @param _addMinter address of minter to be added.
     * @return true if successful.
     */
    function addMinter(address _addMinter) public onlyOwner onlyValidAddress(_addMinter) returns (bool) {
        return EnumerableSet.add(_minters, _addMinter);
    }

    /// @dev used to get the number of minters for this token
    /// @return number of minters.
    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    /// @dev used to check if an address is a minter of token
    /// @return true or false based on minter status.
    function isMinter(address _account) public view returns (bool) {
        return EnumerableSet.contains(_minters, _account);
    }

    // internal function used delegate votes
    function _delegate(address _delegator, address _delegatee) internal {
        address currentDelegate = _delegates[_delegator];
        uint256 delegatorBalance = balanceOf(_delegator); // balance of underlying SYNTHs (not scaled);
        _delegates[_delegator] = _delegatee;

        emit DelegateChanged(_delegator, currentDelegate, _delegatee);

        _moveDelegates(currentDelegate, _delegatee, delegatorBalance);
    }

    // send delegate votes from src to dst in amount
    function _moveDelegates(
        address _srcRep,
        address _dstRep,
        uint256 _amount
    ) internal {
        if (_srcRep != _dstRep && _amount > 0) {
            if (_srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[_srcRep];
                uint256 srcRepOld = srcRepNum > 0
                    ? checkpoints[_srcRep][srcRepNum - 1].votes
                    : 0;
                uint256 srcRepNew = srcRepOld - _amount;
                _writeCheckpoint(_srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (_dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[_dstRep];
                uint256 dstRepOld = dstRepNum > 0
                    ? checkpoints[_dstRep][dstRepNum - 1].votes
                    : 0;
                uint256 dstRepNew = dstRepOld + _amount;
                _writeCheckpoint(_dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address _delegatee,
        uint32 _nCheckpoints,
        uint256 _oldVotes,
        uint256 _newVotes
    ) internal {
        uint32 blockNumber = _safe32(
            block.number,
            "SYNTH::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            _nCheckpoints > 0 &&
            checkpoints[_delegatee][_nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[_delegatee][_nCheckpoints - 1].votes = _newVotes;
        } else {
            checkpoints[_delegatee][_nCheckpoints] = Checkpoint(
                blockNumber,
                _newVotes
            );
            numCheckpoints[_delegatee] = _nCheckpoints + 1;
        }

        emit DelegateVotesChanged(_delegatee, _oldVotes, _newVotes);
    }

    // @dev used get current chain ID
    // @return id as a uint
    function _getChainId() internal view returns (uint256 id) {
        id = block.chainid;
    }

    /*
     * @dev Checks if value is 32 bits
     * @param _n value to be checked
     * @param _errorMessage error message to throw if fails
     * @return The number if valid.
     */
    function _safe32(uint256 _n, string memory _errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(_n < 2**32, _errorMessage);
        return uint32(_n);
    }
}