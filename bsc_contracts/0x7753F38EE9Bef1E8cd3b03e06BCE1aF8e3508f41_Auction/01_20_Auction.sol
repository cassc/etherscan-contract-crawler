// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @dev auction with selling highest bidder
 */
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../../interfaces/ICurrency.sol";
import "../../libraries/Math.sol";
import "../../interfaces/IAuction.sol";
import "../../shared/WhitelistUpgradeable.sol";


contract Auction is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IAuction,
    WhitelistUpgradeable,
    ERC721HolderUpgradeable
{
    uint256 public SERVICE_FEE;
    uint256 public MAX_PERCENTAGE;

    enum AuctionState {
        OPENED,
        CLOSED
    }

    struct AuctionSession {
        address publisher;
        address contractERC20;
        uint256 price;
        uint256 bidStep;
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
        uint256 highestBidding;
        AuctionState state;
    }

    mapping(address => mapping(uint256 => AuctionSession)) public sessions; // address => tokenId => Session
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        public bids;
    mapping(address => mapping(uint256 => bool)) isLock;
    address private _currencyAddress;
    address private _treasuryAddress;

    modifier lockTx(address _contractNFT, uint256 _tokenId) {
        require(
            isLock[_contractNFT][_tokenId] == false,
            "Lock: there exists transaction executing"
        );
        isLock[_contractNFT][_tokenId] = true;
        _;
        isLock[_contractNFT][_tokenId] = false;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    event CreateAuction(
        address from,
        address to,
        address contractNFT,
        uint256 tokenId,
        address contractERC20,
        uint256 startPrice,
        uint256 bidStep,
        uint256 startTime,
        uint256 endTime
    );
    event CloseAuction(
        address from,
        address to,
        address contractNFT,
        uint256 tokenId,
        address contractERC20,
        uint256 finalPrice,
        uint256 startTime
    );
    event PlaceBid(
        address from,
        address to,
        address contractNFT,
        uint256 tokenId,
        address contractERC20,
        uint256 bidPrice,
        uint256 startTime
    );
    
    fallback() external payable {}

    function setFee(uint256 _fee) external validateAdmin {
        SERVICE_FEE = _fee;
    }

    /**
    @dev have to approve tokenId of contractNFT to this contract
   */
    function createAuction(
        address _contractNFT,
        uint256 _tokenId,
        address _contractERC20,
        uint256 _startPrice,
        uint256 _bidStep,
        uint256 _startTime,
        uint256 _endTime
    ) external lockTx(_contractNFT, _tokenId)  {
        require(_is721(_contractNFT), "Auction: not erc721 type");
        require(
            _startTime >= block.timestamp,
            "Auction: start time has to be greater than or equal current time"
        );
        require(
            _endTime > _startTime,
            "Auction: start time has to be smaller than end time"
        );
        require(
            ICurrency(_currencyAddress).currencyState(_contractERC20) == true,
            "Auction: not satisfy currency"
        );
        address _owner = IERC721Upgradeable(_contractNFT).ownerOf(_tokenId);
        require(_owner == _msgSender(), "Auction: You are not owner of this nft");

        IERC721Upgradeable(_contractNFT).safeTransferFrom(_msgSender(), address(this), _tokenId, "0x");

        sessions[_contractNFT][_tokenId] = AuctionSession(
            _msgSender(),
            _contractERC20,
            _startPrice,
            _bidStep,
            _startTime,
            _endTime,
            _msgSender(),
            _startPrice,
            AuctionState.OPENED
        );
        emit CreateAuction(
            _msgSender(),
            address(this),
            _contractNFT,
            _tokenId,
            _contractERC20,
            _startPrice,
            _bidStep,
            _startTime,
            _endTime
        );
    }

    function placeBid(
        address _contractNFT,
        uint256 _tokenId,
        uint256 _bidValue
    ) external payable lockTx(_contractNFT, _tokenId)  {
        AuctionSession memory auction = sessions[_contractNFT][_tokenId];
        require(auction.publisher != _msgSender(), "Auction: You are owner");
        require(
            auction.state == AuctionState.OPENED,
            "Auction: auction is not open"
        );
        require(
            block.timestamp <= auction.endTime,
            "Auction: auction is ended"
        );
        require(block.timestamp >= auction.startTime, "Auction: auction is not on time");
        uint256 currentBid = bids[_contractNFT][_tokenId][_msgSender()] +
            _bidValue;
        require(
            currentBid >= auction.highestBidding + auction.bidStep,
            "Auction: your total bid have to greater than current highestBidding plus bidStep"
        );

        if (auction.contractERC20 == address(0)) {
            require(msg.value >= _bidValue, "Auction: Not enough WBNB");
        }
        else {
            _transferERC20(auction.contractERC20, _bidValue);
        }

        bids[_contractNFT][_tokenId][_msgSender()] = currentBid;

        _placeBid(_contractNFT, _tokenId, currentBid);
        emit PlaceBid(
            _msgSender(),
            address(this),
            _contractNFT,
            _tokenId,
            auction.contractERC20,
            currentBid,
            block.timestamp
        );
    }

    function closeAuction(
        address _contractNFT,
        uint256 _tokenId
    ) external lockTx(_contractNFT, _tokenId) {
        AuctionSession memory auction = sessions[_contractNFT][_tokenId];
        require (auction.endTime < block.timestamp, "Auction: the session is not expired");
        require(
            auction.publisher == _msgSender(),
            "Auction: you are not publisher"
        );
        require(sessions[_contractNFT][_tokenId].state == AuctionState.OPENED, "Auction: the session is not open");
        sessions[_contractNFT][_tokenId].state = AuctionState.CLOSED;
        _closeAuction(_contractNFT, _tokenId);
    }

    function withdrawMoney(address _contractNFT, uint256 _tokenId) external {
        AuctionSession memory auction = sessions[_contractNFT][_tokenId];
        require(
            auction.state == AuctionState.CLOSED,
            "Auction: auction is not closed"
        );
        require(
            bids[_contractNFT][_tokenId][_msgSender()] > 0,
            "Auction: you don't have any money"
        );
        uint256 value = bids[_contractNFT][_tokenId][_msgSender()];
        bids[_contractNFT][_tokenId][_msgSender()] = 0;

        bool success;
        if (auction.contractERC20 == address(0)) {
            (success,) = payable(_msgSender()).call{value: value}("");
        }
        else {
            success = IERC20Upgradeable(auction.contractERC20).transfer(
                _msgSender(),
                value
            );
        }

        require(success, "Auction: transfer money failed!");
    }

    function initialize(address _whitelistAddress) public initializer {
        __Ownable_init();
        _treasuryAddress = _msgSender();
        SERVICE_FEE = 300; // 3%
        MAX_PERCENTAGE = 10000;
        __UUPSUpgradeable_init();
        __WhitelistUpgradeable_init(_whitelistAddress);
        __ERC721Holder_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override validateAdmin {}

    function _closeAuction(address _contractNFT, uint256 _tokenId) private {
        AuctionSession memory auction = sessions[_contractNFT][_tokenId];
        uint256 _highestBidding = auction.highestBidding;
        address _highestBidder = auction.highestBidder;
        uint256 _fee = (_highestBidding * SERVICE_FEE) / MAX_PERCENTAGE;

        bids[_contractNFT][_tokenId][_highestBidder] = 0;
        // Transfer nft and erc20
        IERC721Upgradeable(_contractNFT).safeTransferFrom(
            address(this),
            _highestBidder,
            _tokenId,
            "0x"
        );
        bool success = IERC20Upgradeable(auction.contractERC20).transfer(
            auction.publisher,
            _highestBidding - _fee
        );
        require(success, "Auction: transfer erc20 failed!");
        success = IERC20Upgradeable(auction.contractERC20).transfer(
            _treasuryAddress,
            _fee
        );
        require(success, "Auction: transfer erc20 failed!");
        emit CloseAuction(
            auction.publisher,
            auction.highestBidder,
            _contractNFT,
            _tokenId,
            auction.contractERC20,
            auction.highestBidding,
            block.timestamp
        );
    }

    function _transferERC20(address _contractERC20, uint256 _amount) private {
        uint256 allowance = IERC20Upgradeable(_contractERC20).allowance(
            _msgSender(),
            address(this)
        );
        require(allowance >= _amount, "Auction: not enough allowance");
        bool success = IERC20Upgradeable(_contractERC20).transferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        require(success, "Auction: can not transfer ERC20 token");
    }

    function _placeBid(
        address _contractNFT,
        uint256 _tokenId,
        uint256 _currentBid
    ) private {
        AuctionSession storage auction = sessions[_contractNFT][_tokenId];
        auction.highestBidding = _currentBid;
        auction.highestBidder = _msgSender();
    }

    function setTreasuryAddress(address _address) public validateAdmin {
        _treasuryAddress = _address;
    }

    function setCurrencyAddress(address _address) public validateAdmin {
        _currencyAddress = _address;
    }

    function _is721(address _contractNFT) private view returns (bool) {
        return
            IERC165Upgradeable(_contractNFT).supportsInterface(
                type(IERC721Upgradeable).interfaceId
            );
    }

    // Only use when contract has bugs and not transfer nft
    // It is the case we has made in the past and we add it for previous users
    function withdrawNFTIfError(address _contractNFT, uint256 _tokenId) external {
        AuctionSession memory auction = sessions[_contractNFT][_tokenId];
        require (auction.state == AuctionState.CLOSED, "Auction: The session is not closed");
        IERC721Upgradeable(_contractNFT).safeTransferFrom(
            address(this),
            auction.highestBidder,
            _tokenId,
            "0x"
        );
    }

}