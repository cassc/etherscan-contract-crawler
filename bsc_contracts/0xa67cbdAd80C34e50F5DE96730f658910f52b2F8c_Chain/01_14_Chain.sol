// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./BaseChain.sol";

contract Chain is BaseChain {
    IStakingBank public immutable stakingBank;

    event LogMint(address indexed minter, uint256 blockId, uint256 staked, uint256 power);
    event LogVoter(uint256 indexed blockId, address indexed voter, uint256 vote);

    error NotEnoughSignatures();
    error SignaturesOutOfOrder();

    /// @param _contractRegistry Registry address
    /// @param _padding required "space" between blocks in seconds
    /// @param _requiredSignatures number of required signatures for accepting consensus submission
    /// @param _allowForMixedType we have two "types" of Chain: HomeChain and ForeignChain, when we redeploying
    /// we don't want to mix up them, so we checking, if new Chain has the same type as current one.
    /// However, when we will be switching from one homechain to another one, we have to allow for this mixing up.
    /// This flag will tell contract, if this is the case.
    constructor(
        IRegistry _contractRegistry,
        uint32 _padding,
        uint16 _requiredSignatures,
        bool _allowForMixedType
    ) BaseChain(_contractRegistry, _padding, _requiredSignatures, _allowForMixedType) {
        stakingBank = IStakingBank(_contractRegistry.requireAndGetAddress("StakingBank"));
    }

    /// @dev method for submitting consensus data
    /// @param _dataTimestamp consensus timestamp, this is time for all data in merkle tree including FCDs
    /// @param _root merkle root
    /// @param _keys FCDs keys
    /// @param _values FCDs values
    /// @param _v array of `v` part of validators signatures
    /// @param _r array of `r` part of validators signatures
    /// @param _s array of `s` part of validators signatures
    // solhint-disable-next-line function-max-lines, code-complexity
    function submit(
        uint32 _dataTimestamp,
        bytes32 _root,
        bytes32[] memory _keys,
        uint256[] memory _values,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s
    ) external {
        // below two checks are only for pretty errors, so we can safe gas and allow for raw revert
        // if (_keys.length != _values.length) revert ArraysDataDoNotMatch();
        // if (_v.length != _r.length || _r.length != _s.length) revert ArraysDataDoNotMatch();

        _verifySubmitTimestampAndIncSequence(_dataTimestamp);

        // we can't expect minter will have exactly the same timestamp
        // but for sure we can demand not to be off by a lot, that's why +3sec
        // temporary remove this condition, because recently on ropsten we see cases when minter/node
        // can be even 100sec behind
        // require(_dataTimestamp <= block.timestamp + 3,
        //   string(abi.encodePacked("oh, so you can predict the future:", _dataTimestamp - block.timestamp + 48)));

        bytes memory testimony = abi.encodePacked(_dataTimestamp, _root);

        for (uint256 i = 0; i < _keys.length;) {
            if (uint224(_values[i]) != _values[i]) revert FCDOverflow();

            fcds[_keys[i]] = FirstClassData(uint224(_values[i]), _dataTimestamp);
            testimony = abi.encodePacked(testimony, _keys[i], _values[i]);

            unchecked {
                // we can't pass enough data to overflow
                i++;
            }
        }

        uint256 signatures = 0;
        uint256 power = 0;
        //uint256 staked = stakingBank.totalSupply();
        bytes32 affidavit = keccak256(testimony);

        address prevSigner = address(0x0);

        for (uint256 i; i < _v.length;) {
            address signer = recoverSigner(affidavit, _v[i], _r[i], _s[i]);
            uint256 balance = stakingBank.balanceOf(signer);

            if (prevSigner >= signer) revert SignaturesOutOfOrder();

            prevSigner = signer;

            if (balance == 0) {
                unchecked { i++; }
                continue;
            }

            signatures++;
            emit LogVoter(uint256(_dataTimestamp), signer, balance);

            unchecked {
                // we can't overflow because that means token overflowed
                // and even if we do, we will get lower power
                power += balance;
                i++;
            }
        }

        if (signatures < _REQUIRED_SIGNATURES) revert NotEnoughSignatures();

        emit LogMint(msg.sender, _dataTimestamp, stakingBank.totalSupply(), power);

        // TODO remember to protect against flash loans when DPoS will be in place
        // we turn on power once we have DPoS in action, we have PoA now
        // require(power * 100 / staked >= 66, "not enough power was gathered");

        roots[_dataTimestamp] = _root;
        _consensusData.lastTimestamp = _dataTimestamp;
    }

    /// @inheritdoc BaseChain
    function isForeign() external pure virtual override returns (bool) {
        return false;
    }

    /// @dev helper method that returns all important data about current state of contract
    /// @return blockNumber `block.number`
    /// @return timePadding `this.padding`
    /// @return lastDataTimestamp timestamp for last submitted consensus
    /// @return lastId ID of last submitted consensus
    /// @return nextLeader leader for `block.timestamp + 1`
    /// @return nextBlockId block ID for `block.timestamp + padding`
    /// @return validators array of all validators addresses
    /// @return powers array of all validators powers
    /// @return locations array of all validators locations
    /// @return staked total UMB staked by validators
    /// @return minSignatures `this.requiredSignatures`
    function getStatus() external view virtual returns(
        uint256 blockNumber,
        uint32 timePadding,
        uint32 lastDataTimestamp,
        uint32 lastId,
        address nextLeader,
        uint32 nextBlockId,
        address[] memory validators,
        uint256[] memory powers,
        string[] memory locations,
        uint256 staked,
        uint16 minSignatures
    ) {
        ConsensusData memory data = _consensusData;

        blockNumber = block.number;
        timePadding = data.padding;
        lastId = data.lastTimestamp;
        lastDataTimestamp = lastId;
        minSignatures = _REQUIRED_SIGNATURES;

        staked = stakingBank.totalSupply();
        uint256 numberOfValidators = stakingBank.getNumberOfValidators();
        powers = new uint256[](numberOfValidators);
        validators = new address[](numberOfValidators);
        locations = new string[](numberOfValidators);

        for (uint256 i = 0; i < numberOfValidators;) {
            validators[i] = stakingBank.addresses(i);
            (, locations[i]) = stakingBank.validators(validators[i]);
            powers[i] = stakingBank.balanceOf(validators[i]);

            unchecked {
                // we will run out of gas before overflow happen
                i++;
            }
        }

        unchecked {
            // we will not overflow with timestamp in a lifetime
            nextBlockId = lastId + data.padding + 1;

            nextLeader = numberOfValidators > 0
                // we will not overflow with timestamp in a lifetime
                ? validators[getLeaderIndex(numberOfValidators, block.timestamp + 1)]
                : address(0);
        }
    }

    /// @return address of leader for next second
    function getNextLeaderAddress() external view returns (address) {
        return getLeaderAddressAtTime(block.timestamp + 1);
    }

    /// @return address of current leader
    function getLeaderAddress() external view returns (address) {
        return getLeaderAddressAtTime(block.timestamp);
    }

    /// @param _numberOfValidators total number of validators
    /// @param _timestamp timestamp for which you want to calculate index
    /// @return leader index, use it for StakingBank.addresses[index] to fetch leader address
    function getLeaderIndex(uint256 _numberOfValidators, uint256 _timestamp) public view virtual returns (uint256) {
        ConsensusData memory data = _consensusData;

        unchecked {
            // we will not overflow on `timestamp` and `padding` in a life time
            // timePadding + 1 => because padding is a space between blocks,
            // so next round starts on first block after padding
            // TODO will it work for off-chain??
            uint256 validatorIndex = data.sequence + (_timestamp - data.lastTimestamp) / (data.padding + 1);

            return validatorIndex % _numberOfValidators;
        }
    }

    // @todo - properly handled non-enabled validators, newly added validators, and validators with low stake
    /// @param _timestamp timestamp for which you want to calculate leader address
    /// @return leader address for provider timestamp
    function getLeaderAddressAtTime(uint256 _timestamp) public view virtual returns (address) {
        uint256 numberOfValidators = stakingBank.getNumberOfValidators();

        if (numberOfValidators == 0) {
            return address(0x0);
        }

        uint256 validatorIndex = getLeaderIndex(numberOfValidators, _timestamp);

        return stakingBank.addresses(validatorIndex);
    }

    /// @dev we had stack too deep in `submit` so this method was created as a solution
    // we increasing `_consensusData.sequence` here so we don't have to read sequence again in other place
    function _verifySubmitTimestampAndIncSequence(uint256 _dataTimestamp) internal {
        ConsensusData memory data = _consensusData;

        // `data.lastTimestamp` must be setup either on deployment
        // or via cloning from previous contract
        if (data.lastTimestamp == 0) revert ContractNotReady();

        unchecked {
            // we will not overflow with timestamp and padding in a life time
            if (data.lastTimestamp + data.padding >= _dataTimestamp) revert BlockSubmittedToFastOrDataToOld();
        }

        unchecked {
            // we will not overflow in a life time
            _consensusData.sequence = uint32(data.sequence + 1);
        }
    }
}