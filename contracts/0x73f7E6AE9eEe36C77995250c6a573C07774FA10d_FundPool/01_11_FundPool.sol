// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IBallToken.sol";
import "./Authorizer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FundPool is Ownable, ReentrancyGuard, Authorizer {
    //using Math for mymath;
    using SafeMath for uint256;
    // using IBallToken for IERC20;

    mapping(address => uint) public claimedRewardMapping;

    mapping(address => uint) public claimedBallRewardMapping;

    // mapping(address => mapping(uint256 => bool)) public usedNonces;

    // Ball Token
    address public ballToken;

    bool public claimBallOpen;
    
    event Claim(address indexed user, uint amount, uint nonce);

    event ClaimBall(address indexed user, uint amount, uint nonce);

    event Withdraw(address indexed recipient, uint256 amount);

    constructor(address _authorizer, address _ballToken) {
        authorizer = _authorizer;
        ballToken = _ballToken;
    }

    function claimReward(address receiver, uint256 amount, uint256 nonce, 
        uint256 underBlock, uint256 _type, bytes memory signature) public payable nonReentrant {

        require(block.number <= underBlock, "The signature has expired");
        require(!usedNonces[receiver][nonce], "You cannot claim it twice.");
        require(msg.sender == receiver, "You can not claim for others.");
        require(_type == 0, "Claim type is not correct.");

        require(getEthBalance() >= amount, "The balance in the contract is insufficient");

        usedNonces[receiver][nonce] = true;

        // uint needed = amount >= 0.01 ether;
        // require(needed <= msg.value, "Less than minimum amount");
     
        address recoveredAddr = recoverAuthorizer(receiver, amount, nonce, underBlock, _type, signature);
        require(recoveredAddr == authorizer, "Invalid signature");
        
        payable(receiver).transfer(amount);

        claimedRewardMapping[receiver] = claimedRewardMapping[receiver].add(amount);

        emit Claim(receiver, amount, nonce);
    }

    function claimBallReward(address receiver, uint256 amount, uint256 nonce, 
        uint256 underBlock, uint _type, bytes memory signature) public payable {

        require(claimBallOpen, "Not open");
        require(block.number <= underBlock, "The signature has expired");
        require(!usedNonces[receiver][nonce], "You cannot claim it twice.");
        require(msg.sender == receiver, "You can not claim for others.");
        require(_type == 1, "Claim type is not correct.");

        // require(getTokenBalance() >= amount, "The token balance in the contract is insufficient");
        usedNonces[receiver][nonce] = true;

        // uint needed = amount >= 0.01 ether;
        // require(needed <= msg.value, "Less than minimum amount");
     
        address recoveredAddr = recoverAuthorizer(receiver, amount, nonce, underBlock, _type, signature);
        require(recoveredAddr == authorizer, "Invalid signature");
        
        IBallToken(ballToken).mint(msg.sender, amount);
         
        claimedBallRewardMapping[receiver] = claimedBallRewardMapping[receiver].add(amount);

        emit ClaimBall(receiver, amount, nonce);
    }

    /// @notice Transfer the ownership of BALL token
    /// @param _to Transfer to this address
    function transferBallOwnership(address _to) external onlyOwner {
        Ownable(ballToken).transferOwnership(_to);
    }

    function getEthBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function setClaimBallOpen(bool value) external onlyOwner {
        claimBallOpen = value;
    }

    receive() external payable { }
}