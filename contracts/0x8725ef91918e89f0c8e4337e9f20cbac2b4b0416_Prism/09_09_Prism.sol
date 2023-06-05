// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./markets/MarketRegistry.sol";
import "./interfaces/tokens/IERC20.sol";
import "./interfaces/tokens/IERC721.sol";
import "./interfaces/tokens/IERC1155.sol";
import "./interfaces/IMarket.sol";


contract Prism is Ownable, ReentrancyGuard {

    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }

    struct ERC721Details {
        address tokenAddr;
        address[] to;
        uint256[] ids;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
    }

    bool public openForTrades;
    bool public isAutoRefundEnabled;
    bool public isBalanceWallEnabled;
    MarketRegistry public marketRegistry;

    modifier isOpenForTrades() {
        require(openForTrades, "trades not allowed");
        _;
    }

    constructor(address _marketRegistry) {
        marketRegistry = MarketRegistry(_marketRegistry);
        openForTrades = true;
        isAutoRefundEnabled = true;
        isBalanceWallEnabled = true;
    }

    function setOpenForTrades(bool _openForTrades) external onlyOwner {
        openForTrades = _openForTrades;
    }

    function setAutoRefund(bool _isAutoRefundEnabled) external onlyOwner {
        isAutoRefundEnabled = _isAutoRefundEnabled;
    }

    function setBalanceWall(bool _isBalanceWallEnabled) external onlyOwner {
        isBalanceWallEnabled = _isBalanceWallEnabled;
    }

    // @audit we will setup a system that will monitor the contract for any leftover
    // assets. In case any asset is leftover, the system should be able to trigger this
    // function to close all the trades until the leftover assets are rescued.
    function closeAllTrades() external onlyOwner {
        openForTrades = false;
    }

    function _transferEth(address _to, uint256 _amount) internal {
        bool callStatus;
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), _to, _amount, 0, 0, 0, 0)
        }
        require(callStatus, "_transferEth: Eth transfer failed");
    }

    function _trade(
        MarketRegistry.TradeDetails[] memory _tradeDetails
    ) internal {
        for (uint256 i = 0; i < _tradeDetails.length; i++) {
            // get market details
            (address _proxy, bool _isLib, bool _isActive) = marketRegistry.markets(_tradeDetails[i].marketId);

            // market should be active
            require(_isActive, "_trade: InActive Market");

            // execute trade
            if (_isLib) {
                _proxy.delegatecall(abi.encodeWithSignature("execute(bytes)", _tradeDetails[i].tradeData));
            } else {
                IMarket(_proxy).execute{value:_tradeDetails[i].value}(_tradeDetails[i].tradeData);
            }
        }
    }

    function _returnDust(address[] memory _tokens) internal {
        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
        // return remaining tokens (if any)
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (IERC20(_tokens[i]).balanceOf(address(this)) > 0) {
                _tokens[i].call(abi.encodeWithSelector(0xa9059cbb, msg.sender, IERC20(_tokens[i]).balanceOf(address(this))));
            }
        }
    }

    function batchBuyWithETH(
        MarketRegistry.TradeDetails[] memory tradeDetails
    ) payable external isOpenForTrades nonReentrant {

        // check if balance condition is met
        if (isBalanceWallEnabled) {
            if (address(this).balance > 0) {
                revert("Contract balance should be zero");
            }
        }

        // execute trades
        _trade(tradeDetails);

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    // Used by ERC721BasicToken.sol
    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        virtual
        view
        returns (bool)
    {
        return interfaceId == this.supportsInterface.selector;
    }

    // We will refund received ETH automatically to maintain a contract balance zero
    fallback() external payable {
        if (isAutoRefundEnabled) {
            revert("The trasfer of ETH is not allowed");
        }
    }

    // Emergency function: In case any ETH get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueETH(address recipient) onlyOwner external {
        _transferEth(recipient, address(this).balance);
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) onlyOwner external {
        asset.call(abi.encodeWithSelector(0xa9059cbb, recipient, IERC20(asset).balanceOf(address(this))));
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(address asset, uint256[] calldata ids, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }
}