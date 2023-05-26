// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IWasabiPoolFactory.sol";
import "./IWasabiConduit.sol";
import "./IWasabiPool.sol";
import "./WasabiOption.sol";
import "./IWasabiErrors.sol";
import "./lib/PoolAskVerifier.sol";
import "./lib/PoolBidVerifier.sol";

/**
 * An base abstract implementation of the IWasabiPool which handles issuing and exercising options alond with state management.
 */
abstract contract AbstractWasabiPool is IERC721Receiver, Ownable, IWasabiPool, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    // Pool metadata
    IWasabiPoolFactory public factory;
    WasabiOption private optionNFT;
    IERC721 private nft;
    address private admin;

    // Option state
    EnumerableSet.UintSet private optionIds;
    mapping(uint256 => uint256) private tokenIdToOptionId;
    mapping(uint256 => WasabiStructs.OptionData) private options;
    mapping(uint256 => bool) public idToFilledOrCancelled;

    receive() external payable virtual {}

    fallback() external payable {
        require(false, "No fallback");
    }

    /**
     * @dev Initializes this pool
     */
    function baseInitialize(
        IWasabiPoolFactory _factory,
        IERC721 _nft,
        address _optionNFT,
        address _owner,
        address _admin
    ) internal {
        require(owner() == address(0), "Already initialized");
        factory = _factory;
        _transferOwnership(_owner);

        nft = _nft;
        optionNFT = WasabiOption(_optionNFT);

        if (_admin != address(0)) {
            admin = _admin;
            emit AdminChanged(_admin);
        }
    }

    /// @inheritdoc IWasabiPool
    function getNftAddress() external view returns(address) {
        return address(nft);
    }

    /// @inheritdoc IWasabiPool
    function getLiquidityAddress() public view virtual returns(address) {
        return address(0);
    }

    /// @inheritdoc IWasabiPool
    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
        emit AdminChanged(_admin);
    }

    /// @inheritdoc IWasabiPool
    function removeAdmin() external onlyOwner {
        admin = address(0);
        emit AdminChanged(address(0));
    }

    /// @inheritdoc IWasabiPool
    function getAdmin() public view virtual returns (address) {
        return admin;
    }

    /// @inheritdoc IWasabiPool
    function getFactory() external view returns (address) {
        return address(factory);
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 tokenId,
        bytes memory /* data */)
    public virtual override returns (bytes4) {
        if (_msgSender() == address(optionNFT)) {
            if (!optionIds.contains(tokenId)) {
                revert IWasabiErrors.NftIsInvalid();
            }
            clearOption(tokenId, 0, false);
        } else if (_msgSender() != address(nft)) {
            revert IWasabiErrors.NftIsInvalid();
        }
        return this.onERC721Received.selector;
    }

    /// @inheritdoc IWasabiPool
    function writeOptionTo(
        WasabiStructs.PoolAsk calldata _request, bytes calldata _signature, address _receiver
    ) public payable nonReentrant returns (uint256) {
        if (idToFilledOrCancelled[_request.id]) {
            revert IWasabiErrors.OrderFilledOrCancelled();
        }
        validate(_request, _signature);

        uint256 optionId = optionNFT.mint(_receiver, address(factory));
        WasabiStructs.OptionData memory optionData = WasabiStructs.OptionData(
            true,
            _request.optionType,
            _request.strikePrice,
            _request.expiry,
            _request.tokenId
        );
        options[optionId] = optionData;

        // Lock NFT / Token into a vault
        if (_request.optionType == WasabiStructs.OptionType.CALL) {
            tokenIdToOptionId[_request.tokenId] = optionId;
        }
        optionIds.add(optionId);
        idToFilledOrCancelled[_request.id] = true;

        emit OptionIssued(optionId, _request.premium, _request.id);
        return optionId;
    }

    /// @inheritdoc IWasabiPool
    function writeOption(
        WasabiStructs.PoolAsk calldata _request, bytes calldata _signature
    ) external payable returns (uint256) {
        return writeOptionTo(_request, _signature, _msgSender());
    }

    /**
     * @dev Validates the given PoolAsk in order to issue an option
     */
    function validate(WasabiStructs.PoolAsk calldata _request, bytes calldata _signature) internal {
        // 1. Validate Signature
        address signer = PoolAskVerifier.getSignerForPoolAsk(_request, _signature);
        if (signer == address(0) || (signer != admin && signer != owner())) {
            revert IWasabiErrors.InvalidSignature();
        }

        // 2. Validate Meta
        if (_request.orderExpiry < block.timestamp) {
            revert IWasabiErrors.HasExpired();
        }
        
        require(_request.poolAddress == address(this), "WasabiPool: Signature doesn't belong to this pool");
        validateAndWithdrawPayment(_request.premium, "WasabiPool: Not enough premium is supplied");

        // 3. Request Validation
        if (_request.strikePrice == 0) {
            revert IWasabiErrors.InvalidStrike();
        }
        if (_request.expiry == 0) {
            revert IWasabiErrors.InvalidExpiry();
        }

        // 4. Type specific validation
        if (_request.optionType == WasabiStructs.OptionType.CALL) {
            if (nft.ownerOf(_request.tokenId) != address(this)) {
                revert IWasabiErrors.NftIsInvalid();
            }
            // Check that the token is free
            uint256 optionId = tokenIdToOptionId[_request.tokenId];
            if (isValid(optionId)) {
                revert IWasabiErrors.RequestNftIsLocked();
            }
        } else if (_request.optionType == WasabiStructs.OptionType.PUT) {
            if (availableBalance() < _request.strikePrice) {
                revert IWasabiErrors.InsufficientAvailableLiquidity();
            }
        }
    }

    /// @inheritdoc IWasabiPool
    function executeOption(uint256 _optionId) external payable nonReentrant {
        validateOptionForExecution(_optionId, 0);
        clearOption(_optionId, 0, true);
        emit OptionExecuted(_optionId);
    }

    /// @inheritdoc IWasabiPool
    function executeOptionWithSell(uint256 _optionId, uint256 _tokenId) external payable nonReentrant {
        validateOptionForExecution(_optionId, _tokenId);
        clearOption(_optionId, _tokenId, true);
        emit OptionExecuted(_optionId);
    }

    /**
     * @dev Validates the option if its available for execution
     */
    function validateOptionForExecution(uint256 _optionId, uint256 _tokenId) private {
        require(optionIds.contains(_optionId), "WasabiPool: Option NFT doesn't belong to this pool");
        require(_msgSender() == optionNFT.ownerOf(_optionId), "WasabiPool: Only the token owner can execute the option");

        WasabiStructs.OptionData memory optionData = options[_optionId];
        if (optionData.expiry < block.timestamp) {
            revert IWasabiErrors.HasExpired();
        }

        if (optionData.optionType == WasabiStructs.OptionType.CALL) {
            validateAndWithdrawPayment(optionData.strikePrice, "WasabiPool: Strike price needs to be supplied to execute a CALL option");
        } else if (optionData.optionType == WasabiStructs.OptionType.PUT) {
            require(_msgSender() == nft.ownerOf(_tokenId), "WasabiPool: Need to own the token to sell in order to execute a PUT option");
        }
    }

    /// @inheritdoc IWasabiPool
    function acceptBid(
        WasabiStructs.Bid calldata _bid,
        bytes calldata _signature,
        uint256 _tokenId
    ) public onlyOwner returns(uint256) {
        // Other validations are done in WasabiConduit
        if (_bid.optionType == WasabiStructs.OptionType.CALL) {
            if (!isAvailableTokenId(_tokenId)) {
                revert IWasabiErrors.NftIsInvalid();
            }
        } else {
            if (availableBalance() < _bid.strikePrice) {
                revert IWasabiErrors.InsufficientAvailableLiquidity();
            }
            _tokenId = 0;
        }

        // Lock NFT / Token into a vault
        uint256 _optionId = optionNFT.mint(_bid.buyer, address(factory));
        if (_bid.optionType == WasabiStructs.OptionType.CALL) {
            tokenIdToOptionId[_tokenId] = _optionId;
        }

        WasabiStructs.OptionData memory optionData = WasabiStructs.OptionData(
            true,
            _bid.optionType,
            _bid.strikePrice,
            _bid.expiry,
            _tokenId
        );
        options[_optionId] = optionData;
        optionIds.add(_optionId);

        emit OptionIssued(_optionId, _bid.price);
        IWasabiConduit(factory.getConduitAddress()).poolAcceptBid(_bid, _signature, _optionId);
        return _optionId;
    }

    /// @inheritdoc IWasabiPool
    function acceptAsk (
        WasabiStructs.Ask calldata _ask,
        bytes calldata _signature
    ) external onlyOwner {

        if (_ask.tokenAddress == getLiquidityAddress() && availableBalance() < _ask.price) {
            revert IWasabiErrors.InsufficientAvailableLiquidity();
        }

        if (_ask.tokenAddress == address(0)) {
            IWasabiConduit(factory.getConduitAddress()).acceptAsk{value: _ask.price}(_ask, _signature);
        } else {
            IERC20 erc20 = IERC20(_ask.tokenAddress);
            erc20.approve(factory.getConduitAddress(), _ask.price);
            IWasabiConduit(factory.getConduitAddress()).acceptAsk(_ask, _signature);
        }
    }

    /// @inheritdoc IWasabiPool
    function acceptPoolBid(WasabiStructs.PoolBid calldata _poolBid, bytes calldata _signature) external payable nonReentrant {
        // 1. Validate
        address signer = PoolBidVerifier.getSignerForPoolBid(_poolBid, _signature);
        if (signer != owner()) {
            revert IWasabiErrors.InvalidSignature();
        }
        if (!isValid(_poolBid.optionId)) {
            revert IWasabiErrors.HasExpired();
        }
        if (idToFilledOrCancelled[_poolBid.id]) {
            revert IWasabiErrors.OrderFilledOrCancelled();
        }
        if (_poolBid.orderExpiry < block.timestamp) {
            revert IWasabiErrors.HasExpired();
        }

        // 2. Only owner of option can accept bid
        if (_msgSender() != optionNFT.ownerOf(_poolBid.optionId)) {
            revert IWasabiErrors.Unauthorized();
        }

        if (_poolBid.tokenAddress == getLiquidityAddress()) {
            WasabiStructs.OptionData memory optionData = getOptionData(_poolBid.optionId);
            if (optionData.optionType == WasabiStructs.OptionType.CALL && availableBalance() < _poolBid.price) {
                revert IWasabiErrors.InsufficientAvailableLiquidity();
            } else if (optionData.optionType == WasabiStructs.OptionType.PUT &&
                // The strike price of the option can be used to payout the bid price
                (availableBalance() + optionData.strikePrice) < _poolBid.price
            ) {
                revert IWasabiErrors.InsufficientAvailableLiquidity();
            }
            clearOption(_poolBid.optionId, 0, false);
            payAddress(_msgSender(), _poolBid.price);
        } else {
            IWasabiFeeManager feeManager = IWasabiFeeManager(factory.getFeeManager());
            (address feeReceiver, uint256 feeAmount) = feeManager.getFeeData(address(this), _poolBid.price);
            uint256 maxFee = _maxFee(_poolBid.price);
            if (feeAmount > maxFee) {
                feeAmount = maxFee;
            }

            if (_poolBid.tokenAddress == address(0)) {
                if (address(this).balance < _poolBid.price) {
                    revert IWasabiErrors.InsufficientAvailableLiquidity();
                }
                (bool sent, ) = payable(_msgSender()).call{value: _poolBid.price - feeAmount}("");
                if (!sent) {
                    revert IWasabiErrors.FailedToSend();
                }
                if (feeAmount > 0) {
                    (bool _sent, ) = payable(feeReceiver).call{value: feeAmount}("");
                    if (!_sent) {
                        revert IWasabiErrors.FailedToSend();
                    }
                }
            } else {
                IERC20 erc20 = IERC20(_poolBid.tokenAddress);
                if (erc20.balanceOf(address(this)) < _poolBid.price) {
                    revert IWasabiErrors.InsufficientAvailableLiquidity();
                }
                if (!erc20.transfer(_msgSender(), _poolBid.price - feeAmount)) {
                    revert IWasabiErrors.FailedToSend();
                }
                if (feeAmount > 0) {
                    if (!erc20.transfer(feeReceiver, feeAmount)) {
                        revert IWasabiErrors.FailedToSend();
                    }
                }
            }
            clearOption(_poolBid.optionId, 0, false);
        }
        idToFilledOrCancelled[_poolBid.id] = true;
        emit PoolBidTaken(_poolBid.id);
    }

    /**
     * @dev An abstract function to check available balance in this pool.
     */
    function availableBalance() view public virtual returns(uint256);

    /**
     * @dev An abstract function to send payment for any function
     */
    function payAddress(address _seller, uint256 _amount) internal virtual;

    /**
     * @dev An abstract function to validate and withdraw payment for any function
     */
    function validateAndWithdrawPayment(uint256 _premium, string memory _message) internal virtual;

    /// @inheritdoc IWasabiPool
    function clearExpiredOptions(uint256[] memory _optionIds) public {
        if (_optionIds.length > 0) {
            for (uint256 i = 0; i < _optionIds.length; i++) {
                uint256 _optionId = _optionIds[i];
                if (!isValid(_optionId)) {
                    optionIds.remove(_optionId);
                }
            }
        } else {
            for (uint256 i = 0; i < optionIds.length();) {
                uint256 _optionId = optionIds.at(i);
                if (!isValid(_optionId)) {
                    optionIds.remove(_optionId);
                } else {
                    i ++;
                }
            }
        }
    }

    /**
     * @dev Clears the option from the existing state and optionally exercises it.
     */
    function clearOption(uint256 _optionId, uint256 _tokenId, bool _exercised) internal {
        WasabiStructs.OptionData memory optionData = options[_optionId];
        if (optionData.optionType == WasabiStructs.OptionType.CALL) {
            if (_exercised) {
                // Sell to executor, the validateOptionForExecution already checked if strike is paid
                nft.safeTransferFrom(address(this), _msgSender(), optionData.tokenId);
            }
            if (tokenIdToOptionId[optionData.tokenId] == _optionId) {
                delete tokenIdToOptionId[optionData.tokenId];
            }
        } else if (optionData.optionType == WasabiStructs.OptionType.PUT) {
            if (_exercised) {
                // Buy from executor
                nft.safeTransferFrom(_msgSender(), address(this), _tokenId);
                payAddress(_msgSender(), optionData.strikePrice);
            }
        }
        options[_optionId].active = false;
        optionIds.remove(_optionId);
        optionNFT.burn(_optionId);
    }

    /// @inheritdoc IWasabiPool
    function withdrawERC721(IERC721 _nft, uint256[] calldata _tokenIds) external onlyOwner nonReentrant {
        bool isPoolAsset = _nft == nft;

        uint256 numNFTs = _tokenIds.length;
        for (uint256 i; i < numNFTs; ) {
            if (isPoolAsset) {
                if (nft.ownerOf(_tokenIds[i]) != address(this)) {
                    revert IWasabiErrors.NftIsInvalid();
                }
                uint256 optionId = tokenIdToOptionId[_tokenIds[i]];
                if (isValid(optionId)) {
                    revert IWasabiErrors.RequestNftIsLocked();
                }

                delete tokenIdToOptionId[_tokenIds[i]];
            }
            _nft.safeTransferFrom(address(this), owner(), _tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IWasabiPool
    function depositERC721(IERC721 _nft, uint256[] calldata _tokenIds) external onlyOwner nonReentrant {
        require(_nft == nft, 'Invalid Collection');
        uint256 numNFTs = _tokenIds.length;
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IWasabiPool
    function cancelOrder(uint256 _orderId) external {
        if (_msgSender() != admin && _msgSender() != owner()) {
            revert IWasabiErrors.Unauthorized();
        }
        if (idToFilledOrCancelled[_orderId]) {
            revert IWasabiErrors.OrderFilledOrCancelled();
        }
        idToFilledOrCancelled[_orderId] = true;
        emit OrderCancelled(_orderId);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IWasabiPool).interfaceId
            || interfaceId == type(IERC721Receiver).interfaceId;
    }

    /// @inheritdoc IWasabiPool
    function isValid(uint256 _optionId) view public returns(bool) {
        return options[_optionId].active && options[_optionId].expiry >= block.timestamp;
    }

    /// @inheritdoc IWasabiPool
    function getOptionData(uint256 _optionId) public view returns(WasabiStructs.OptionData memory) {
        return options[_optionId];
    }

    /// @inheritdoc IWasabiPool
    function getOptionIdForToken(uint256 _tokenId) external view returns(uint256) {
        if (nft.ownerOf(_tokenId) != address(this)) {
            revert IWasabiErrors.NftIsInvalid();
        }
        return tokenIdToOptionId[_tokenId];
    }

    /// @inheritdoc IWasabiPool
    function getOptionIds() public view returns(uint256[] memory) {
        return optionIds.values();
    }

    /// @inheritdoc IWasabiPool
    function isAvailableTokenId(uint256 _tokenId) public view returns(bool) {
        if (nft.ownerOf(_tokenId) != address(this)) {
            return false;
        }
        uint256 optionId = tokenIdToOptionId[_tokenId];
        return !isValid(optionId);
    }

    /**
     * @dev returns the maximum fee that the protocol can take for the given amount
     */
    function _maxFee(uint256 _amount) internal pure returns(uint256) {
        return _amount / 10;
    }
}