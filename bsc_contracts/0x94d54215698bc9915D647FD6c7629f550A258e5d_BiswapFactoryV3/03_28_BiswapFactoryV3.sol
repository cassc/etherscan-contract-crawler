// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../interfaces/IBiswapFactoryV3.sol";
import "./BiswapPoolV3.sol";
import "../libraries/DeployPool.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

struct DeployPoolParams {
    address tokenX;
    address tokenY;
    uint16 fee;
    int24 currentPoint;
    int24 pointDelta;
    uint24 feeChargePercent;
}

contract BiswapFactoryV3 is Ownable, IBiswapFactoryV3 {

    /// @notice charge receiver of all pools in this factory
    address public override chargeReceiver;

    /// @notice tokenX/tokenY/fee => pool address
    mapping(address => mapping(address => mapping(uint16 => address))) public override pool;

    /// @notice fee discount for user address => pool address => % discount in base 10000
    mapping(address => mapping(address => uint16)) public override feeDiscount;

    /// @notice mapping from fee amount to pointDelta
    mapping(uint16 => int24) public override fee2pointDelta;

    /// @notice mapping from fee to fee delta [fee - %delta; fee + %delta] delta in percent base 10000
    mapping(uint16 => uint16) public override fee2DeltaFee;

    /// @notice mark contract address in constructor to avoid delegate call
    address public only_addr_;

    address public discountSetter;

    /// @notice Add struct to save gas
    Addresses public override addresses;

    /// @notice default fee rate from miner's fee gain * 100
    uint24 public override defaultFeeChargePercent;

    DeployPoolParams public override deployPoolParams;

    /// @notice Construct the factory
    /// @param _swapX2YModule swap module to support swapX2Y(DesireY)
    /// @param _swapY2XModule swap module to support swapY2X(DesireX)
    /// @param _liquidityModule liquidity module to support mint/burn/collect
    /// @param _limitOrderModule module for user to manage limit orders
    /// @param _flashModule module for user to flash
    /// @param _defaultFeeChargePercent default fee rate from miner's fee gain * 100
    constructor(
        address _chargeReceiver,
        address _swapX2YModule,
        address _swapY2XModule,
        address _liquidityModule,
        address _limitOrderModule,
        address _flashModule,
        uint24 _defaultFeeChargePercent
    ) {
        only_addr_ = address(this);
        fee2pointDelta[100] = 1;
        fee2pointDelta[400] = 8;
        fee2pointDelta[2000] = 40;
        fee2pointDelta[10000] = 200;
        addresses.swapX2YModule = _swapX2YModule;
        addresses.swapY2XModule = _swapY2XModule;
        addresses.liquidityModule = _liquidityModule;
        addresses.limitOrderModule = _limitOrderModule;
        addresses.flashModule = _flashModule;
        chargeReceiver = _chargeReceiver;
        defaultFeeChargePercent = _defaultFeeChargePercent;
    }

    modifier noDelegateCall() {
        require(address(this) == only_addr_);
        _;
    }

    modifier onlyDiscountSetter(){
        require(msg.sender == discountSetter);
        _;
    }

    /// @inheritdoc IBiswapFactoryV3
    function enableFeeAmount(uint16 fee, uint24 pointDelta) external override noDelegateCall onlyOwner {
        require(pointDelta > 0, "P0");
        require(fee2pointDelta[fee] == 0, "FD0");
        fee2pointDelta[fee] = int24(pointDelta);
    }

    /// @inheritdoc IBiswapFactoryV3
    function newPool(
        address tokenX,
        address tokenY,
        uint16 fee,
        int24 currentPoint
    ) external override noDelegateCall returns (address addr) {
        require(tokenX != tokenY, "SmTK");
        if (tokenX > tokenY) {
            (tokenX, tokenY) = (tokenY, tokenX);
        }
        require(pool[tokenX][tokenY][fee] == address(0));
        int24 pointDelta = fee2pointDelta[fee];

        require(pointDelta > 0, 'pd');
        // now creating
        bytes32 salt = keccak256(abi.encode(tokenX, tokenY, fee));

        deployPoolParams = DeployPoolParams({
            tokenX: tokenX,
            tokenY: tokenY,
            fee: fee,
            currentPoint: currentPoint,
            pointDelta: pointDelta,
            feeChargePercent: defaultFeeChargePercent
        });

        addr = DeployPool.deployPool(salt);
        delete deployPoolParams;

        pool[tokenX][tokenY][fee] = addr;
        pool[tokenY][tokenX][fee] = addr;
        emit NewPool(tokenX, tokenY, fee, uint24(pointDelta), addr);
    }

    /// @inheritdoc IBiswapFactoryV3
    function modifyChargeReceiver(address _chargeReceiver) external override onlyOwner {
        chargeReceiver = _chargeReceiver;
    }

    /// @inheritdoc IBiswapFactoryV3
    function modifyDefaultFeeChargePercent(uint24 _defaultFeeChargePercent) external override onlyOwner {
        defaultFeeChargePercent = _defaultFeeChargePercent;
    }

    /// @inheritdoc IBiswapFactoryV3
    function getFeeRange(uint16 fee) public view override returns(uint16 low, uint16 high){
        uint16 delta = fee2DeltaFee[fee];
        if(delta == 0){
            return(fee, fee);
        } else {
            return(uint16(fee - uint256(fee) * delta/10000), uint16(fee + uint256(fee) * delta/10000));
        }
    }

    /// @inheritdoc IBiswapFactoryV3
    function setFeeDelta(uint16 fee, uint16 delta) external override onlyOwner {
        require(delta <= 5000, "DOR");
        uint16 oldDelta = fee2DeltaFee[fee];
        fee2DeltaFee[fee] = delta;
        emit FeeDeltaChanged(oldDelta, delta);
    }

    function checkFeeInRange(uint16 fee, uint16 initFee) external view override returns(bool){
        (uint16 lowFee, uint16 highFee) = getFeeRange(initFee);
        return(fee >= lowFee && fee <= highFee);
    }

    function setDiscountSetterAddress(address newDiscountSetter) external override onlyOwner {
        require(newDiscountSetter != address(0));
        discountSetter = newDiscountSetter;
        emit NewDiscountSetter(newDiscountSetter);
    }

    struct DiscountStr {
        address user;
        address pool;
        uint16 discount;
    }

    function setDiscount(DiscountStr[] calldata discounts) external onlyDiscountSetter {
        for(uint i; i < discounts.length;i++){
            require(discounts[i].discount <= 5000,"VOR");
            feeDiscount[discounts[i].user][discounts[i].pool] = discounts[i].discount;
        }
    }

    function INIT_CODE_HASH() external pure returns(bytes32){
        return(DeployPool.INIT_CODE_HASH());
    }

}