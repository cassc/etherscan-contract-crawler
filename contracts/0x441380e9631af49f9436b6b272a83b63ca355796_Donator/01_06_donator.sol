// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "Ownable.sol";
import "IERC20.sol";

import "ICurve.sol";
import "IStakePrizePool.sol";

contract Donator is Ownable {
    event RecipientSet(address indexed recipient);
    event EtherReceived(address indexed sender, uint256 indexed value);
    event MinimumPriceSet(uint256 indexed price);
    event BaseTokenWithdrawn(uint256 indexed amount);
    event BaseTokenSwapped(uint256 indexed amount);
    event EtherDonated(address indexed recipient, uint256 indexed amount);

    /// @dev This offers an interface for the PoolTogether prize pool contract from which the prizes can be withdrawn
    IStakePrizePool public immutable stakePrizePool;

    /// @dev This is the prize token which is used by above prize pool
    IERC20 public immutable prizeToken;

    /// @dev This is the base token which is deposited and withdrawn from above prize pool
    IERC20 public immutable baseToken;

    /// @dev This is the pool used to swap the withdrawn prize token to ETH
    ICurve public immutable pool;

    /// @dev This defines the minimum price allowed when swapping the base token for ETH
    uint256 public minimumPrice;

    /// @dev This is the recipient of the donate function
    address public recipient;

    /// @dev Public constructor
    constructor (IStakePrizePool _stakePrizePool, IERC20 _prizeToken, IERC20 _baseToken, ICurve _pool, address _recipient) {
        require(address(_stakePrizePool) != address(0), "prize-pool-zero");
        require(address(_prizeToken) != address(0), "prize-token-zero");
        require(address(_baseToken) != address(0), "base-token-zero");
        require(address(_pool) != address(0), "pool-contract-zero");
        require(_recipient != address(0), "recipient-zero");

        stakePrizePool = _stakePrizePool;
        prizeToken = _prizeToken;
        baseToken = _baseToken;
        pool = _pool;

        recipient = _recipient;

        emit RecipientSet(recipient);
    }

    /// @notice Allows this contract to receive Ether
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /// @notice Allows the owner of this contract to set the receiving address
    /// @param _recipient The recipient for the donate function
    /// @dev Only allow setting a non-zero recipient and when the current balance is zero
    function setRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "recipient-zero");
        require(prizeToken.balanceOf(address(this)) == 0, "balance-not-zero");

        recipient = _recipient;

        emit RecipientSet(recipient);
    }

    /// @notice Allows the owner of this contract to set the minimum price for the swap (a.k.a. slippage)
    /// @param _price The minimum price
    function setMinimumPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "price-zero");

        minimumPrice = _price;

        emit MinimumPriceSet(minimumPrice);
    }

    /// @notice Allows anyone to call the donate function
    function donate() external {
        require(minimumPrice > 0, "price-not-set");
        require(prizeToken.balanceOf(address(this)) > 0, "nothing-to-donate");

        uint256 baseTokenWithdraw = withdrawFromPool();
        emit BaseTokenWithdrawn(baseTokenWithdraw);

        uint256 etherSwapped = swapBaseTokenForEth(baseTokenWithdraw);
        emit BaseTokenSwapped(etherSwapped);

        // Send all ETH to the recipient
        (bool sent, ) = payable(recipient).call{value: etherSwapped}("");
        require(sent, "donate-failed");
        emit EtherDonated(recipient, etherSwapped);
    }

    /// @notice Helper function to withdraw the prize token from the pool
    function withdrawFromPool() internal returns (uint256 baseTokenWithdraw){
        stakePrizePool.withdrawInstantlyFrom(
            address(this),
            prizeToken.balanceOf(address(this)),
            address(prizeToken),
            0
        );
        baseTokenWithdraw = baseToken.balanceOf(address(this));
    }

    /// @notice Helper function to approve and swap the base token to ETH
    function swapBaseTokenForEth(uint256 _amountIn) internal returns (uint256 amountOut) {
        // Approve the withdrawn token for swapping
        baseToken.approve(address(pool), _amountIn);

        // Swap _amountIn of the token (index 1) for amountOutMinimum ETH (index 0)
        uint256 amountOutMinimum = _amountIn * minimumPrice / 1e18;
        amountOut = pool.exchange(1, 0, _amountIn, amountOutMinimum);
    }
}