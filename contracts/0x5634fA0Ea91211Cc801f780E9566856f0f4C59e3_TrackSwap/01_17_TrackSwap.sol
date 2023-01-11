// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./MarketRegistry.sol";
import "./SpecialTransferHelper.sol";
import "./libs/X2Y2Market.sol";
import "./interfaces/IExecutionStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract TrackSwap is SpecialTransferHelper, Ownable, ReentrancyGuard {

    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
    }

    struct ConverstionDetails {
        bytes conversionData;
    }

    address public constant GOV = 0xD92ed451d94983957957c97F54d3c685D84D316a;
    address public constant X2Y2_ERC721_DELEGATE = 0xF849de01B080aDC3A814FaBE1E2087475cF2E354;
    address public constant X2Y2_ERC1155_DELEGATE = 0x024aC22ACdB367a3ae52A3D94aC6649fdc1f0779;
    address public guardian;
    address public converter;
    address public punkProxy;
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
        openForTrades = true;
        openForFreeTrades = true;
    }

    function setUp() external onlyOwner {
        // Create CryptoPunk Proxy
        IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).registerProxy();
        punkProxy = IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).proxyInfo(address(this));

        // approve wrapped mooncats rescue to Acclimated​MoonCats contract
        IERC721(0x7C40c393DC0f283F318791d746d894DdD3693572).setApprovalForAll(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69, true);
    }

    // modifies `src`
    function _arrayReplace(
        bytes memory src,
        bytes memory replacement,
        bytes memory mask
    ) internal view virtual {
        require(src.length == replacement.length);
        require(src.length == mask.length);

        for (uint256 i = 0; i < src.length; i++) {
            if (mask[i] != 0) {
                src[i] = replacement[i];
            }
        }
    }
    // @audit This function is used to approve specific tokens to specific market contracts with high volume.
    // This is done in very rare cases for the gas optimization purposes. 
    function setOneTimeApproval(IERC20 token, address operator, uint256 amount) external onlyOwner {
        token.approve(operator, amount);
    }

    function updateGuardian(address _guardian) external onlyOwner {
        guardian = _guardian;
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

    function setConverter(address _converter) external onlyOwner {
        converter = _converter;
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

    function _transferFromHelper(
        ERC20Details memory erc20Details,
        SpecialTransferHelper.ERC721Details[] memory erc721Details,
        ERC1155Details[] memory erc1155Details
    ) internal {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            erc20Details.tokenAddrs[i].call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), erc20Details.amounts[i]));
        }

        // transfer ERC721 tokens from the sender to this contract
        for (uint256 i = 0; i < erc721Details.length; i++) {
            // accept CryptoPunks
            if (erc721Details[i].tokenAddr == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
                _acceptCryptoPunk(erc721Details[i]);
            }
            // accept Mooncat
            else if (erc721Details[i].tokenAddr == 0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6) {
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
        ConverstionDetails[] memory _converstionDetails
    ) internal {
        for (uint256 i = 0; i < _converstionDetails.length; i++) {
            // convert to desired asset
            (bool success, ) = converter.delegatecall(_converstionDetails[i].conversionData);
            // check if the call passed successfully
            _checkCallResult(success);
        }
    }

    function _trade(
        MarketRegistry.TradeDetails[] memory _tradeDetails
    ) internal {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < _tradeDetails.length; i++) {
            totalValue += _tradeDetails[i].value;
        }
        require(msg.value >= totalValue * 1005/1000, "Insuficient total funds!");
        uint256 fee = 0;

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
            if(success)
            {
                fee += _tradeDetails[i].value * 1005 / 1000;

                if(_tradeDetails[i].marketId == 2)
                {
                    // X2Y2
                    X2Y2Market.RunInput memory input = abi.decode(_tradeDetails[i].tradeData, (X2Y2Market.RunInput));
                    for(uint256 k=0; k < input.details.length; k ++)
                    {
                        X2Y2Market.SettleDetail memory detail = input.details[k];
                        X2Y2Market.Order memory order = input.orders[detail.orderIdx];
                        X2Y2Market.OrderItem memory item = order.items[detail.itemIdx];
                        bytes memory data = item.data;
                        {
                            if (order.dataMask.length > 0 && detail.dataReplacement.length > 0) {
                                _arrayReplace(data, detail.dataReplacement, order.dataMask);
                            }
                        }
                        if(address(detail.executionDelegate) == X2Y2_ERC721_DELEGATE)
                        {
                            X2Y2Market.ERC721Pair[] memory pairs = abi.decode(data, (X2Y2Market.ERC721Pair[]));
                            for (uint256 j = 0; j < pairs.length; j++) {
                                X2Y2Market.ERC721Pair memory p = pairs[j];
                                if(p.token.ownerOf(p.tokenId) == address(this))
                                    p.token.safeTransferFrom(address(this), msg.sender, p.tokenId);
                            }
                        }else if(address(detail.executionDelegate) == X2Y2_ERC1155_DELEGATE)
                        {
                            X2Y2Market.ERC1155Pair[] memory pairs = abi.decode(data, (X2Y2Market.ERC1155Pair[]));
                            for (uint256 j = 0; j < pairs.length; j++) {
                                X2Y2Market.ERC1155Pair memory p = pairs[j];
                                p.token.safeTransferFrom(address(this), msg.sender, p.tokenId, p.amount, "");
                            }
                        }
                    }
                }
                if(_tradeDetails[i].marketId == 3)
                {
                    (OrderTypes.TakerOrder memory takerBid, OrderTypes.MakerOrder memory makerAsk) = abi.decode(_tradeDetails[i].tradeData, (OrderTypes.TakerOrder, OrderTypes.MakerOrder));
                    // Retrieve execution parameters
                    (, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerAsk.strategy).canExecuteTakerBid(takerBid, makerAsk);
                    if (IERC165(makerAsk.collection).supportsInterface(INTERFACE_ID_ERC721)) {
                        IERC721(makerAsk.collection).transferFrom(address(this), msg.sender, tokenId);
                    } else if (IERC165(makerAsk.collection).supportsInterface(INTERFACE_ID_ERC1155)) {
                        IERC1155(makerAsk.collection).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
                    }
                }
            }
        }
        if(fee > 0)
            payable(GOV).transfer(fee);
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
    ) payable external nonReentrant {
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
        ConverstionDetails[] memory converstionDetails,
        address[] memory dustTokens
    ) payable external nonReentrant {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            erc20Details.tokenAddrs[i].call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), erc20Details.amounts[i]));
        }

        // Convert any assets if needed
        _conversionHelper(converstionDetails);

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
        ConverstionDetails[] memory converstionDetails,
        MarketRegistry.TradeDetails[] memory tradeDetails,
        address[] memory dustTokens
    ) payable external isOpenForTrades nonReentrant {
        // transfer all tokens
        _transferFromHelper(
            erc20Details,
            erc721Details,
            erc1155Details
        );

        // Convert any assets if needed
        _conversionHelper(converstionDetails);

        // execute trades
        _trade(tradeDetails);

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
    function rescueETH(address recipient) onlyOwner external {
        _transferEth(recipient, address(this).balance);
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) onlyOwner external { 
        (bool success, ) = asset.call(abi.encodeWithSelector(0xa9059cbb, recipient, IERC20(asset).balanceOf(address(this))));
        _checkCallResult(success);
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