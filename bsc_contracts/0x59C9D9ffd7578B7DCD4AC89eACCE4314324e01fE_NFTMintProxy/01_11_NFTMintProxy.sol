// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.4;
pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/INFTFactory.sol";
import "./interface/IGegoRuleProxy.sol";
import "./library/Governance.sol";


contract NFTMintProxy is Governance, IGegoRuleProxy{
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public _qualityBase = 10000;
    uint256 public _burnRate = 2500;
    uint256 public _maxGrade = 5;
    uint256 public _maxGradeLong = 50;
    uint256 public _maxTLevel = 5;
    address private constant _deadWallet = address(0x000000000000000000000000000000000000dEaD);


    struct RuleData{
        uint256 maxMintAmount;
        uint256 costErc20Amount;
        uint256 costErc20Discount;
        uint256 costErc20DiscountQunatity;
        address mintErc20;
        address costErc20;
        uint256 maxQuantityPerClick;
        uint256 maxQuantityPerBatch;
        uint256 expiringDuration;
        bool canMintMaxGrade;
    }

    address public _costErc20Pool = address(0x0);
    INFTFactory public _factory = INFTFactory(address(0));

    event eSetRuleData(
        uint256 ruleId,
        uint256 maxMintAmount,
        uint256 costErc20Amount,
        uint256 costErc20Discount,
        uint256 costErc20DiscountQunatity,
        address mintErc20,
        address costErc20,
        uint256 maxQuantityPerClick,
        uint256 maxQuantityPerBatch,
        bool canMintMaxGrade,
        uint256 expiringDuration
    );

    uint256 public _currentRuleId;
    mapping(uint256 => RuleData) public _ruleData;
    mapping(uint256 => uint256) public _quantityPerRule;
    mapping(uint256 => bool) public _ruleSwitch;

    constructor(address costErc20Pool) {
        // costErc20Pool : Address wallet to store cost
        _costErc20Pool = costErc20Pool;
    }

    function changePools(address costErc20Pool) external onlyGovernance {
        // costErc20Pool : Address wallet to store cost
        _costErc20Pool = costErc20Pool;
    }

    function setBurnRate(uint256 val) external onlyGovernance{
        require(val < 10000, "invalid burn rate");
        _burnRate = val;
    }


    function setQualityBase(uint256 val) external onlyGovernance{
        _qualityBase = val;
    }

    function setMaxGrade(uint256 val) external onlyGovernance{
        _maxGrade = val;
    }

    function setMaxTLevel(uint256 val) external onlyGovernance{
        _maxTLevel = val;
    }

    function setMaxGradeLong(uint256 val) external onlyGovernance{
        _maxGradeLong = val;
    }

    function setRuleData(
        uint256 ruleId,
        uint256 maxMintAmount,
        uint256 costErc20Amount,
        uint256 costErc20Discount,
        uint256 costErc20DiscountQunatity,
        address mintErc20,
        address costErc20,
        uint256 maxQuantityPerClick,
        uint256 maxQuantityPerBatch,
        uint256 expiringDuration,
        bool canMintMaxGrade
         )
        external
        onlyGovernance
    {
        
        _ruleData[ruleId].maxMintAmount = maxMintAmount;
        _ruleData[ruleId].costErc20Amount = costErc20Amount;
        _ruleData[ruleId].costErc20Discount = costErc20Discount;
        _ruleData[ruleId].costErc20DiscountQunatity = costErc20DiscountQunatity;
        _ruleData[ruleId].mintErc20 = mintErc20;
        _ruleData[ruleId].costErc20 = costErc20;
        _ruleData[ruleId].maxQuantityPerClick = maxQuantityPerClick;
        _ruleData[ruleId].maxQuantityPerBatch = maxQuantityPerBatch;
        _ruleData[ruleId].expiringDuration = expiringDuration;
        _ruleData[ruleId].canMintMaxGrade = canMintMaxGrade;

        _ruleSwitch[ruleId] = true;

        emit eSetRuleData(
            ruleId,
            maxMintAmount,
            costErc20Amount,
            costErc20Discount,
            costErc20DiscountQunatity,
            mintErc20,
            costErc20,
            maxQuantityPerClick,
            maxQuantityPerBatch,
            canMintMaxGrade,
            expiringDuration
        );
    }


     function enableRule( uint256 ruleId,bool enable )
        external
        onlyGovernance
     {
        _ruleSwitch[ruleId] = enable;
     }

     function setCurrentRuleId(uint256 ruleId) external onlyGovernance {
         _currentRuleId = ruleId;
     }

     function setFactory( address factory )
        external
        onlyGovernance
     {
        _factory = INFTFactory(factory);
     }

     function takeFee(
        INFTSignature.Gego calldata gego,
        uint256 feeAmount,
        address receipt
    ) external override returns (address) {
        require(_factory == INFTFactory(msg.sender)," invalid factory caller");
        require(receipt != address(0), "invalid treasuery");
        require(feeAmount < gego.amount, "invalid fee amount");

        IERC20 erc20 = IERC20(gego.erc20);
        erc20.safeTransfer(receipt, feeAmount);
        return gego.erc20;
    }

    function cost( MintParams calldata params) external override returns (  uint256 mintAmount,address mintErc20 ){
        require(_factory == INFTFactory(msg.sender)," invalid factory caller");
        require(_ruleData[params.ruleId].maxQuantityPerBatch >= _quantityPerRule[params.ruleId] + 1, "too much at batch");
       (mintAmount,mintErc20) = _cost(params, 0, true);

       _quantityPerRule[params.ruleId] ++;
    }

    function inject( MintParams calldata params, uint256 oldAmount) external override returns (
        uint256 mintAmount,
        address mintErc20, 
        uint256 expiringDuration
    ){
        require(_factory == INFTFactory(msg.sender)," invalid factory caller");
        expiringDuration = _ruleData[params.ruleId].expiringDuration;
       (mintAmount,mintErc20) = _cost(params, oldAmount, false);
    }

    function costMultiple(MintParams calldata params, uint256 quantity) external override returns ( address mintErc20 ){
        require(_factory == INFTFactory(msg.sender)," invalid factory caller");
        require(_ruleData[params.ruleId].mintErc20 != address(0x0), "invalid mintErc20 rule !");
        require(_ruleData[params.ruleId].costErc20 != address(0x0), "invalid costErc20 rule !");
        require(_ruleData[params.ruleId].maxQuantityPerClick >= quantity, "too much at once");
        require(_ruleData[params.ruleId].maxQuantityPerBatch >= quantity + _quantityPerRule[params.ruleId], "too much at batch");

        uint256 costErc20Amount = _ruleData[params.ruleId].costErc20Amount.mul(quantity);
        if (_ruleData[params.ruleId].costErc20DiscountQunatity > 0) {
            costErc20Amount = costErc20Amount.sub(quantity.div(_ruleData[params.ruleId].costErc20DiscountQunatity).mul(_ruleData[params.ruleId].costErc20Discount));
        }
        
        if(costErc20Amount > 0 && !params.fromAdmin){
            IERC20 costErc20 = IERC20(_ruleData[params.ruleId].costErc20);
            costErc20.transferFrom(params.user, _costErc20Pool, costErc20Amount);
        }
        
        mintErc20 = _ruleData[params.ruleId].mintErc20;

        _quantityPerRule[params.ruleId] += quantity;
    }

    function generate( address user, uint256 ruleId, uint256 randomNonce) external override view returns ( INFTSignature.Gego memory gego ){
        require(_factory == INFTFactory(msg.sender), " invalid factory caller");
        require(_ruleSwitch[ruleId], " rule is closed ");

        uint256 seed = computerSeed(user, randomNonce);

        gego.quality = seed%_qualityBase;
        gego.grade = getGrade(gego.quality);

        if(gego.grade == _maxGrade && _ruleData[ruleId].canMintMaxGrade == false){
            gego.grade = gego.grade.sub(1);
            gego.quality = gego.quality.sub(_maxGradeLong);
        }
        gego.expiringTime = block.timestamp + _ruleData[ruleId].expiringDuration;
        randomNonce++;
    }

    function _cost( MintParams memory params, uint256 oldAmount, bool minting) internal returns (  uint256 mintAmount,address mintErc20 ){
        require(_ruleData[params.ruleId].mintErc20 != address(0x0), "invalid mintErc20 rule !");
        require(_ruleData[params.ruleId].costErc20 != address(0x0), "invalid costErc20 rule !");
        require(params.amount + oldAmount <= _ruleData[params.ruleId].maxMintAmount, "invalid mint amount!");

        mintErc20 = _ruleData[params.ruleId].mintErc20;
        IERC20 mintIErc20 = IERC20(_ruleData[params.ruleId].mintErc20);
        uint256 balanceBefore = mintIErc20.balanceOf(address(this));
        if (params.amount > 0) {
            mintIErc20.transferFrom(params.user, address(this), params.amount);
        }
        uint256 balanceEnd = mintIErc20.balanceOf(address(this));

        if (minting && !params.fromAdmin) {
            uint256 costErc20Amount = _ruleData[params.ruleId].costErc20Amount;
            if(costErc20Amount > 0){
                IERC20 costErc20 = IERC20(_ruleData[params.ruleId].costErc20);
                costErc20.transferFrom(params.user, _costErc20Pool, costErc20Amount);
            }
        }

        mintAmount = balanceEnd.sub(balanceBefore);
    }

    function getActiveRuleData() public view returns (
        uint256 ruleId,
        uint256 maxMintAmount,
        uint256 costErc20Amount,
        uint256 costErc20Discount,
        uint256 costErc20DiscountQunatity,
        address mintErc20,
        address costErc20,
        uint256 maxQuantityPerClick,
        uint256 maxQuantityPerBatch,
        uint256 expiringDuration,
        uint256 mintedQuantity,
        bool canMintMaxGrade
    ) {
        ruleId = _currentRuleId;
        maxMintAmount = _ruleData[_currentRuleId].maxMintAmount;
        costErc20Amount = _ruleData[_currentRuleId].costErc20Amount;
        costErc20Discount = _ruleData[_currentRuleId].costErc20Discount;
        costErc20DiscountQunatity = _ruleData[_currentRuleId].costErc20DiscountQunatity;
        mintErc20 = _ruleData[_currentRuleId].mintErc20;
        costErc20 = _ruleData[_currentRuleId].costErc20;
        maxQuantityPerClick = _ruleData[_currentRuleId].maxQuantityPerClick;
        maxQuantityPerBatch = _ruleData[_currentRuleId].maxQuantityPerBatch;
        expiringDuration = _ruleData[_currentRuleId].expiringDuration;
        canMintMaxGrade = _ruleData[_currentRuleId].canMintMaxGrade;
        mintedQuantity = _quantityPerRule[_currentRuleId];
    }

    function getGrade(uint256 quality) public view returns (uint256){
        if( quality < _qualityBase.mul(500).div(1000)){
            return 1;
        } else if( _qualityBase.mul(500).div(1000) <= quality && quality < _qualityBase.mul(800).div(1000)){
            return 2;
        }else if( _qualityBase.mul(800).div(1000) <= quality && quality < _qualityBase.mul(900).div(1000)){
            return 3;
        }else if( _qualityBase.mul(900).div(1000) <= quality && quality < _qualityBase.mul(980).div(1000)){
            return 4;
        }else if( _qualityBase.mul(980).div(1000) <= quality && quality < _qualityBase.mul(998).div(1000)){
            return 5;
        }else{
            return 6;
        }
    }

    function computerSeed( address user, uint256 nonce ) internal view returns (uint256) {
        // from fomo3D
        uint256 seed = uint256(keccak256(abi.encodePacked(
            //(user.balance).add
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(user)))) / (block.timestamp)).add
            (block.number)
            ,nonce
        )));
        return seed;
    }
}