//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./LibertiVault.sol";
import "./Weth9.sol";

contract LibertiVaultETH is LibertiVault {
    Weth9 private immutable weth;

    constructor(
        address _router,
        address _delegatedPriceFeed,
        address _weth
    ) LibertiVault(_router, _delegatedPriceFeed) {
        weth = Weth9(_weth);
    }

    function depositEth(address receiver) public payable returns (uint256) {
        return depositEth(receiver, 0);
    }

    function depositEth(address receiver, uint256 amountOutMin) public payable returns (uint256) {
        require(!SANCTIONS_LIST.isSanctioned(_msgSender()), "!sanction");
        require(msg.value <= maxDeposit(receiver), "ERC4626: deposit more than max");
        (uint256 shares, uint256 sellToken0, uint256 entryFeeAmount) = _previewDeposit(msg.value);
        require(shares >= amountOutMin, "!min");
        weth.deposit{value: msg.value}();
        if (0 < sellToken0) {
            swapExactTokensForTokens(sellToken0, asset(), other, address(this));
        }
        _mint(receiver, shares);
        _mint(owner(), entryFeeAmount);
        //FIXME: emit event
        return shares;
    }

    function redeemEth(
        uint256 shares,
        address receiver,
        address _owner
    ) public returns (uint256) {
        return redeemEth(shares, receiver, _owner, 0);
    }

    // safe redeem
    function redeemEth(
        uint256 shares,
        address receiver,
        address _owner,
        uint256 amountOutMin
    ) public returns (uint256) {
        require(shares <= maxRedeem(_owner), "ERC4626: redeem more than max");
        (uint256 assets, , uint256 exitFeeAmount) = _redeem0(shares, address(this), amountOutMin);
        if (_msgSender() != _owner) {
            _spendAllowance(_owner, _msgSender(), shares);
        }
        _burn(_owner, shares - exitFeeAmount);
        _transfer(_owner, owner(), exitFeeAmount);
        weth.withdraw(assets);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = payable(receiver).call{value: assets}("");
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(returndata, 32), mload(returndata))
            }
        }
        //FIXME: emit event
        return assets;
    }

    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }
}