pragma solidity =0.5.16;
import '../interfaces/IZirconPylonFactory.sol';
import '../interfaces/IZirconFactory.sol';
import '../energy/interfaces/IZirconEnergyFactory.sol';
import 'hardhat/console.sol';

// this contract serves as feeToSetter, allowing owner to manage fees in the context of a specific feeTo implementation
contract FeeToSetter {
    // immutables
    address public factory;
    address public energyFactory;
    address public pylonFactory;
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, 'ZPT: FORBIDDEN');
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function initialize(address factory_, address energyFactory_, address pylonFactory_) public onlyOwner {
        factory = factory_;
        energyFactory = energyFactory_;
        pylonFactory = pylonFactory_;
    }

    // allows owner to change itself at any time
    function setOwner(address owner_) public {
        require(msg.sender == owner, 'FeeToSetter::setOwner: not allowed');
        owner = owner_;
    }

    // allows owner to change feeToSetter
    function setFeeToSetter(address feeToSetter_) public onlyOwner {
        IZirconPylonFactory(pylonFactory).setFeeToSetter(feeToSetter_);
        IZirconEnergyFactory(energyFactory).setFeeToSetter(feeToSetter_);
        IZirconFactory(factory).setFeeToSetter(feeToSetter_);
    }

    function setFees(uint _maximumPercentageSync, uint _deltaGammaTreshold, uint _deltaGammaMinFee, uint _muUpdatePeriod, uint _muChangeFactor, uint _EMASamples, uint _oracleUpdate) external onlyOwner {
        IZirconPylonFactory(pylonFactory).setFees(_maximumPercentageSync, _deltaGammaTreshold, _deltaGammaMinFee, _muUpdatePeriod, _muChangeFactor, _EMASamples, _oracleUpdate);
    }

    function setMinMaxFee(uint112 minFee, uint112 maxFee) external onlyOwner {
        IZirconEnergyFactory(energyFactory).setFee(minFee, maxFee);
    }

    function setPaused(bool paused) external onlyOwner {
        IZirconPylonFactory(pylonFactory).setPaused(paused);
    }

    function setInsurancePerMille(uint insurancePerMille) external onlyOwner {
        IZirconEnergyFactory(energyFactory).setInsurancePerMille(insurancePerMille);
    }

    function setLiquidityFee(uint liquidityFee) external onlyOwner {
        IZirconFactory(factory).setLiquidityFee(liquidityFee);
//        IZirconPylonFactory(pylonFactory).setLiquidityFee(liquidityFee);
    }

    function setDynamicRatio(uint dynamicRatio) external onlyOwner {
        IZirconFactory(factory).setDynamicRatio(dynamicRatio);
    }

    function setFeePercentageRev(uint fee) external onlyOwner {
        require(fee <= 100, 'ZE: FEE_TOO_HIGH');
        require(fee >= 0, 'ZE: FEE_TOO_LOW');
        IZirconEnergyFactory(energyFactory).setFeePercentageRev(fee);
    }

    function setFeePercentageEnergy(uint fee) external onlyOwner {
        require(fee <= 100, 'ZE: FEE_TOO_HIGH');
        require(fee >= 0, 'ZE: FEE_TOO_LOW');
        IZirconEnergyFactory(energyFactory).setFeePercentageEnergy(fee);
    }

    function getFees(address _token, uint _amount, address _to, address energyRev) external onlyOwner {
        require(_amount != 0, "Operations: Cannot recover zero balance");
        IZirconEnergyFactory(energyFactory).getFees(_token, _amount, _to, energyRev);
    }

}