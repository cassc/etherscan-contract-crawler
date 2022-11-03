// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./FundsDistributor.sol";

contract FundsDistributorFactoryA is Ownable{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @notice PUSH token address
    address public immutable pushToken;

    /// @notice identifier for the contract
    string public identifier;

    /// @notice Cliff time to withdraw tokens back
    uint256 public immutable cliff;

    /// @notice An event thats emitted when fundee contract is deployed
    event DeployFundee(address indexed fundeeAddress, address indexed beneficiaryAddress, uint256 amount);

    /// @notice An event thats emitted when a fundee is revoked
    event RevokeFundee(address indexed fundeeAddress);

    /**
     * @notice Construct FundsDistributor Factory
     * @param _pushToken The push token address
     * @param _start The start time for cliff
     * @param _cliffDuration The cliff duration
     * @param _identifier unique identifier for the contract
     */
    constructor(address _pushToken, uint256 _start, uint256 _cliffDuration, string memory _identifier) public {
        require(_pushToken != address(0), "FundsDistributorFactoryA::constructor: pushtoken is the zero address");
        require(_cliffDuration > 0, "FundsDistributorFactoryA::constructor: cliff duration is 0");
        require(_start.add(_cliffDuration) > block.timestamp, "FundsDistributorFactoryA::constructor: cliff time is before current time");
        pushToken = _pushToken;
        cliff = _start.add(_cliffDuration);
        identifier = _identifier;
    }

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param start the time (as Unix time) at which point vesting starts
     * @param duration duration in seconds of the period in which the tokens will vest
     * @param revocable whether the vesting is revocable or not
     * @param amount amount to send to fundee vesting contract
     * @param _identifier unique identifier for the contract
     */
    function deployFundee(address beneficiary, uint256 start, uint256 cliffDuration, uint256 duration, bool revocable, uint256 amount, string memory _identifier) external onlyOwner returns(bool){
        FundsDistributor fundeeContract = new FundsDistributor(beneficiary, start, cliffDuration, duration, revocable, _identifier);
        // IERC20 pushTokenInstance = IERC20(pushToken);
        // pushTokenInstance.safeTransfer(address(fundeeContract), amount);
        emit DeployFundee(address(fundeeContract), beneficiary, amount);
        return true;
    }

    /**
     * @dev Revokes the tokens from someone and sends back to this contract
     * @param fundeeAddress address of the beneficiary vesting contract
     */
    function revokeFundeeTokens(FundsDistributor fundeeAddress) external onlyOwner returns(bool){
        fundeeAddress.revoke(IERC20(pushToken));
        emit RevokeFundee(address(fundeeAddress));
        return true;
    }

    /**
     * @dev Withdraw remaining tokens after the cliff period has ended
     * @param amount Amount of tokens to withdraw
     */
    function withdrawTokens(uint amount) external onlyOwner returns(bool){
        require(block.timestamp > cliff, "FundsDistributorFactoryA::withdrawTokens: cliff period not complete");
        IERC20 pushTokenInstance = IERC20(pushToken);
        pushTokenInstance.safeTransfer(msg.sender, amount);
        return true;
    }
}