// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.5.16;
import './ZirconPair.sol';
import './energy/interfaces/IZirconEnergyFactory.sol';
import "./energy/interfaces/IZirconEnergyRevenue.sol";

contract ZirconFactory is IZirconFactory {
    address public energyFactory;
    address public migrator;
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    address public feeToSetter;
    uint public liquidityFee;
    uint public dynamicRatio;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    modifier _onlyMigrator {
        require(msg.sender == migrator, 'ZPT: FORBIDDEN');
        _;
    }

    modifier _onlyFeeToSetter {
        require(msg.sender == feeToSetter, 'ZPT: FORBIDDEN');
        _;
    }

    constructor(address _energyFactory, address _feeToSetter, address _migrator) public {
        energyFactory = _energyFactory;
        migrator = _migrator;
        feeToSetter = _feeToSetter;
        liquidityFee = 15;
        dynamicRatio = 5;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(ZirconPair).creationCode);
    }

    function createEnergy( address _pairAddress, address _tokenA, address _tokenB, address _pylonFactory) private returns (address energy){
        energy = IZirconEnergyFactory(energyFactory).createEnergyRev(_pairAddress, _tokenA, _tokenB, _pylonFactory);
    }

    function createPair(address tokenA, address tokenB, address _pylonFactory) external returns (address pair) {
        require(tokenA != tokenB, 'ZF: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZF: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'ZF: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(ZirconPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(pair != address(0), 'ZF: PCF');
        address energyRev = createEnergy(pair, token0, token1, _pylonFactory);
        IZirconPair(pair).initialize(token0, token1, energyRev);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeToSetter(address _feeToSetter) external _onlyFeeToSetter {
        feeToSetter = _feeToSetter;
    }

    function setMigrator(address _migrator) external _onlyMigrator {
        migrator = _migrator;
    }

    function changeEnergyRevAddress(address _pairAddress, address _tokenA, address _tokenB, address _pylonFactory) external _onlyMigrator returns (address newEnergy){

        newEnergy = IZirconEnergyFactory(energyFactory).getEnergyRevenue(_tokenA, _tokenB);
        if (newEnergy == address(0)) {
            newEnergy = IZirconEnergyFactory(energyFactory).createEnergyRev(_pairAddress, _tokenA, _tokenB, _pylonFactory);
        }
        ZirconPair(_pairAddress).changeEnergyRevAddress(newEnergy);
    }

    function changeEnergyFactoryAddress(address _newEnergyFactory) external _onlyMigrator {
        energyFactory = _newEnergyFactory;
    }

    function setLiquidityFee(uint _liquidityFee) external _onlyFeeToSetter {
        liquidityFee = _liquidityFee;
    }

    function setDynamicRatio(uint _dynamicRatio) external _onlyFeeToSetter {
        dynamicRatio = _dynamicRatio;
    }


}