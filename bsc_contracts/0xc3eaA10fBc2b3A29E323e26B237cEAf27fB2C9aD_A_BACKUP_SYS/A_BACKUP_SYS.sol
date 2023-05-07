/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.19;

/**----------------------------------------*
    ███████ ██    ██    ███████ ██ ███████
    ██░░░██ ██   ███    ██░░░██ ██     ██
    ██░░░██ ██ ██ ██    █████   ██   ███  
    ██░░░██ ███   ██    ██░░░██ ██  ██     
    ███████ ██    ██    ███████ ██ ███████                                      
-------------------------------------------*/


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
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

interface IOLD {
    struct AccountInfo {
        uint256 num;
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

    function usedIds(bytes32 id) external view returns (bool);
    function accInfo(bytes32 id) external view returns (AccountInfo memory);
    function iD2Addr(bytes32 id) external view returns (address);
    function users(bytes32 id) external view returns (User memory);
    function getUser(bytes32 _id) external view returns (User memory);
    function getUserRefList(bytes32 id) external view returns (bytes32[] memory);
    function iDOfAdd(address addr) external view returns (bytes32[] memory);
    function getTopListAll(uint n) external view returns (bytes32[] memory);
    function getSiteInfo()external view returns (uint256 u, uint256 acc, uint256 tPay, uint256 bnb,uint256 usd);
}
interface INEW {
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

    function backUpTotal() external;

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
    
    function setAccOfAddPush(address addr, bytes32 id) external;
    function setAccOfAdd(address addr, bytes32[] memory list) external;

    function setTopsPush(uint lv, bytes32 id) external;
    function setTops(uint lv, bytes32[] memory list) external;
    
    function setUser(bytes32 id, IOLD.User memory u) external;
    

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
    function getUser(bytes32 _id) external view returns (User memory);
    function getSpon(bytes32 id) external view returns (bytes32);
    function getPa(bytes32 id) external view returns (bytes32);
    function getIncome(bytes32 id) external view returns (uint256);
    function getStep(bytes32 id) external view returns(uint r, uint s);

    function getUserSideList(bytes32 id) external view returns (bytes32[] memory);
    function getUserLevel(bytes32 id, uint idx) external view returns (uint);
    function getUserRefList(bytes32 id) external view returns (bytes32[] memory);
    function getTopListAll(uint n) external view returns (bytes32[] memory);
    function getNumAcc(bytes32 id) external view returns(uint acc, uint max);

    function getPayUp(bytes32 fromID, uint fromS, uint fromR) external view returns(bytes32 payID);
    function checkPa(bytes32 paID, uint fromS, uint fromR) external view returns(bytes32 paOk);
    
