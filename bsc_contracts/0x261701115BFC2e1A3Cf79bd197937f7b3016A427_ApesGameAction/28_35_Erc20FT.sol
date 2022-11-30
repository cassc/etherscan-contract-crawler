// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./lib/Verify.sol";

contract Erc20FT is ERC20Upgradeable, OwnableUpgradeable, Verify {
    using SafeMathUpgradeable for uint256;
    address[] public users;
    uint256 public ratio;
    address public team;
    uint256 public burnRatio;

    mapping(address => bool) public admin;
    mapping(address => mapping(bytes32 => uint256)) public records;

    string private name_;
    string private symbol_;

    function initialize(string memory _name, string memory _symbol)
        public
        initializer
    {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        setNameSymbol(_name, _symbol);
    }

    function setNameSymbol(string memory _name, string memory _symbol)
        public
        onlyAdmin
    {
        name_ = _name;
        symbol_ = _symbol;
    }

    function name() public view virtual override returns (string memory) {
        return name_;
    }

    function symbol() public view virtual override returns (string memory) {
        return symbol_;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == recipient) {
                uint256 fee = amount.mul(ratio).div(10000);
                amount = amount.sub(fee);
                super._transfer(sender, team, fee);
            }
        }
        super._transfer(sender, recipient, amount);
    }

    // function mint(address account, uint256 amount) external onlyAdmin {
    //     return super._mint(account, amount);
    // }

    function adminMint(address account, uint256 amount) external onlyAdmin {
        return super._mint(account, amount);
    }

    function mintTo(address account, uint256 amount) external onlyOwner {
        require(
            super.balanceOf(msg.sender) >= amount,
            "ERC20: mintTo amount exceeds balance"
        );
        return super._mint(account, amount);
    }

    function burn(uint256 amount) external {
        require(
            super.balanceOf(msg.sender) >= amount,
            "ERC20: burn amount exceeds balance"
        );
        super._burn(_msgSender(), amount);
    }

    function insert(address _user) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == _user) {
                return;
            }
        }
        users.push(_user);
    }

    function setRatio(uint256 _ratio) external onlyOwner {
        ratio = _ratio;
    }

    function setBurnRatio(uint256 _burnratio) external onlyOwner {
        burnRatio = _burnratio;
    }

    function setTeam(address _user) external onlyOwner {
        team = _user;
    }
    /**
     * @notice withdraw tokens from the game to the chain (Please use the official channel to withdraw)
     * @param _amount withdraw amount(2000 => 20.00).
     * @param timestamp ns.
     * @param data Signature information.
     */
    function withdraw(
        uint256 _amount,
        uint256 timestamp,
        bytes memory data
    ) external {
        uint256 amount = _amount.mul(1e16);
        uint256 second = timestamp.div(1e9);
        uint256 date = second.div(86400); // 24 * 60 * 60
        bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _amount, timestamp));
        require(
            withdrewRecordStatus[_hash] == WithdrawStatus.NotFound,
            "Withdraw: signature has been used"
        );
        
        if(dateAmount[date].add(amount) > withdrawLimit) {
            withdrewRecordStatus[_hash] = WithdrawStatus.ExceedDailyLimit;
            emit Withdrew(msg.sender, amount, timestamp, WithdrawStatus.ExceedDailyLimit);
            return ;
        }

        if(userDailyAmount[msg.sender][date].add(amount) > userDailyWithdrawLimit) {
            withdrewRecordStatus[_hash] = WithdrawStatus.UserDailyLimit;
            emit Withdrew(msg.sender, amount, timestamp, WithdrawStatus.UserDailyLimit);
            return ;
        }
        
        if(second < block.timestamp && block.timestamp.sub(second) > 300) {
            withdrewRecordStatus[_hash] = WithdrawStatus.TimeOut;
            emit Withdrew(msg.sender, amount, timestamp, WithdrawStatus.TimeOut);
            return ;
        }

        if(!verify(_hash, data)) {
            withdrewRecordStatus[_hash] = WithdrawStatus.AuthFailed;
            emit Withdrew(msg.sender, amount, timestamp, WithdrawStatus.AuthFailed);
            return ;
        }

        super._mint(msg.sender, amount);
        dateAmount[date] = dateAmount[date].add(amount);
        userDailyAmount[msg.sender][date] = userDailyAmount[msg.sender][date].add(amount);
        withdrewRecordStatus[_hash] = WithdrawStatus.Successed;
        emit Withdrew(msg.sender, amount, timestamp, WithdrawStatus.Successed);
    }

    function setAdmin(address user, bool _auth) external onlyOwner {
        admin[user] = _auth;
    }

    modifier onlyAdmin() {
        require(
            admin[msg.sender] || owner() == msg.sender,
            "Admin: caller is not the admin"
        );
        _;
    }

    struct Supply {
        uint256 cap;
        uint256 total;
    }
    mapping(address => Supply) public bridges;
    event BridgeSupplyCapUpdated(address bridge, uint256 supplyCap);
    /**
     * @notice Updates the supply cap for a bridge.
     * @param _bridge The bridge address.
     * @param _cap The new supply cap.
     */
    function updateBridgeSupplyCap(address _bridge, uint256 _cap) external onlyOwner {
        // cap == 0 means revoking bridge role
        bridges[_bridge].cap = _cap;
        emit BridgeSupplyCapUpdated(_bridge, _cap);
    }

    function mint(address _to, uint256 _amount) external {
        Supply storage b = bridges[msg.sender];
        require(b.cap > 0, "invalid caller");
        require(b.total.add(_amount) <= b.cap, "exceeds bridge supply cap");
        b.total = b.total.add(_amount);
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external  {
        Supply storage b = bridges[msg.sender];
        require(b.cap > 0, "invalid caller");
        require(b.total >= _amount, "exceeds bridge minted amount");
        _spendAllowance(_from, _msgSender(), _amount);
        _burn(_from, _amount);
        b.total = b.total.sub(_amount);
    }

    mapping(uint256=>uint256) public dateAmount;
    uint256 public withdrawLimit;
    function setWithdrawLimit(uint256 amount_) public onlyAdmin {
        withdrawLimit = amount_;
    }

    /**
     * @notice withdraw status
     * NotFound:          0, transaction not found
     * Successed:         1, withdraw successed
     * ExceedDailyLimit:  2, withdraw money exccesd daily limit
     * TimeOut:           3, withdraw timeout
     * AuthFailed:        4, withdrawal signature authentication failed
     * UserDailyLimit:    5, Exceeding the daily withdrawal amount of the user
     */
    enum WithdrawStatus{ NotFound, Successed, ExceedDailyLimit, TimeOut, AuthFailed, UserDailyLimit}
    mapping (bytes32 => WithdrawStatus) withdrewRecordStatus;
   
    event Withdrew(address indexed sender,uint256 indexed amount, uint256 indexed timestamp, WithdrawStatus status);
    event Deposited(address indexed sender, uint256 indexed amount);
    function deposit(uint256 _amount) external{
        super._burn(msg.sender, _amount);
        emit Deposited(msg.sender, _amount);
    }

    function withdrewRecord(address _sender, uint256 _amount,uint256 _timestamp)  external view returns (WithdrawStatus) {
        return withdrewRecordStatus[keccak256(abi.encodePacked(_sender, _amount, _timestamp))];
    }

    mapping(address=>mapping(uint256 => uint256)) public userDailyAmount;
    uint256 public userDailyWithdrawLimit;
    function setUserDailyWithdrawLimit(uint256 _amount) public onlyAdmin {
        userDailyWithdrawLimit = _amount;
    }
}