// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./types/AccessControlled.sol";

import "hardhat/console.sol";

contract Treasury is AccessControlled {

    /* ========== EVENTS ========== */

    event Deposit(address indexed token, uint256 amount);
    event DepositEther(uint256 amount);
    event EtherDeposit(uint256 amount);
    event Withdrawal(address indexed token, uint256 amount);
    event EtherWithdrawal(address to, uint256 amount);

    /* ========== DATA STRUCTURES ========== */

    enum STATUS {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 public Kondux;


    string internal notAccepted = "Treasury: not accepted";
    string internal notApproved = "Treasury: not approved";
    string internal invalidToken = "Treasury: invalid token";

    mapping(STATUS => mapping(address => bool)) public permissions;
    mapping(address => bool) public isTokenApprooved;
    mapping(address => IERC20) public approvedTokens;

    address[] public approvedTokensList;
    uint256 public approvedTokensCount;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _authority) AccessControlled(IAuthority(_authority)) {
        approvedTokensCount = 0;
    }


    /**
     * @notice allow approved address to deposit an asset for Kondux
     * @param _amount uint256
     * @param _token address
     */
    function deposit(
        uint256 _amount,
        address _token
    ) external {
        if (permissions[STATUS.RESERVETOKEN][_token]) {
            require(permissions[STATUS.RESERVEDEPOSITOR][msg.sender], notApproved);
        } else {
            revert(invalidToken);
        }

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);      

        emit Deposit(_token, _amount);
    }

    function depositEther () external payable {
        require(permissions[STATUS.RESERVEDEPOSITOR][msg.sender], notApproved);  
        console.log("Deposit Ether: %s", msg.value);              
                
        emit DepositEther(msg.value);
    }

    /**
     * @notice allow approved address to withdraw Kondux from reserves
     * @param _amount uint256
     * @param _token address
     */
    function withdraw(uint256 _amount, address _token) external {
        require(permissions[STATUS.RESERVETOKEN][_token], notAccepted); // Only reserves can be used for redemptions
        require(permissions[STATUS.RESERVESPENDER][msg.sender], notApproved);

        IERC20(_token).transferFrom(address(this), msg.sender, _amount);

        emit Withdrawal(_token, _amount);
    }

    receive() external payable {
        console.log("Received Ether: %s", msg.value);
        emit EtherDeposit(msg.value);
    }

    fallback() external payable { 
        console.log("Fallback Ether: %s", msg.value);
        emit EtherDeposit(msg.value); 
    }
    
    function withdrawEther(uint _amount) external {
        require(permissions[STATUS.RESERVESPENDER][msg.sender], notApproved);
        require(payable(msg.sender).send(_amount));

        emit EtherWithdrawal(msg.sender, _amount);
    }

    function setPermission(
        STATUS _status,
        address _address,
        bool _permission
    ) public onlyGovernor {
        permissions[_status][_address] = _permission;
        if (_status == STATUS.RESERVETOKEN) {
            isTokenApprooved[_address] = _permission;
            if (_permission) {
                approvedTokens[_address] = IERC20(_address);
                approvedTokensList.push(_address);
                approvedTokensCount++;
            }
        }
    }
}