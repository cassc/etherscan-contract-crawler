pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract IPADVesting is Ownable {
    using SafeERC20 for IERC20;

    uint constant HUNDRED_PERCENT = 1e3;

    IERC20 public immutable token;
    uint public immutable feePercentage;
    uint public immutable claimWaitPeriod;

    uint public totalTokens;

    struct User {
        uint tokens;
        uint requestedClaimAt;
    }
    mapping(address => User) public users;

    event Deposit(address indexed userAddress, uint amount);
    event Claim(address indexed userAddress, uint claimAmount, uint feeAmount);
    event ClaimRequest(address indexed userAddress, uint timestampAt);

    constructor(
        IERC20 _token,
        uint _feePercentage, 
        uint _claimWaitPeriod
    ) {
        require(_feePercentage <= HUNDRED_PERCENT);

        token = _token;
        feePercentage = _feePercentage;
        claimWaitPeriod = _claimWaitPeriod;
    }

    function depositFor(address[] calldata userAddresses, uint[] calldata _tokens) external {
        for (uint i; i < userAddresses.length; i++) {
            _deposit(userAddresses[i], _tokens[i]);
        }
    }

    function deposit(uint amount) external {
        _deposit(msg.sender, amount);
    }

    function requestClaim() external {
        User storage user = users[msg.sender];
        require(user.tokens > 0, "nothing to claim");
        require(user.requestedClaimAt == 0, "claim requested already");

        user.requestedClaimAt = block.timestamp;
        emit ClaimRequest(msg.sender, block.timestamp);
    }

    function claim() external {
        _claim(msg.sender);
    }

    function claimFor(address userAddress) external {
        require(canClaimWithoutFee(userAddress), "not claimable for free");
        _claim(userAddress);
    }

    function _claim(address userAddress) internal {
        User storage user = users[userAddress];
        require(user.requestedClaimAt > 0, "no claim requested");

        uint tokens = user.tokens;
        uint fee;
        if (!canClaimWithoutFee(userAddress)) {
            fee = tokens * feePercentage / HUNDRED_PERCENT;
            token.safeTransfer(owner(), fee);
        }

        uint claimAmount = tokens - fee;
        totalTokens -= tokens;
        token.safeTransfer(userAddress, claimAmount);

        delete users[userAddress];
        emit Claim(userAddress, claimAmount, fee);
    }

    function _deposit(address userAddress, uint amount) internal {
        User storage user = users[userAddress];
        require(user.requestedClaimAt == 0, "user requested claim");

        uint balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint received = token.balanceOf(address(this)) - balanceBefore;

        user.tokens += received;
        totalTokens += received;
        emit Deposit(userAddress, received);
    }

    function canClaimWithoutFee(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (
            user.requestedClaimAt + claimWaitPeriod > block.timestamp || 
            user.requestedClaimAt == 0
        ) {
            return false;
        } else {
            return true;
        }
    }
}