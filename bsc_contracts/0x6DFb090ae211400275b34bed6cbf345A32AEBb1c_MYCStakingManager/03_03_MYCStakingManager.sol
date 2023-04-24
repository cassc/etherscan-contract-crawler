// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MYCStakingManager is Ownable {
    /**
     * @dev Emitted when `owner` changes status to `status` for `factory` address
     */
    event ChangeFactoryStatus(address indexed factory, bool status);

    /**
     * @dev Emitted when `factory` created new staking contract `poolAddress` address using `signature`
     */
    event AddedStakingPool(
        address indexed factory,
        bytes32 signature,
        address poolAddress
    );

    error WrongAddress();
    error OnlyFactories();
    error SignatureAlreadyUsed();
    error OnlyOwnerOrSigner();

    /**
     * @dev Throws if param is address zero
     */
    modifier noAddressZero(address adr) {
        if (adr == address(0)) revert WrongAddress();
        _;
    }

    mapping(bytes32 => address) internal _poolAddressBySignature;
    address[] internal _allPools;
    mapping(address => bool) internal _factoryStatus;
    address internal _treasury;
    address internal _signer;

    constructor(address treasury_, address signer_) {
        _treasury = treasury_;
        _signer = signer_;
    }

    /**
     * @dev Returns pool address by `id`
     */
    function poolAddressById(uint256 id) external view returns (address) {
        return _allPools[id];
    }

    /**
     * @dev Returns pool length
     */
    function poolAddressesLength() external view returns (uint256) {
        return _allPools.length;
    }

    /**
     * @dev Returns {PoolInfo} by `signature`
     */
    function poolAddressBySignature(
        bytes memory signature
    ) external view returns (address) {
        return _poolAddressBySignature[bytes32(signature)];
    }

    function poolAddressBySignature(
        bytes32 signature
    ) external view returns (address) {
        return _poolAddressBySignature[bytes32(signature)];
    }

    /**
     * @dev Returns MYC treasury address
     */
    function treasury() external view returns (address) {
        return _treasury;
    }

    /**
     * @dev Returns signer address
     */
    function signer() external view returns (address) {
        return _signer;
    }

    /**
     * @dev Uses signature to prevent external usage
     * Only owner and signer can execute the function
     * Important: Sets address(1) as usage status flag
     */
    function useSignature(bytes32 signature) external {
        if (msg.sender != owner() && msg.sender != _signer)
            revert OnlyOwnerOrSigner();
        _poolAddressBySignature[signature] = address(1);
    }

    /**
     * @dev Sets new `status` for `factory`
     * @param factory Factory address
     * @param status New status: (toEnable): [true/false]
     */
    function setFactoryStatus(address factory, bool status) external onlyOwner {
        _factoryStatus[factory] = status;
        emit ChangeFactoryStatus(factory, status);
    }

    /**
     * @dev Returns status of factory
     * @param factory Factory address
     * @return status
     */
    function factoryStatus(address factory) external view returns(bool){
        return _factoryStatus[factory];
    }

    /**
     * @dev Used by approved factories contracts for emiting {AddedStakingPool} events
     * @param poolAddress Staking pool address
     * @param signature Signature used for creating pool
     */
    function addStakingPool(address poolAddress, bytes32 signature) external {
        if (!_factoryStatus[msg.sender]) revert OnlyFactories();
        if (_poolAddressBySignature[signature] != address(0))
            revert SignatureAlreadyUsed();
        _allPools.push(poolAddress);
        _poolAddressBySignature[signature] = poolAddress;
        emit AddedStakingPool(msg.sender, signature, poolAddress);
    }

    /**
     * @dev Sets `newTreasury` as new {treasury} address
     * @param newTreasury new treasury address
     */
    function setTreasury(
        address newTreasury
    ) external noAddressZero(newTreasury) onlyOwner {
        _treasury = newTreasury;
    }

    /**
     * @dev Sets `newSigner` as new {signer} address
     * @param newSigner new signer address
     */
    function setSigner(
        address newSigner
    ) external noAddressZero(newSigner) onlyOwner {
        _signer = newSigner;
    }
}