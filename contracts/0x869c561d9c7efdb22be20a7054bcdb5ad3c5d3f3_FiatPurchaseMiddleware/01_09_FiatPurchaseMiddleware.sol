// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "lib/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin/contracts/access/Ownable.sol";
import "src/interfaces/Storage.sol";

contract FiatPurchaseMiddleware is Ownable, Storage {
    using SafeERC20 for IERC20;

    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);

    error NothingToClaim();
    error AlreadyClaimed();
    error AlreadyInitialized();
    error CantPurchaseToItself();
    error CantPurchaseToZeroAddress();

    constructor() Ownable(msg.sender) {}

    function initialize(address _presale, address _token) external {
        if (_initialized) revert AlreadyInitialized();
        presale = IPresalePurchases(_presale);
        saleToken = IERC20(IPresalePurchases(_presale).saleToken());
        usdToken = IERC20(_token);
        _initialized = true;
    }

    event log_uint(uint256 a);
    event log_address(address a);

    function purchaseFor(address _purchaseTarget, uint256 _amount, uint256 _referrerId) external {
        if (_purchaseTarget == address(this)) revert CantPurchaseToItself();
        if (_purchaseTarget == address(0)) revert CantPurchaseToZeroAddress();

        _purchasedTokens[_purchaseTarget] += _amount;
        purchaseSum += _amount;

        (,uint256 priceInUSD) = presale.getPrice(_amount);
        usdToken.safeTransferFrom(msg.sender, address(this), priceInUSD);

        address(usdToken).call(
            abi.encodeWithSignature("approve(address,uint256)", address(presale), priceInUSD)
        );

        presale.buyWithUSD(_amount, _referrerId);
    }

    function claimPresale() external {
        presale.claim();
    }

    function claim() external {
        uint256 amount = _purchasedTokens[msg.sender] * 1e18;
        if (amount == 0) revert NothingToClaim();
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        hasClaimed[msg.sender] = true;
        saleToken.safeTransfer(msg.sender, amount);
        emit TokensClaimed(msg.sender, amount, block.timestamp);
    }
}