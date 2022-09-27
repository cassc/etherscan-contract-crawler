//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import {SafeMath} from "../lib/SafeMath.sol";
import {SafeCast} from "../lib/SafeCast.sol";
import {IComposedSoccerStarNft} from "../interfaces/IComposedSoccerStarNft.sol";
import {ISoccerStarNft} from "../interfaces/ISoccerStarNft.sol";
import {IBIBOracle} from "../interfaces/IBIBOracle.sol";

contract ComposedSoccerStarNft is 
IComposedSoccerStarNft, 
OwnableUpgradeable, 
PausableUpgradeable {
    using SafeMath for uint;

    address constant public BLACK_HOLE = address(0x0000000000000000000000000000000000000001);
   
    ISoccerStarNft public tokenContract;
    IERC20 public bibContract;
    IERC20 public busdContract;
    IUniswapV2Router02 public router;

    // fill with default
    uint[12] public feeRates;

    address public treasury;

    uint constant public MAX_STARLEVEL = 4;
    uint constant public STARLEVEL_RANGE = 4;
    uint constant public ORACLE_PRECISION = 1e18;

    uint public startup;
    uint public deadline;

    event TokenContractChanged(address sender, address oldValue, address newValue);
    event BIBContractChanged(address sender, address oldValue, address newValue);
    event BUSDContractChanged(address sender, address oldValue, address newValue);
    event TreasuryChanged(address sender, address oldValue, address newValue);
    event SwapRouterChanged(address sender, address oldValue, address newValue);
    event FeeRateChanged(address sender, uint[12] oldValue, uint[12] newValue);
    
    mapping(address=>bool) public allowToCallTb;

    function initialize(
    address _tokenContract,
    address _bibContract,
    address _busdContract,
    address _treasury,
    address _router
    ) public reinitializer(1) {
        tokenContract = ISoccerStarNft(_tokenContract);
        bibContract = IERC20(_bibContract);
        busdContract = IERC20(_busdContract);
        treasury = _treasury;

        router = IUniswapV2Router02(_router);

        feeRates = [360000,  730000,  1200000, 2200000,
                    1800000, 3650000, 6000000, 11000000,
                    9000000, 18250000,30000000,55000000];

        __Pausable_init();
        __Ownable_init();
    }

    function setAllowToCall(address _caller, bool value) public onlyOwner{
        allowToCallTb[_caller] = value;
    }

    modifier onlyAllowToCall(){
          require(allowToCallTb[msg.sender] || msg.sender == owner(), "ONLY_PERMIT_CALLER");
        _;
    }

    function setActivityTimeline(uint _startup, uint _deadline) public onlyAllowToCall{
        require(_startup > block.timestamp, "STARTUP_TOO_EARLY");
        require(_deadline > _startup, "INVALID_DEADLINE");

        startup = _startup;
        deadline = _deadline;
    }

    function isActivityOpen() public view returns(bool){
        return block.timestamp >= startup && block.timestamp < deadline;
    }

    function setTokenContract(address _tokenContract) public onlyOwner{
        require(address(0) != _tokenContract, "INVLID_ADDRESS");
        emit TokenContractChanged(msg.sender, address(tokenContract), _tokenContract);
        tokenContract = ISoccerStarNft(_tokenContract);
    }

    function setBIBContract(address _bibContract) public onlyOwner{
        require(address(0) != _bibContract, "INVLID_ADDRESS");
        emit BIBContractChanged(msg.sender, address(bibContract), _bibContract);
        bibContract = IERC20(_bibContract);
    }

    function setTreasury(address _treasury) public onlyOwner{
        require(address(0) != _treasury, "INVLID_ADDRESS");
        emit TreasuryChanged(msg.sender, treasury, _treasury);
        treasury = _treasury;
    }

    function setSwapRouter(address _router) public onlyOwner{
        require(address(0) != _router, "INVLID_ADDRESS");
        emit SwapRouterChanged(msg.sender, address(router), _router);
        router = IUniswapV2Router02(_router);
    }

    function setBUSDContract(address _busdContract) public onlyOwner{
        require(address(0) != _busdContract, "INVLID_ADDRESS");
        emit BUSDContractChanged(msg.sender, address(busdContract), _busdContract);
        busdContract = IERC20(_busdContract);
    }

    function configFeeRate(uint[12] memory _feeRates) public onlyOwner{
        require(_feeRates.length == feeRates.length, "INVLID_FEERATES");
        emit FeeRateChanged(msg.sender, feeRates, _feeRates);
        for(uint i = 0; i < _feeRates.length; i++){
            feeRates[i] = _feeRates[i];
        }
    }

    function compose(
    uint[] memory tokenIds,
    ComposeMode mode, 
    uint extralToken, 
    PayMethod payMethod
    ) public override whenNotPaused{
        require(4 == tokenIds.length, "NEED_FOUR_TOKENS");
        require(validToken(tokenIds[0], tokenIds), "NEED_SAME_TOKEN_PROPER");
        require(validStarLevel(tokenIds[0]), "INVALID_STARLEVEL");

        // valid owner ship
        validOwnership(tokenIds);

        // burn all
        for(uint i = 0; i < tokenIds.length; i++){
            IERC721(address(tokenContract)).transferFrom(msg.sender, BLACK_HOLE, tokenIds[i]);
        }

        // compose new
        ISoccerStarNft.SoccerStar memory soccerStar = tokenContract.getCardProperty(tokenIds[0]);

        uint payAmount = 0;
        if(ComposeMode.COMPOSE_NORMAL == mode) {
            require(msg.sender == IERC721(address(tokenContract)).ownerOf(extralToken), "TOKEN_NOT_BELLOW_TO_SENDER");
            // burn the extral
            IERC721(address(tokenContract)).transferFrom(msg.sender, BLACK_HOLE, extralToken);
        } else {
            require(isActivityOpen(), "ACTIVITY_IS_NOT_OPENED");
            
            payAmount = caculateBurnAmount(soccerStar.starLevel, soccerStar.gradient);
            if(PayMethod.PAY_BIB == payMethod){
                bibContract.transferFrom(msg.sender, BLACK_HOLE, payAmount);
            } else {
                payAmount = caculateBUSDAmount(payAmount);
                busdContract.transferFrom(msg.sender, treasury, payAmount);
            }
        }

        uint newToken = tokenContract.protocolMint();
        // starlevel added by one
        soccerStar.starLevel += 1;
        tokenContract.protocolBind(newToken, soccerStar);
        IERC721(address(tokenContract)).transferFrom(address(this), msg.sender, newToken);
        emit Composed(msg.sender, tokenIds, extralToken,newToken, mode, payMethod, payAmount);
    }

    function caculateBurnAmount(uint starLevel, uint gradient) public view returns(uint){
        uint decimals = IERC20Metadata(address(bibContract)).decimals();
        return feeRates[(starLevel - 1) * STARLEVEL_RANGE + (gradient - 1)].exp(decimals);
    }

    function caculateBUSDAmount(uint bibAmount) public view returns(uint){
        // the price has ORACLE_PRECISION
        address[] memory path = new address[](2);
        path[0] = address(bibContract);
        path[1] = address(busdContract);
        return router.getAmountsOut(bibAmount, path)[1];
    }

    function validOwnership(uint[] memory tokensToValid) internal view {
        for(uint i = 0; i < tokensToValid.length; i++){
            require(msg.sender == IERC721(address(tokenContract)).ownerOf(tokensToValid[i]), "TOKEN_NOT_BELLOW_TO_SENDER");
        }
    }

    function validStarLevel(uint tokenId) internal view returns(bool){
        uint level = tokenContract.getCardProperty(tokenId).starLevel;
        return level > 0 && level < MAX_STARLEVEL;
    }

    function validToken(uint base, uint[] memory tokensToValid) internal view returns(bool){
        if(0 == tokensToValid.length){
            return false;
        }

        ISoccerStarNft.SoccerStar memory baseProperty = tokenContract.getCardProperty(base);
        for(uint i = 0; i < tokensToValid.length; i++){
            if(!cmpProperty(baseProperty, tokenContract.getCardProperty(tokensToValid[i]))){
                return false;
            }
        }
        return true;
    }

    function cmpProperty (
    ISoccerStarNft.SoccerStar memory a, 
    ISoccerStarNft.SoccerStar memory b) internal pure returns(bool){
        return keccak256(bytes(a.name)) == keccak256(bytes(b.name))
        && keccak256(bytes(a.country)) == keccak256(bytes(b.country))
        && keccak256(bytes(a.position)) == keccak256(bytes(b.position))
        && a.gradient == b.gradient;
    }
}