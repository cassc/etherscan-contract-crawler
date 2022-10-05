/*
 * Global Market Exchange 
 * Official Site  : https://globalmarket.host
 * Private Sale   : https://globalmarketinc.io
 * Email          : [email protected]
 * Telegram       : https://t.me/gmekcommunity
 * Development    : Digichain Development Technology
 * Dev Is         : Tommy Chain & Team
 * Powering new equity blockchain on decentralized real and virtual projects
 * It is a revolutionary blockchain, DeFi and crypto architecture technology project
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./utils/Pausable.sol";

/**
 * @title PresaleGmexRefundVault
 * @dev This contract is used for storing funds while a presale
 * is in progress. Supports refunding the money if presale fails,
 * and forwarding it if presale is successful.
 */
contract PresaleGmexRefundVault is Initializable, OwnableUpgradeable, Pausable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum State {
        Active,
        Refunding,
        Closed
    }

    mapping(address => uint256) public deposited;
    mapping(address => bool) public tokenClaimedTracker;

    uint256 public totalBUSDDeposited;

    address public wallet;
    IERC20Upgradeable public busd;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 busdAmount);

    function initialize(address _wallet, IERC20Upgradeable _busd)
        public
        initializer
    {
        __Ownable_init();
        __PausableUpgradeable_init();
        wallet = _wallet;
        busd = _busd;
        state = State.Active;
        totalBUSDDeposited = 0;
    }

    function approve(
        address tokenAddress,
        address spender,
        uint256 amount
    ) public onlyOwner whenNotPaused returns (bool) {
        IERC20Upgradeable(tokenAddress).approve(spender, amount);
        return true;
    }

    function deposit(address _investor, uint256 _amount)
        public
        onlyOwner
        whenNotPaused
    {
        require(state == State.Active, "Requires Active state");
        deposited[_investor] = deposited[_investor].add(_amount);
        totalBUSDDeposited = totalBUSDDeposited.add(_amount);
        busd.safeTransferFrom(_investor, address(this), _amount);
    }

    function tokenClaimed(address investor) public onlyOwner whenNotPaused {
        tokenClaimedTracker[investor] = true;
    }

    function close() public onlyOwner whenNotPaused {
        require(state == State.Active, "Requires Active state");
        state = State.Closed;
        emit Closed();
    }

    function enableRefunds() public onlyOwner whenNotPaused {
        require(state == State.Closed, "Requires Closed state");
        state = State.Refunding;
        emit RefundsEnabled();
    }

    function withdrawBUSD() public onlyOwner whenNotPaused {
        require(state == State.Closed, "Requires Closed state");
        busd.safeTransfer(wallet, totalBUSDDeposited);
    }

    function refund(address investor) public onlyOwner whenNotPaused {
        require(state == State.Refunding, "Requires Refunding state");
        require(
            tokenClaimedTracker[investor] == false,
            "Token has already been claimed"
        );
        require(deposited[investor] > 0, "No amount to be refunded.");

        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;

        totalBUSDDeposited = totalBUSDDeposited.sub(depositedValue);

        busd.safeTransfer(investor, depositedValue);
        emit Refunded(investor, depositedValue);
    }

    function updateWalletAddress(address _wallet) public onlyOwner {
        wallet = _wallet;
    }
}