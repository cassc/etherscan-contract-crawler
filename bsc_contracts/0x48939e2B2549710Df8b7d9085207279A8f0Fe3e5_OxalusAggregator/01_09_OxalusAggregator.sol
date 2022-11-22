// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./utils/ReentrancyGuard.sol";
import "./markets/MarketRegistry.sol";

contract OxalusAggregator is Ownable, ReentrancyGuard {
    struct TradeDetails {
        uint256 marketId;
        uint256 value;
        bytes tradeData;
    }

    struct TransferBackERC721 {
        address collection;
        uint256 tokenId;
    }

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

    address public guardian;
    uint256 public baseFees;
    bool public openForTrades;
    bool public openForFreeTrades;
    MarketRegistry public marketRegistry;

    modifier isOpenForTrades() {
        require(openForTrades, "trades not allowed");
        _;
    }

    modifier isOpenForFreeTrades() {
        require(openForFreeTrades, "free trades not allowed");
        _;
    }

    constructor(address _marketRegistry, address _guardian) {
        marketRegistry = MarketRegistry(_marketRegistry);
        guardian = _guardian;
        baseFees = 0;
        openForTrades = true;
        openForFreeTrades = true;
    }

    // @audit This function is used to approve specific tokens to specific market contracts with high volume.
    // This is done in very rare cases for the gas optimization purposes.
    function setOneTimeApproval(
        IERC20 token,
        address operator,
        uint256 amount
    ) external onlyOwner {
        token.approve(operator, amount);
    }

    function updateGuardian(address _guardian) external onlyOwner {
        guardian = _guardian;
    }

    function setBaseFees(uint256 _baseFees) external onlyOwner {
        baseFees = _baseFees;
    }

    function setOpenForTrades(bool _openForTrades) external onlyOwner {
        openForTrades = _openForTrades;
    }

    function setOpenForFreeTrades(bool _openForFreeTrades) external onlyOwner {
        openForFreeTrades = _openForFreeTrades;
    }

    // @audit we will setup a system that will monitor the contract for any leftover
    // assets. In case any asset is leftover, the system should be able to trigger this
    // function to close all the trades until the leftover assets are rescued.
    function closeAllTrades() external {
        require(_msgSender() == guardian);
        openForTrades = false;
        openForFreeTrades = false;
    }

    function setMarketRegistry(MarketRegistry _marketRegistry) external onlyOwner {
        marketRegistry = _marketRegistry;
    }

    function _transferEth(address _to, uint256 _amount) internal {
        bool callStatus;
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), _to, _amount, 0, 0, 0, 0)
        }
        require(callStatus, "_transferEth: Eth transfer failed");
    }

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _trade(TradeDetails[] memory _tradeDetails, bool _safeMode) internal {
        for (uint256 i = 0; i < _tradeDetails.length; i++) {
            // get market details
            (address _proxy, , bool _isActive) = marketRegistry.markets(_tradeDetails[i].marketId);
            // market should be active
            require(_isActive, "_trade: InActive Market");
            // execute trade
            (bool success, ) = _proxy.call{value: _tradeDetails[i].value}(_tradeDetails[i].tradeData);
            // check if the call passed successfully
            if (_safeMode) {
                _checkCallResult(success);
            }
        }
    }

    function _returnNFTs(TransferBackERC721[] memory _nfts) internal {
        for ( uint256 i = 0; i < _nfts.length; i++ ) {
            address _collection = _nfts[i].collection;
            uint256 _tokenId = _nfts[i].tokenId;
            IERC721(_collection).safeTransferFrom(
                address(this), msg.sender, _tokenId
            );
        }
    }

    function _checkAndReturnNFTs(TransferBackERC721[] memory _nfts) internal {
        for ( uint256 i = 0; i < _nfts.length; i++ ) {
            address _collection = _nfts[i].collection;
            uint256 _tokenId = _nfts[i].tokenId;
            if (IERC721(_collection).ownerOf(_tokenId) == address(this)) {
                IERC721(_collection).safeTransferFrom(
                    address(this), msg.sender, _tokenId
                );
            }

        }
    }

    function _returnDust(address[] memory _tokens) internal {
        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
            }
        }
        // return remaining tokens (if any)
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (IERC20(_tokens[i]).balanceOf(address(this)) > 0) {
                _tokens[i].call(abi.encodeWithSelector(0xa9059cbb, msg.sender, IERC20(_tokens[i]).balanceOf(address(this))));
            }
        }
    }

    function batchBuyWithETH(TradeDetails[] memory tradeDetails, TransferBackERC721[] memory nfts) external payable nonReentrant {
        // execute trades
        _trade(tradeDetails, true);
        _returnNFTs(nfts);

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
            }
        }
    }

    function batchBuyAnyWithETH(TradeDetails[] memory tradeDetails, TransferBackERC721[] memory nfts) external payable nonReentrant {
        // execute trades
        _trade(tradeDetails, false);
        _checkAndReturnNFTs(nfts);

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
            }
        }
    }

    function batchBuyWithERC20s(
        ERC20Details memory erc20Details,
        TradeDetails[] memory tradeDetails,
        TransferBackERC721[] memory nfts,
        address[] memory dustTokens
    ) external payable nonReentrant {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            erc20Details.tokenAddrs[i].call(
                abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), erc20Details.amounts[i])
            );
        }

        // execute trades
        _trade(tradeDetails, false);
        _checkAndReturnNFTs(nfts);

        // return dust tokens (if any)
        _returnDust(dustTokens);
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

    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return interfaceId == this.supportsInterface.selector;
    }

    receive() external payable {}

    // Emergency function: In case any ETH get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueETH(address recipient) external onlyOwner {
        _transferEth(recipient, address(this).balance);
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) external onlyOwner {
        asset.call(abi.encodeWithSelector(0xa9059cbb, recipient, IERC20(asset).balanceOf(address(this))));
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(
        address asset,
        uint256[] calldata ids,
        address recipient
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(
        address asset,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address recipient
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }
}