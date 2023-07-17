// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import './interfaces/IViralswapFactory.sol';
import './libraries/UniswapV2LiquidityMathLibrary.sol';
import './ViralswapPair.sol';
import './ViralswapVault.sol';

contract ViralswapFactory is IViralswapFactory {
    address public override feeTo;
    address public override feeToSetter;
    address public override migrator;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    mapping(address => mapping(address => address)) public override getVault;
    address[] public override allVaults;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event VaultCreated(address indexed tokenIn, address indexed tokenOut, address vault, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function allVaultsLength() external override view returns (uint) {
        return allVaults.length;
    }

    function pairCodeHash() external pure override returns (bytes32) {
        return keccak256(type(ViralswapPair).creationCode);
    }

    function vaultCodeHash() external pure override returns (bytes32) {
        return keccak256(type(ViralswapVault).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'Viralswap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Viralswap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Viralswap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(ViralswapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ViralswapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /**
     * @dev Function to create a VIRAL Vault for the specified tokens.
     *
     * @param tokenOutPerInflatedTokenIn : number of tokenOut to distribute per 1e18 tokenIn
     * @param tokenIn : the input token address
     * @param tokenOut : the output token address
     * @param router : address of the ViralSwap router
    **/
    function createVault(uint tokenOutPerInflatedTokenIn, address tokenIn, address tokenOut, address router, uint feeOnTokenOutTransferBIPS) external override returns (address vault) {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        require(tokenIn != tokenOut, 'Viralswap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenIn < tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
        require(token0 != address(0), 'Viralswap: ZERO_ADDRESS');
        require(getVault[token0][token1] == address(0), 'Viralswap: VAULT_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(ViralswapVault).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ViralswapVault(vault).initialize(tokenOutPerInflatedTokenIn, tokenIn, tokenOut, router, feeOnTokenOutTransferBIPS);
        getVault[token0][token1] = vault;
        getVault[token1][token0] = vault; // populate mapping in the reverse direction
        allVaults.push(vault);
        emit VaultCreated(tokenIn, tokenOut, vault, allVaults.length);
    }

    /**
     * @dev Function to increase the minting quota for the VIRAL Vault for the specified tokens.
     *
     * @param tokenA : the first token address
     * @param tokenB : the second token address
     * @param quota : the minting quota to add
    **/
    function addQuota(address tokenA, address tokenB, uint quota) external override {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        address vault = getVault[tokenA][tokenB];
        require(vault != address(0), 'Viralswap: VAULT_DOES_NOT_EXIST');
        ViralswapVault(vault).addQuota(quota);
    }

    /**
     * @dev Function to update the router address for the VIRAL Vault for the specified tokens.
     *
     * @param tokenA : the first token address
     * @param tokenB : the second token address
     * @param _viralswapRouter02 : the new router address
    **/
    function updateRouterInVault(address tokenA, address tokenB, address _viralswapRouter02) external override {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        address vault = getVault[tokenA][tokenB];
        require(vault != address(0), 'Viralswap: VAULT_DOES_NOT_EXIST');
        ViralswapVault(vault).updateRouter(_viralswapRouter02);
    }

    function withdrawERC20FromVault(address tokenA, address tokenB, address tokenToWithdraw, address to) external override {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        address vault = getVault[tokenA][tokenB];
        require(vault != address(0), 'Viralswap: VAULT_DOES_NOT_EXIST');
        ViralswapVault(vault).withdrawERC20(tokenToWithdraw, to);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setMigrator(address _migrator) external override {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB
    ) external pure override returns (bool, uint256) {
        return UniswapV2LiquidityMathLibrary.computeProfitMaximizingTrade(
            truePriceTokenA,
            truePriceTokenB,
            reserveA,
            reserveB
        );
    }
}