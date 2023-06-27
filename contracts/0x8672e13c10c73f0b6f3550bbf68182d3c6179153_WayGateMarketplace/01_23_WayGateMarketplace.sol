// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// binance/polygon/
// On Deployment use Specific values for Enums as Like (0,1,2,3)
// Lock Bidder Value

import "./interfaces/IWGNFT.sol";
import "./WayGateRoyalties.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

contract WayGateMarketplace is WayGateRoyalties {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    address MARKETPLACE_ADMIN_WALLET;

    address WAYGATE_ERC721_TOKEN_ADDRESS;
    address WAYGATE_ERC1155_TOKEN_ADDRESS;

    uint256 serviceFeePercentage;
    uint256 airdropFeePercentage;
    uint256 serviceFeeFor2DNFT;
    uint256 serviceFeeFor3DNFT;
    uint256 specialNftDiscountPercentage;

    event NftonFixedPrice(
        address owner,
        bytes32 nftListingIdHash,
        uint256 timestamp,
        uint256 nftID,
        uint256 copies,
        uint256 Price,
        NftType nftStatus
    );

    event NftOnAuction(
        address owner,
        bytes32 nftListingIdHash,
        uint256 timestamp,
        uint256 nftId,
        uint256 copies,
        uint256 Price,
        NftType nftStatus,
        string
    );

    event AdminSettingsUpdated(
        uint256 airdropFee,
        uint256 _serviceFeeFor2DNFT,
        uint256 _serviceFeeFor3DNFT,
        uint256 specialDiscountFee,
        uint256 royaltyFee
    );

    event SellerAmountTransferred(address seller, uint256 amount);
    event RoyaltyTransferred(address seller, uint256 amount);
    event NFTClaimed(uint256 bidAmount, address receiver, uint256 copies);
    event NFTSold(address from, address to, uint256 nftID);
    event NftUnlisted(address owner, uint256 nftID);
    event ServiceFeeTransferred(uint256 amount);
    event RemovedFormSale(uint256, string);

    modifier notOnSale(bytes32 _nftListingIdHash) {
        require(
            nftListingIdDetail[_nftListingIdHash].saleStatus ==
                SaleTypeChoice.NotOnSale,
            "WayGate: Already on Sale"
        );
        _;
    }
    modifier onAuction(bytes32 _nftListingIdHash) {
        require(
            nftListingIdDetail[_nftListingIdHash].saleStatus ==
                SaleTypeChoice.onAuction,
            "WayGate: Not on Auction"
        );
        _;
    }
    modifier onFixedPrice(bytes32 _nftListingIdHash) {
        require(
            nftListingIdDetail[_nftListingIdHash].saleStatus ==
                SaleTypeChoice.OnfixedPrice,
            "WayGate: Not on Fixed Price"
        );
        _;
    }

    modifier platformAddressesSet() {
        require(
            MARKETPLACE_ADMIN_WALLET != address(0) &&
                WAYGATE_ERC721_TOKEN_ADDRESS != address(0) &&
                WAYGATE_ERC1155_TOKEN_ADDRESS != address(0),
            "WayGate: Platform Addresses Not Set"
        );
        _;
    }
    modifier onlyAdmin() {
        require(
            MARKETPLACE_ADMIN_WALLET == _msgSender(),
            "WayGate: Access Denied"
        );
        _;
    }

    function initialize() public override initializer {
        __Ownable_init();
        WayGateRoyalties.initialize();
    }

    function listNFTForFixedPrice(
        uint256 _tokenId,
        uint256 _price,
        uint256 _copies,
        uint256 _saleTokenType,
        address _hostContract
    ) external platformAddressesSet {
        _selectNftContractType(_tokenId, _copies, _hostContract);
        bytes32 _nftListingIdHash = keccak256(
            abi.encodePacked(
                _tokenId,
                _hostContract,
                _msgSender(),
                block.timestamp
            )
        );
        nftListingIdDetail[_nftListingIdHash].seller = _msgSender();
        nftListingIdDetail[_nftListingIdHash].hostContract = _hostContract;
        nftListingIdDetail[_nftListingIdHash].tokenId = _tokenId;
        nftListingIdDetail[_nftListingIdHash].price = _price;
        nftListingIdDetail[_nftListingIdHash].copies = _copies;
        nftListingIdDetail[_nftListingIdHash].saleStatus = SaleTypeChoice(2);
        nftListingIdDetail[_nftListingIdHash].saleTokenType = SaleTokenType(
            _saleTokenType
        );
        if (
            _hostContract == WAYGATE_ERC721_TOKEN_ADDRESS ||
            _hostContract == WAYGATE_ERC1155_TOKEN_ADDRESS
        ) {
            _platformNftTypeStatus(_tokenId, _hostContract, _nftListingIdHash);
        }
        _transferNftToMarketplace(_hostContract, _tokenId, _nftListingIdHash);
        emit NftonFixedPrice(
            _msgSender(),
            _nftListingIdHash,
            block.timestamp,
            _tokenId,
            _copies,
            _price,
            nftType
        );
    }

    function listNFTForTimedAuction(
        uint256 _tokenId,
        uint32 _startTime,
        uint32 _endTime,
        uint256 _price,
        uint256 _saleTokenType,
        address _hostContract
    ) external platformAddressesSet {
        require(
            _startTime != _endTime &&
                block.timestamp < _endTime &&
                _startTime < _endTime,
            "WayGate: Time Error"
        );
        require(_endTime > _startTime + 86400, "WayGate: Minimum time limit");
        require(
            !(
                IERC165Upgradeable(_hostContract).supportsInterface(
                    type(IERC1155Upgradeable).interfaceId
                )
            ),
            "WAYGATE: 1155 Auctions Unsupported"
        );
        _selectNftContractType(_tokenId, 1, _hostContract);
        bytes32 _nftListingIdHash = keccak256(
            abi.encodePacked(
                _tokenId,
                _hostContract,
                _msgSender(),
                block.timestamp
            )
        );
        nftListingIdDetail[_nftListingIdHash].seller = _msgSender();
        nftListingIdDetail[_nftListingIdHash].hostContract = _hostContract;
        nftListingIdDetail[_nftListingIdHash].startTime = _startTime;
        nftListingIdDetail[_nftListingIdHash].endTime = _endTime;
        nftListingIdDetail[_nftListingIdHash].tokenId = _tokenId;
        nftListingIdDetail[_nftListingIdHash].price = _price;
        nftListingIdDetail[_nftListingIdHash].copies = 1;
        nftListingIdDetail[_nftListingIdHash].saleStatus = SaleTypeChoice(1);
        nftListingIdDetail[_nftListingIdHash].saleTokenType = SaleTokenType(
            _saleTokenType
        );

        if (_hostContract == WAYGATE_ERC721_TOKEN_ADDRESS) {
            _platformNftTypeStatus(_tokenId, _hostContract, _nftListingIdHash);
        }

        _transferNftToMarketplace(_hostContract, _tokenId, _nftListingIdHash);

        emit NftOnAuction(
            _msgSender(),
            _nftListingIdHash,
            block.timestamp,
            _tokenId,
            1,
            _price,
            nftType,
            "Accepting Bids for Timed Auction"
        );
    }

    function unlistNFT(bytes32 _nftListingIdHash) external {
        require(
            nftListingIdDetail[_nftListingIdHash].saleStatus !=
                SaleTypeChoice(0),
            "WayGate: Not Listed"
        );
        require(
            nftListingIdDetail[_nftListingIdHash].seller == _msgSender(),
            "WayGate: Insufficient Allowance"
        );
        if (
            nftListingIdDetail[_nftListingIdHash].saleStatus ==
            SaleTypeChoice(1)
        ) {
            require(
                nftListingIdDetail[_nftListingIdHash].bidderAddress ==
                    address(0),
                "WayGate: Bids Found"
            );
        }
        _unlistNft(_nftListingIdHash);
        delete nftListingIdDetail[_nftListingIdHash];
    }

    function addAuctionBid(
        uint256 _bidAmount,
        bytes32 _nftListingIdHash
    ) external payable onAuction(_nftListingIdHash) {
        require(
            nftListingIdDetail[_nftListingIdHash].saleTokenType ==
                SaleTokenType.nativeBlockchainToken,
            "WayGate: Not a Native Token"
        );
        uint minBidAmount = getHighestBid(_nftListingIdHash);
        require(
            _bidAmount > minBidAmount && msg.value == _bidAmount,
            "WayGate: Bid Amount < Minimum Bid Amount"
        );
        _addAuctionBid(_bidAmount, _nftListingIdHash);
    }

    function addAuctionBidWithWayGateTokens(
        uint256 _bidAmount,
        bytes32 _nftListingIdHash
    ) external onAuction(_nftListingIdHash) {
        require(
            nftListingIdDetail[_nftListingIdHash].saleTokenType ==
                SaleTokenType.utilityWayGateToken,
            "WayGate: Invalud Token"
        );
        require(
            getAllowance() >= _bidAmount,
            "WayGate: Insufficient Allowance"
        );
        uint minBidAmount = getHighestBid(_nftListingIdHash);
        require(
            _bidAmount > minBidAmount,
            "WayGate: Bid Amount < Minimum Bid Amount"
        );
        _addAuctionBid(_bidAmount, _nftListingIdHash);
    }

    function _addAuctionBid(
        uint256 _bidAmount,
        bytes32 _nftListingIdHash
    ) internal nonReentrant {
        require(
            nftListingIdDetail[_nftListingIdHash].seller != _msgSender(),
            "WayGate: Cannot self Bid"
        );
        require(
            block.timestamp < nftListingIdDetail[_nftListingIdHash].endTime,
            "WayGate: Auction Time Over"
        );
        if (nftListingIdDetail[_nftListingIdHash].bidderAddress != address(0)) {
            uint256 lastBidAmount = nftListingIdDetail[_nftListingIdHash]
                .bidAmount;
            address lastHighestBiderAddress = nftListingIdDetail[
                _nftListingIdHash
            ].bidderAddress;
            require(
                _bidAmount > lastBidAmount,
                "WayGate: Bid Amount < Minimum Bid Amount"
            );
            _transferAmountToSeller(
                _nftListingIdHash,
                lastBidAmount,
                payable(lastHighestBiderAddress)
            );
        }
        nftListingIdDetail[_nftListingIdHash].bidAmount = _bidAmount;
        nftListingIdDetail[_nftListingIdHash].bidderAddress = _msgSender();
        if (
            nftListingIdDetail[_nftListingIdHash].saleTokenType ==
            SaleTokenType.utilityWayGateToken
        ) {
            wayGateToken.transferFrom(_msgSender(), address(this), _bidAmount);
        }
    }

    function claimNft(bytes32 _nftListingIdHash) external {
        nftListingIdDetail[_nftListingIdHash].bidderAddress != address(0);
        address highestBiderAddress = getHighestBidder(_nftListingIdHash);
        require(
            highestBiderAddress == _msgSender(),
            "WayGate: Only Highest Bidder can Claim"
        );

        _claimNft(_nftListingIdHash);
    }

    function checkNftSaleStatus(
        bytes32 _nftListingIdHash
    ) external view returns (SaleTypeChoice) {
        return nftListingIdDetail[_nftListingIdHash].saleStatus;
    }

    function buyNFTForFixedPrice(
        uint256 copies,
        bytes32 _nftListingIdHash
    ) external payable onFixedPrice(_nftListingIdHash) {
        require(
            nftListingIdDetail[_nftListingIdHash].saleTokenType ==
                SaleTokenType.nativeBlockchainToken,
            "WayGate: Invalid Token"
        );
        _buyNFTforFixedPrice(msg.value, copies, _nftListingIdHash);
    }

    function buyNFTForFixedPriceWithWayGateTokens(
        uint256 _tokenAmount,
        uint256 copies,
        bytes32 _nftListingIdHash
    ) external onFixedPrice(_nftListingIdHash) {
        require(
            nftListingIdDetail[_nftListingIdHash].saleTokenType ==
                SaleTokenType.utilityWayGateToken,
            "WayGate: Invalid Token"
        );
        require(
            getAllowance() >= _tokenAmount,
            "WayGate: Insufficient Allowance"
        );
        _buyNFTforFixedPrice(_tokenAmount, copies, _nftListingIdHash);
    }

    function _buyNFTforFixedPrice(
        uint256 _tokenAmount,
        uint256 copies,
        bytes32 _nftListingIdHash
    ) internal {
        uint256 uintPrice = _tokenAmount / copies;
        require(
            uintPrice == nftListingIdDetail[_nftListingIdHash].price,
            "WayGate: Insufficient Amount"
        );

        require(
            nftListingIdDetail[_nftListingIdHash].seller != _msgSender(),
            "WayGate: Cannot Self Buy NFT"
        );
        _transferNftAndFeeHandler(
            nftListingIdDetail[_nftListingIdHash].hostContract,
            nftListingIdDetail[_nftListingIdHash].tokenId,
            _msgSender(),
            _tokenAmount,
            copies,
            _nftListingIdHash
        );
    }

    function clearClaimableTokens(
        bytes32[] calldata _nftListingIdHash
    ) external onlyAdmin {
        for (uint256 i = 0; i < _nftListingIdHash.length; i++) {
            _claimNft(_nftListingIdHash[i]);
        }
    }

    function getRoyaltiesStatus(
        address _hostContract
    ) internal view returns (bool) {
        bool success = ERC721Upgradeable(_hostContract).supportsInterface(
            _INTERFACE_ID_ERC2981
        );
        return success;
    }

    function _claimNft(
        bytes32 _nftListingIdHash
    ) internal onAuction(_nftListingIdHash) {
        address highestBiderAddress = getHighestBidder(_nftListingIdHash);

        if (highestBiderAddress != address(0)) {
            uint256 highestBidAmount = getHighestBid(_nftListingIdHash);
            _transferNftAndFeeHandler(
                nftListingIdDetail[_nftListingIdHash].hostContract,
                nftListingIdDetail[_nftListingIdHash].tokenId,
                highestBiderAddress,
                highestBidAmount,
                1,
                _nftListingIdHash
            );

            emit NFTClaimed(
                highestBidAmount,
                highestBiderAddress,
                nftListingIdDetail[_nftListingIdHash].copies
            );
        } else {
            _unlistNft(_nftListingIdHash);
        }
        delete nftListingIdDetail[_nftListingIdHash];
    }

    function _unlistNft(bytes32 _nftListingIdHash) internal nonReentrant {
        address _hostContract = nftListingIdDetail[_nftListingIdHash]
            .hostContract;
        uint256 _tokenId = nftListingIdDetail[_nftListingIdHash].tokenId;
        if (
            IERC165Upgradeable(_hostContract).supportsInterface(
                type(IERC721Upgradeable).interfaceId
            )
        ) {
            ERC721Upgradeable nftContract721 = ERC721Upgradeable(_hostContract);
            nftContract721.safeTransferFrom(
                address(this),
                nftListingIdDetail[_nftListingIdHash].seller,
                _tokenId
            );
        } else {
            ERC1155Upgradeable nftContract1155 = ERC1155Upgradeable(
                _hostContract
            );
            nftContract1155.safeTransferFrom(
                address(this),
                nftListingIdDetail[_nftListingIdHash].seller,
                _tokenId,
                nftListingIdDetail[_nftListingIdHash].copies,
                "0x00"
            );
        }
        emit NftUnlisted(_msgSender(), _tokenId);
    }

    function _transferNftAndFeeHandler(
        address _hostContract,
        uint256 _tokenId,
        address _buyerAddress,
        uint256 _price,
        uint256 _copies,
        bytes32 _nftListingIdHash
    ) internal nonReentrant {
        if (
            nftListingIdDetail[_nftListingIdHash].saleStatus ==
            SaleTypeChoice.OnfixedPrice &&
            nftListingIdDetail[_nftListingIdHash].saleTokenType ==
            SaleTokenType.utilityWayGateToken
        ) {
            wayGateToken.transferFrom(_msgSender(), address(this), _price);
        }
        address royaltyReceiver;
        uint royaltyAmount;
        if (getRoyaltiesStatus(_hostContract)) {
            (royaltyReceiver, royaltyAmount) = IERC2981Upgradeable(
                _hostContract
            ).royaltyInfo(_tokenId, _price);
        }
        if (
            nftListingIdDetail[_nftListingIdHash].nftTokenTypeStatus ==
            NftTokenType.airdropNFT
        ) {
            _royaltyAndWayGateNFTFee(
                _nftListingIdHash,
                _price,
                royaltyAmount,
                payable(royaltyReceiver),
                payable(nftListingIdDetail[_nftListingIdHash].seller),
                airdropFeePercentage
            );
        }
        if (
            nftListingIdDetail[_nftListingIdHash].nftTokenTypeStatus ==
            NftTokenType.specialNFT
        ) {
            _royaltyAndWayGateNFTFee(
                _nftListingIdHash,
                _price,
                royaltyAmount,
                payable(royaltyReceiver),
                payable(nftListingIdDetail[_nftListingIdHash].seller),
                specialNftDiscountPercentage
            );
        }
        if (
            nftListingIdDetail[_nftListingIdHash].nftTokenTypeStatus ==
            NftTokenType.simpleNFT
        ) {
            if (
                nftListingIdDetail[_nftListingIdHash].nftTypeStatus ==
                NftType.TYPE_2D
            )
                _royaltyAndWayGateNFTFee(
                    _nftListingIdHash,
                    _price,
                    royaltyAmount,
                    payable(royaltyReceiver),
                    payable(nftListingIdDetail[_nftListingIdHash].seller),
                    serviceFeeFor2DNFT
                );
            if (
                nftListingIdDetail[_nftListingIdHash].nftTypeStatus ==
                NftType.TYPE_3D
            )
                _royaltyAndWayGateNFTFee(
                    _nftListingIdHash,
                    _price,
                    royaltyAmount,
                    payable(royaltyReceiver),
                    payable(nftListingIdDetail[_nftListingIdHash].seller),
                    serviceFeeFor3DNFT
                );
        }
        if (
            IERC165Upgradeable(_hostContract).supportsInterface(
                type(IERC721Upgradeable).interfaceId
            )
        ) {
            ERC721Upgradeable nftContract721 = ERC721Upgradeable(_hostContract);

            require(_copies == 1, "ERC721: Does Not Support Copies");
            nftContract721.safeTransferFrom(
                address(this),
                _buyerAddress,
                _tokenId
            );

            delete nftListingIdDetail[_nftListingIdHash];
        } else {
            ERC1155Upgradeable nftContract1155 = ERC1155Upgradeable(
                _hostContract
            );
            require(
                _copies <= nftListingIdDetail[_nftListingIdHash].copies,
                "WayGate: Copies not Available"
            );
            require(
                _price == nftListingIdDetail[_nftListingIdHash].price * _copies,
                "WayGate: Insufficient Copies"
            );
            nftContract1155.safeTransferFrom(
                address(this),
                _buyerAddress,
                _tokenId,
                _copies,
                "0x00"
            );
            uint256 remainingCopies = nftListingIdDetail[_nftListingIdHash]
                .copies - _copies;
            if (remainingCopies != 0) {
                nftListingIdDetail[_nftListingIdHash].copies = remainingCopies;
            } else {
                delete nftListingIdDetail[_nftListingIdHash];
            }
        }
    }

    function _transferNftToMarketplace(
        address _hostContract,
        uint256 _tokenId,
        bytes32 _nftListingIdHash
    ) internal nonReentrant {
        if (
            IERC165Upgradeable(_hostContract).supportsInterface(
                type(IERC721Upgradeable).interfaceId
            )
        ) {
            ERC721Upgradeable nftContract721 = ERC721Upgradeable(_hostContract);
            nftContract721.safeTransferFrom(
                nftContract721.ownerOf(_tokenId),
                address(this),
                _tokenId
            );

            nftContract721.approve(_msgSender(), _tokenId);
            nftContract721.approve(MARKETPLACE_ADMIN_WALLET, _tokenId);
        } else {
            ERC1155Upgradeable nftContract1155 = ERC1155Upgradeable(
                _hostContract
            );

            nftContract1155.safeTransferFrom(
                nftListingIdDetail[_nftListingIdHash].seller,
                address(this),
                _tokenId,
                nftListingIdDetail[_nftListingIdHash].copies,
                "0x00"
            );
            nftContract1155.setApprovalForAll(_msgSender(), true);
            nftContract1155.setApprovalForAll(MARKETPLACE_ADMIN_WALLET, true);
        }
    }

    function _selectNftContractType(
        uint256 _tokenId,
        uint256 _copies,
        address _hostContract
    ) internal view {
        if (
            IERC165Upgradeable(_hostContract).supportsInterface(
                type(IERC721Upgradeable).interfaceId
            )
        ) {
            ERC721Upgradeable nftContract721 = ERC721Upgradeable(_hostContract);
            require(_copies == 1, "WayGate: ERC721 doesn't support copies");
            require(
                nftContract721.ownerOf(_tokenId) == _msgSender(),
                "WayGate: Not an Owner"
            );
        } else {
            ERC1155Upgradeable nftContract1155 = ERC1155Upgradeable(
                _hostContract
            );
            require(
                nftContract1155.balanceOf(_msgSender(), _tokenId) >= _copies &&
                    _copies > 0,
                "ERC1155: Not enough copies"
            );
        }
    }

    function _platformNftTypeStatus(
        uint256 _tokenId,
        address _hostContract,
        bytes32 _nftListingIdHash
    ) internal {
        nftType = NftType(IWGNFT(_hostContract).getNftTypeStatus(_tokenId));
        nftListingIdDetail[_nftListingIdHash].nftTypeStatus = nftType;
        if (_hostContract == WAYGATE_ERC721_TOKEN_ADDRESS) {
            if (IWGNFT(_hostContract).getWhitelistTokenIdStatus(_tokenId)) {
                nftListingIdDetail[_nftListingIdHash]
                    .nftTokenTypeStatus = NftTokenType.airdropNFT;
            }
            if (IWGNFT(_hostContract).getSpecialNftTokenIdStatus(_tokenId)) {
                nftListingIdDetail[_nftListingIdHash]
                    .nftTokenTypeStatus = NftTokenType.specialNFT;
            }
        }
    }

    function setAdminSettings(
        uint256 _airdropPercentage,
        uint256 _serviceFeeFor2DNFT,
        uint256 _serviceFeeFor3DNFT,
        uint256 _specialNftDiscountPercentage,
        uint256 _maxRoyaltyPercentage,
        address _hostContract
    ) external onlyOwner {
        airdropFeePercentage = _airdropPercentage;
        serviceFeeFor2DNFT = _serviceFeeFor2DNFT;
        serviceFeeFor3DNFT = _serviceFeeFor3DNFT;
        specialNftDiscountPercentage = _specialNftDiscountPercentage;
        IWGNFT(_hostContract).setMaxRoyaltyPercentage(_maxRoyaltyPercentage);
        emit AdminSettingsUpdated(
            _airdropPercentage,
            _serviceFeeFor2DNFT,
            _serviceFeeFor3DNFT,
            _specialNftDiscountPercentage,
            _maxRoyaltyPercentage
        );
    }

    function setPlatformTokenContractAddress(
        address _erc721,
        address _erc1155
    ) external onlyOwner {
        require(
            _erc721 != address(0) && _erc1155 != address(0),
            "WayGate: Invalid Address"
        );
        require(
            IERC165Upgradeable(_erc721).supportsInterface(
                type(IERC721Upgradeable).interfaceId
            ),
            "WayGate721: Invalid Address"
        );
        require(
            IERC165Upgradeable(_erc1155).supportsInterface(
                type(IERC1155Upgradeable).interfaceId
            ),
            "WayGate1155: Invalid Address"
        );

        WAYGATE_ERC721_TOKEN_ADDRESS = _erc721;
        WAYGATE_ERC1155_TOKEN_ADDRESS = _erc1155;
    }

    function setMarketplaceAdminWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "WayGate: Invalid Address");
        MARKETPLACE_ADMIN_WALLET = _wallet;
    }

    function getListingId(
        uint256 _tokenId,
        address _hostContract,
        uint256 timestamp,
        address _seller
    ) external view returns (bytes32) {
        bytes32 _nftListingIdHash = keccak256(
            abi.encodePacked(_tokenId, _hostContract, _seller, timestamp)
        );
        require(
            nftListingIdDetail[_nftListingIdHash].saleStatus !=
                SaleTypeChoice.NotOnSale,
            "WayGate: Not on Sale"
        );
        return _nftListingIdHash;
    }

    function getNFTListingDetails(
        bytes32 _nftListingIdHash
    ) external view returns (NFTDetails memory) {
        return nftListingIdDetail[_nftListingIdHash];
    }

    function getHighestBidder(
        bytes32 _nftListingIdHash
    ) public view returns (address) {
        require(
            block.timestamp > nftListingIdDetail[_nftListingIdHash].endTime,
            "WayGate: Auction Time Not Over"
        );
        if (nftListingIdDetail[_nftListingIdHash].bidderAddress != address(0)) {
            address currentHighestBidder = nftListingIdDetail[_nftListingIdHash]
                .bidderAddress;
            return currentHighestBidder;
        } else {
            return address(0);
        }
    }

    function getHighestBid(
        bytes32 _nftListingIdHash
    ) public view onAuction(_nftListingIdHash) returns (uint256) {
        if (nftListingIdDetail[_nftListingIdHash].bidderAddress == address(0)) {
            return nftListingIdDetail[_nftListingIdHash].price;
        } else {
            uint256 currentHighestBid = nftListingIdDetail[_nftListingIdHash]
                .bidAmount;
            return currentHighestBid;
        }
    }

    function getWayGate721ContractAddress() external view returns (address) {
        return WAYGATE_ERC721_TOKEN_ADDRESS;
    }

    function getServiceFeeFor2DNFT() external view returns (uint256) {
        return serviceFeeFor2DNFT;
    }

    function getServiceFeeFor3DNFT() external view returns (uint256) {
        return serviceFeeFor3DNFT;
    }

    function getWayGate1155ContractAddress() external view returns (address) {
        return WAYGATE_ERC1155_TOKEN_ADDRESS;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    fallback() external payable {}

    receive() external payable {}
}