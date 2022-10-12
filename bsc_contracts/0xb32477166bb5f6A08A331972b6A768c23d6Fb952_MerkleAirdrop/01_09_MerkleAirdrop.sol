// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MerkleAirdrop is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Claimed(address indexed claimant, uint16 week, uint256 balance);
    event TrancheAdded(uint16 tranche, bytes32 merkleRoot, uint256 totalAmount);
    event TrancheExpired(uint16 tranche);
    event RemovedFunder(address indexed _address);

    IERC20Upgradeable public token;

    mapping(uint256 => bytes32) public merkleRoots;
    mapping(uint256 => mapping(address => bool)) public claimed;
    mapping(uint256 => uint256) public allocations;
    uint16 public tranches;

    // constructor(address tokenAddress) {
    function init(address _tokenAddress) 
        external
        initializer 
    {
        __Ownable_init();
        token = IERC20Upgradeable(_tokenAddress);
    }

    function seedNewAllocations(bytes32 _merkleRoot, uint256 _totalAllocation)
        external
        onlyOwner
        returns (uint16 trancheId)
    {
        token.safeTransferFrom(msg.sender, address(this), _totalAllocation);

        trancheId = tranches;
        merkleRoots[trancheId] = _merkleRoot;
        allocations[trancheId] = _totalAllocation;

        tranches = tranches + 1;

        emit TrancheAdded(trancheId, _merkleRoot, _totalAllocation);
    }

    function expireTranche(uint16 _trancheId)
        external
        onlyOwner
    {
        merkleRoots[_trancheId] = bytes32(0);

        uint256 _balance = allocations[_trancheId];

        if (_balance > 0) {
            token.safeTransfer(_msgSender(), _balance);
        }

        emit TrancheExpired(_trancheId);
    }

    function claimWeek(
        address _liquidityProvider,
        uint16 _tranche,
        uint256 _balance,
        bytes32[] calldata _merkleProof
    )
        external
    {
        _claimWeek(_liquidityProvider, _tranche, _balance, _merkleProof);
        _disburse(_liquidityProvider, _balance);
    }


    function claimWeeks(
        address _liquidityProvider,
        uint16[] calldata _tranches,
        uint256[] calldata _balances,
        bytes32[][] calldata _merkleProofs
    )
        external
    {
        uint256 len = _tranches.length;
        require(len == _balances.length && len == _merkleProofs.length, "Mismatching inputs");

        uint256 totalBalance = 0;
        for(uint16 i = 0; i < len; i++) {
            _claimWeek(_liquidityProvider, _tranches[i], _balances[i], _merkleProofs[i]);
            totalBalance += _balances[i];
        }
        _disburse(_liquidityProvider, totalBalance);
    }


    function verifyClaim(
        address _liquidityProvider,
        uint16 _tranche,
        uint256 _balance,
        bytes32[] calldata _merkleProof
    )
        external
        view
        returns (bool valid)
    {
        return _verifyClaim(_liquidityProvider, _tranche, _balance, _merkleProof);
    }

    function _claimWeek(
        address _liquidityProvider,
        uint16 _tranche,
        uint256 _balance,
        bytes32[] calldata _merkleProof
    )
        private
    {
        require(_tranche < tranches, "Week cannot be in the future");

        require(!claimed[_tranche][_liquidityProvider], "LP has already claimed");
        require(_verifyClaim(_liquidityProvider, _tranche, _balance, _merkleProof), "Incorrect merkle proof");

        claimed[_tranche][_liquidityProvider] = true;
        allocations[_tranche] -= _balance;

        emit Claimed(_liquidityProvider, _tranche, _balance);
    }

    function _verifyClaim(
        address _liquidityProvider,
        uint16 _tranche,
        uint256 _balance,
        bytes32[] calldata _merkleProof
    )
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_liquidityProvider, _balance));
        return MerkleProofUpgradeable.verify(_merkleProof, merkleRoots[_tranche], leaf);
    }


    function _disburse(address _liquidityProvider, uint256 _balance) private {
        if (_balance > 0) {
            token.safeTransfer(_liquidityProvider, _balance);
        } else {
            revert("Zero balance");
        }
    }
}