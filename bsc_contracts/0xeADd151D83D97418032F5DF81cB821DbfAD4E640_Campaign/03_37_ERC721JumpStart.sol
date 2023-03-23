// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Whitelist.sol";
import "./ICampaign.sol";
import "./IJumpStartTicket.sol";
import "./ICampaignManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract ERC721JumpStart is
    ERC2981,
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    Whitelist
{
    struct Batch {
        uint256 quantity;
        uint256 price;
        bool active;
    }

    ICampaign campaignContract;
    ICampaignManager campaignManagerContract;

    Batch public currentBatch;

    using SafeCast for uint256;
    using SafeMathUpgradeable for uint256;

    string public baseUri;
    string private contractUri;
    string public mintType;
    string public nftUID;

    uint256 public mintLimit;
    uint256 public mintPrice;
    uint256 public maxMintPerWallet;
    uint256 public maxMintPerTransaction;
    uint256 public jumpStartFee;
    uint256 public priceDiscount;
    uint256 public priceDiscountEndDate;
    uint256 public ticketsPerMint;
    uint256 public ticketsMinted;
    // track total fees collected
    uint256 public totalFeesCollected;
    uint256 currentBatchIndex;

    address public campaign;
    address public paymentToken;
    address public ticketContract;

    bool public whitelistEnabled;
    bool public redeemable;
    bool public batchedEnabled;
    bool public pfpEnabled;

    mapping(address => uint256) private mintedPerWallet;

    event NewBatchCreated(uint256 batchStartIndex);

    function initialize(
        // [0] = tokenName, [1] = tokenSymbol, [2] = tokenUri
        // [3] = mintType, [4] = nftUID, [5] = contractUri
        string[6] memory _stringSettings,
        // [0] = quantity, [1] = mintPrice, [2] = priceDiscount,
        //[3] = priceDiscountEndDate, [4] = mintPerAddress,
        //[5] = mintPerTransaction, [6] = ticketsPerMint, [7] = campaignFee, [8] = royaltyFee
        uint256[9] memory _intSettings,
        //_enableWhitelist, _redeemable, batchEnabled
        bool[3] memory _boolSettings,
        // [0] = campaign,[1] = royaltyReceiver , [2] = paymentToken, [3] = campaignManager
        address[4] memory _addresses
    ) external initializerERC721A initializer {
        OwnableUpgradeable.__Ownable_init();
        __ERC721A_init(_stringSettings[0], _stringSettings[1]);

        baseUri = _stringSettings[2];
        mintType = _stringSettings[3];
        nftUID = _stringSettings[4];
        contractUri = _stringSettings[5];

        mintLimit = _intSettings[0];
        mintPrice = _intSettings[1];
        priceDiscount = _intSettings[2];
        priceDiscountEndDate = _intSettings[3];
        maxMintPerWallet = _intSettings[4];
        maxMintPerTransaction = _intSettings[5];
        ticketsPerMint = _intSettings[6];
        jumpStartFee = _intSettings[7];

        _setDefaultRoyalty(_addresses[1], _intSettings[8].toUint96());

        whitelistEnabled = _boolSettings[0];
        redeemable = _boolSettings[1];
        batchedEnabled = _boolSettings[2];

        if (batchedEnabled) {
            currentBatch = Batch({
                quantity: _intSettings[0],
                price: _intSettings[1],
                active: true
            });
            currentBatchIndex = 1;
        }

        if (
            keccak256(abi.encodePacked(mintType)) ==
            keccak256(abi.encodePacked("base"))
        ) {
            paymentToken = address(0);
        } else {
            paymentToken = _addresses[2];
        }
        campaignContract = ICampaign(_addresses[0]);
        campaignManagerContract = ICampaignManager(_addresses[3]);
        campaign = _addresses[0];
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function setContractURI(string memory _uri) public onlyOwner {
        contractUri = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function mint(uint256 _numberOfNfts) public {
        (
            uint256 startDate,
            uint256 endDate,
            bool refundActive,
            uint256 campaignFee,
            address jumpstartFeeCollector
        ) = campaignContract.getDates();
        require(startDate <= block.timestamp, "Campaign has not started");
        require(!refundActive, "Campaign refunded");
        require(_numberOfNfts > 0, "mint quantity cannot be 0");

        if (batchedEnabled) {
            require(currentBatch.active, "Batch not active");
            require(currentBatch.quantity > 0, "Batch quantity exceeded");

            //check enough to mint from batch
            _numberOfNfts = _numberOfNfts > currentBatch.quantity
                ? currentBatch.quantity
                : _numberOfNfts;
            // update batch quantity
            currentBatch.quantity = (currentBatch.quantity - _numberOfNfts);            
        } else {
            require(_totalMinted() < mintLimit, "All NFT's Minted");
            require(
                _totalMinted() + _numberOfNfts <= mintLimit,
                "Exceeds mintLimit"
            );
        }

        require(
            _numberOfNfts <= maxMintPerTransaction,
            "Exceeds maxMintPerTransaction"
        );

        require(
            mintedPerWallet[msg.sender] + _numberOfNfts <= maxMintPerWallet,
            "Mint goes over limit"
        );

        if (whitelistEnabled) {
            require(whitelist[msg.sender] == true, "Not whitelisted");
        }

        mintChainPay(msg.sender, _numberOfNfts);

        if(batchedEnabled) {
            totalFeesCollected += _numberOfNfts * currentBatch.price;
        }
        else{
            totalFeesCollected += _numberOfNfts * mintPrice;
        }        

        // mint tickets
        if (redeemable) {
            mintTickets(msg.sender, _numberOfNfts * ticketsPerMint);
        }
    }

    function mintChainPay(address _minter, uint256 _numberOfNfts) private {
        (
            uint256 startDate,
            uint256 endDate,
            bool refundActive,
            uint256 campaignFee,
            address jumpStartFeeCollector
        ) = campaignContract.getDates();
        // check priceDiscount
        uint256 _price;

        if (batchedEnabled) {
            _price = currentBatch.price;
        } else {
            _price = mintPrice;
        }

        if (block.timestamp < priceDiscountEndDate) {
            _price = _price
                .mul(SafeMathUpgradeable.sub(100, priceDiscount))
                .div(100);
        }

        require(
            IERC20(paymentToken).balanceOf(_minter) >= _price * _numberOfNfts,
            "Insufficient balance"
        );
        require(_pay(_minter, _price * _numberOfNfts), "Payment failed");
        
        // update campaign totals
        campaignContract.updateUserContributed(
            msg.sender,
            _numberOfNfts * _price
        );

        mintedPerWallet[_minter] += _numberOfNfts;
        _safeMint(_minter, _numberOfNfts);
    }

    function _pay(address payee, uint256 fee) internal virtual returns (bool) {
        IERC20 token = IERC20(paymentToken);
        (
            uint256 startDate,
            uint256 endDate,
            bool refundActive,
            uint256 campaignFee,
            address jumpStartFeeCollector
        ) = campaignContract.getDates();
        if (endDate > block.timestamp) {
            // transfer to campaign
            token.transferFrom(payee, campaign, fee);
        } else {
            // take campaign fee
            uint256 jsFee = fee.mul(campaignFee).div(1e18 * 100); // 5% fee

            token.transferFrom(payee, jumpStartFeeCollector, jsFee);
            // transfer to admin
            token.transferFrom(payee, owner(), fee - jsFee);
        }
        return true;
    }

    function mintTickets(address minter, uint256 _numberOfTickets) private {
        IJumpStartTicket(ticketContract).mintTicket(minter, _numberOfTickets);
    }

    function setTicketContract(address _ticketContract) public onlyOwner {
        ticketContract = _ticketContract;
    }

    function disableWhitelist() public onlyOwner {
        whitelistEnabled = false;
    }

    // update maxMintPerWallet
    function updateMaxMintPerWallet(uint256 _maxMintPerWallet)
        public
        onlyOwner
    {
        maxMintPerWallet = _maxMintPerWallet;
    }

    // update maxMintPerTransaction
    function updateMaxMintPerTransaction(uint256 _maxMintPerTransaction)
        public
        onlyOwner
    {
        maxMintPerTransaction = _maxMintPerTransaction;
    }

    // update baseUri
    function updateBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    // batch methods
    function setCurrentBatch(
        uint256 quantity,
        uint256 price,
        bool active
    ) public onlyOwner {
        require(currentBatch.quantity == 0, "Current batch not finished.");

        currentBatch.quantity = quantity;
        currentBatch.active = active;
        currentBatch.price = price;
        mintLimit += quantity;

        emit NewBatchCreated(currentBatchIndex++);
    }

    function setCurrentBatchActive(bool active) public onlyOwner {
        currentBatch.active = active;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0 && !pfpEnabled ? string(abi.encodePacked(baseURI)) :
            pfpEnabled ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
    }
}