// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.5.16;
import "./ZirconEnergy.sol";
import "./ZirconEnergyRevenue.sol";
import "./interfaces/IZirconEnergyFactory.sol";
import "./interfaces/IZirconEnergyRevenue.sol";

contract ZirconEnergyFactory is IZirconEnergyFactory{
    mapping(address => mapping(address => address)) public getEnergy;
    mapping(address => mapping(address => address)) public getEnergyRevenue;
    address[] public allEnergies;
    address[] public allEnergiesRevenue;
    address public feeToSetter;
    address public migrator;
    uint public insurancePerMille;

    uint public feePercentageRev;
    uint public feePercentageEnergy;
    struct Fee {
        uint112 minPylonFee;
        uint112 maxPylonFee;
    }
    Fee private fee;
    event CREATE_ENERGY(address a, address b, address c, address d);

    event EnergyCreated(address indexed pair, address indexed energy, address tokenA, address tokenB, uint);

    modifier onlyFeeToSetter {
        require(msg.sender == feeToSetter, 'ZPT: FORBIDDEN');
        _;
    }
    modifier onlyMigrator {
        require(msg.sender == migrator, 'ZPT: FORBIDDEN');
        _;
    }

    constructor(address _feeToSetter, address _migrator) public {
        fee = Fee({minPylonFee: 1, maxPylonFee: 50});
        insurancePerMille = 100;
        feePercentageRev = 20;
        feePercentageEnergy = 20;
        feeToSetter = _feeToSetter;
        migrator = _migrator;
    }

    function getMinMaxFee() external view returns (uint112 minFee, uint112 maxFee) {
        minFee = fee.minPylonFee;
        maxFee = fee.maxPylonFee;
    }

    function setFee(uint112 _minPylonFee, uint112 _maxPylonFee) external onlyFeeToSetter {
        fee.minPylonFee = _minPylonFee;
        fee.maxPylonFee = _maxPylonFee;
    }

    function setInsurancePerMille(uint _insurancePerMille) external onlyFeeToSetter {
        insurancePerMille = _insurancePerMille;
    }

    function allEnergiesLength() external view returns (uint) {
        return allEnergies.length;
    }

    function allEnergiesRevenueLength() external view returns (uint) {
        return allEnergiesRevenue.length;
    }

    function energyCodeHash() public pure returns (bytes32) {
        return keccak256(type(ZirconEnergy).creationCode);
    }

    function energyRevenueCodeHash() public pure returns (bytes32) {
        return keccak256(type(ZirconEnergy).creationCode);
    }

    // DO NOT CHANGE THIS FUNCTIONS 'yarn bytecode' will do it for you ;)
    function energyFor(address token, address pair) view internal returns (address energy) {energy = address(uint(keccak256(abi.encodePacked(hex'ff',address(this),keccak256(abi.encodePacked(pair, token)),hex'17658e35a49b53c303ac807ca11fcbfb625aa6d8589bba4aa3f431f22d075de1'))));}

    function pylonFor(address tokenA, address tokenB, address pair, address pylonFactory) pure internal returns (address pylon){pylon=address(uint(keccak256(abi.encodePacked(hex'ff',pylonFactory,keccak256(abi.encodePacked(tokenA, tokenB,pair)),hex'3508acedf22fbd1cd58c77dab5a9a8fae96136a610450bd1d812b9bded1f882f'))));}

    function createEnergyRev(address _pair, address _tokenA, address _tokenB, address _pylonFactory) external returns (address energy) {
        require(_tokenA != _tokenB, 'ZF: IDENTICAL_ADDRESS');
        require(_pair != address(0), 'ZE: ZERO_ADDRESS0');
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        require(getEnergyRevenue[token0][token1] == address(0), 'ZE: ENERGY_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(ZirconEnergyRevenue).creationCode;
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        bytes32 salt = keccak256(abi.encodePacked(_pair, token0, token1));
        assembly {
            energy := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(energy != address(0), "Create2: Failed on deploy");
        address energy0 = energyFor(token0, _pair);
        address energy1 = energyFor(token1, _pair);
        // pylon 0 always with token0 first
        address pylon0 = pylonFor(token0, token1, _pair, _pylonFactory);
        address pylon1 = pylonFor(token1, token0, _pair, _pylonFactory);

        IZirconEnergyRevenue(energy).initialize(_pair, token0, token1, energy0, energy1, pylon0, pylon1);
        getEnergyRevenue[token0][token1] = energy;
        getEnergyRevenue[token1][token0] = energy;
        allEnergiesRevenue.push(energy);
        emit EnergyCreated(_pair, energy, token0, token1, allEnergies.length);
    }


    function createEnergy(address _pylon, address _pair, address _tokenA, address _tokenB) external returns (address energy) {
        emit CREATE_ENERGY(_pylon, _pair, _tokenA, _tokenB);
        require(_tokenA != _tokenB, 'ZF: IDENTICAL_ADDRESS');
        require(_pylon != address(0) && _pair != address(0), 'ZE: ZERO_ADDRESS1');
        require(getEnergy[_tokenA][_tokenB] == address(0), 'ZE: ENERGY_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(ZirconEnergy).creationCode;
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        bytes32 salt = keccak256(abi.encodePacked(_pair, _tokenA));
        assembly {
            energy := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(energy != address(0), "Create2: Failed on deploy");
        IZirconEnergy(energy).initialize(_pylon, _pair, _tokenA, _tokenB);
        getEnergy[_tokenA][_tokenB] = energy;
        allEnergies.push(energy);
        emit EnergyCreated(_pair, energy, _tokenA, _tokenB, allEnergies.length);
    }

    function migrateEnergyLiquidity(address pair, address token, address newEnergy) external onlyMigrator{
        require(newEnergy != address(0), 'ZE: ZERO_ADDRESS2');
        address energy = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                keccak256(abi.encodePacked(pair, token)),
                energyCodeHash() // init code hash
            ))));
        IZirconEnergy(energy).migrateLiquidity(newEnergy);
    }

    function migrateEnergyRevenue(address oldEnergy, address newEnergy) external onlyMigrator{
        require(newEnergy != address(0), 'ZE: ZERO_ADDRESS3');
        IZirconEnergyRevenue(oldEnergy).migrateLiquidity(newEnergy);
    }

    function migrateEnergyRevenueFees(address oldEnergy, address newEnergy) external onlyMigrator{
        require(newEnergy != address(0), 'ZE: ZERO_ADDRESS4');

        uint feeValue0 = IZirconEnergyRevenue(oldEnergy).feeValue0();
        uint feeValue1 = IZirconEnergyRevenue(oldEnergy).feeValue1();
        IZirconEnergyRevenue(newEnergy).setFeeValue(feeValue0, feeValue1);

    }

    function migrateEnergy(address oldEnergy, address newEnergy) external onlyMigrator{
        require(newEnergy != address(0), 'ZE: ZERO_ADDRESS5');

        IZirconEnergy(oldEnergy).migrateLiquidity(newEnergy);
    }

    function setFeePercentageRev(uint _fee) external onlyFeeToSetter {
        require(_fee <= 100, 'ZE: FEE_TOO_HIGH');
        require(_fee >= 0, 'ZE: FEE_TOO_LOW');
        feePercentageRev = _fee;
    }

    function setFeePercentageEnergy(uint _fee) external onlyFeeToSetter {
        require(_fee <= 100, 'ZE: FEE_TOO_HIGH');
        require(_fee >= 0, 'ZE: FEE_TOO_LOW');
        feePercentageEnergy = _fee;
    }

    function setFeeToSetter(address _feeToSetter) external onlyFeeToSetter {
        feeToSetter = _feeToSetter;
    }

    function setMigrator(address _migrator) external onlyMigrator {
        migrator = _migrator;
    }
    function getFees(address _token, uint _amount, address _to, address energyRev) external onlyFeeToSetter {

        require(_amount != 0, "Operations: Cannot recover zero balance");

        IZirconEnergyRevenue(energyRev).getFees(_token, _amount, _to);
    }
}