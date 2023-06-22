// SPDX-License-Identifier: MIT
pragma solidity = 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RewardStake is AccessControl, ReentrancyGuard, Pausable {

    bytes32 public constant OWNER_ADMIN = keccak256("OWNER_ADMIN");

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    uint256 constant public unlockTime = 1687348800; // 21/06/2023 12:00 GMT
    
    //User => Balance in SHI
    mapping (address => uint256) public userBalance;    
                     
    //ERC20 Token
    address public token;

    constructor (address _token) {
        require(_token != address(0x0), 'Shirtum Reward Stake: Address must be different to zero address');
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ADMIN, msg.sender);

        token = _token;
    }

    /**
     * @dev Returns the total balance of the user.
     */
    function balanceOf(address user) public view returns (uint256 balance) {
        return userBalance[user];
    }

    function setToken(address _token) public onlyRole(OWNER_ADMIN) {        
        token = _token;        
    }

    /**
     * @dev Generates the deposit
     * Requirements: contract must not be paused
     *   
     */
    function stake(address[] memory users, uint256[] memory amounts) public nonReentrant whenNotPaused{
        require(hasRole(OWNER_ADMIN, msg.sender), "Shirtum Reward Stake: Restricted to OWNER_ADMIN role");
        require(users.length <= 100,"Shirtum Reward Stake: users length must be less or equal than 100");
        require(amounts.length <= 100,"Shirtum Reward Stake: amounts length must be less or equal than 100");
        require(users.length == amounts.length,"Shirtum Reward Stake: users and amounts length must be equal");

        for(uint256 i; i < users.length; i++){
            userBalance[users[i]] += amounts[i];

            emit Deposit(users[i], amounts[i]);
        }
    }

    /**
     * @dev Withdraw user deposit
     * Requirements: contract must not be paused. Unlock time has to be reached.
     *   
     */
    function withdraw() public nonReentrant whenNotPaused{
        require(block.timestamp >= unlockTime, "Shirtum Reward Stake: Unlock time has not arrived");
        require(userBalance[msg.sender] > 0, "Shirtum Rewards Stake: user has nothing to withdraw");
                        
        //Transfer tokens to user
        require(
            IERC20(token).transfer(msg.sender, userBalance[msg.sender]),
            "Shirtun Reward Stake: Unable to transfer the tokens"
        );
        
        emit Withdraw(msg.sender, userBalance[msg.sender]);

        userBalance[msg.sender] = 0;
    }

    /**
     * @dev Withdraw user deposit
     * Requirements: contract must not be paused. Unlock time has to be reached.
     *   
     */
    function adminWithdraw(address user) public nonReentrant whenNotPaused{
        require(hasRole(OWNER_ADMIN, msg.sender), "Shirtum Reward Stake: Restricted to OWNER_ADMIN role");
        require(block.timestamp >= unlockTime, "Shirtum Reward Stake: Unlock time has not arrived");
        require(userBalance[user] > 0, "Shirtum Rewards Stake: user has nothing to withdraw");
                        
        //Transfer tokens to user
        require(
            IERC20(token).transfer(user, userBalance[user]),
            "Shirtun Reward Stake: Unable to transfer the tokens"
        );
        
        emit Withdraw(user, userBalance[user]);

        userBalance[user] = 0;
    }

    function pause() public onlyRole(OWNER_ADMIN){
        _pause();
    }

    function unpause() public onlyRole(OWNER_ADMIN){
        _unpause();
    }
    
}