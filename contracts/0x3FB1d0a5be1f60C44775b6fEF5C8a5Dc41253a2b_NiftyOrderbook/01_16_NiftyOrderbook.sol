pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";
import "./INiftyOrderbook.sol";
import "./lib/Ownable.sol";
import "./Validator.sol";
import "./MarketRegistry.sol";
import "./IWeth.sol";

contract NiftyOrderbook is INiftyOrderbook, ReentrancyGuard, Validator, Ownable, GelatoRelayContext {

    string public constant name = "Nifty Orderbook";
    string public constant version = "1.0";

    bool isOpen = true;
    bool onlyGelatoCanMatch = true;

    MarketRegistry public marketRegistry;
    IWeth public weth;

    mapping(bytes32 => uint256) public amountFulfilled;

    mapping(bytes32 => bool) public cancelled;

    event Match(bytes32 orderHash, uint256 amountFilled);

    event Cancel(bytes32 orderHash, uint256 amountFilled);

    constructor(uint chainId, address _marketRegistry, address payable _weth) {
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name              : name,
            version           : version,
            chainId           : chainId,
            verifyingContract : address(this)
        }));
        marketRegistry = MarketRegistry(_marketRegistry);
        weth = IWeth(_weth);
    }

    modifier contractIsOpen() {
        require(isOpen, "contract close");
        _;
    }

    modifier onlyGelatoRelayMatch() {
        if (onlyGelatoCanMatch) {
            require(
                _isGelatoRelay(msg.sender),
                "only gelato can match"
            );
        }
        _;
    }

    function setMarketRegistry(address _marketRegistry) external onlyOwner {
        marketRegistry = MarketRegistry(_marketRegistry);
    }

    function toggleIsOpen() external onlyOwner {
        isOpen = !isOpen;
    }

    function toggleOnlyGelatoCanMatch() external onlyOwner {
        onlyGelatoCanMatch = !onlyGelatoCanMatch;
    }

    /// @dev After calling, the order can not be filled anymore.
    /// @param order Order struct containing order specifications.
    function cancelOrder(Order calldata order) public
    {
        // Validate transaction signed by maker
        if (order.maker != msg.sender) {
            revert('invalid maker');
        }
        // get the order hash
        bytes32 orderHash = hashOrder(order);
        // validate not fully filled
        require(amountFulfilled[orderHash] < order.amount, "order has already been fully filled");
        // validate not cancelled
        require(!cancelled[orderHash], "order has already been cancelled");
        // update cancel state
        cancelled[orderHash] = true;
        // emit cancel event
        emit Cancel(orderHash, amountFulfilled[orderHash]);
    }

    /// @dev direct buy - cart
    /// @param tradeDetails items to purchase
    function buy(
        MarketRegistry.TradeDetails[] calldata tradeDetails
    ) external payable nonReentrant contractIsOpen {
        // execute trades
        _trade(tradeDetails);
        // return remaining ETH (if any)
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    /// @dev fulfill limit order
    /// @param signature signed by the order maker
    /// @param order limit order to fill
    /// @param tradeDetails items to purchase
    function matchOrders(
        bytes calldata signature,
        Order calldata order,
        MarketRegistry.TradeDetails[] calldata tradeDetails
    ) external payable nonReentrant contractIsOpen onlyGelatoRelayMatch {
        // get the order hash
        bytes32 orderHash = hashOrder(order);
        // get the number of items to fulfill
        uint256 numOfItems = tradeDetails.length;
        // validate signature
        require(signatureValid(orderHash, order.maker, signature), "signature invalid");
        // validate expiration time
        require(order.expirationTime >= block.timestamp, "order expired");
        // validate items can be fulfilled
        require(amountFulfilled[orderHash] + numOfItems <= order.amount && numOfItems > 0, "too much to fulfill");
        // validate not cancelled
        require(!cancelled[orderHash], "order has been cancelled");
        // validate the order items
        uint256 totalValue = validateOrderItems(tradeDetails, order);
        // update amount filfilled
        amountFulfilled[orderHash] += numOfItems;
        // if relayer is executing calculate total value plus fee
        if (_isGelatoRelay(msg.sender)) {
            // check maxFee per nft
            totalValue += _getFee();
        }
        // take current value from order maker
        weth.transferFrom(order.maker, address(this), totalValue);
        // convert weth to eth
        weth.withdraw(totalValue);
        // if relayer is executing pay it's fee
        if (_isGelatoRelay(msg.sender)) {
            _transferRelayFeeCapped(order.maxFee * numOfItems);
        }
        // execute trades
        _trade(tradeDetails);
        // return remaining ETH (if any)
        if (address(this).balance > 0) {
            payable(order.maker).transfer(address(this).balance);
        }
        // emit match event
        emit Match(orderHash, amountFulfilled[orderHash]);
    }

    function validateOrderItems(
        MarketRegistry.TradeDetails[] calldata tradeDetails,
        Order calldata order
    ) internal view returns (uint256 totalValue) {
        for (uint256 i = 0; i < tradeDetails.length; i++) {
            // market details
            (,uint256 assetContractSlice, uint256 receiverAddressSlice,) = marketRegistry.markets(tradeDetails[i].marketId);
            // asset contract address should match trade details
            require(getAddress(tradeDetails[i].tradeData, assetContractSlice) == order.contractAddress, "wrong asset purchase");
            // receiver address should match order maker
            require(getAddress(tradeDetails[i].tradeData, receiverAddressSlice) == order.maker, "wrong receiver");
            // price should be lower than order
            require(order.price >= tradeDetails[i].value, "high asset price");
            // total order value
            totalValue += tradeDetails[i].value;
        }

        return totalValue;
    }

    function _trade(MarketRegistry.TradeDetails[] memory tradeDetails)
        internal
    {
        require(tradeDetails.length > 0, "tradeDetails not valid");

        for (uint256 i = 0; i < tradeDetails.length; i++) {
            // get market details
            (address _proxy,,,bool _isActive) = marketRegistry
                .markets(tradeDetails[i].marketId);
            // market should be active
            require(_isActive, "market not active");
            // execute trade
            (bool success, ) = _proxy.call{value: tradeDetails[i].value}(
                tradeDetails[i].tradeData
            );
            // check if the call passed successfully
            _checkCallResult(success);
        }
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

    function getAddress(bytes calldata tradeData, uint256 addressSlice)
        internal
        pure
        returns (address slicedAddress)
    {
        // sliced the data at a given point
        return
            abi.decode(
                tradeData[addressSlice:],
                (address)
            );
    }

    receive() external payable {}
}