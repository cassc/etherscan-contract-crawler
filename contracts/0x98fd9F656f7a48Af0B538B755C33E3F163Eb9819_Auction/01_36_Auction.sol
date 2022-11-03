// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/Timers.sol";
// import "../../utils/Timers.sol";
import "../../env/IWETH.sol";

import "./AuctionFactory.sol";

/// @custom:security-contact [email protected]
contract Auction is
    IERC1363Receiver,
    ERC20PermitUpgradeable,
    OwnableUpgradeable,
    Multicall
{
    using Timers for uint64;
    using Timers for Timers.Timestamp;

    AuctionFactory   public immutable auctionManager;
    IWETH            public immutable weth;
    IERC20           public payment;
    IERC20           public token;
    Timers.Timestamp public start;
    Timers.Timestamp public deadline;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _weth)
        initializer()
    {
        auctionManager = AuctionFactory(msg.sender);
        weth           = IWETH(_weth);
    }

    function initialize(
        IERC20 _token,
        IERC20 _payment,
        uint64 _start,
        uint64 _deadline
    )
        external
        initializer()
    {
        string memory _name   = string.concat("P00ls Auction Token - ", IERC20Metadata(address(_token)).name());
        string memory _symbol = string.concat("P00lsAuction-",          IERC20Metadata(address(_token)).symbol());

        __Ownable_init();
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);

        payment  = _payment;
        token    = _token;
        // start    = _start.toTimestamp();
        // deadline = _deadline.toTimestamp();
        start.setDeadline(_start);
        deadline.setDeadline(_deadline);
    }

    receive()
        external
        payable
    {
        commit(msg.sender, 0);
    }

    function commit(address to, uint256 amount)
        public
        payable
    {
        if (msg.value > 0)
        {
            require(weth == payment);
            weth.deposit{ value: msg.value }();
            _commit(to, msg.value);
        }
        else
        {
            SafeERC20.safeTransferFrom(payment, msg.sender, address(this), amount);
            _commit(to, amount);
        }
    }

    function onTransferReceived(address, address from, uint256 value, bytes calldata)
        external
        override
        returns (bytes4)
    {
        require(msg.sender == address(payment));
        _commit(from, value);
        return this.onTransferReceived.selector;
    }

    function _commit(address user, uint256 amount)
        internal
    {
        require(start.isExpired() && deadline.isPending(), "Auction: auction not active");
        _mint(user, amount);
    }

    function leave(address to)
        public
    {
        require(start.isExpired() && deadline.isPending(), "Auction: auction not active");
        uint256 value = balanceOf(msg.sender);
        _burn(msg.sender, value);
        SafeERC20.safeTransfer(payment, to, Math.mulDiv(value, 80, 100)); // 20% penalty
    }

    function withdraw(address to)
        public
    {
        require(deadline.isExpired(), "Auction: auction not finished");
        uint256 value = balanceOf(msg.sender);
        uint256 amount = paymentToToken(value); // must be computed BEFORE the _burn operation
        _burn(msg.sender, value);
        SafeERC20.safeTransfer(token, to, amount);
    }

    function finalize(address to)
        public
        onlyOwner()
    {
        require(deadline.isExpired(), "Auction: auction not finished");
        SafeERC20.safeTransfer(payment, to, payment.balanceOf(address(this)));
    }

    function paymentToToken(uint256 amount)
       public
       view
       returns (uint256)
    {
        return Math.mulDiv(amount, token.balanceOf(address(this)), totalSupply());
    }

    function tokenToPayment(uint256 amount)
        public
        view
        returns (uint256)
    {
        return Math.mulDiv(amount, totalSupply(), token.balanceOf(address(this)));
    }
}