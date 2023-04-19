//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./library/EGoldUtils.sol";

import "../../interfaces/iEGoldMinerNFT.sol";
import "../../interfaces/iEGoldIdentity.sol";
import "../../interfaces/iEGoldMinerRegistry.sol";
import "../../interfaces/iEGoldRank.sol";
import "../../interfaces/iEGoldRate.sol";
import "../../interfaces/iEGoldCashback.sol";

contract EGoldTreasury3 is AccessControl , Pausable , ReentrancyGuard {
    using SafeMath for uint256;

    IEGoldIdentity public Identity;

    IEGoldMinerRegistry public MinerRegistry;

    IEGoldRank public Rank;

    IEGoldRate public Rate;

    IERC20 public Token;

    iEGoldMinerNFT public NFT;

    iEGoldCashback public Cashback;

    address public burner;

    uint256 public burnRatio;

    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");

    uint256 public MaxLevel;

    address public masterAddress;

    mapping ( address => userStruct ) private Userinfo;

    struct userStruct {
        uint256 share;
        uint256 sales;
    }

    modifier isVaildClaim(uint256 _amt) {
        require(Userinfo[msg.sender].share >= _amt);
        _;
    }

    modifier isVaildReferer(address _ref) {
        uint256 level = Identity.fetchRank(_ref);
        require(level != 0);
        _;
    }

    event puchaseEvent(
        address indexed _buyer,
        address indexed _referer,
        uint256 _minterType,
        uint256 _rate
    );

    event alloc(address indexed _address, uint256 _share);

    event claimEvent(address indexed _buyer, uint256 _value, uint256 _pendingShare);

    constructor ( address _identity , address _minerReg , address _rank ,  address _rate , address _master , uint256 _maxLevel , address _token , address _nft , uint256 _burnRatio , address _burnerAddr , address _cashback , address _DFA ) AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, _DFA);

        Identity = IEGoldIdentity(_identity);
        MinerRegistry = IEGoldMinerRegistry(_minerReg);
        Rank = IEGoldRank(_rank);
        Rate = IEGoldRate(_rate);
        Token = IERC20(_token);
        NFT = iEGoldMinerNFT(_nft);
        Cashback = iEGoldCashback(_cashback);
        burnRatio = _burnRatio;
        burner = _burnerAddr;

        masterAddress = _master;
        MaxLevel = _maxLevel;
    }

    function setShare(address _addr , userStruct memory _userInfo ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        Userinfo[_addr] = _userInfo;
        return true;
    }


    // Pause Function
    function pauseToken() external onlyRole(PAUSE_ROLE) returns (bool) {
        _pause();
        return true;
    }

    function unpauseToken() external onlyRole(PAUSE_ROLE) returns (bool) {
        _unpause();
        return true;
    }
    // Pause Function

    function LevelChange(address _addr) internal {
        uint256 curLevel = Identity.fetchRank(_addr);
        while (curLevel <= MaxLevel) {
            ( uint256 _sn , ) = Identity.fetchSales(_addr);
            if ( _sn < Rank.fetchRanklimit(curLevel) ){
                break;
            } else {
                // Set function
                bytes memory data = abi.encodeWithSignature("setRank(address,uint256)", _addr , curLevel );
                (bool success, ) = address(Identity).call( data);
                require(success, "Call failed");
            }
            curLevel = curLevel.add(1);
        }
    }

    function LoopFx(
        address _addr,
        uint256 _value0,
        uint256 _value,
        uint256 _shareRatio,
        uint256 _ctr
    ) internal returns ( uint256 value ) {
        ( uint256 _sn , uint256 _sales ) = Identity.fetchSales(_addr );
        // Set Fx
        bytes memory data = abi.encodeWithSignature("setSales(address,uint256,uint256)", _addr , _sn + _value0  , _sales + _value0);
        (bool success, ) = address(Identity).call( data);
        require(success, "Call failed");

        uint256 rankPercent = Rank.fetchRankPercent(Identity.fetchRank(_addr));
        if ( _shareRatio < rankPercent ) {
            uint256 diff = rankPercent - _shareRatio;
            Userinfo[_addr].share = Userinfo[_addr].share + _value.mul(diff).div(1000000);
            Userinfo[_addr].sales = Userinfo[_addr].sales + _value.mul(diff).div(1000000);
            emit alloc( _addr , _value.mul(diff).div(1000000) );
            value = rankPercent;

            // Set Cashback
            addCashback( _addr , _value0 , _ctr);

        } else if ( _shareRatio == rankPercent ) {
            emit alloc(_addr, 0);
            value = rankPercent;
        }
        return value;
    }

    function addCashback ( address _addr , uint256 _value , uint256 _ctr ) internal {
        uint256 cb;
        if ( _ctr == 1 ){
            cb = (_value.mul(1000)).div(10000);
        }else{
            cb = (_value.mul(100)).div(10000);
        }

        // Set Cashback
        bytes memory data3 = abi.encodeWithSignature("addCashback(address,uint256)", _addr , cb );
        (bool success, ) = address(Cashback).call( data3 );
        require(success, "Call failed");
    }

    function iMint(address _addr, uint256 _type) internal {
        EGoldUtils.minerStruct memory minerInfo = MinerRegistry.fetchMinerInfo(_type);
        NFT.mint(_addr,  minerInfo.uri , minerInfo.name , minerInfo.hashRate, minerInfo.powerFactor);
    }

    function purchase(address _referer, uint256 _type)
        public
        whenNotPaused
        isVaildReferer(_referer)
        returns (bool)
    {
        address Parent;
        uint256 cut = 0;
        uint256 lx = 0;
        bool overflow = false;
        iMint(msg.sender, _type);

        uint256 amt = MinerRegistry.fetchMinerRate(_type);
        uint256 tokens = Rate.fetchRate(amt);
        Token.transferFrom(msg.sender, address(this) , tokens);

        uint256 bToken = (tokens.mul(burnRatio)).div(10000);
        tokens = tokens.sub(bToken);
        Token.transfer( burner , bToken);

        if (Identity.fetchRank(msg.sender) == 0) {
            // Set Fx
            bytes memory data1 = abi.encodeWithSignature("setRank(address,uint256)", msg.sender , 1 );
            (bool success, ) = address(Identity).call( data1 );
            require(success, "Call failed");
        }

        address iParent = Identity.fetchParent(msg.sender);
        if (iParent == address(0)) {
            Parent = _referer;
            // Set Fx
            bytes memory data2 = abi.encodeWithSignature("setParent(address,address)", msg.sender , Parent );
            (bool success, ) = address(Identity).call( data2 );
            require(success, "Call failed");
        } else {
            Parent = iParent;
        }
        while (lx < 500) {
            lx = lx.add(1);
            cut = LoopFx(Parent, amt * 1 ether , tokens ,  cut , lx );
            LevelChange(Parent);
            address lParent = Identity.fetchParent(Parent);
            if (lParent == address(0)) {
                break;
            }
            Parent = lParent;
            if (lx == 500) {
                overflow = true;
            }
        }
        if (overflow) {
            cut = LoopFx(masterAddress, amt * 1 ether , tokens , cut , lx);
        }
        emit puchaseEvent(msg.sender, iParent, _type , amt );
        return true;
    }

    function claim(uint256 _amt) external whenNotPaused isVaildClaim(_amt) returns (bool) {
        uint256 userShare = Userinfo[msg.sender].share;
        Userinfo[msg.sender].share = userShare  - _amt;
        Token.transfer(msg.sender,_amt);
        emit claimEvent(msg.sender, _amt, Userinfo[msg.sender].share);
        return true;
    }

    function fetchClaim( address _addr ) external view returns ( uint256 ){
        return Userinfo[_addr].share;
    }

    function fetchSales( address _addr ) external view returns ( uint256 ){
        return Userinfo[_addr].sales;
    }

}