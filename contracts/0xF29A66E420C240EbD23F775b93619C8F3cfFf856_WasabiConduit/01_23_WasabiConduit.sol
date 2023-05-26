// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../IWasabiPool.sol";
import "../IWasabiErrors.sol";
import "../IWasabiPoolFactory.sol";
import "../IWasabiConduit.sol";
import "../WasabiOption.sol";
import "./ConduitSignatureVerifier.sol";
import "../fees/IWasabiFeeManager.sol";

/**
 * @dev A conduit that allows for trades of WasabiOptions
 */
contract WasabiConduit is
    Ownable,
    IERC721Receiver,
    ReentrancyGuard,
    ConduitSignatureVerifier,
    IWasabiConduit
{
    event AskTaken(
        uint256 optionId,
        uint256 orderId,
        address seller,
        address taker
    );
    event BidTaken(
        uint256 optionId,
        uint256 orderId,
        address buyer,
        address taker
    );

    event BidCancelled(uint256 orderId, address buyer);
    event AskCancelled(uint256 orderId, address seller);

    WasabiOption private option;
    uint256 public maxOptionsToBuy;
    mapping(bytes => bool) public idToFinalizedOrCancelled;
    address private factory;

    /**
     * @dev Initializes a new WasabiConduit
     */
    constructor(WasabiOption _option) {
        option = _option;
        maxOptionsToBuy = 100;
    }

    /// @inheritdoc IWasabiConduit
    function buyOptions(
        WasabiStructs.PoolAsk[] calldata _requests,
        WasabiStructs.Ask[] calldata _asks,
        bytes[] calldata _signatures
    ) external payable returns (uint256[] memory) {
        uint256 size = _requests.length + _asks.length;
        require(size > 0, "Need to provide at least one request");
        require(size <= maxOptionsToBuy, "Cannot buy that many options");
        require(
            size == _signatures.length,
            "Need to provide the same amount of signatures and requests"
        );

        uint256[] memory optionIds = new uint[](size);
        for (uint256 index = 0; index < _requests.length; index++) {
            uint256 tokenId = buyOption(_requests[index], _signatures[index]);
            optionIds[index] = tokenId;
        }
        for (uint256 index = 0; index < _asks.length; index++) {
            uint256 sigIndex = index + _requests.length;
            uint256 tokenId = acceptAsk(
                _asks[index],
                _signatures[sigIndex]
            );
            optionIds[sigIndex] = tokenId;
        }
        return optionIds;
    }

    /// @inheritdoc IWasabiConduit
    function buyOption(
        WasabiStructs.PoolAsk calldata _request,
        bytes calldata _signature
    ) public payable returns (uint256) {

        IWasabiPoolFactory poolFactory = IWasabiPoolFactory(factory);
        IWasabiFeeManager feeManager = IWasabiFeeManager(poolFactory.getFeeManager());
        (, uint256 feeAmount) = feeManager.getFeeData(_request.poolAddress, _request.premium);
        uint256 amount = _request.premium + feeAmount;

        IWasabiPool pool = IWasabiPool(_request.poolAddress);

        if (pool.getLiquidityAddress() != address(0)) {
            IERC20 erc20 = IERC20(pool.getLiquidityAddress());
            if (!erc20.transferFrom(_msgSender(), address(this), amount)) {
                revert IWasabiErrors.FailedToSend();
            }
            erc20.approve(_request.poolAddress, amount);
            return pool.writeOptionTo(_request, _signature, _msgSender());
        } else {
            require(msg.value >= amount, "Not enough ETH supplied");
            return pool.writeOptionTo{value: amount}(_request, _signature, _msgSender());
        }
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes memory /* data */
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @inheritdoc IWasabiConduit
    function transferToken(
        address _nft,
        uint256 _tokenId,
        address _target
    ) external onlyOwner {
        IERC721(_nft).safeTransferFrom(address(this), _target, _tokenId);
    }

    /// @inheritdoc IWasabiConduit
    function setOption(WasabiOption _option) external onlyOwner {
        option = _option;
    }

    /// @inheritdoc IWasabiConduit
    function setMaxOptionsToBuy(uint256 _maxOptionsToBuy) external onlyOwner {
        maxOptionsToBuy = _maxOptionsToBuy;
    }

    /// @inheritdoc IWasabiConduit
    function setPoolFactoryAddress(address _factory) external onlyOwner {
        factory = _factory;
    }

    /// @inheritdoc IWasabiConduit
    function acceptAsk(
        WasabiStructs.Ask calldata _ask,
        bytes calldata _signature
    ) public payable nonReentrant returns (uint256) {
        bytes memory id = getAskId(_ask);
        require(
            !idToFinalizedOrCancelled[id],
            "Order was finalized or cancelled"
        );

        validateAsk(_ask, _signature);

        uint256 price = _ask.price;

        (address royaltyAddress, uint256 royaltyAmount) = option.royaltyInfo(
            _ask.optionId,
            price
        );

        if (_ask.tokenAddress == address(0)) {
            require(msg.value >= price, "Not enough ETH supplied");
            if (royaltyAmount > 0) {
                (bool sent, ) = payable(royaltyAddress).call{value: royaltyAmount}("");
                if (!sent) {
                    revert IWasabiErrors.FailedToSend();
                }
                price -= royaltyAmount;
            }
            (bool _sent, ) = payable(_ask.seller).call{value: price}("");
            if (!_sent) {
                revert IWasabiErrors.FailedToSend();
            }
        } else {
            IERC20 erc20 = IERC20(_ask.tokenAddress);
            if (royaltyAmount > 0) {
                if(!erc20.transferFrom(_msgSender(), royaltyAddress, royaltyAmount)) {
                    revert IWasabiErrors.FailedToSend();
                }
                price -= royaltyAmount;
            }
            if (!erc20.transferFrom(_msgSender(), _ask.seller, price)) {
                revert IWasabiErrors.FailedToSend();
            }
        }
        option.safeTransferFrom(_ask.seller, _msgSender(), _ask.optionId);
        idToFinalizedOrCancelled[id] = true;

        emit AskTaken(_ask.optionId, _ask.id, _ask.seller, _msgSender());
        return _ask.optionId;
    }

    /// @inheritdoc IWasabiConduit
    function acceptBid(
        uint256 _optionId,
        address _poolAddress,
        WasabiStructs.Bid calldata _bid,
        bytes calldata _signature
    ) external payable nonReentrant {
        bytes memory id = getBidId(_bid);
        require(
            !idToFinalizedOrCancelled[id],
            "Order was finalized or cancelled"
        );

        IWasabiPool pool = IWasabiPool(_poolAddress);
        validateOptionForBid(_optionId, pool, _bid);
        validateBid(pool, _bid, _signature);

        uint256 price = _bid.price;

        (address royaltyAddress, uint256 royaltyAmount) = option.royaltyInfo(
            _optionId,
            price
        );

        IERC20 erc20 = IERC20(_bid.tokenAddress);
        if (royaltyAmount > 0) {
            if (!erc20.transferFrom(_bid.buyer, royaltyAddress, royaltyAmount)) {
                revert IWasabiErrors.FailedToSend();
            }
            price -= royaltyAmount;
        }
        if (!erc20.transferFrom(_bid.buyer, _msgSender(), price)) {
            revert IWasabiErrors.FailedToSend();
        }
        option.safeTransferFrom(_msgSender(), _bid.buyer, _optionId);
        idToFinalizedOrCancelled[id] = true;

        emit BidTaken(_optionId, _bid.id, _bid.buyer, _msgSender());
    }

    /// @inheritdoc IWasabiConduit
    function poolAcceptBid(WasabiStructs.Bid calldata _bid, bytes calldata _signature, uint256 _optionId) external {
        bytes memory id = getBidId(_bid);

        address poolAddress = _msgSender();
        require(
            !idToFinalizedOrCancelled[id],
            "Order was finalized or cancelled"
        );
        
        require(IWasabiPoolFactory(factory).isValidPool(_msgSender()), "Pool is not valid");

        IWasabiPool pool = IWasabiPool(poolAddress);
        validateBid(pool, _bid, _signature);

        IERC20 erc20 = IERC20(_bid.tokenAddress);

        (address royaltyAddress, uint256 royaltyAmount) = option.royaltyInfo(_optionId, _bid.price);

        if (royaltyAmount > 0) {
            if (!erc20.transferFrom(_bid.buyer, royaltyAddress, royaltyAmount)) {
                revert IWasabiErrors.FailedToSend();
            }
        }
        if (!erc20.transferFrom(_bid.buyer, poolAddress, _bid.price - royaltyAmount)) {
            revert IWasabiErrors.FailedToSend();
        }

        idToFinalizedOrCancelled[id] = true;

        emit BidTaken(_optionId, _bid.id, _bid.buyer, poolAddress);
    }

    /**
     * @dev Validates if the _ask with _signature
     *
     * @param _ask the _ask to validate
     * @param _signature the _signature to validate the ask with
     */
    function validateAsk(
        WasabiStructs.Ask calldata _ask,
        bytes calldata _signature
    ) internal view {
        // Validate Signature
        address currentOwner = option.ownerOf(_ask.optionId);

        require(
            verifyAsk(_ask, _signature, owner()) || verifyAsk(_ask, _signature, currentOwner),
            "Incorrect signature"
        );
        require(currentOwner == _ask.seller, "Seller is not owner");

        require(_ask.orderExpiry >= block.timestamp, "Order expired");
        require(_ask.price > 0, "Price needs to be greater than 0");
    }

    /**
     * @dev Validates the bid against the given option
     *
     * @param _optionId the id of option
     * @param _pool the pool where the option was issued from
     * @param _bid the _bid to validate
     */
    function validateOptionForBid(
        uint256 _optionId,
        IWasabiPool _pool,
        WasabiStructs.Bid calldata _bid
    ) internal view {
        require(
            option.ownerOf(_optionId) == _msgSender(),
            "Seller is not owner"
        );

        WasabiStructs.OptionData memory optionData = _pool.getOptionData(_optionId);

        require(
            optionData.optionType == _bid.optionType,
            "Option types don't match"
        );
        require(
            optionData.strikePrice == _bid.strikePrice,
            "Strike prices don't match"
        );

        uint256 diff = optionData.expiry > _bid.expiry
            ? optionData.expiry - _bid.expiry
            : _bid.expiry - optionData.expiry;
        require(diff <= _bid.expiryAllowance, "Not within expiry range");
    }

    /**
     * @dev Validates the bid
     *
     * @param _pool the pool the option was issued from
     * @param _bid the _bid to validate
     * @param _signature the _signature to validate the bid with
     */
    function validateBid(
        IWasabiPool _pool,
        WasabiStructs.Bid calldata _bid,
        bytes calldata _signature
    ) internal view {
        // Validate Signature
        require(
            verifyBid(_bid, _signature, owner()) ||
                verifyBid(_bid, _signature, _bid.buyer),
            "Incorrect signature"
        );
        require(
            _bid.tokenAddress != address(0),
            "Bidder didn't provide a ERC20 token"
        );

        require(_bid.orderExpiry >= block.timestamp, "Order expired");
        require(_bid.price > 0, "Price needs to be greater than 0");

        require(_pool.getNftAddress() == _bid.collection, "Collections don't match");
        require(_pool.getLiquidityAddress() == _bid.optionTokenAddress, "Option liquidity doesn't match");
    }

    /// @inheritdoc IWasabiConduit
    function cancelAsk(
        WasabiStructs.Ask calldata _ask,
        bytes calldata _signature
    ) external {
        // Validate Signature
        require(verifyAsk(_ask, _signature, _ask.seller), "Incorrect signature");
        require(_msgSender() == _ask.seller, "Only the signer can cancel");

        bytes memory id = getAskId(_ask);
        require(
            !idToFinalizedOrCancelled[id],
            "Order was already finalized or cancelled"
        );

        idToFinalizedOrCancelled[id] = true;

        emit AskCancelled(_ask.id, _ask.seller);
    }

    /// @inheritdoc IWasabiConduit
    function cancelBid(
        WasabiStructs.Bid calldata _bid,
        bytes calldata _signature
    ) external {
        // Validate Signature
        require(verifyBid(_bid, _signature, _bid.buyer), "Incorrect signature");
        require(_msgSender() == _bid.buyer, "Only the signer can cancel");

        bytes memory id = getBidId(_bid);
        require(
            !idToFinalizedOrCancelled[id],
            "Order was already finalized or cancelled"
        );

        idToFinalizedOrCancelled[id] = true;
        emit BidCancelled(_bid.id, _bid.buyer);
    }

    /**
     * @dev returns the id of _ask
     */
    function getAskId(
        WasabiStructs.Ask calldata _ask
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_ask.seller, _ask.id);
    }

    /**
     * @dev returns the id of _bid
     */
    function getBidId(
        WasabiStructs.Bid calldata _bid
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_bid.buyer, _bid.id);
    }
}