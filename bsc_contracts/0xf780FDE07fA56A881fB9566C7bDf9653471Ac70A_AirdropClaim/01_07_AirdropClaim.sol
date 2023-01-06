// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IVotingEscrow.sol";

contract AirdropClaim is ReentrancyGuard {

    using SafeERC20 for IERC20;

    struct UserInfo{
        uint256 totalAmount;
        uint256 initAmount;
        uint256 vestedAmount;
        uint256 lockedAmount;
        uint256 tokenPerSec;
        uint256 lastTimestamp;
        uint256 claimed;
        address to;
    }

    bool public init;

    uint256 public INIT_SHARE;
    // 50% vethe, 25% instant claim the, 25% 3 weeks linear $the
    uint256 constant public PRECISION = 1000;
    uint256 constant public VESTED_SHARE = 500;
    uint256 constant public LINEAR_DISTRO = 250;

    uint256 public startTimestamp;

    uint256 public tokenPerSec; 
    uint256 public constant DISTRIBUTION_PERIOD = 3 * 7 * 86400;
    uint256 public totalAirdrop;

    
    address public owner;
    address public ve;
    address public merkle;
    IERC20 public token;
    

    mapping(address => UserInfo) public users;
    mapping(address => bool) public usersFlag;
    mapping(address => bool) public depositors;

    modifier onlyOwner {
        require(msg.sender == owner, 'not owner');
        _;
    }

    modifier onlyMerkle {
        require(msg.sender == merkle, 'not owner');
        _;
    }

    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);

    constructor(address _token, address _ve) {
        owner = msg.sender;
        token = IERC20(_token);
        ve = _ve;
    }


    function deposit(uint256 amount) external {
        require(depositors[msg.sender] == true || msg.sender == owner);
        require(init == false);
        token.safeTransferFrom(msg.sender, address(this), amount);
        totalAirdrop += amount;
        emit Deposit(amount);
    }

    function withdraw(uint256 amount, address _token, address _to) external {
        require(depositors[msg.sender] == true || msg.sender == owner);
        IERC20(_token).safeTransfer(_to, amount);
        totalAirdrop -= amount;

        emit Withdraw(amount);
    }
    

    /// @notice set user infromation for the claim
    /// @param _who is claiming
    /// @param _to who's getting the token
    /// @param _amount total amount to claim
    function setUserInfo(address _who, address _to, uint256 _amount) external onlyMerkle nonReentrant returns(bool status) {

        require(_who != address(0), 'addr 0');
        require(_to != address(0), 'addr 0');
        require(_amount > 0, 'amnt 0');
        require(usersFlag[_who] == false, '!flag');
        require(init, 'not init');


        uint256 _vestedAmount = _amount * VESTED_SHARE / PRECISION;
        uint256 _theInstantAmount = _amount * LINEAR_DISTRO / PRECISION;
        uint256 _theLockedLinearAmount = _theInstantAmount; 
        uint256 _tokenPerSec = _theLockedLinearAmount * PRECISION / DISTRIBUTION_PERIOD;

        UserInfo memory _user = UserInfo({
            totalAmount: _amount,
            initAmount: _theInstantAmount,
            vestedAmount: _vestedAmount,
            lockedAmount: _theLockedLinearAmount,
            tokenPerSec: _tokenPerSec,
            lastTimestamp: startTimestamp,
            claimed: _theInstantAmount + _vestedAmount,
            to: _to
        });

        users[_who] = _user;
        usersFlag[_who] = true;

        // send out init amount
        token.safeTransfer(_to, _theInstantAmount);
        token.approve(ve, 0);
        token.approve(ve, _vestedAmount);
        IVotingEscrow(ve).create_lock_for(_vestedAmount, 2 * 364 * 86400 , _who);

        status = true;
    }



    function claim() external nonReentrant {

        // check user exists
        require(usersFlag[msg.sender]);

        // load info
        UserInfo memory _user = users[msg.sender];

        // check lastTimestamp
        require(_user.lastTimestamp <= startTimestamp + DISTRIBUTION_PERIOD, 'time: claimed all');
        require(_user.claimed <= _user.totalAmount, 'amnt: claimed all');
        
        // save _to
        address _to = _user.to;

        // check if timestamp is > than the vesting period timestamp
        // if true then save timestamp as last possible timestamp
        uint256 _timestamp = block.timestamp; 
        if(_timestamp > startTimestamp + DISTRIBUTION_PERIOD){
            _timestamp = startTimestamp + DISTRIBUTION_PERIOD;
        }

        // find how many token 
        uint256 _dT = _timestamp - _user.lastTimestamp;  
        require(_dT > 0);   
        uint256 __claimable = _dT * _user.tokenPerSec / PRECISION;

        // update and check math
        _user.lastTimestamp = _timestamp;
        _user.claimed += __claimable;
        require(_user.claimed <= _user.totalAmount, 'claimed > totAmnt');
        users[msg.sender] = _user;

        // transfer
        token.safeTransfer(_to, __claimable);
    }


    function claimable(address user) public view returns(uint _claimable){
        // check user exists
        require(usersFlag[user]);
        // load info
        UserInfo memory _user = users[user];

        // check lastTimestamp
        require(_user.lastTimestamp <= startTimestamp + DISTRIBUTION_PERIOD, 'time: claimed all');
        require(_user.claimed <= _user.totalAmount, 'amnt: claimed all');
        
        // check if timestamp is > than the vesting period timestamp
        // if true then save timestamp as last possible timestamp
        uint256 _timestamp = block.timestamp; 
        if(_timestamp > startTimestamp + DISTRIBUTION_PERIOD){
            _timestamp = startTimestamp + DISTRIBUTION_PERIOD;
        }

        // find how many token 
        uint256 _dT = _timestamp - _user.lastTimestamp;  
        require(_dT > 0);   
        _claimable = _dT * _user.tokenPerSec / PRECISION;
    }


    /* 
        OWNER FUNCTIONS
    */

    function setDepositor(address depositor) external onlyOwner {
        require(depositors[depositor] == false);
        depositors[depositor] = true;
    }

    function setMerkleTreeContract(address _merkle) external onlyOwner {
        require(_merkle != address(0));
        merkle = _merkle;
    }

    function setOwner(address _owner) external onlyOwner{
        require(_owner != address(0));
        owner = _owner;
    }

    
    function _init() external onlyOwner {
        require(init == false);
        init = true;
        startTimestamp = 1672927200;//block.timestamp;
    }

}