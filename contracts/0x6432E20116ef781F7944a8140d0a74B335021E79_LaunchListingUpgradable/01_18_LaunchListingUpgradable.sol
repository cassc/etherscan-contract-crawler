// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./ILaunchSettings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILaunchNfti {
    function purchase(
        address _to,
        uint256 _amount,
        uint256 _tokenId
    ) external payable;

    function batchPurchase(
        address _from,
        address _to,
        uint256 _amount,
        uint256[] memory tokenIds
    ) external payable;

    function curator() external returns (address);

    function fee() external returns (uint96);

    function ownerOf(uint256 _tokenId) external returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external returns (uint256 amountTransferred);
}

contract LaunchListingUpgradable is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    enum ContractType {
        FNFT,
        NFT
    }
    mapping(address => mapping(uint256 => uint256)) public fnftListing;
    mapping(address => mapping(uint256 => uint256)) public nftListing;
    address public launchSetting;
    event Purchase(
        address indexed tokenAddress,
        uint256 _amount,
        uint256 _tokenId,
        ContractType _purchaseType,
        address indexed _from,
        address indexed _to
    );
    event FNFTListed(
        address indexed fnft,
        uint256 nftId,
        address indexed _from,
        uint256 price,
        uint256 timestamp
    );
    event FNFTUnListed(
        address indexed fnft,
        uint256 nftId,
        address indexed _from,
        uint256 price,
        uint256 timestamp
    );
    event NFTListed(
        address indexed nft,
        uint256 nftId,
        address indexed _from,
        uint256 price,
        uint256 timestamp
    );
    event NFTUnListed(
        address indexed nft,
        uint256 nftId,
        address indexed _from,
        uint256 price,
        uint256 timestamp
    );

    function initialize(address _launchSetting) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        launchSetting = _launchSetting;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function addFnftToListing(
        address fnft,
        uint256 nftId,
        uint256 price
    ) public {
        require(
            IERC721Upgradeable(fnft).ownerOf(nftId) == msg.sender,
            "not owner of fnft"
        );
        if (nftId == 0) {
            require(
                IERC721Upgradeable(fnft).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
                "not approved"
            );
        } else {
            require(
                IERC721Upgradeable(fnft).getApproved(nftId) == address(this),
                "not approved"
            );
        }

        require(price >= 100000000000000, "price must be >= 100000000000000");
        fnftListing[fnft][nftId] = price;
        // if nftId is 0 then list all else list one
        emit FNFTListed(fnft, nftId, msg.sender, price, block.timestamp);
    }

    function removeFnftFromListing(address fnft, uint256 nftId) public {
        require(
            IERC721Upgradeable(fnft).ownerOf(nftId) == msg.sender,
            "not owner of fnft"
        );
        require(fnftListing[fnft][nftId] >= 100000000000000, "not listed");
        // if nftId is 0 then unlist all else unlist one
        unlistFNFTs(fnft, nftId);
    }

    function addNftToListing(
        address nft,
        uint256 nftId,
        uint256 price
    ) public {
        require(
            IERC721Upgradeable(nft).ownerOf(nftId) == msg.sender,
            "not owner of nft"
        );
        require(
            IERC721Upgradeable(nft).getApproved(nftId) == address(this),
            "not approved"
        );

        require(price >= 100000000000000, "price must be >= 100000000000000");
        nftListing[nft][nftId] = price;
        emit NFTListed(nft, nftId, msg.sender, price, block.timestamp);
    }

    function removeNftFromListing(address nft, uint256 nftId) public {
        require(
            IERC721Upgradeable(nft).ownerOf(nftId) == msg.sender,
            "not owner of nft"
        );
        require(nftListing[nft][nftId] >= 100000000000000, "not listed");
        unlistNFTs(nft, nftId);
    }

    function calculateRoyaltyFees(
        uint256 _salePrice,
        address _tokenAddress,
        uint256 _tokenId
    ) public view returns (uint256 _amount) {
        IERC2981 _token = IERC2981(_tokenAddress);
        (
            /*address _receiver*/
            ,
            uint256 _royaltyAmt
        ) = _token.royaltyInfo(_tokenId, _salePrice);

        return _royaltyAmt;
    }

    function getLatestPrice(address _feed) public view returns (int256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_feed);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // returning price in wei
        // Suppose feed is ETH/USD, then getting price like 116123220002
        // which means USD has 8 decimals so it will be 1ETH = 1161.23220002 USD
        // so if price of token is 0.5 ETH, then equivalent price with USD will be
        // 0.5 x 116123220002 OR (5000000000000000000 Wei x 116123220002) / 10 ** 8
        return price;
    }

    function purchaseNFTInETH(
        address _tokenAddress,
        uint256 _tokenId,
        ContractType _contractType
    ) external payable nonReentrant {
        address oldOwner = IERC721Upgradeable(_tokenAddress).ownerOf(_tokenId);
        uint256 _platformFee = ILaunchSettings(launchSetting).getPlatformFee(
            address(0)
        );
        // calculate platform fee amount
        uint256 _platformFeeAmt = (msg.value / 10000) * _platformFee;
        // calculate remaining amount
        uint256 _remainingAmt = msg.value - _platformFeeAmt;
        // deduct platform fee
        // transfer platform fee for NFT to receiver
        payable(ILaunchSettings(launchSetting).feeReceiverForNFT()).transfer(
            _platformFeeAmt
        );

        if (_contractType == ContractType.FNFT) {
            if (fnftListing[_tokenAddress][_tokenId] == 0) {
                require(fnftListing[_tokenAddress][0] > 0, "not listed");
                fnftListing[_tokenAddress][_tokenId] = fnftListing[
                    _tokenAddress
                ][0];
            }
            require(
                fnftListing[_tokenAddress][_tokenId] == msg.value,
                "invalid price"
            );

            require(
                address(msg.sender).balance >=
                    fnftListing[_tokenAddress][_tokenId],
                "insufficent funds"
            );

            ILaunchNfti launchNfti = ILaunchNfti(_tokenAddress);

            if (launchNfti.curator() != launchNfti.ownerOf(_tokenId)) {
                // deduct royalty
                uint256 _royaltyAmt = calculateRoyaltyFees(
                    _remainingAmt,
                    _tokenAddress,
                    _tokenId
                );

                uint256 _saleAmt = _remainingAmt - _royaltyAmt;

                // transfer _royaltyAmt to curator
                payable(launchNfti.curator()).transfer(_royaltyAmt);
                // transfer _saleAmt price to owner
                payable(launchNfti.ownerOf(_tokenId)).transfer(_saleAmt);
            } else {
                // transfer remainingAmt to owner/curator
                payable(launchNfti.ownerOf(_tokenId)).transfer(_remainingAmt);
            }
            launchNfti.safeTransferFrom(
                launchNfti.ownerOf(_tokenId),
                msg.sender,
                _tokenId,
                ""
            );

            unlistFNFTs(_tokenAddress, _tokenId);
        } else if (_contractType == ContractType.NFT) {
            if (nftListing[_tokenAddress][_tokenId] == 0) {
                require(nftListing[_tokenAddress][0] > 0, "not listed");
                nftListing[_tokenAddress][_tokenId] = nftListing[_tokenAddress][
                    0
                ];
            }
            require(
                nftListing[_tokenAddress][_tokenId] == msg.value,
                "invalid price"
            );
            require(
                address(msg.sender).balance >=
                    nftListing[_tokenAddress][_tokenId],
                "insufficent funds"
            );
            IERC721Upgradeable erc721Token = IERC721Upgradeable(_tokenAddress);
            address _owner = erc721Token.ownerOf(_tokenId);
            (bool sent, ) = _owner.call{value: _remainingAmt}("");
            require(sent, "tx failed");
            erc721Token.safeTransferFrom(_owner, msg.sender, _tokenId);
            unlistNFTs(_tokenAddress, _tokenId);
        }
        emit Purchase(
            _tokenAddress,
            msg.value,
            _tokenId,
            _contractType,
            oldOwner,
            msg.sender
        );
    }

    function purchaseNFT(
        address _feed,
        address _buyIn,
        address _tokenAddress,
        uint256 _tokenId,
        ContractType _contractType
    ) external nonReentrant {
        address oldOwner = IERC721Upgradeable(_tokenAddress).ownerOf(_tokenId);
        uint256 multiplier = uint256(getLatestPrice(_feed));
        if (_contractType == ContractType.FNFT) {
            if (fnftListing[_tokenAddress][_tokenId] == 0) {
                require(fnftListing[_tokenAddress][0] > 0, "Not listed");
                fnftListing[_tokenAddress][_tokenId] = fnftListing[
                    _tokenAddress
                ][0];
            }
            uint256 amt = (fnftListing[_tokenAddress][_tokenId] * multiplier) /
                10**18;
            require(
                IERC20(_buyIn).balanceOf(msg.sender) >= amt,
                "insufficent funds"
            );

            // approval address(this)
            require(
                IERC20(_buyIn).allowance(msg.sender, address(this)) >= amt,
                "amt not approved"
            );

            // deduct platform fee
            uint256 _platformFee = ILaunchSettings(launchSetting)
                .getPlatformFee(_buyIn);
            // calculate platform fee amount
            uint256 _platformFeeAmt = (amt / 10000) * _platformFee;
            // calculate remaining amount
            uint256 _remainingAmt = amt - _platformFeeAmt;

            // transfer platform fee for NFT to receiver
            IERC20(_buyIn).transferFrom(
                msg.sender,
                ILaunchSettings(launchSetting).feeReceiverForNFT(),
                _platformFeeAmt
            );

            ILaunchNfti launchNfti = ILaunchNfti(_tokenAddress);

            if (launchNfti.curator() != launchNfti.ownerOf(_tokenId)) {
                // deduct royalty
                uint256 _royaltyAmt = calculateRoyaltyFees(
                    _remainingAmt,
                    _tokenAddress,
                    _tokenId
                );

                uint256 _saleAmt = _remainingAmt - _royaltyAmt;

                // transfer _royaltyAmt to curator
                IERC20(_buyIn).transferFrom(
                    msg.sender,
                    launchNfti.curator(),
                    _royaltyAmt
                );

                // transfer _saleAmt price to owner
                IERC20(_buyIn).transferFrom(
                    msg.sender,
                    launchNfti.ownerOf(_tokenId),
                    _saleAmt
                );
            } else {
                // transfer remainingAmt to owner/curator
                IERC20(_buyIn).transferFrom(
                    msg.sender,
                    launchNfti.ownerOf(_tokenId),
                    _remainingAmt
                );
            }
            launchNfti.safeTransferFrom(
                launchNfti.ownerOf(_tokenId),
                msg.sender,
                _tokenId,
                ""
            );

            unlistFNFTs(_tokenAddress, _tokenId);
            emit Purchase(
                _tokenAddress,
                amt,
                _tokenId,
                _contractType,
                oldOwner,
                msg.sender
            );
        } else if (_contractType == ContractType.NFT) {
            if (nftListing[_tokenAddress][_tokenId] == 0) {
                require(nftListing[_tokenAddress][0] > 0, "not listed");
                nftListing[_tokenAddress][_tokenId] = nftListing[_tokenAddress][
                    0
                ];
            }
            uint256 amt = (nftListing[_tokenAddress][_tokenId] * multiplier) /
                10**18;

            require(
                IERC20(_buyIn).balanceOf(msg.sender) >= amt,
                "insufficent funds"
            );

            // approval address(this)
            require(
                IERC20(_buyIn).allowance(msg.sender, address(this)) >= amt,
                "amt not approved"
            );

            // deduct platform fee
            uint256 _platformFee = ILaunchSettings(launchSetting)
                .getPlatformFee(_buyIn);
            // calculate platform fee amount
            uint256 _platformFeeAmt = (amt / 10000) * _platformFee;
            // calculate remaining amount
            uint256 _remainingAmt = amt - _platformFeeAmt;

            // transfer platform fee for NFT to receiver
            IERC20(_buyIn).transferFrom(
                msg.sender,
                ILaunchSettings(launchSetting).feeReceiverForNFT(),
                _platformFeeAmt
            );

            IERC721Upgradeable erc721Token = IERC721Upgradeable(_tokenAddress);
            address _owner = erc721Token.ownerOf(_tokenId);

            IERC20(_buyIn).transferFrom(msg.sender, _owner, _remainingAmt);

            erc721Token.safeTransferFrom(_owner, msg.sender, _tokenId);
            unlistNFTs(_tokenAddress, _tokenId);
            emit Purchase(
                _tokenAddress,
                amt,
                _tokenId,
                _contractType,
                oldOwner,
                msg.sender
            );
        }
    }

    function unlistFNFTs(address _nftAddress, uint256 _tokenId) private {
        uint256 _listingPrice = fnftListing[_nftAddress][_tokenId];
        delete fnftListing[_nftAddress][_tokenId];
        emit FNFTUnListed(
            _nftAddress,
            _tokenId,
            msg.sender,
            _listingPrice,
            block.timestamp
        );
    }

    function unlistNFTs(address _nftAddress, uint256 _tokenId) private {
        uint256 _listingPrice = nftListing[_nftAddress][_tokenId];
        delete nftListing[_nftAddress][_tokenId];
        emit NFTUnListed(
            _nftAddress,
            _tokenId,
            msg.sender,
            _listingPrice,
            block.timestamp
        );
    }
}