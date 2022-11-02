//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./utils/MarketplaceValidator.sol";
import "./interfaces/INFT.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IEscrow.sol";
import "./interfaces/IClubrareMarketPlace.sol";

/**
 * @title ClubrareMarketplace contract
 * @notice NFT marketplace contract for Digital and Physical NFTs Clubrare.
 */
contract ClubrareMarketplace is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    EIP712Upgradeable,
    ERC721HolderUpgradeable,
    IClubrareMarketplace
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    //Escrow Contract Interface
    IEscrow internal escrow;
    MarketplaceValidator internal validator;

    // WETH Contract Address
    address public wETHAddress;

    uint256 public updateClosingTime;
    //Order Nonce For Seller
    mapping(address => CountersUpgradeable.Counter) internal _orderNonces;

    //Bid Nonce For Seller
    mapping(address => CountersUpgradeable.Counter) internal _bidderNonces;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;
    //To delete
    mapping(uint256 => Auction) private auctions;
    //to delete
    mapping(uint256 => bool) private bids;

    /* Fee denomiator that can be used to calculate %. 100% = 10000 */
    uint16 public constant FEE_DENOMINATOR = 10000;

    /* Reward fee of LP Staking */
    uint16 public lpStakeFee;

    //_treasuryWallet to manage admin royalties and sell fee
    address internal treasuryWallet;

    //MPWR Staking Address
    address public stakeAddress;
    //LPStaking address
    address public lpStakeAddress;

    //fee Spilt array
    FeeSplit[] public feeSplits;

    /* Reward fee of MPWR Staking */
    uint16 public stakeFee;

    /* Auction Map */
    mapping(string => Auction) public auctionsMap;
    /* bid map on auctions */
    mapping(string => bool) public bidsMap;

    function initialize(
        address _validator,
        FeeSplit[] calldata _feeSplits,
        uint16 _stakereward,
        uint16 _lpreward,
        address _treasuryWallet,
        address _escrowAddress,
        address _wethAddress
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        validator = MarketplaceValidator(_validator);
        _setFeeSplit(_feeSplits, false);
        stakeFee = _stakereward;
        lpStakeFee = _lpreward;
        treasuryWallet = _treasuryWallet;
        escrow = IEscrow(_escrowAddress);
        wETHAddress = _wethAddress;
        updateClosingTime = 600;
    }

    function updateParam(
        address _validator,
        FeeSplit[] calldata _feeSplits,
        uint16 _stakereward,
        uint16 _lpreward,
        address _treasuryWallet,
        address _escrowAddress,
        address _wethAddress
    ) external onlyOwner {
        validator = MarketplaceValidator(_validator);
        _setFeeSplit(_feeSplits, true);
        stakeFee = _stakereward;
        lpStakeFee = _lpreward;
        treasuryWallet = _treasuryWallet;
        escrow = IEscrow(_escrowAddress);
        wETHAddress = _wethAddress;
    }

    modifier isExpired(Order calldata _order) {
        require(_order.expirationTime > block.timestamp, "auction ended");
        _;
    }

    modifier adminOrOwnerOnly(address contractAddress, uint256 tokenId) {
        bool isAdmin = validator.admins(msg.sender);
        require(
            isAdmin || (msg.sender == IERC721Upgradeable(contractAddress).ownerOf(tokenId)),
            "AdminManager: admin and owner only."
        );
        _;
    }

    modifier isAllowedToken(address contractAddress) {
        require(validator.allowedPaymenTokens(contractAddress), "Invalid Payment token");
        _;
    }

    modifier isNotBlacklisted(address user) {
        require(!validator.blacklist(user), "Access Denied");
        _;
    }

    modifier isNonZero(uint256 num) {
        require(num > 0, "zero value");
        _;
    }

    modifier onlySeller(Order calldata order) {
        require(validator.verifySeller(order, msg.sender), "Not a seller");
        _;
    }

    modifier isSignActive(bytes32 digest) {
        require(!cancelledOrFinalized[digest], "Signature replay");
        _;
    }

    function setClosingTime(uint256 _second) external onlyOwner {
        updateClosingTime = _second;
    }

    function getCurrentOrderNonce(address owner) public view returns (uint256) {
        return _orderNonces[owner].current();
    }

    function getCurrentBidderNonce(address owner) public view returns (uint256) {
        return _bidderNonces[owner].current();
    }

    function admins(address _admin) external view whenNotPaused returns (bool) {
        return validator.admins(_admin);
    }

    function adminContracts(address _contract) external view whenNotPaused returns (bool) {
        return validator.adminContracts(_contract);
    }

    function hashOrder(Order memory _order) external view whenNotPaused returns (bytes32 hash) {
        return validator.hashOrder(_order);
    }

    function hashBid(Bid memory _bid) external view whenNotPaused returns (bytes32 hash) {
        return validator.hashBid(_bid);
    }

    function _setFeeSplit(FeeSplit[] calldata _feeSplits, bool isUpdate) internal {
        uint256 len = _feeSplits.length;
        for (uint256 i; i < len; i++) {
            if (_feeSplits[i].payee != address(0) && _feeSplits[i].share > 0) {
                if (isUpdate) {
                    feeSplits[i] = _feeSplits[i];
                } else {
                    feeSplits.push(_feeSplits[i]);
                }
            }
        }
    }

    function resetFeeSplit(FeeSplit[] calldata _feeSplits) external onlyOwner {
        delete feeSplits;
        _setFeeSplit(_feeSplits, false);
    }

    // =================== Owner operations ===================

    /**
     * @dev Pause trading
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause trading
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function buy(
        address contractAddress,
        uint256 tokenId,
        uint256 amount,
        Order calldata order
    ) public payable whenNotPaused nonReentrant isAllowedToken(order.paymentToken) isNotBlacklisted(msg.sender) {
        require(!validator.onAuction(order.expirationTime), "item on auction");
        validator.checkTokenGate(order, msg.sender);
        (address signer, uint256 paid) = _validate(order, amount);
        Order calldata _order = order;
        INFT nftContract = INFT(contractAddress);
        uint256 _tokenId = tokenId;
        if (_tokenId == 0) {
            // mint if not Minted

            bool isAdmin = validator.admins(signer);
            _tokenId = isAdmin
                ? _adminMint(_order.contractAddress, _order.uri, _order.royaltyFee)
                : nftContract.safeMint(_order.seller, _order.uri, _order.royaltyReceiver, _order.royaltyFee);
        }

        uint256 earning = _settlement(nftContract, _tokenId, paid, msg.sender, _order, false);

        uint256 id;

        if (_order.orderType == Type.Escrow) {
            id = escrow.createOrder(
                _tokenId,
                earning,
                _order.paymentToken,
                _order.contractAddress,
                _order.seller,
                msg.sender
            );
        }
        emit Buy(
            msg.sender,
            _order.seller,
            _order.contractAddress,
            _tokenId,
            paid,
            block.timestamp,
            _order.paymentToken,
            id,
            _order.objId
        );
    }

    function acceptOffer(
        Order calldata order,
        Bid calldata bid,
        address buyer,
        uint256 _amount
    )
        external
        whenNotPaused
        nonReentrant
        onlySeller(order)
        isAllowedToken(order.paymentToken)
        isNotBlacklisted(msg.sender)
    {
        (address signer, uint256 amt) = _validate(order, _amount);
        Order calldata _order = order;
        Bid calldata _bid = bid;
        address taker = buyer;
        require(validator.validateBid(_bid, taker, amt), "invalid bid");
        INFT nftContract = INFT(_order.contractAddress);
        uint256 _tokenId = _order.tokenId;

        if (_tokenId == 0) {
            // mint if not Minted

            bool isAdmin = validator.admins(signer);
            _tokenId = isAdmin
                ? _adminMint(_order.contractAddress, _order.uri, _order.royaltyFee)
                : nftContract.safeMint(msg.sender, _order.uri, _order.royaltyReceiver, _order.royaltyFee);
        }

        _settlement(nftContract, _tokenId, amt, taker, _order, false);

        emit AcceptOffer(
            taker,
            msg.sender,
            _order.contractAddress,
            _tokenId,
            amt,
            block.timestamp,
            _order.paymentToken,
            _order.objId
        );
    }

    function bidding(Order calldata order, uint256 amount)
        public
        payable
        whenNotPaused
        nonReentrant
        isAllowedToken(order.paymentToken)
        isNotBlacklisted(msg.sender)
    {
        validator.checkTokenGate(order, msg.sender);
        (, uint256 amt) = _validate(order, amount);

        IToken Token = IToken(order.contractAddress);

        Auction memory _auction = auctionsMap[order.objId];
        Order calldata _order = order;

        require(amt > _auction.currentBid, "Insufficient bidding amount.");
        if (order.paymentToken == address(0)) {
            if (_auction.buyer) {
                payable(_auction.highestBidder).transfer(_auction.currentBid);
            }
        } else {
            IERC20Upgradeable erc20Token = IERC20Upgradeable(_order.paymentToken);
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amt,
                "Allowance is less than amount sent for bidding."
            );

            erc20Token.transferFrom(msg.sender, address(this), amt);

            if (_auction.buyer == true) {
                erc20Token.transfer(_auction.highestBidder, _auction.currentBid);
            }
        }

        _auction.closingTime = _auction.currentBid == 0
            ? _order.expirationTime + updateClosingTime
            : _auction.closingTime + updateClosingTime;
        _auction.currentBid = _order.paymentToken == address(0) ? msg.value : amount;
        uint256 _tokenId = order.tokenId;
        address owner;
        if (_tokenId > 0) {
            owner = Token.ownerOf(_tokenId);
            if (owner != address(this)) {
                Token.safeTransferFrom(owner, address(this), _tokenId);
            }
        }

        _auction.buyer = true;
        _auction.highestBidder = msg.sender;
        _auction.currentBid = amt;
        auctionsMap[_order.objId] = _auction;
        bidsMap[_order.objId] = true;
        // Bid event
        // Bid event
        emit Bidding(
            _order.contractAddress,
            _tokenId,
            _order.seller,
            _auction.highestBidder,
            _auction.currentBid,
            block.timestamp,
            _auction.closingTime,
            _order.paymentToken,
            _order.objId
        );
    }

    function claim(Order calldata order) external whenNotPaused nonReentrant isNotBlacklisted(msg.sender) {
        require(block.timestamp > order.expirationTime, "auction not Ended");

        Auction memory auction = auctionsMap[order.objId];
        require(validator.verifySeller(order, msg.sender) || msg.sender == auction.highestBidder, "not a valid caller");
        (, address signer) = validator._verifyOrderSig(order);
        Order calldata _order = order;
        uint256 _tokenId = order.tokenId;
        INFT nftContract = INFT(_order.contractAddress);
        if (_tokenId == 0) {
            // mint if not Minted
            bool isAdmin = validator.admins(signer);
            _tokenId = isAdmin
                ? _adminMint(_order.contractAddress, _order.uri, _order.royaltyFee)
                : nftContract.safeMint(_order.seller, _order.uri, _order.royaltyReceiver, _order.royaltyFee);
        }
        _settlement(nftContract, _tokenId, auction.currentBid, auction.highestBidder, _order, true);
        emit Claimed(
            _order.contractAddress,
            _tokenId,
            nftContract.ownerOf(_tokenId),
            auction.highestBidder,
            auction.currentBid,
            _order.paymentToken,
            _order.objId
        );
    }

    function _validate(Order calldata order, uint256 amount) internal returns (address, uint256) {
        (, address signer) = validator._verifyOrderSig(order);
        bool isToken = order.paymentToken == address(0) ? false : true;
        uint256 paid = isToken ? amount : msg.value;
        require(paid > 0, "invalid amount");
        require(validator.validateOrder(order), "Invalid Order");
        return (signer, paid);
    }

    function _settlement(
        INFT nftContract,
        uint256 _tokenId,
        uint256 amt,
        address taker,
        Order calldata _order,
        bool isClaim
    ) internal returns (uint256) {
        (address creator, uint256 royaltyAmt) = _getRoyalties(
            nftContract,
            _tokenId,
            amt,
            _order.contractAddress,
            msg.sender
        );
        uint256 sellerEarning = _chargeAndSplit(amt, taker, _order.paymentToken, royaltyAmt, creator, isClaim);
        _executeExchange(_order, _order.seller, taker, sellerEarning, _tokenId, isClaim);
        return sellerEarning;
    }

    //Platform Fee Split
    function _splitFee(
        address user,
        uint256 _amount,
        address _erc20Token,
        bool isClaim
    ) internal returns (uint256) {
        bool isToken = _erc20Token != address(0);
        uint256 _platformFee;
        uint256 len = feeSplits.length;
        for (uint256 i; i < len; i++) {
            uint256 commission = (feeSplits[i].share * _amount) / FEE_DENOMINATOR;
            address payee = feeSplits[i].payee;
            if (isToken) {
                if (isClaim) {
                    IERC20Upgradeable(_erc20Token).transfer(payee, commission);
                } else {
                    IERC20Upgradeable(_erc20Token).transferFrom(user, payee, commission);
                }
            } else {
                payable(payee).transfer(commission);
            }
            _platformFee += commission;
        }
        return _platformFee;
    }

    //Internal function to distribute commission and royalties
    function _chargeAndSplit(
        uint256 _amount,
        address user,
        address _erc20Token,
        uint256 royaltyValue,
        address royaltyReceiver,
        bool isClaim
    ) internal returns (uint256) {
        uint256 amt = _amount;
        uint256 stakingSplit = (stakeFee * amt) / FEE_DENOMINATOR;
        uint256 lpSplit = (lpStakeFee * amt) / FEE_DENOMINATOR;
        address _token = _erc20Token;
        bool isEth = _checkEth(_token);
        address _user = user;
        address sender = _getTransferUser(_token, isClaim, _user);
        IERC20Upgradeable ptoken = IERC20Upgradeable(isEth ? wETHAddress : _token);

        uint256 marketFee = stakingSplit + lpSplit;
        uint256 platformFee;
        uint256 _royaltyValue = royaltyValue;
        address _royaltyReceiver = royaltyReceiver;
        bool _isClaim = isClaim;
        if (isEth) {
            payable(_royaltyReceiver).transfer(_royaltyValue);
            platformFee = _splitFee(sender, amt, _token, _isClaim);
            IWETH(wETHAddress).deposit{ value: marketFee }();
        } else {
            if (_isClaim) {
                ptoken.transfer(_royaltyReceiver, _royaltyValue);
            } else {
                ptoken.transferFrom(sender, _royaltyReceiver, _royaltyValue);
            }
            platformFee = _splitFee(sender, amt, _token, _isClaim);
        }
        if (_isClaim) {
            ptoken.transfer(treasuryWallet, marketFee);
        } else {
            ptoken.transferFrom(sender, treasuryWallet, marketFee);
        }

        emit Reckon(platformFee, treasuryWallet, stakingSplit, lpSplit, _token, _royaltyValue, _royaltyReceiver);
        return amt - (platformFee + marketFee + _royaltyValue);
    }

    function _getTransferUser(
        address _token,
        bool isClaim,
        address user
    ) private view returns (address) {
        return _token == address(0) || isClaim ? address(this) : user;
    }

    function _checkEth(address _token) private pure returns (bool) {
        return _token == address(0) ? true : false;
    }

    function invalidateSignedOrder(Order calldata order) external whenNotPaused nonReentrant {
        (bytes32 digest, address signer) = validator._verifyOrderSig(order);
        require(!bidsMap[order.objId], "bid exit on item");
        require(!cancelledOrFinalized[digest], "signature already invalidated");
        bool isAdmin = validator.admins(msg.sender);
        require(isAdmin ? order.seller == address(this) : msg.sender == signer, "Not a signer");
        cancelledOrFinalized[digest] = true;
        _orderNonces[isAdmin ? address(this) : signer].increment();
        emit CancelOrder(
            order.seller,
            order.contractAddress,
            order.tokenId,
            order.basePrice,
            block.timestamp,
            order.paymentToken,
            order.objId
        );
    }

    //Bulk cancel Order
    function invalidateSignedBulkOrder(Order[] calldata _order) external whenNotPaused nonReentrant {
        address _signer;
        bool isAdmin;
        uint256 len = _order.length;
        for (uint256 i; i < len; i++) {
            Order calldata order = _order[i];
            (bytes32 digest, address signer) = validator._verifyOrderSig(order);
            isAdmin = validator.admins(msg.sender);
            require(isAdmin ? order.seller == address(this) : msg.sender == signer, "Not a signer");
            _signer = signer;
            cancelledOrFinalized[digest] = true;
            emit CancelOrder(
                order.seller,
                order.contractAddress,
                order.tokenId,
                order.basePrice,
                block.timestamp,
                order.paymentToken,
                order.objId
            );
        }
        _orderNonces[isAdmin ? address(this) : _signer].increment();
    }

    function invalidateSignedBid(Bid calldata bid) external whenNotPaused nonReentrant {
        (bytes32 digest, address signer) = validator._verifyBidSig(bid);
        require(msg.sender == signer, "Not a signer");
        cancelledOrFinalized[digest] = true;
        _bidderNonces[signer].increment();
        emit CancelOffer(
            bid.bidder,
            bid.seller,
            bid.contractAddress,
            bid.tokenId,
            bid.bidAmount,
            block.timestamp,
            bid.paymentToken,
            bid.objId,
            bid.bidId
        );
    }

    function withdrawETH(address admin) external onlyOwner {
        payable(admin).transfer(address(this).balance);
    }

    function withdrawToken(address admin, address _paymentToken) external onlyOwner isAllowedToken(_paymentToken) {
        IERC20Upgradeable token = IERC20Upgradeable(_paymentToken);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(admin, amount);
    }

    function _executeExchange(
        Order calldata order,
        address seller,
        address buyer,
        uint256 _amount,
        uint256 _tokenId,
        bool isClaim
    ) internal {
        _invalidateSignedOrder(order);
        bool isToken = order.paymentToken == address(0) ? false : true;
        if (order.orderType != Type.Escrow) {
            IToken token = IToken(order.contractAddress);
            address _seller = token.ownerOf(_tokenId);
            IERC721Upgradeable(order.contractAddress).transferFrom(_seller, buyer, _tokenId);
            if (isToken) {
                if (isClaim) {
                    IERC20Upgradeable(order.paymentToken).transfer(_seller, _amount);
                } else {
                    IERC20Upgradeable(order.paymentToken).transferFrom(buyer, _seller, _amount);
                }
            } else {
                payable(_seller).transfer(_amount);
            }
        } else {
            IERC721Upgradeable(order.contractAddress).transferFrom(seller, address(escrow), _tokenId);
            if (isToken) {
                IERC20Upgradeable(order.paymentToken).transferFrom(buyer, address(escrow), _amount);
            } else {
                payable(address(escrow)).transfer(_amount);
            }
        }
    }

    function _invalidateSignedOrder(Order calldata order) internal {
        (bytes32 digest, address signer) = validator._verifyOrderSig(order);
        cancelledOrFinalized[digest] = true;
        _orderNonces[signer].increment();
    }

    function _invalidateSignedBid(address bidder, Bid calldata bid) internal {
        (bytes32 digest, address signer) = validator._verifyBidSig(bid);
        require(bidder == signer, "not a signer");
        cancelledOrFinalized[digest] = true;
        _bidderNonces[signer].increment();
    }

    function _getRoyalties(
        INFT nft,
        uint256 tokenId,
        uint256 amount,
        address contractAddress,
        address _sender
    ) internal view returns (address, uint256) {
        try nft.royaltyInfo(tokenId, amount) returns (address royaltyReceiver, uint256 royaltyAmt) {
            return (royaltyReceiver, royaltyAmt);
        } catch {
            if (validator.adminContracts(contractAddress)) {
                IToken token = IToken(contractAddress);
                uint256 royalities = token.royalities(tokenId);
                address creator = validator.admins(_sender) ? address(this) : token.creators(tokenId);
                uint256 royalty = (royalities * amount) / 10000;
                return (creator, royalty);
            }

            return (address(0), 0);
        }
    }

    function _adminMint(
        address contractAddress,
        string calldata uri,
        uint256 royality
    ) internal returns (uint256 tokenId) {
        require(validator.adminContracts(contractAddress), "not a admin contract");
        IToken token = IToken(contractAddress);
        return token.safeMint(uri, royality);
    }

    function _isMinted(address contractAddress, uint256 tokenId) internal view returns (bool) {
        try IERC721Upgradeable(contractAddress).ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    /**
     * @notice This function is used to burn the apporved NFTToken to
     * certain admin address which was allowed by super admin the owner of Admin Manager
     * @dev This Fuction is take two arguments address of contract and tokenId of NFT
     * @param collection tokenId The contract address of NFT contract and tokenId of NFT
     */
    function burnNFT(address collection, uint256 tokenId) public adminOrOwnerOnly(collection, tokenId) {
        INFT nftContract = INFT(collection);

        string memory tokenURI = nftContract.tokenURI(tokenId);
        require(nftContract.getApproved(tokenId) == address(this), "Token not approve for burn");
        nftContract.burn(tokenId);
        emit NFTBurned(collection, tokenId, msg.sender, block.timestamp, tokenURI);
    }

    receive() external payable {}
}