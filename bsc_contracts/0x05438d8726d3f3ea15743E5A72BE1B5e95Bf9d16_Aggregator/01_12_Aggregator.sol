// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "./MarketRegistry.sol";
import "./libraries/Configable.sol";
import "./libraries/ReentrancyGuard.sol";
import "./libraries/SpecialTransferHelper.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC1155.sol";

contract Aggregator is SpecialTransferHelper, Configable, ReentrancyGuard {

    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
    }

    struct FeeDetails {
        address recipient;
        uint256 amount;
    }

    struct SendETHParam {
        address to;
        uint256 amount;
    }

    struct SendERC20Param {
        address tokenAddr;
        address to;
        uint256 amount;
    }

    struct SendERC721Param {
        address tokenAddr;
        address to;
        uint256 tokenId;
    }

    struct SendERC1155Param {
        address tokenAddr;
        address to;
        uint256[] ids;
        uint256[] amounts;
    }

    address public converter;
    uint256 public baseFees;
    uint256 public maxFees;
    bool public openForTrades;
    MarketRegistry public marketRegistry;
    MarketRegistry public converterRegistry;
    address public cryptoPunksMarket;
    address public moonCatRescue;

    modifier isOpenForTrades() {
        require(openForTrades, "trades not allowed");
        _;
    }

    constructor(address _marketRegistry, address _converterRegistry) {
        owner = msg.sender;
        marketRegistry = MarketRegistry(_marketRegistry);
        converterRegistry = MarketRegistry(_converterRegistry);
        baseFees = 0;
        openForTrades = true;
    }

    
    function setUp(address _punkProxy, address _cryptoPunksMarket, address _moonCatRescue) external onlyDev {
        // Create CryptoPunk Proxy
        IWrappedPunk(_punkProxy).registerProxy();

        cryptoPunksMarket = _cryptoPunksMarket;
        moonCatRescue = _moonCatRescue;
    }

    // @audit This function is used to approve specific tokens to specific market contracts with high volume.
    // This is done in very rare cases for the gas optimization purposes. 
    function setERC20Approval(IERC20 token, address operator, uint256 amount) external onlyDev {
        token.approve(operator, amount);
    }

    function setERC721Approval(IERC721 token, address operator) external onlyDev {
        token.setApprovalForAll(operator, true);
    }

    function setFees(uint256 _baseFees, uint256 _maxFees) external onlyManager {
        baseFees = _baseFees;
        maxFees = _maxFees;
    }

    function setOpenForTrades(bool _openForTrades) external onlyManager {
        openForTrades = _openForTrades;
    }

    function setConverterRegistry(MarketRegistry _converterRegistry) external onlyDev {
        converterRegistry = _converterRegistry;
    }

    function setMarketRegistry(MarketRegistry _marketRegistry) external onlyDev {
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

    function _collectFee(FeeDetails[] memory _feeDetails) internal {
        if(_feeDetails.length == 0) return;
        require(_feeDetails[0].amount >= baseFees, "Insufficient base fee");
        require(_feeDetails[0].recipient == team(), "Invalid base recipient");
        uint256 total;
        for(uint256 i; i< _feeDetails.length; i++) {
            total += _feeDetails[i].amount;
            if(_feeDetails[i].amount > 0) {
                _transferEth(_feeDetails[i].recipient, _feeDetails[i].amount);
            }
        }
        require(total <= maxFees, "Over max fee");
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

    function _transferFromHelper(
        ERC20Details memory erc20Details,
        SpecialTransferHelper.ERC721Details[] memory erc721Details,
        ERC1155Details[] memory erc1155Details
    ) internal {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            (bool success, ) = erc20Details.tokenAddrs[i].call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), erc20Details.amounts[i]));
            _checkCallResult(success);
        }

        // transfer ERC721 tokens from the sender to this contract
        for (uint256 i = 0; i < erc721Details.length; i++) {
            // accept CryptoPunksMarket
            if (erc721Details[i].tokenAddr == cryptoPunksMarket) {
                _acceptCryptoPunk(erc721Details[i]);
            }
            // accept MoonCatRescue
            else if (erc721Details[i].tokenAddr == moonCatRescue) {
                _acceptMoonCat(erc721Details[i]);
            }
            // default
            else {
                for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                    IERC721(erc721Details[i].tokenAddr).transferFrom(
                        _msgSender(),
                        address(this),
                        erc721Details[i].ids[j]
                    );
                }
            }
        }

        // transfer ERC1155 tokens from the sender to this contract
        for (uint256 i = 0; i < erc1155Details.length; i++) {
            IERC1155(erc1155Details[i].tokenAddr).safeBatchTransferFrom(
                _msgSender(),
                address(this),
                erc1155Details[i].ids,
                erc1155Details[i].amounts,
                ""
            );
        }
    }

    function _conversionHelper(
        MarketRegistry.TradeDetails[] memory _converstionDetails
    ) internal {
        for (uint256 i = 0; i < _converstionDetails.length; i++) {
            (address _proxy, bool _isLib, bool _isActive) = converterRegistry.markets(_converstionDetails[i].marketId);
            // market should be active
            require(_isActive, "_trade: InActive Converter");
            // convert to desired asset
            (bool success, ) = _isLib
                ? _proxy.delegatecall(_converstionDetails[i].tradeData)
                : _proxy.call{value:_converstionDetails[i].value}(_converstionDetails[i].tradeData);
            // check if the call passed successfully
            _checkCallResult(success);
        }
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
            (bool success, ) = _isLib
                ? _proxy.delegatecall(_tradeDetails[i].tradeData)
                : _proxy.call{value:_tradeDetails[i].value}(_tradeDetails[i].tradeData);
            // check if the call passed successfully
            _checkCallResult(success);
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
                (bool success, ) = _tokens[i].call(abi.encodeWithSelector(0xa9059cbb, msg.sender, IERC20(_tokens[i]).balanceOf(address(this))));
                _checkCallResult(success);
            }
        }
    }
    
    function batchBuyWithETH(
        MarketRegistry.TradeDetails[] memory tradeDetails,
        FeeDetails[] memory feeDetails
    ) payable external isOpenForTrades nonReentrant {
        _collectFee(feeDetails);

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

    function batchBuyWithERC20s(
        ERC20Details memory erc20Details,
        MarketRegistry.TradeDetails[] memory tradeDetails,
        MarketRegistry.TradeDetails[] memory converstionDetails,
        address[] memory dustTokens,
        FeeDetails[] memory feeDetails
    ) payable external isOpenForTrades nonReentrant {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            (bool success, ) = erc20Details.tokenAddrs[i].call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), erc20Details.amounts[i]));
            _checkCallResult(success);
        }

        // Convert any assets if needed
        _conversionHelper(converstionDetails);

        _collectFee(feeDetails);

        // execute trades
        _trade(tradeDetails);

        // return dust tokens (if any)
        _returnDust(dustTokens);
    }

    // swaps any combination of ERC-20/721/1155
    // User needs to approve assets before invoking swap
    // WARNING: DO NOT SEND TOKENS TO THIS FUNCTION DIRECTLY!!!
    function multiAssetSwap(
        ERC20Details memory erc20Details,
        SpecialTransferHelper.ERC721Details[] memory erc721Details,
        ERC1155Details[] memory erc1155Details,
        MarketRegistry.TradeDetails[] memory converstionDetails,
        MarketRegistry.TradeDetails[] memory tradeDetails,
        address[] memory dustTokens,
        FeeDetails[] memory feeDetails
    ) payable external isOpenForTrades nonReentrant {
        
        // transfer all tokens
        _transferFromHelper(
            erc20Details,
            erc721Details,
            erc1155Details
        );

        // Convert any assets if needed
        _conversionHelper(converstionDetails);

        // collect fees
        _collectFee(feeDetails);

        // execute trades
        _trade(tradeDetails);

        // return dust tokens (if any)
        _returnDust(dustTokens);
    }

    function batchTransfer(
        SendETHParam[] memory eths,
        SendERC20Param[] memory erc20s,
        SendERC721Param[] memory erc721s,
        SendERC1155Param[] memory erc1155s
    ) payable external isOpenForTrades nonReentrant {
        // transfer ETH
        uint256 value = 0;
        for(uint256 i=0; i < eths.length; i++) {
            value += eths[i].amount;
            _transferEth(eths[i].to, eths[i].amount);
        }

        require(value == msg.value, 'invalid value');

        // transfer ERC20 tokens from the sender to
        for (uint256 i = 0; i < erc20s.length; i++) {
            (bool success, ) = erc20s[i].tokenAddr.call(abi.encodeWithSelector(0x23b872dd, _msgSender(), erc20s[i].to, erc20s[i].amount));
            _checkCallResult(success);
        }

        // transfer ERC721 tokens from the sender to
        for (uint256 i = 0; i < erc721s.length; i++) {
            if (erc721s[i].tokenAddr == cryptoPunksMarket) {
                revert('CryptoPunks is not supported');
            }
            // accept MoonCatRescue
            else if (erc721s[i].tokenAddr == moonCatRescue) {
                revert('MoonCatRescue is not supported');
            }
            // default
            else {
                IERC721(erc721s[i].tokenAddr).transferFrom(
                    _msgSender(),
                    erc721s[i].to,
                    erc721s[i].tokenId
                );
            }
        }

        // transfer ERC1155 tokens from the sender to this contract
        for (uint256 i = 0; i < erc1155s.length; i++) {
            IERC1155(erc1155s[i].tokenAddr).safeBatchTransferFrom(
                _msgSender(),
                erc1155s[i].to,
                erc1155s[i].ids,
                erc1155s[i].amounts,
                ""
            );
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

    receive() external payable {}

    // Emergency function: In case any ETH get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueETH(address recipient) onlyDev external {
        _transferEth(recipient, address(this).balance);
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) onlyDev external { 
        IERC20(asset).transfer(recipient, IERC20(asset).balanceOf(address(this)));
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(address asset, uint256[] calldata ids, address recipient) onlyDev external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient) onlyDev external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }
}