/**
 *Submitted for verification at Etherscan.io on 2020-02-28
*/

/**
 *Submitted for verification at Etherscan.io on 2020-02-11
*/

pragma solidity ^0.4.25;



contract IStdToken {
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
}



contract SwapCommon {

    mapping(address => bool) private _admins;
    mapping(address => bool) private _services;

    modifier onlyAdmin() {
        require(_admins[msg.sender], "not admin");
        _;
    }

    modifier onlyAdminOrService() {
        require(_admins[msg.sender] || _services[msg.sender], "not admin/service");
        _;
    }

    constructor() public {
        _admins[msg.sender] = true;
    }

    function addAdmin(address addr) public onlyAdmin {
        _admins[addr] = true;
    }

    function removeAdmin(address addr) public onlyAdmin {
        _admins[addr] = false;
    }

    function isAdmin(address addr) public view returns (bool) {
        return _admins[addr];
    }

    function addService(address addr) public onlyAdmin {
        _services[addr] = true;
    }

    function removeService(address addr) public onlyAdmin {
        _services[addr] = false;
    }

    function isService(address addr) public view returns (bool) {
        return _services[addr];
    }
}



contract SwapCore is SwapCommon {

    address public controllerAddress = address(0x0);

    IStdToken public mntpToken;

    modifier onlyController() {
        require(controllerAddress == msg.sender, "not controller");
        _;
    }

    constructor(address mntpTokenAddr) SwapCommon() public {
        controllerAddress = msg.sender;
        mntpToken = IStdToken(mntpTokenAddr);
    }

    function setNewControllerAddress(address newAddress) public onlyController {
        controllerAddress = newAddress;
    }
}



contract Swap {

    SwapCore public core;

    IStdToken public mntpToken;

    bool public isActual = true;
    bool public isActive = true;

    event onSwapMntp(address indexed from, uint256 amount, bytes32 to);
    event onSentMntp(address indexed to, uint256 amount, bytes32 from);

    modifier onlyAdmin() {
        require(core.isAdmin(msg.sender), "not admin");
        _;
    }

    modifier onlyAdminOrService() {
        require(core.isAdmin(msg.sender) || core.isService(msg.sender), "not admin/service");
        _;
    }

    modifier onlyValidAddress(address addr) {
        require(addr != address(0x0), "nil address");
        _;
    }

    modifier onlyActiveContract() {
        require(isActive, "inactive contract");
        _;
    }

    modifier onlyInactiveContract() {
        require(!isActive, "active contract");
        _;
    }

    modifier onlyActualContract() {
        require(isActual, "outdated contract");
        _;
    }

    constructor(address coreAddr) public onlyValidAddress(coreAddr) {
        core = SwapCore(coreAddr);
        mntpToken = core.mntpToken();
    }

    function toggleActivity() public onlyActualContract onlyAdmin {
        isActive = !isActive;
    }

    function migrateContract(address newControllerAddr) public onlyValidAddress(newControllerAddr) onlyActualContract onlyAdmin {
        core.setNewControllerAddress(newControllerAddr);
        uint256 mntpTokenAmount = getMntpBalance();
        if (mntpTokenAmount > 0) mntpToken.transfer(newControllerAddr, mntpTokenAmount);
        isActive = false;
        isActual = false;
    }

    function getMntpBalance() public view returns(uint256) {
        return mntpToken.balanceOf(address(this));
    }

    function drainMntp(address addr) public onlyValidAddress(addr) onlyAdmin onlyInactiveContract {
        uint256 amount = getMntpBalance();
        if (amount > 0) mntpToken.transfer(addr, amount);
    }

    // ---

    function swapMntp(uint256 amount, bytes32 mintAddress) public onlyActualContract onlyActiveContract {
        require(amount > 0, "zero amount");
        require(mntpToken.balanceOf(msg.sender) >= amount, "not enough mntp");
        require(mntpToken.allowance(msg.sender, address(this)) >= amount, "invalid allowance");

        require(mntpToken.transferFrom(msg.sender, address(this), amount), "transfer failure");
        emit onSwapMntp(msg.sender, amount, mintAddress);
    }

    function sendMntp(uint256 amount, address addr, bytes32 sourceMintAddress) public onlyActualContract onlyActiveContract onlyAdminOrService {
        require(amount > 0, "zero amount");
        require(mntpToken.balanceOf(address(this)) >= amount, "not enough mntp");

        require(mntpToken.transfer(addr, amount), "transfer failure");
        emit onSentMntp(msg.sender, amount, sourceMintAddress);
    }
}


library SafeMath {

    // Multiplies two numbers, throws on overflow.
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    // Integer division of two numbers, truncating the quotient.
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    // Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    // Adds two numbers, throws on overflow.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    // Min from a/b
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // Max from a/b
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? b : a;
    }
}