pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Constants.sol";

contract FeeDistributor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    event Withdrawal(IERC20[] tokens, address indexed recipient);

    uint256 public immutable totalShares;

    // recipient => number of shares
    mapping(address => uint256) public shares;

    // Total amount of tokens that have been withdrawn
    mapping(IERC20 => uint256) internal _totalWithdrawn;
    // Total amount of tokens that have been withdrawn by a recipient
    mapping(IERC20 => mapping(address => uint256)) internal _withdrawn;

    constructor(address[] memory recipients, uint256[] memory _shares) public {
        require(recipients.length != 0, "EMPTY_RECIPIENTS");
        require(recipients.length == _shares.length, "RECIPIENT_SHARE_LEN");

        uint256 _totalShares;

        for (uint256 i = 0; i < recipients.length; i++) {
            require(_shares[i] != 0, "INVALID_SHARES");
            address recipient = recipients[i];
            require(recipient != address(0), "INVALID_RECIPIENT");
            require(shares[recipient] == 0, "DUPLICATE_RECIPIENT");
            uint256 newRecipientShares = _shares[i];
            _totalShares = _totalShares.add(newRecipientShares);
            shares[recipient] = newRecipientShares;
        }
        totalShares = _totalShares;
    }

    /// @dev Receives ether
    fallback() external payable {}

    /**
     * @dev Withdraws the specified tokens or ETH
     * @param tokens Array of tokens to withdraw
     * @param tokens Array of amounts to withdraw for each token
     */
    function withdraw(IERC20[] calldata tokens) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];
            uint256 amount = available(token, msg.sender);
            _withdrawn[token][msg.sender] += amount;
            _totalWithdrawn[token] += amount;
            _transfer(token, amount);
        }
        emit Withdrawal(tokens, msg.sender);
    }

    /**
     * @dev Returns the amount of ETH or ERC20 tokens held by this contract
     * @param token Token address (address(0) for ETH)
     */
    function tokenBalance(IERC20 token) public view returns (uint256) {
        if (address(token) == Constants.ETH) {
            return address(this).balance;
        } else {
            return token.balanceOf(address(this));
        }
    }

    /**
     * @dev Returns the total amount of ETH or ERC20 tokens that a recipient has earned
     * @param token Token address (address(0) for ETH)
     * @param recipient Address of the recipient
     */
    function earned(IERC20 token, address recipient)
        public
        view
        returns (uint256)
    {
        uint256 totalReceived = tokenBalance(token).add(_totalWithdrawn[token]);
        return totalReceived.mul(shares[recipient]).div(totalShares);
    }

    /**
     * @dev Returns the amount of ETH or ERC20 tokens a recipient can withdraw
     * @param token Token address (address(0) for ETH)
     * @param recipient Address of the recipient
     */
    function available(IERC20 token, address recipient)
        public
        view
        returns (uint256)
    {
        return earned(token, recipient).sub(_withdrawn[token][recipient]);
    }

    /**
     * @dev Internal function that transfers ETH or ERC20 tokens
     * @param token Token address (address(0) for ETH)
     * @param amount Amount of tokens or ETH to transfer
     */
    function _transfer(IERC20 token, uint256 amount) internal {
        if (address(token) == Constants.ETH) {
            msg.sender.sendValue(amount);
        } else {
            token.safeTransfer(msg.sender, amount);
        }
    }
}