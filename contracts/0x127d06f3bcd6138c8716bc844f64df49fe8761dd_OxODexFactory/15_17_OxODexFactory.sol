// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.5;

import "./OxODexTokenPool.sol";
import "./interfaces/IOxODexTokenPool.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Pausable } from "./lib/Pausable.sol";

contract OxODexFactory is Pausable {

    enum FeeType {
        TOKEN,
        POOL,
        DISCOUNT_PERCENT,
        RELAYER_PERCENT,
        RELAYER_GAS_CHARGE
    } 

    /// Errors
    error PoolExists();
    error ZeroAddress();
    error Forbidden();

    /// Events
    event PoolCreated(address indexed token, address poolAddress);
    event ManagerChanged(address indexed newManager);
    event FeeChanged(uint256 newFee, FeeType feeType); 
    event TokenChanged(address indexed newToken);
    event TreasurerChanged(address indexed newTreasurer);

    address[] public allPools;
    address public managerAddress = 0x0000000000000000000000000000000000000000;
    address public treasurerAddress = 0x0000000000000000000000000000000000000000;
    address public token = 0x0000000000000000000000000000000000000000;
    uint256 public tokenFeeDiscountPercent = 100; // 0.1% of total supply  

    uint256 public fee = 90; // 0.9% fee
    uint256 public tokenFee = 45; // 0.45% fee
    uint256 public relayerFee = 30; // 0.3% fee

    
    /// token => pool
    mapping(address => address) public pools;
    mapping(address => uint256) public maxRelayerGasCharge;

    constructor(address _managerAddress, address _treasurerAddress, address _token) Pausable() {
        if(_managerAddress == address(0)) revert ZeroAddress();
        if(_treasurerAddress == address(0)) revert ZeroAddress();
        if(_token == address(0)) revert ZeroAddress();

        managerAddress = _managerAddress;
        treasurerAddress = _treasurerAddress;
        token = _token;
    }

    
    /// @notice Creates a new pool for the given token
    /// @param _token The token to create the pool for
    /// @return vault The address of the new pool
    function createPool(address _token, uint256 _relayerGasCharge) external onlyManager returns (address vault) {
        if (_token == address(0)) revert ZeroAddress();
        if(pools[_token] != address(0)) revert PoolExists();

        bytes memory bytecode = type(OxODexTokenPool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token));

        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IOxODexTokenPool(vault).initialize(_token, address(this));

        pools[_token] = vault;
        allPools.push(vault);

        maxRelayerGasCharge[vault] = _relayerGasCharge;

        emit PoolCreated(_token, vault);
    }

    /// @notice Returns the pool address for the given token
    /// @param _token The token to get the pool for
    /// @return The address of the pool
    function getPool(address _token) external view returns (address) {
        return pools[_token];
    }

    /// @notice Returns the address of the pool for the given token
    /// @return The length of all pools
    function allPoolsLength() external view returns (uint) {
        return allPools.length;
    }

    modifier onlyManager() {
        if (msg.sender != managerAddress) revert Forbidden();
        _;
    }

    modifier limitFee(uint256 _fee) {
        require(_fee <= 300, "Fee too high");
        _;
    }

    /// @notice set the relayer fixed fee for ETH to cover gas
    /// @param _fee the fee to set
    function setETHRelayerGasCharge(uint256 _fee) external onlyManager {
        maxRelayerGasCharge[address(0)] = _fee;
        emit FeeChanged(_fee, FeeType.RELAYER_GAS_CHARGE);
    }

    /// @notice set the relayer fixed fee to cover gas
    /// @param _token the token to set the fee for
    /// @param _fee the fee to set
    function setRelayerGasCharge(address _token, uint256 _fee) external onlyManager {
        address poolAddress = pools[_token];
        if(poolAddress == address(0)) revert ZeroAddress();

        maxRelayerGasCharge[poolAddress] = _fee;
        emit FeeChanged(_fee, FeeType.RELAYER_GAS_CHARGE);
    }

    /// @notice Sets the manager address
    /// @param _managerAddress The new manager address
    function setManager(address _managerAddress) external onlyManager {
        if(_managerAddress == address(0)) revert ZeroAddress();
        managerAddress = _managerAddress;

        emit ManagerChanged(_managerAddress);
    }

    /// @notice Sets the treasurer address
    /// @param _treasurerAddress The new treasurer address
    function setTreasurerAddress(address _treasurerAddress) external onlyManager {
        if(_treasurerAddress == address(0)) revert ZeroAddress();
        treasurerAddress = _treasurerAddress;

        emit TreasurerChanged(_treasurerAddress);
    }

    /// @notice Sets the token address
    /// @param _token The new token address
    function setToken(address _token) external onlyManager {
        if(_token == address(0)) revert ZeroAddress();
        token = _token;
        
        emit TokenChanged(_token);
    }

    /// @notice Set the percentage threshold for fee free transactions
    /// @param _value the new percentage threshold
    function setTokenFeeDiscountPercent(uint256 _value) external onlyManager {
        tokenFeeDiscountPercent = _value;

        emit FeeChanged(_value, FeeType.DISCOUNT_PERCENT);
    }

    /// @notice Set token fee
    /// @param _fee the new percentage threshold
    function setTokenFee(uint256 _fee) external onlyManager limitFee(_fee){
        tokenFee = _fee;

        emit FeeChanged(_fee, FeeType.TOKEN);
    }

    /// @notice Sets the fee
    /// @param _fee The new fee
    function setFee(uint256 _fee) external onlyManager limitFee(_fee){
        fee = _fee;

        emit FeeChanged(_fee, FeeType.POOL);
    }

    /// @notice Sets the relayer fee
    /// @param _fee The new fee
    function setRelayerFee(uint256 _fee) external onlyManager limitFee(_fee){
        relayerFee = _fee;

        emit FeeChanged(_fee, FeeType.RELAYER_PERCENT);
    }

    /// @dev Pauses functionality for all pools
    function pause() external onlyManager {
        _pause();
    }

    /// @dev Unpauses functionality for all pools
    function unpause() external onlyManager {
        _unpause();
    }

    function getTokenFeeDiscountLimit() external view returns (uint256) {
        return (ERC20(token).totalSupply() * tokenFeeDiscountPercent) / 100_000;
    }
}