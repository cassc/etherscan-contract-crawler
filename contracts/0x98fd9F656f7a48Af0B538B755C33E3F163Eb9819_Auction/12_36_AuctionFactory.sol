// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@amxx/hre/contracts/ENSReverseRegistration.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./Auction.sol";

/**
 * @dev WARNING: the P00ls auction must be finalized before the other auctions. Otherwise, the p00ls tokens reserved
 * for providing liquidity in the ETH <> P00ls pair would be drained in the P00ls <> Creactor pair.
 */
/// @custom:security-contact [email protected]
contract AuctionFactory is AccessControl, Multicall {
    bytes32 public constant AUCTION_MANAGER_ROLE = keccak256("AUCTION_MANAGER_ROLE");

    address            public immutable template;
    IUniswapV2Router02 public immutable router;
    IUniswapV2Factory  public immutable factory;
    IERC20             public immutable p00ls;
    address            public           lpreceiver;

    uint8 private _openPayments;

    event AuctionCreated(address indexed token, address indexed payment, address auction, uint256 tokensAuctioned, uint64 start, uint64 deadline);
    event AuctionFinalized(address indexed token, address indexed payment, address auction, uint256 amountPayment, uint256 amountToken);
    event LPReceiverUpdate(address lpreceiver);

    constructor(address _admin, IUniswapV2Router02 _router, IERC20 _p00ls, address _lpreceiver)
    {
        _grantRole(DEFAULT_ADMIN_ROLE,   _admin);
        _grantRole(AUCTION_MANAGER_ROLE, _admin);
        template   = address(new Auction(_router.WETH()));
        router     = _router;
        factory    = IUniswapV2Factory(_router.factory());
        p00ls      = _p00ls;
        lpreceiver = _lpreceiver;
    }

    function start(IERC20 token, uint64 timestamp, uint64 duration)
        external
        onlyRole(AUCTION_MANAGER_ROLE)
        returns (Auction)
    {
        uint256 balance = token.balanceOf(address(this)) / 2;
        require(balance > 0);
        IERC20 payment = address(token) == address(p00ls)
            ? IERC20(router.WETH())
            : p00ls;

        Auction instance = Auction(payable(Clones.cloneDeterministic(template, bytes32(bytes20(address(token))))));

        // Send half of the token to the instance - keep the rest for the AMM
        SafeERC20.safeTransfer(token, address(instance), balance);

        // Start auction
        instance.initialize(token, payment, timestamp, timestamp + duration);

        emit AuctionCreated(address(token), address(payment), address(instance), balance, timestamp, timestamp + duration);

        return instance;
    }

    function finalize(IERC20 token)
        external
        onlyRole(AUCTION_MANAGER_ROLE)
    {
        Auction instance = getAuctionInstance(token);
        instance.finalize(address(this));

        IERC20  payment = instance.payment();
        uint256 balancePayment = payment.balanceOf(address(this));
        uint256 balanceToken   = token.balanceOf(address(this));

        // create AMM pair if needed
        if (factory.getPair(address(payment), address(token)) == address(0)) {
            factory.createPair(address(payment), address(token));
        }

        // approve tokens
        //
        // WARNING: do not use SafeERC20.safeApproval here!
        // Doing so would revert because of leftover allowance on "payment" from the previous runs
        if (payment.allowance(address(this), address(router)) < balancePayment) {
            payment.approve(address(router), type(uint256).max);
        }

        if (token.allowance(address(this), address(router)) < balanceToken) {
            token.approve(address(router), type(uint256).max);
        }

        // add liquidity
        router.addLiquidity(
            address(payment),
            address(token),
            balancePayment,
            balanceToken,
            0,
            0,
            lpreceiver,
            block.timestamp
        );

        emit AuctionFinalized(address(token), address(payment), address(instance), balancePayment, balanceToken);
    }

    function getAuctionInstance(IERC20 token)
        public
        view
        returns (Auction)
    {
        address instance = Clones.predictDeterministicAddress(template, bytes32(bytes20(address(token))));
        require(Address.isContract(instance), "No auction for this token");
        return Auction(payable(instance));
    }

    function setLPReceiver(address newLPReceiver)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit LPReceiverUpdate(newLPReceiver);
        lpreceiver = newLPReceiver;
    }

    function setName(address ensregistry, string calldata ensname)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ENSReverseRegistration.setName(ensregistry, ensname);
    }
}