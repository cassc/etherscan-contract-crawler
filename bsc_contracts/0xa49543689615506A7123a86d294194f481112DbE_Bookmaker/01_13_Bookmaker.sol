// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";

import "./interfaces/IRouter.sol";

contract Bookmaker is ReentrancyGuard, Pausable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address payable;
    using SafeERC20 for IERC20;
    using PRBMathUD60x18 for uint256;

    struct Recipient {
        address payable wallet;
        uint256 percentage;
    }

    uint256 private constant BASE_PERCENTAGE = 10000;

    address public immutable router;
    address public immutable stakingToken;
    uint256 public immutable numberOfPools;
    bool public closed;

    mapping(uint256 => uint256) public supplies;
    mapping(uint256 => mapping(address => uint256)) public balances;
    mapping(uint256 => EnumerableSet.AddressSet) private _stakers;
    address[] public path;
    Recipient[] public recipients;

    event Bet(address indexed staker, uint256 pool, uint256 amount);
    event Closed(uint256 winningPool);
    event Withdrawn(uint256 amount);
    event Received(address sender, uint amount);

    /// @param router_ Router contract address (from PancakeSwap DEX).
    /// @param stakingToken_ Staking token address.
    /// @param numberOfPools_ Number of pools.
    /// @param wallets_ Recipient wallet addresses.
    /// @param percentages_ Recipient percentages.
    constructor(
        address router_,
        address stakingToken_,
        uint256 numberOfPools_,
        address[] memory wallets_,
        uint256[] memory percentages_
    ) {
        router = router_;
        stakingToken = stakingToken_;
        IERC20(stakingToken_).approve(router_, type(uint256).max);
        numberOfPools = numberOfPools_;
        setRecipients(wallets_, percentages_);
        path.push(stakingToken_);
        path.push(IRouter(router_).WETH());
    }

    /// @notice Makes contract able to receive BNB.
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @notice Triggers stopped state.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Returns to normal state.
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    * @notice Determines the winning pool of the match 
    * and distributes tokens among its stakers.
    * @param pool_ Winning pool index.
    */
    function close(uint256 pool_) external onlyOwner {
        require(!closed, "Bookmaker: B1");
        require(pool_ < numberOfPools, "Bookmaker: B2");
        uint256 reward;
        for (uint256 i = 0; i < numberOfPools; i++) {
            if (i == pool_) {
                continue;
            } else {
                reward += supplies[i];
            }
        }
        uint256 fee;
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 amount = reward * recipients[i].percentage / BASE_PERCENTAGE;
            uint256[] memory amounts = IRouter(router).swapExactTokensForETH(
                amount,
                0,
                path,
                address(this),
                block.timestamp
            );
            recipients[i].wallet.sendValue(amounts[1]);
            fee += amount;
        }
        reward -= fee;
        for (uint256 i = 0; i < _stakers[pool_].length(); i++) {
            address staker = _stakers[pool_].at(i);
            uint256 balance = balances[pool_][staker];
            uint256 amount = balance + balance.mul(reward).div(supplies[pool_]);
            IERC20(stakingToken).safeTransfer(staker, amount);
        }
        emit Closed(pool_);
        uint256 remainingBalance = IERC20(stakingToken).balanceOf(address(this));
        if (remainingBalance != 0) {
            _withdraw(remainingBalance);
        }
        closed = true;
    }

    /// @notice Places the user's bet.
    /// @param pool_ Pool index.
    /// @param amount_ Amount to bet.
    function bet(
        uint256 pool_,
        uint256 amount_
    ) 
        external
        nonReentrant 
        whenNotPaused
    {
        require(!closed, "Bookmaker: B1");
        require(amount_ != 0, "Bookmaker: B3");
        require(pool_ < numberOfPools, "Bookmaker: B2");
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount_);
        supplies[pool_] += amount_;
        balances[pool_][msg.sender] += amount_;
        if (!_stakers[pool_].contains(msg.sender)) {
            _stakers[pool_].add(msg.sender);
        }
        emit Bet(msg.sender, pool_, amount_);
    }

    /// @notice Returns `pool` staker by index.
    /// @param pool_ Pool index.
    /// @param index_ Index.
    /// @return Staker address.
    function getStaker(
        uint256 pool_,
        uint256 index_
    ) 
        external 
        view 
        returns (address) 
    {
        return _stakers[pool_].at(index_);
    }

    /// @notice Returns number of `pool_` stakers.
    /// @param pool_ Pool index.
    /// @return Number of `pool_` stakers.
    function getNumberOfStakers(
        uint256 pool_
    ) 
        external 
        view 
        returns (uint256) 
    {
        return _stakers[pool_].length();
    }

    /// @notice Returns bool value (`staker_` is staker of `pool_` or not).
    /// @param pool_ Pool index.
    /// @param staker_ Staker address.
    /// @return True if `staker_` is staker of `pool_`.
    function isStaker(
        uint256 pool_,
        address staker_
    ) 
        external 
        view 
        returns (bool)
    {
        return _stakers[pool_].contains(staker_);
    }

    /// @notice Sets recipients.
    /// @param wallets_ Recipient wallet addresses.
    /// @param percentages_ Recipient percentages.
    function setRecipients(
        address[] memory wallets_,
        uint256[] memory percentages_
    )
        public
        onlyOwner
    {
        uint256 length = percentages_.length;
        require(wallets_.length == length && length != 0, "Bookmaker: B4");
        uint256 sum;
        for (uint256 i = 0; i < percentages_.length; i++) {
            sum += percentages_[i];
        }
        require(sum <= BASE_PERCENTAGE, "Bookmaker: B5");
        delete recipients;
        for (uint256 i = 0; i < length; i++) {
            Recipient memory recipient;
            recipient.wallet = payable(wallets_[i]);
            recipient.percentage = percentages_[i];
            recipients.push(recipient);
        }
    }

    /**
    * @notice Withdraws tokens from the contract 
    * in case they were not distributed after closing.
    */
    function _withdraw(uint256 remainingBalance_) private {
        IERC20(stakingToken).safeTransfer(owner(), remainingBalance_);
        emit Withdrawn(remainingBalance_);
    }
}