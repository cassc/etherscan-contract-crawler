pragma solidity =0.5.16;
import '../interfaces/IZirconPylonFactory.sol';
import '../interfaces/IZirconPTFactory.sol';
import '../interfaces/IZirconFactory.sol';
import '../interfaces/IZirconPylon.sol';
import '../interfaces/IOldZirconPylon.sol';
import '../interfaces/IZirconPoolToken.sol';
import '../energy/interfaces/IZirconEnergyFactory.sol';
//import "hardhat/console.sol";

// this contract serves as feeToSetter, allowing owner to manage fees in the context of a specific feeTo implementation

contract Migrator {

    // Immutables
    address public owner;
    address public energyFactory;
    address public ptFactory;
    address public pylonFactory;
    address public pairFactory;

    modifier onlyOwner {
        require(msg.sender == owner, 'ZPT: FORBIDDEN');
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function initialize(address energyFactory_, address ptFactory_, address pylonFactory_, address pairFactory_) public onlyOwner {
        require(energyFactory_ != address(0), 'ZPT: FORBIDDEN');
        require(ptFactory_ != address(0), 'ZPT: FORBIDDEN');
        require(pylonFactory_ != address(0), 'ZPT: FORBIDDEN');
        require(pairFactory_ != address(0), 'ZPT: FORBIDDEN');
        energyFactory = energyFactory_;
        ptFactory = ptFactory_;
        pylonFactory = pylonFactory_;
        pairFactory = pairFactory_;
    }

    function setPylonMigrator(address migrator_) public onlyOwner {
        IZirconPylonFactory(pylonFactory).setMigrator(migrator_);
    }

    function setEnergyMigrator(address migrator_) public onlyOwner {
        IZirconEnergyFactory(energyFactory).setMigrator(migrator_);
    }

    function setFactoryMigrator(address migrator_) public onlyOwner {
        IZirconFactory(pairFactory).setMigrator(migrator_);
    }

    function setPTMigrator(address migrator_) public onlyOwner {
        IZirconPTFactory(pairFactory).setMigrator(migrator_);
    }

    function setMigrator(address migrator_) public onlyOwner {
        IZirconPylonFactory(pylonFactory).setMigrator(migrator_);
        IZirconEnergyFactory(energyFactory).setMigrator(migrator_);
        IZirconFactory(pairFactory).setMigrator(migrator_);
        IZirconPTFactory(ptFactory).setMigrator(migrator_);
    }

    // allows owner to change itself at any time
    function setOwner(address owner_) public {
        require(owner_ != address(0), 'ZPT: Address zero');
        require(msg.sender == owner, 'FeeToSetter::setOwner: not allowed');
        owner = owner_;
    }

    function migrate(address newPylonFactory, address newEnergyFactory, address _tokenA, address _tokenB) external onlyOwner {

        // Obtaining old addresses from the old factories
        address pair = IZirconFactory(pairFactory).getPair(_tokenA, _tokenB);
        address oldPylon = IZirconPylonFactory(pylonFactory).getPylon(_tokenA, _tokenB);

        // Obtaining Old Energies Address
        address oldEnergyRev = IZirconEnergyFactory(energyFactory).getEnergyRevenue(_tokenA, _tokenB);
        address oldEnergy = IZirconEnergyFactory(energyFactory).getEnergy(_tokenA, _tokenB);

        // Migrating Factory to new Energy Factory
        IZirconFactory(pairFactory).changeEnergyFactoryAddress(newEnergyFactory);
        {
            // Creating new energy revenue address
            address newEnergyRev = IZirconFactory(pairFactory).changeEnergyRevAddress(pair, _tokenA, _tokenB, newPylonFactory);
            require(newEnergyRev != address(0), 'Energy Rev does not exist');

            // Migrating Liquidity to new energy Revenue
            IZirconEnergyFactory(energyFactory).migrateEnergyRevenue(oldEnergyRev, newEnergyRev);
            IZirconEnergyFactory(newEnergyFactory).migrateEnergyRevenueFees(oldEnergyRev, newEnergyRev);
        }

        // Creating New Pylon with old PT Tokens
        address poolTokenA = IZirconPTFactory(ptFactory).getPoolToken(oldPylon, _tokenA);
        address newPylonAddress = IZirconPylonFactory(newPylonFactory).addPylonCustomPT(pair, _tokenA, _tokenB, poolTokenA, IZirconPTFactory(ptFactory).getPoolToken(oldPylon, _tokenB));
        require(newPylonAddress != address(0), 'Pylon does not exist');

        // Getting New Energy
        address newEnergy = IZirconEnergyFactory(newEnergyFactory).getEnergy(_tokenA, _tokenB);
        require(newEnergy != address(0), 'Energy does not exist');

        // Communicating Changes on PT Factory
        {
            // Genesis pylon and Genesis Factory are required because PT are created with the first pylon
            // so in second migrations we cannot use the Pylon from which we are migrating
            address genesisPylonFactory = IZirconPoolToken(poolTokenA).pylonFactory();
            address genesisPylon = IZirconPylonFactory(genesisPylonFactory).getPylon(_tokenA, _tokenB);
            IZirconPTFactory(ptFactory).changePylonAddress(genesisPylon, _tokenA, _tokenB, newPylonAddress, genesisPylonFactory);
        }

        // Migrating Pylon Liquidity
        IZirconPylonFactory(pylonFactory).migrateLiquidity(oldPylon, newPylonAddress);

        // Communicating new Pylon Variables
        IZirconPylonFactory(newPylonFactory).startPylon(
            newPylonAddress,
            IOldZirconPylon(oldPylon).gammaMulDecimals(),
            IOldZirconPylon(oldPylon).virtualAnchorBalance(),
            IOldZirconPylon(oldPylon).formulaSwitch());

        // Migrating Energy Liquidity
        IZirconEnergyFactory(energyFactory).migrateEnergy(oldEnergy, newEnergy);
    }

    function changeEnergyFactoryAddress(address newEnergyFactoryAddress) external onlyOwner {
        IZirconPylonFactory(pylonFactory).changeEnergyFactoryAddress(newEnergyFactoryAddress);
        IZirconFactory(pairFactory).changeEnergyFactoryAddress(newEnergyFactoryAddress);
    }

}