// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@0x/contracts-zero-ex/contracts/src/features/interfaces/INativeOrdersFeature.sol";
import "../interfaces/IWallet.sol";

contract ZeroExTradeWallet is IWallet, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    INativeOrdersFeature public immutable zeroExRouter;
    address public immutable manager;
    EnumerableSet.AddressSet internal tokens;

    modifier onlyManager() {
        require(msg.sender == manager, "INVALID_MANAGER");
        _;
    }

    constructor(address newRouter, address newManager) public {
        require(newRouter != address(0), "INVALID_ROUTER");
        require(newManager != address(0), "INVALID_MANAGER");
        zeroExRouter = INativeOrdersFeature(newRouter);
        manager = newManager;
    }

    function getTokens() external view returns (address[] memory) {
        address[] memory returnData = new address[](tokens.length());
        for (uint256 i = 0; i < tokens.length(); ++i) {
            returnData[i] = tokens.at(i);
        }
        return returnData;
    }

    // solhint-disable-next-line no-empty-blocks
    function registerAllowedOrderSigner(address signer, bool allowed) external override onlyOwner {
        require(signer != address(0), "INVALID_SIGNER");
        zeroExRouter.registerAllowedOrderSigner(signer, allowed);
    }

    function deposit(address[] calldata depositTokens, uint256[] calldata amounts)
        external
        override
        onlyManager
        nonReentrant
    {
        uint256 tokensLength = depositTokens.length;
        uint256 amountsLength = amounts.length;

        require(tokensLength > 0, "EMPTY_TOKEN_LIST");
        require(tokensLength == amountsLength, "LENGTH_MISMATCH");
        for (uint256 i = 0; i < tokensLength; ++i) {
            require(tokens.contains(depositTokens[i]), "ADDRESS_NOT_WHITELISTED");
            IERC20(depositTokens[i]).safeTransferFrom(msg.sender, address(this), amounts[i]);
            // NOTE: approval must be done after transferFrom; balance is checked in the approval
            _approve(IERC20(depositTokens[i]));
        }
    }

    function withdraw(address[] calldata tokensToWithdraw, uint256[] calldata amounts)
        external
        override
        onlyManager
        nonReentrant
    {
        uint256 tokensLength = tokensToWithdraw.length;
        uint256 amountsLength = amounts.length;

        require(tokensLength > 0, "EMPTY_TOKEN_LIST");
        require(tokensLength == amountsLength, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < tokensLength; ++i) {
            require(tokens.contains(tokensToWithdraw[i]), "ADDRESS_NOT_WHITELISTED");
            IERC20(tokensToWithdraw[i]).safeTransfer(msg.sender, amounts[i]);
        }
    }

    function whitelistTokens(address[] calldata tokensToAdd) external onlyOwner {
        for (uint256 i = 0; i < tokensToAdd.length; ++i) {
            require(tokens.add(tokensToAdd[i]), "ADD_FAIL");
        }
    }

    function removeWhitelistedTokens(address[] calldata tokensToRemove) external onlyOwner {
        for (uint256 i = 0; i < tokensToRemove.length; ++i) {
            require(tokens.remove(tokensToRemove[i]), "REMOVE_FAIL");
        }
    }

    function _approve(IERC20 token) internal {
        // Approve the zeroExRouter's allowance to max if the allowance ever drops below the balance of the token held
        uint256 allowance = token.allowance(address(this), address(zeroExRouter));
        if (allowance < token.balanceOf(address(this))) {
            uint256 amount = token.balanceOf(address(this)).sub(allowance);
            token.safeIncreaseAllowance(address(zeroExRouter), amount);
        }
    }
}