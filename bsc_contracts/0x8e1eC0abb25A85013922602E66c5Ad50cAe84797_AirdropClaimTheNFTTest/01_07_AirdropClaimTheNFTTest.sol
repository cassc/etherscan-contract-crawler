// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IVotingEscrow.sol";

contract AirdropClaimTheNFTTest is ReentrancyGuard {

    using SafeERC20 for IERC20;

    bool public init;

    uint256 public VE_SHARE;
    uint256 constant public PRECISION = 1000;

    uint256 public tokenPerSec; 
    uint256 public LOCK_PERIOD;
    uint256 public totalAirdrop;

    
    address public owner;
    address public ve;
    address public merkle;
    IERC20 public token;

    string public info = "this is a test unit";
    
    mapping(address => bool) public depositors;

    modifier onlyOwner {
        require(msg.sender == owner, 'not owner');
        _;
    }

    modifier onlyMerkle {
        require(msg.sender == merkle, 'not merkle');
        _;
    }

    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
    event Claim(address indexed _who, address indexed _to, uint256 _totalAmount, uint256 veAmount, uint256 _tokenId, uint256 _when);

    constructor(address _token, address _ve) {
        owner = msg.sender;
        token = IERC20(_token);
        ve = _ve;
        LOCK_PERIOD = 2 * 364 * 86400;
        VE_SHARE = 400;

    }


    function deposit(uint256 amount) external {
        require(depositors[msg.sender] == true || msg.sender == owner);
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
    

    /// @notice claim the given amount and send to _to. Checks are done by merkle tree contract. (eg.: 40% veTHE 60% $THE)
    function claim(address _who, uint _amount, address _to) external nonReentrant onlyMerkle returns(bool){
        require(token.balanceOf(address(this)) >= _amount, 'not enough token');

        uint256 _veShare = (VE_SHARE * _amount) / PRECISION;
        token.approve(ve, 0);
        token.approve(ve, _amount);
        uint256 _tokenId = IVotingEscrow(ve).create_lock_for(_veShare, LOCK_PERIOD, _to);
        require(_tokenId != 0);
        require(IVotingEscrow(ve).ownerOf(_tokenId) == _to, 'wrong ve mint'); 


        uint256 _theShare = _amount - _veShare;
        token.safeTransfer(_to, _theShare);
        emit Claim(_who, _to, _amount, _veShare, _tokenId, block.timestamp);
        return true;
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

    /// @notice set the % amount claimable early. The remaining is vested linearly
    function setVeShare(uint _share) external onlyOwner{
        require(_share <= PRECISION);
        VE_SHARE = _share;
    }

    
}