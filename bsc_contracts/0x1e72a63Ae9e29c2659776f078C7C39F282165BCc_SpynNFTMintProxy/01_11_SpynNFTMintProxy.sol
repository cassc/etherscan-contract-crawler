// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.4;
pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/ISpynNFTFactory.sol";
import "./interface/IGegoRuleProxy.sol";
import "./library/Governance.sol";


contract SpynNFTMintProxy is Governance, IGegoRuleProxy{
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public _qualityBase = 10000;
    uint256 public _maxGrade = 6;
    uint256 public _maxGradeLong = 20;
    uint256 public _minLockDays = 180;
    uint256 public _maxLockDays = 360;

    bool public _canAirdrop = false;
    uint256 public _airdopMintAmount = 5 * (10**15);


    struct RuleData{
        uint256 minMintAmount;
        uint256 maxMintAmount;
        uint256 costErc20Amount;
        address mintErc20;
        address costErc20;
        uint256 minBurnTime;
        bool canMintMaxGrade;
    }

    address public _costErc20Pool = address(0x0);
    ISpynNFTFactory public _factory = ISpynNFTFactory(address(0));

    event eSetRuleData(uint256 ruleId, uint256 minMintAmount, uint256 maxMintAmount, uint256 costErc20Amount, address mintErc20, address costErc20, bool canMintMaxGrade,uint256 minBurnTime);

    mapping(uint256 => RuleData) public _ruleData;
    mapping(uint256 => bool) public _ruleSwitch;

    constructor(address costErc20Pool) {
        // costErc20Pool : Address wallet to store cost
        _costErc20Pool = costErc20Pool;
    }

    function setMaxLockDays(uint256 maxLockDays) public onlyGovernance{
        _maxLockDays = maxLockDays;
    }

    function setMinLockDays(uint256 minLockDays) public onlyGovernance{
        _minLockDays = minLockDays;
    }

    function setAirdropAmount(uint256 value) public onlyGovernance{
        _airdopMintAmount = value;
    }

    function enableAirdrop(bool b) public onlyGovernance{
        _canAirdrop = b;
    }


    function setQualityBase(uint256 val) public onlyGovernance{
        _qualityBase = val;
    }

    function setMaxGrade(uint256 val) public onlyGovernance{
        _maxGrade = val;
    }

    function setMaxGradeLong(uint256 val) public onlyGovernance{
        _maxGradeLong = val;
    }

    function setRuleData(
        uint256 ruleId,
        uint256 minMintAmount,
        uint256 maxMintAmount,
        uint256 costErc20Amount,
        address mintErc20,
        address costErc20,
        uint256 minBurnTime,
        bool canMintMaxGrade
         )
        public
        onlyGovernance
    {
        
        _ruleData[ruleId].minMintAmount = minMintAmount;
        _ruleData[ruleId].maxMintAmount = maxMintAmount;
        _ruleData[ruleId].costErc20Amount = costErc20Amount;
        _ruleData[ruleId].mintErc20 = mintErc20;
        _ruleData[ruleId].costErc20 = costErc20;
        _ruleData[ruleId].minBurnTime = minBurnTime;
        _ruleData[ruleId].canMintMaxGrade = canMintMaxGrade;

        _ruleSwitch[ruleId] = true;

        emit eSetRuleData( ruleId, minMintAmount, maxMintAmount, costErc20Amount, mintErc20,  costErc20, canMintMaxGrade,minBurnTime);
    }


     function enableRule( uint256 ruleId,bool enable )
        public
        onlyGovernance
     {
        _ruleSwitch[ruleId] = enable;
     }

     function setFactory( address factory )
        public
        onlyGovernance
     {
        _factory = ISpynNFTFactory(factory);
     }

    function takeFee(
        ISpynNFT.Gego calldata gego,
        uint256 feeAmount,
        address receipt
    ) external override returns (address) {
        require(_factory == ISpynNFTFactory(msg.sender)," invalid factory caller");
        require(receipt != address(0), "invalid treasuery");
        require(feeAmount < gego.amount, "invalid fee amount");

        IERC20 erc20 = IERC20(gego.erc20);
        erc20.safeTransfer(receipt, feeAmount);
        return gego.erc20;
    }
    function cost( MintParams calldata params) external override returns (  uint256 mintAmount,address mintErc20 ){
        require(_factory == ISpynNFTFactory(msg.sender)," invalid factory caller");
       (mintAmount,mintErc20) = _cost(params);
    }

    function destroy(  address owner, ISpynNFT.Gego calldata gego) external override {
        require(_factory == ISpynNFTFactory(msg.sender)," invalid factory caller");

        // rule proxy ignore mint time
        if( _factory.isRulerProxyContract(owner) == false){
            require((block.timestamp - gego.createdTime) >= gego.lockedDays * 86400, "< minBurnTime");
        }

        IERC20 erc20 = IERC20(gego.erc20);
        erc20.safeTransfer(owner, gego.realAmount);
    }


    function generate( address user , uint256 ruleId, uint256 randomNonce ) external override view returns (  ISpynNFT.Gego memory gego ){
        require(_factory == ISpynNFTFactory(msg.sender), " invalid factory caller");
        require(_ruleSwitch[ruleId], " rule is closed ");

        uint256 seed = computerSeed(user);

        gego.quality = seed%_qualityBase;
        gego.grade = getGrade(gego.quality);

        if(gego.grade == _maxGrade && _ruleData[ruleId].canMintMaxGrade == false){
            gego.grade = gego.grade.sub(1);
            gego.quality = gego.quality.sub(_maxGradeLong);
        }
        gego.lockedDays = computeLockDays(user, randomNonce);
        randomNonce++;
    }

    function _cost( MintParams memory params) internal returns (  uint256 mintAmount,address mintErc20 ){
        require(_ruleData[params.ruleId].mintErc20 != address(0x0), "invalid mintErc20 rule !");
        require(_ruleData[params.ruleId].costErc20 != address(0x0), "invalid costErc20 rule !");
        require(params.amount >= _ruleData[params.ruleId].minMintAmount && params.amount < _ruleData[params.ruleId].maxMintAmount, "invalid mint amount!");

        IERC20 mintIErc20 = IERC20(_ruleData[params.ruleId].mintErc20);
        uint256 balanceBefore = mintIErc20.balanceOf(address(this));
        mintIErc20.transferFrom(params.user, address(this), params.amount);
        uint256 balanceEnd = mintIErc20.balanceOf(address(this));

        uint256 costErc20Amount = _ruleData[params.ruleId].costErc20Amount;
        if(costErc20Amount > 0){
            IERC20 costErc20 = IERC20(_ruleData[params.ruleId].costErc20);
            costErc20.transferFrom(params.user, _costErc20Pool, costErc20Amount);
        }

        mintAmount = balanceEnd.sub(balanceBefore);
        mintErc20 = _ruleData[params.ruleId].mintErc20;

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

    function computerSeed( address user ) internal view returns (uint256) {
        // from fomo3D
        uint256 seed = uint256(keccak256(abi.encodePacked(
            //(user.balance).add
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(user)))) / (block.timestamp)).add
            (block.number)
            
        )));
        return seed;
    }

    function computeLockDays(address user, uint nonce) internal view returns (uint256) {
        // random from 180 - 360 days
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, user, nonce))) % (_minLockDays + 1);
        randomnumber = randomnumber + _maxLockDays - _minLockDays;
        if(randomnumber < _minLockDays) randomnumber = _minLockDays;
        if(randomnumber > _maxLockDays) randomnumber = _maxLockDays;
        return randomnumber;
    }


}