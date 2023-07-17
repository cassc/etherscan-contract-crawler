pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../StafiBase.sol";
import "../interfaces/node/IStafiSuperNode.sol";
import "../interfaces/node/IStafiNodeManager.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";
import "../interfaces/eth/IDepositContract.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";
import "../interfaces/storage/IPubkeySetStorage.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract StafiSuperNode is StafiBase, IStafiSuperNode {
    // Libs
    using SafeMath for uint256;

    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event Staked(address node, bytes pubkey);
    event Deposited(address node, bytes pubkey, bytes validatorSignature);
    event SetPubkeyStatus(bytes pubkey, uint256 status);

    uint256 public constant PUBKEY_STATUS_UNINITIAL = 0;
    uint256 public constant PUBKEY_STATUS_INITIAL = 1;
    uint256 public constant PUBKEY_STATUS_MATCH = 2;
    uint256 public constant PUBKEY_STATUS_STAKING = 3;
    uint256 public constant PUBKEY_STATUS_UNMATCH = 4;
    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        version = 1;
    }

    // Deposit ETH from deposit pool
    // Only accepts calls from the StafiUserDeposit contract
    function depositEth() override external payable onlyLatestContract("stafiUserDeposit", msg.sender) {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    function EthDeposit() private view returns (IDepositContract) {
        return IDepositContract(getContractAddress("ethDeposit"));
    }

    function StafiNetworkSettings() private view returns (IStafiNetworkSettings) {
        return IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));
    }

    function PubkeySetStorage() public view returns (IPubkeySetStorage) {
        return IPubkeySetStorage(getContractAddress("pubkeySetStorage"));
    }

    // Get the number of pubkeys owned by a super node
    function getSuperNodePubkeyCount(address _nodeAddress) override public view returns (uint256) {
        return PubkeySetStorage().getCount(keccak256(abi.encodePacked("superNode.pubkeys.index", _nodeAddress)));
    }

    // Get a super node pubkey by index
    function getSuperNodePubkeyAt(address _nodeAddress, uint256 _index) override public view returns (bytes memory) {
        return PubkeySetStorage().getItem(keccak256(abi.encodePacked("superNode.pubkeys.index", _nodeAddress)), _index);
    }
    
    // Get a super node pubkey status
    function getSuperNodePubkeyStatus(bytes calldata _validatorPubkey) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("superNode.pubkey.status", _validatorPubkey)));
    }

    // Set a super node pubkey status
    function _setSuperNodePubkeyStatus(bytes calldata _validatorPubkey, uint256 _status) private {
        setUint(keccak256(abi.encodePacked("superNode.pubkey.status", _validatorPubkey)), _status);

        emit SetPubkeyStatus(_validatorPubkey, _status);
    }

    function setSuperNodePubkeyStatus(bytes calldata _validatorPubkey, uint256 _status) public onlySuperUser {
        _setSuperNodePubkeyStatus(_validatorPubkey, _status);
    }

    function getSuperNodeDepositEnabled() public view returns (bool) {
        return getBoolS("settings.superNode.deposit.enabled");
    }

    function getPubkeyVoted(bytes calldata _validatorPubkey, address user) public view returns (bool) {
        return getBool(keccak256(abi.encodePacked("superNode.memberVotes.", _validatorPubkey, user)));
    }

    function setSuperNodeDepositEnabled(bool _value) public onlySuperUser {
        setBoolS("settings.superNode.deposit.enabled", _value);
    }

    function deposit(bytes[] calldata _validatorPubkeys, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) override external onlyLatestContract("stafiSuperNode", address(this)) onlySuperNode(msg.sender) {
        require(getSuperNodeDepositEnabled(), "super node deposits are currently disabled");
        uint256 len = _validatorPubkeys.length;
        require(len == _validatorSignatures.length && len == _depositDataRoots.length, "params len err");
        require(getSuperNodePubkeyCount(msg.sender).add(len) <= StafiNetworkSettings().getSuperNodePubkeyLimit(), "pubkey amount over limit");
        // Load contracts
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        stafiUserDeposit.withdrawExcessBalanceForSuperNode(len.mul(1 ether));

        for (uint256 i = 0; i < len; i++) {
            _deposit(_validatorPubkeys[i], _validatorSignatures[i], _depositDataRoots[i]);
        }
    }

    function stake(bytes[] calldata _validatorPubkeys, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) override external onlyLatestContract("stafiSuperNode", address(this)) onlySuperNode(msg.sender) {
        uint256 len = _validatorPubkeys.length;
        require(len == _validatorSignatures.length && len == _depositDataRoots.length, "params len err");
        // Load contracts
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        stafiUserDeposit.withdrawExcessBalanceForSuperNode(len.mul(31 ether));
        
        for (uint256 i = 0; i < len; i++) {
            _stake(_validatorPubkeys[i], _validatorSignatures[i], _depositDataRoots[i]);
        }
    }

    function _deposit(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) private {
        setAndCheckNodePubkeyInDeposit(_validatorPubkey);
        // Send staking deposit to casper
        EthDeposit().deposit{value: 1 ether}(_validatorPubkey, StafiNetworkSettings().getWithdrawalCredentials(), _validatorSignature, _depositDataRoot);

        emit Deposited(msg.sender, _validatorPubkey, _validatorSignature);
    }


    function _stake(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) private {
        setAndCheckNodePubkeyInStake(_validatorPubkey);
        // Send staking deposit to casper
        EthDeposit().deposit{value: 31 ether}(_validatorPubkey, StafiNetworkSettings().getWithdrawalCredentials(), _validatorSignature, _depositDataRoot);

        emit Staked(msg.sender, _validatorPubkey);
    }

    
    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInDeposit(bytes calldata _pubkey) private {
        // check pubkey of stakingpools
        require(getAddress(keccak256(abi.encodePacked("validator.stakingpool", _pubkey))) == address(0x0), "stakingpool pubkey exists");
        // check pubkey of lightNodes
        require(getUint(keccak256(abi.encodePacked("lightNode.pubkey.status", _pubkey))) == PUBKEY_STATUS_UNINITIAL, "light Node pubkey exists");

        // check status
        require(getSuperNodePubkeyStatus(_pubkey) == PUBKEY_STATUS_UNINITIAL, "pubkey status unmatch");
        // set pubkey status
        _setSuperNodePubkeyStatus(_pubkey, PUBKEY_STATUS_INITIAL);
        // add pubkey to set
        PubkeySetStorage().addItem(keccak256(abi.encodePacked("superNode.pubkeys.index", msg.sender)), _pubkey);
    }
    
    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInStake(bytes calldata _pubkey) private {
        // check status
        require(getSuperNodePubkeyStatus(_pubkey) == PUBKEY_STATUS_MATCH, "pubkey status unmatch");
        // set pubkey status
        _setSuperNodePubkeyStatus(_pubkey, PUBKEY_STATUS_STAKING);
    }

    function voteWithdrawCredentials(bytes[] calldata _pubkeys, bool[] calldata _matchs) override external onlyLatestContract("stafiSuperNode", address(this)) onlyTrustedNode(msg.sender) {
        require(_pubkeys.length == _matchs.length, "params len err");
        for ( uint256 i = 0; i < _pubkeys.length; i++) {
            _voteWithdrawCredentials(_pubkeys[i], _matchs[i]);
        }
    }

    // Only accepts calls from trusted (oracle) nodes
    function _voteWithdrawCredentials(bytes calldata _pubkey, bool _match) private {
        // Check & update node vote status
        require(!getBool(keccak256(abi.encodePacked("superNode.memberVotes.", _pubkey, msg.sender))), "Member has already voted to withdrawCredentials");
        setBool(keccak256(abi.encodePacked("superNode.memberVotes.", _pubkey, msg.sender)), true);
       
        // Increment votes count
        uint256 totalVotes = getUint(keccak256(abi.encodePacked("superNode.totalVotes", _pubkey, _match)));
        totalVotes = totalVotes.add(1);
        setUint(keccak256(abi.encodePacked("superNode.totalVotes", _pubkey, _match)), totalVotes);

        // Check count and set status
        uint256 calcBase = 1 ether;
        IStafiNodeManager stafiNodeManager = IStafiNodeManager(getContractAddress("stafiNodeManager"));
        if (getSuperNodePubkeyStatus(_pubkey) == PUBKEY_STATUS_INITIAL &&  calcBase.mul(totalVotes) >= stafiNodeManager.getTrustedNodeCount().mul(StafiNetworkSettings().getNodeConsensusThreshold())) {
            _setSuperNodePubkeyStatus(_pubkey, _match ? PUBKEY_STATUS_MATCH : PUBKEY_STATUS_UNMATCH);
        }
    }
}