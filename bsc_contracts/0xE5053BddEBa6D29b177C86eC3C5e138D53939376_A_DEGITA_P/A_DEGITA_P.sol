/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.19;

/**----------------------------------------*
    ███████ ██    ██    ███████ ██ ███████
    ██░░░██ ██   ███    ██░░░██ ██     ██
    ██░░░██ ██ ██ ██    █████   ██   ███  
    ██░░░██ ███   ██    ██░░░██ ██  ██     
    ███████ ██    ██    ███████ ██ ███████                                      
-------------------------------------------**--**/
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
abstract contract Ownable {
    address private _owner;
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IBEP20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface ISYS {
    struct AccountInfo {
        uint num;
        address addr;
    }
    struct User {
        bytes32 id;
        bytes32 spon;
        bytes32 parent;
        bytes32 side1;
        bytes32 side2;
        bytes32 side3;

        uint teamTotal;
        uint[3] genCount; //[f1, f1Act, totalGen]
        uint[3] team; // [1,2,3]
        uint[12] level; // [1-12]
        uint[12] level12; // [1-12]
        uint[2] totalPay; // [me,tree]
        uint256 totalIncome;

        uint roundStep; //1-->12
        uint round; //1-->5
        uint256 firstTime;
        uint myAcc;
        uint maxAcc;
    }
    struct Round {
        uint no; //1-->5
        uint step; // 12
        uint payTotal; //17$
        uint fee; //2$
        uint aff; //5$
        uint bonus; //10$
    }

    function addrCallCheck() external view returns (address ori, address sender, address contr, address admin, address spec, address comp, address top);
    function sellToken(uint256 amountUsd) external returns (bool success);
    function getSiteInfo()external view returns (uint256 u, uint256 acc, uint256 tPay, uint tBcount, uint256 bnb,uint256 usd);
    
    function setNumIds() external;
    function setNumIdsNew(uint numNew) external;
    
    function setTotalUsers() external;
    function setTotalUsersNew(uint numNew) external;

    function setTotalPayAmounts(uint256 amount) external;
    function setTotalPayAmountsNew(uint256 amountNew) external;

    function setBonusCount(uint numNew) external;

    function setAccInfo(bytes32 id, address addr, uint num) external;
    function setUsedIds(bytes32 id, bool b) external;

    function setRefListPush(bytes32 refID, bytes32 id) external;
    function setRefList(bytes32 refID, bytes32[] memory list) external;
    function setRefListIdx(uint idx, bytes32 idOld, bytes32 idNew) external;
    
    function setAccOfAddPush(address addr, bytes32 id) external;
    function setAccOfAdd(address addr, bytes32[] memory list) external;

    function setTopsPush(uint lv, bytes32 id) external;
    function setTops(uint lv, bytes32[] memory list) external;

    function setUser(bytes32 id, User memory u) external;
    function setUid(bytes32 id) external;
    function setUSpon(bytes32 id, bytes32 spon) external;
    function setUPa(bytes32 id, bytes32 pa) external;
    function setUside1(bytes32 id, bytes32 sID) external;
    function setUside2(bytes32 id, bytes32 sID) external;
    function setUside3(bytes32 id, bytes32 sID) external;
    
    // ---------------------
    function register(bytes32 refID) external;
    function regNewAcc(bytes32 spon) external;

    function payByUSD(bytes32 id) external;
    function payAll(address addr) external;
    function payStepAll(address addr, uint step) external ;
    function newAccAll(address addr) external;

    function getPayUp(bytes32 fromID, uint fromS, uint fromR) external view returns(bytes32 payID);
    function checkPa(bytes32 paID, uint fromS, uint fromR) external view returns(bytes32 paOk);
    function iDOfAdd(address addr) external view returns (bytes32[] memory);
    function iD2Addr(bytes32 id) external view returns (address);
    function iD0(address addr) external view returns (bytes32);
    // ---------------------

    function checkInGen(bytes32 fromID, bytes32 id) external view returns(bool done);
    function checkInTree(bytes32 fromID, bytes32 id) external view returns(bool done);
    function isExist(bytes32 id) external view returns(bool);
    function isMax(bytes32 id) external view returns(bool);
    
    function round2() external view returns(bool);
    function r2list() external view returns (bytes32[] memory);
    function isMaxCheckList(address addr) external view returns(bytes32[] memory);
    function findLocal(bytes32 spon) external view returns (bytes32 lo, uint s);
    function checkTop12(bytes32 id, uint lv) external view returns(bool b);
    
    function usedIds(bytes32 id) external view returns (bool);
    function accInfo(bytes32 id) external view returns (AccountInfo memory);
    function users(bytes32 id) external view returns (User memory);
    function getUser(bytes32 id) external view returns (User memory);
    function getSpon(bytes32 id) external view returns (bytes32);
    function getPa(bytes32 id) external view returns (bytes32);
    function getIncome(bytes32 id) external view returns (uint256);
    function getStep(bytes32 id) external view returns(uint r, uint s);

    function getUserSideList(bytes32 id) external view returns (bytes32[] memory);
    function getUserLevel(bytes32 id, uint idx) external view returns (uint);
    function getUserRefList(bytes32 id) external view returns (bytes32[] memory);
    function getTopListAll(uint n) external view returns (bytes32[] memory);
    function getNumAcc(bytes32 id) external view returns(uint acc, uint max);
}

/**----------------------------------------**/
contract A_DEGITA_P is Ownable {
    using SafeMath for uint256;
    IBEP20 private _usd;
    ISYS private _sys;

    address private _admin;
    address private _special;
    address private _company;
    uint256 private _changeAddrFee = 1*1e18; //1$
    bool public needFee = false;

    constructor() {
        _usd = IBEP20(0x55d398326f99059fF775485246999027B3197955);
        _admin = owner();
        _special = owner();
    }

    function wBNB() external onlyOwner {
        require(address(this).balance > 0, "Balance need > 0!");
        payable(msg.sender).transfer(address(this).balance);
    }
    function wAnyTokenAll(address _contract) external onlyOwner {
        require(IBEP20(_contract).balanceOf(address(this)) > 0, "Need > 0!");
        IBEP20(_contract).transfer(msg.sender, IBEP20(_contract).balanceOf(address(this)));
    }
    function wAnyToken(address _contract, uint256 amount) external onlyOwner {
        require(IBEP20(_contract).balanceOf(address(this)) >= amount, "Not enough!");
        IBEP20(_contract).transfer(msg.sender, amount);
    }
    modifier onlyAdmin() {
        require(_admin == tx.origin, "Only Admin");
        _;
    }   
    modifier onlySpecial() {
        require(_special == _msgSender() || _admin == tx.origin, "Only Special || admin");
        _;
    }
    
    //SET----------------------------------------
    function setAdmin(address addr) external onlyAdmin {
        _admin = address(addr);
    }
    function setSpecial(address addr) external onlyAdmin {
        _special = address(addr);
    }
    function setCompany(address addr) external onlyAdmin {
        _company = address(addr);
    }
    function setConUsd(address _contract) external onlyAdmin {
        _usd = IBEP20(_contract);
    }
    function setConSys(address _contract) public onlyAdmin {
        _sys = ISYS(_contract);
    }
    function setNeedFee() external onlyAdmin {
        needFee = !needFee;
    }
    
    // SYS-------------------------
    function getSiteInfo()public view returns (uint256 u, uint256 acc,uint256 tPay, uint tBcount, uint256 bnb,uint256 usd){
       return _sys.getSiteInfo();
    }
    
    function findLocal(bytes32 spon) external view returns (bytes32 lo, uint s){
        (bytes32 _lo, uint _s) = _sys.findLocal(spon);
        lo = _lo;
        s = _s;
    }
    function checkTop12(bytes32 id, uint lv) external view returns(bool b){
        b = _sys.checkTop12(id, lv);
    }
    function checkInGen(bytes32 fromID, bytes32 id) external view returns(bool done){
       done = _sys.checkInGen(fromID, id);
    }
    function checkInTree(bytes32 fromID, bytes32 id) external view returns(bool done){
       done = _sys.checkInTree(fromID, id);
    }
    function isMax(bytes32 id) external view returns(bool){
        return _sys.isMax(id);
    }
    function isMaxCheckList(address addr) external view returns(bytes32[] memory){
       return _sys.isMaxCheckList(addr);
    }
    
    function getUser(bytes32 id) external view returns (ISYS.User memory){
       return  _sys.getUser(id);
    }
    function getSpon(bytes32 id) public view returns (bytes32){
        return _sys.getSpon(id);
    }
    function getPa(bytes32 id) public view returns (bytes32){
        return _sys.getPa(id);
    }
    function getIncome(bytes32 id) public view returns (uint256){
        return _sys.getIncome(id);
    }
    function getStep(bytes32 id) external view returns(uint r, uint s){
        (uint _r, uint _s) = _sys.getStep(id);
        r = _r;
        s = _s;
    }
    function getNumAcc(bytes32 id) external view returns(uint acc, uint max){
        (uint _acc, uint _max) = _sys.getNumAcc(id);
        acc = _acc;
        max = _max;
    }
    
    function getUserSideList(bytes32 id) external view returns (bytes32[] memory){
        return _sys.getUserSideList(id);
    }
    function getUserSide1(bytes32 id) external view returns (bytes32){
        return _sys.getUser(id).side1;
    }
    function getUserSide2(bytes32 id) external view returns (bytes32){
        return _sys.getUser(id).side2;
    }
    function getUserSide3(bytes32 id) external view returns (bytes32){
        return _sys.getUser(id).side3;
    }
    function getUserLevel(bytes32 id, uint idx) external view returns (uint){
        return  _sys.getUserLevel(id, idx);
    }
    function getUserRefList(bytes32 id) external view returns (bytes32[] memory){
        return _sys.getUserRefList(id);
    }
    function getTopListAll(uint n) external view returns (bytes32[] memory){
        return _sys.getTopListAll(n);
    }

    //--------------------------------------------------
    function register(bytes32 refID) external{
        _sys.register(refID);
    }
    function regNewAcc(bytes32 spon) external{
        _sys.regNewAcc(spon);
    }

    function payByUSD(bytes32 id) external{
        return _sys.payByUSD(id);
    }
    function payAll(address addr) external{
        return _sys.payAll(addr);
    }
    function payStepAll(address addr, uint step) external {
        return _sys.payStepAll(addr, step);
    }
    function newAccAll(address addr) external{
        return _sys.newAccAll(addr);
    }

    function getPayUp(bytes32 fromID, uint fromS, uint fromR) external view returns(bytes32 payID){
        payID = _sys.getPayUp(fromID, fromS, fromR);
    }
    function checkPa(bytes32 paID, uint fromS, uint fromR) external view returns(bytes32 paOk){
        paOk = _sys.checkPa(paID, fromS, fromR);   
    }
    function iDOfAdd(address addr) external view returns (bytes32[] memory){
        return _sys.iDOfAdd(addr);
    }
    function iD2Addr(bytes32 id) external view returns (address){
        return _sys.iD2Addr(id);
    }
    function iD0(address addr) external view returns (bytes32){
        return _sys.iD0(addr);
    }

    function setChangeAddrFee(uint256 fee) external onlyAdmin {
        _changeAddrFee = fee;
    }
    function setChangeAddr(address addrNew) external {
        address addrOld = tx.origin;
        bytes32 _0ID = _sys.iD0(addrNew);
        require(!_sys.usedIds(_0ID), "ID already exist");
        require(_sys.getUser(_0ID).spon == bytes32(0), "Spon exist!");
        require(_sys.getUser(_0ID).parent == bytes32(0), "Parent exist!");

        if(needFee){
            require(address(_usd) != address(0), "USD contract not set!");
            require(_usd.balanceOf(addrOld) >= _changeAddrFee, "Balance not enough!");
            require(_usd.allowance(addrOld, address(this)) >= _changeAddrFee, "Allowance is not ready!");
            _usd.transferFrom(addrOld,(_company == address(0)? address(_sys): _company), _changeAddrFee);
        }

        // CHANGE ADDRESS NEW;
        bytes32[] memory _iDOfAdd = _sys.iDOfAdd(addrOld);
        bytes32[] memory _iDOfAddNew = new bytes32[](_iDOfAdd.length);
        uint256 count = 0;

        if(_iDOfAdd.length > 0 ){
            for (uint256 i = 0; i < _iDOfAdd.length; i++) {
                bytes32 _id = _iDOfAdd[i];
                require(_id != bytes32(0), "ID not ok!");
                if(_sys.usedIds(_id)){
                    ISYS.AccountInfo memory _iDInfoOld = _sys.accInfo(_id);
                    bytes32 _idNew = keccak256(abi.encodePacked(addrNew, _iDInfoOld.num));
                    require(_idNew != bytes32(0), "idNew not ok!");
                    
                    _iDOfAddNew[count] = _idNew;
                    count++;

                    _sys.setAccInfo(_idNew, _iDInfoOld.addr, uint(_iDInfoOld.num));
                    _sys.setUsedIds(_idNew, _sys.usedIds(_id));
                    _sys.setUser(_idNew, _sys.getUser(_id));
                    
                    _sys.setRefList(_idNew, _sys.getUserRefList(_id));
                    
                    bytes32 _pa = _sys.getUser(_id).parent;
                    if(_sys.getUser(_pa).side1 == _id){
                        _sys.setUside1(_pa, _idNew);
                    }else if(_sys.getUser(_pa).side2 == _id){
                        _sys.setUside2(_pa, _idNew);
                    }else {
                        _sys.setUside3(_pa, _idNew);
                    }

                    // //_refList of Spon need replate:
                    bytes32 _sponID = _sys.getUser(_id).spon;
                    require(_sponID != bytes32(0), "SponID not ok!");

                    bytes32[] memory _sponL = _sys.getUserRefList(_sponID);
                    _sponL[findIndexRef(_id, _sponID)] = _idNew;
                    _sys.setRefList(_sponID, _sponL);

                    //Clear User;
                    _sys.setUSpon(_id, bytes32(0));
                    _sys.setUPa(_id, bytes32(0));
                    _sys.setUside1(_id, bytes32(0));
                    _sys.setUside2(_id, bytes32(0));
                    _sys.setUside3(_id, bytes32(0));
                }
            }
            bytes32[] memory result = new bytes32[](count);
            for (uint256 i = 0; i < count; i++) {
                result[i] = _iDOfAddNew[i];
            }
            _sys.setAccOfAdd(addrNew, result);
        }
    }
    function setChangeAddrAdmin(address addrOld, address addrNew) external onlyAdmin{
        // bytes32 _0ID = _sys.iD0(addrNew);
        // require(!_sys.usedIds(_0ID), "ID already exist");
        // require(_sys.getUser(_0ID).spon == bytes32(0), "Spon exist!");
        // require(_sys.getUser(_0ID).parent == bytes32(0), "Parent exist!");

        if(needFee){
            require(address(_usd) != address(0), "USD contract not set!");
            require(_usd.balanceOf(addrOld) >= _changeAddrFee, "Balance not enough!");
            require(_usd.allowance(addrOld, address(this)) >= _changeAddrFee, "Allowance is not ready!");
            _usd.transferFrom(addrOld,(_company == address(0)? address(_sys): _company), _changeAddrFee);
        }

        // CHANGE ADDRESS NEW;
        bytes32[] memory _iDOfAdd = _sys.iDOfAdd(addrOld);
        bytes32[] memory _iDOfAddNew = new bytes32[](_iDOfAdd.length);
        uint256 count = 0;

        if(_iDOfAdd.length > 0 ){
            for (uint256 i = 0; i < _iDOfAdd.length; i++) {
                bytes32 _id = _iDOfAdd[i];
                require(_id != bytes32(0), "ID not ok!");
                if(_sys.usedIds(_id)){
                    ISYS.AccountInfo memory _iDInfoOld = _sys.accInfo(_id);
                    bytes32 _idNew = keccak256(abi.encodePacked(addrNew, _iDInfoOld.num));
                    require(_idNew != bytes32(0), "idNew not ok!");
                    
                    _iDOfAddNew[count] = _idNew;
                    count++;

                    _sys.setAccInfo(_idNew, _iDInfoOld.addr, uint(_iDInfoOld.num));
                    _sys.setUsedIds(_idNew, _sys.usedIds(_id));
                    
                    _sys.setUser(_idNew, _sys.getUser(_id));
                    
                    _sys.setRefList(_idNew, _sys.getUserRefList(_id));
                    
                    bytes32 _pa = _sys.getUser(_id).parent;
                    if(_sys.getUser(_pa).side1 == _id){
                        _sys.setUside1(_pa, _idNew);
                    }else if(_sys.getUser(_pa).side2 == _id){
                        _sys.setUside2(_pa, _idNew);
                    }else {
                        _sys.setUside3(_pa, _idNew);
                    }

                    // //_refList of Spon need replate:
                    bytes32 _sponID = _sys.getUser(_id).spon;
                    require(_sponID != bytes32(0), "SponID not ok!");

                    bytes32[] memory _sponL = _sys.getUserRefList(_sponID);
                    _sponL[findIndexRef(_id, _sponID)] = _idNew;
                    _sys.setRefList(_sponID, _sponL);

                    //Clear User;
                    _sys.setUSpon(_id, bytes32(0));
                    _sys.setUPa(_id, bytes32(0));
                    _sys.setUside1(_id, bytes32(0));
                    _sys.setUside2(_id, bytes32(0));
                    _sys.setUside3(_id, bytes32(0));
                }
            }
            bytes32[] memory result = new bytes32[](count);
            for (uint256 i = 0; i < count; i++) {
                result[i] = _iDOfAddNew[i];
            }
            _sys.setAccOfAdd(addrNew, result);
        }
    }
    
    function findIndexRef(bytes32 idOfSponList, bytes32 sponID) public view returns (uint) {
        for (uint i = 0; i < _sys.getUserRefList(sponID).length; i++) {
            if (_sys.getUserRefList(sponID)[i] == idOfSponList) {
                return i;
            }
        }
        revert("Not found");
    }
}