    function iDOfAdd(address addr) external view returns (bytes32[] memory);
    function iD2Addr(bytes32 id) external view returns (address);
    function iD0(address addr) external view returns (bytes32);
}
contract A_BACKUP_SYS is Ownable {
    using SafeMath for uint256;
    IOLD private _sysOld;
    INEW private _sysNew;
    address private _admin;
    address private _special;
    address private _origin;

    uint public accTotal;
    bytes32[] public allAccList;
    mapping(uint => bytes32) public allacc;

    constructor() {
        _sysOld = IOLD(0x43B5F546f388680cf56B6C5a820da023d25c966f);
        _sysNew = INEW(0x7e766CE042B39Da1ED95A51963Bd6352cE92c83F);
        _admin = owner();
        _special = owner();
        _origin = owner();
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
        require(_admin == _msgSender(), "Only Admin");
        _;
    }
    modifier onlyOrigin() {
        require(_origin == tx.origin, "Only Special origin");
        _;
    }
    modifier onlySpecial() {
        require(_special == _msgSender() || tx.origin == _msgSender(), "Only Special || origin");
        _;
    }

    //----------------------------------------
    function setAdmin(address addr) external onlyAdmin {
        _admin = address(addr);
    }
    function setSpecial(address addr) external onlyAdmin {
        _special = address(addr);
    }
    function setConSysOld(address _contract) external onlyAdmin {
        _sysOld = IOLD(_contract);
    }
    function setConSysNew(address _contract) external onlyAdmin {
        _sysNew = INEW(_contract);
    }
    
    //----------------------------------------
    function setTops(uint lv, bytes32[] memory list) public onlyOrigin{
        _sysNew.setTops(lv, list);
    }
    function setAccInfo(bytes32 id, address addr, uint num) public onlyOrigin{
        _sysNew.setAccInfo(id, addr, num);
    }
    function setUsedIds(bytes32 id, bool b) public onlyOrigin{
        _sysNew.setUsedIds(id, b);
    }
    function setUser(bytes32 id, IOLD.User memory u) public onlyOrigin{
        _sysNew.setUser(id, u);
    }
    function setRefList(bytes32 refID, bytes32[] memory list) public onlyOrigin{
        _sysNew.setRefList(refID, list);
    }
    function setAccOfAdd(address addr, bytes32[] memory list) public onlyOrigin{
        _sysNew.setAccOfAdd(addr, list);
    }

    // Update old data----------------------------------------
    function backUpTotal() public onlyOrigin {
        require(msg.sender.balance > 0, "BNB need > 0!");
        (uint256 u, uint256 acc, uint256 tPay,,) = _sysOld.getSiteInfo();
        _sysNew.setNumIdsNew(acc);
        _sysNew.setTotalUsersNew(u);
        _sysNew.setTotalPayAmountsNew(tPay);
        // _sysNew.setBonusCount(tBcount);
        
        for(uint i = 2; i <= 12; i += 2) {
            setTops(i, _sysOld.getTopListAll(i));
        }
    }    
    function backUpUser(bytes32 _id) public onlyOrigin{
        IOLD.AccountInfo memory _accIOld = _sysOld.accInfo(_id);
        _sysNew.setAccInfo(_id, _accIOld.addr, uint(_accIOld.num));

        setUsedIds(_id, _sysOld.usedIds(_id));
        setUser(_id, _sysOld.getUser(_id));
        setRefList(_id, _sysOld.getUserRefList(_id));

        address _addr = _sysOld.iD2Addr(_id);
        require(_addr != address(0), "Addr not ok!");
        setAccOfAdd(_addr, _sysOld.iDOfAdd(_addr));
    }
    function backUpUser1(bytes32 _id) public onlyOrigin{
        if(!_sysNew.usedIds(_id)){
            backUpUser(_id);
        }else {
            bytes32 _pa = _sysNew.getUser(_id).parent;
            if(_pa == bytes32(0)) backUpUser(_id);
        }
    }
    function backUpUserUP(bytes32 _id) public onlyOrigin{
        if(!_sysNew.usedIds(_id)){
            backUpUser1(_id);
            bytes32 _pa = _sysOld.getUser(_id).parent;
            if(_pa != bytes32(0)) backUpUserUP(_pa);
        }
    }
    function backUpUserGen(bytes32 idTop, uint genOld, uint maxGen) public onlyOrigin{
        backUpUser1(idTop);
        bytes32[] memory _refListOfTop = _sysOld.getUserRefList(idTop);
        uint256 _numF1 = _refListOfTop.length;
        uint _gen = genOld;
        if(_numF1 > 0 ){
            for (uint256 i = 0; i < _numF1; i++) {
                bytes32 _id = _refListOfTop[i];
                require(_id != bytes32(0), "ID not ok!");
                IOLD.AccountInfo memory _accIOld = _sysOld.accInfo(_id);

                if(_sysNew.usedIds(_id)){
                    _gen++;
                    if(_gen < maxGen) backUpUserGen(_id, _gen, maxGen);
                }else {
                    setAccInfo(_id, _accIOld.addr, uint(_accIOld.num));
                    setUsedIds(_id, _sysOld.usedIds(_id));
                    setUser(_id, _sysOld.getUser(_id));
                    setRefList(_id, _sysOld.getUserRefList(_id));

                    address _addr = _sysOld.iD2Addr(_id);
                    require(_addr != address(0), "Addr not ok!");
                    setAccOfAdd(_addr, _sysOld.iDOfAdd(_addr));

                    _gen++;
                    if(_gen < maxGen) backUpUserGen(_id, _gen, maxGen);
                }
            }
        }
    }
    function backUpUserAllTree(bytes32 idTop) public onlyOrigin{
        backUpUser1(idTop);
        bytes32[] memory _refListOfTop = _sysOld.getUserRefList(idTop);
        uint256 _numF1 = _refListOfTop.length;
        if(_numF1 > 0 ){
            for (uint256 i = 0; i < _numF1; i++) {
                bytes32 _id = _refListOfTop[i];
                require(_id != bytes32(0), "ID not ok!");
                if(_sysNew.usedIds(_id)){
                    backUpUserAllTree(_id);
                }else {
                    IOLD.AccountInfo memory _accIOld = _sysOld.accInfo(_id);

                    setAccInfo(_id, _accIOld.addr, uint(_accIOld.num));
                    setUsedIds(_id, _sysOld.usedIds(_id));
                    setUser(_id, _sysOld.getUser(_id));
                    setRefList(_id, _sysOld.getUserRefList(_id));

                    address _addr = _sysOld.iD2Addr(_id);
                    require(_addr != address(0), "Addr not ok!");
                    setAccOfAdd(_addr, _sysOld.iDOfAdd(_addr));

                    backUpUserAllTree(_id);
                }
            }
        }
    }
    function backUpGetAllTree(bytes32 idTop) public view  returns (bytes32[] memory) {
        (, uint256 acc,,,) = _sysOld.getSiteInfo();
        bytes32[] memory _allAcc = new bytes32[](uint(acc));
        bytes32[] memory _refListOfTop = _sysOld.getUserRefList(idTop);
        uint256 _numF1 = _refListOfTop.length;
        uint256 idx = 0; // Số lượng phần tử đã thêm vào mảng ll
        if(_numF1 > 0 ){
            for (uint256 i = 0; i < _numF1; i++) {
                bytes32 _id = _refListOfTop[i];
                if(!_sysNew.usedIds(_id)){
                    _allAcc[idx] = _id; // Thêm phần tử vào mảng
                    idx++;
                    backUpGetAllTree(_id);
                }
            }
        }
        bytes32[] memory result = new bytes32[](idx); // Tạo một mảng mới với độ dài bằng số lượng phần tử đã thêm vào mảng ll
        for(uint256 i = 0; i < idx; i++) {
            result[i] = _allAcc[i];
        }
        return result;
    }
    function backUpAddAllTree(bytes32 idTop, uint idx) public {
        bytes32[] memory _refListOfTop = _sysOld.getUserRefList(idTop);
        uint256 _numF1 = _refListOfTop.length;
        uint _idx = idx;
        if(_numF1 > 0 ){
            for (uint i = 0; i < _numF1; i++) {
                bytes32 _id = _refListOfTop[i];
                if(!_sysNew.usedIds(_id)){
                    allacc[_idx] = _id;
                    allAccList.push(_id);
                    accTotal++;

                    _idx++;
                    backUpAddAllTree(_id, _idx);
                }
            }
        }
    }
    //----------------------------------------
}