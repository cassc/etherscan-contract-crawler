//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ShibaFriendPet.sol";
import "./external/AggregatorV3Interface.sol";
import "./SHFAffiliate.sol";

contract SHFStore is AccessControlUpgradeable, PausableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.AddressSet private acceptedNFTs;

    enum SaleStatus { Ongoing, Expired }

    struct PetSale {
        address nftContractAddress;
        uint128 price;
        uint64 startedAt;
        SaleStatus status;
        uint64 batchId;
        uint64 tier;
        uint32 limit;
        uint32 bought;
    }
    event SaleCreated(address nftContractAddress, uint256 price, uint64 startedAt, SaleStatus status, uint64 batchId, uint64 tier);
    event SaleEnded(address nftContractAddress, uint64 batchId, uint64 tier);
    // event SaleSuccessful(uint256 indexed _tokenId, uint256 _price);

    PetSale[] PetSales;
    uint256[] private toBeDeleted;

    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    AggregatorV3Interface internal bnbPriceFeed;
    address binanceUSD;

    // Affiliate system
    SHFAffiliate private shfAffiliate;

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();
    }

    function allowNFTContract(address _nftContractAddress)
        external
        returns(bool)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFStore: Caller is not an admin"
        );
        require(IERC721(_nftContractAddress).supportsInterface(type(IERC721).interfaceId), "SHFStore: Contract should be ERC721");
        return acceptedNFTs.add(_nftContractAddress);
    }

    function disallowNFTContract(address _nftContractAddress)
        external
        returns(bool)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFStore: Caller is not an admin"
        );
        return acceptedNFTs.remove(_nftContractAddress);
    }

    function setBUSDCurrency(address currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        binanceUSD = currencyAddress;
    }

    function setAffiliate(address _shfAffiliate) 
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "DEFI: Caller is not an admin"
        );
        shfAffiliate = SHFAffiliate(_shfAffiliate);
    }

    /*
        @dev This function will mint a pet of a sale with referral code
        Requirements:
        - NFT contract address is allowed
        - saleId is existed
    */
    function buyWithAffiliate(
        address _nftContractAddress,
        uint64 _saleId,
        address _currency,
        uint32 _referrerCode
    )
        external
        payable
    {
        uint256 petSalePrice = _buy(_nftContractAddress, _saleId, _currency);

        // BEGIN: Referral system
        // If _referralCode is good and referrer of user not exist
        if (shfAffiliate.checkReferralCode(_referrerCode) == 0 && !shfAffiliate.hasReferrerTier1ForStore(msg.sender)) {
            shfAffiliate.addReferrer(msg.sender, _referrerCode);
        }
        // Check referral information of user
        if (shfAffiliate.hasReferrerTier1ForStore(msg.sender)) {
            
            uint32 affCodeTier1 = shfAffiliate.getReferrerCodeTier1ForStore(msg.sender);
            _payCommisionReferral(shfAffiliate.getAddressOfCode(affCodeTier1), petSalePrice, _currency, _saleId, shfAffiliate.getEarningRateLv1());

            if (shfAffiliate.hasReferrerTier2ForStore(msg.sender)) {
                uint32 affCodeTier2 = shfAffiliate.getReferrerCodeTier2ForStore(msg.sender);
                _payCommisionReferral(shfAffiliate.getAddressOfCode(affCodeTier2), petSalePrice, _currency, _saleId, shfAffiliate.getEarningRateLv2());
            }
        }
    }

        /*
        @dev This function will mint a pet of a sale with referral code
        Requirements:
        - NFT contract address is allowed
        - saleId is existed
    */
    function _payCommisionReferral(
        address _receiver,
        uint256 _price,
        address _currency,
        uint64 _saleId,
        uint rate
    )
        internal
    {
        uint256 price = _price * rate / 100;
        if (_currency == address(0)) {
            //Native currency
            payable(_receiver).transfer(price);
        } else{
            // IERC20 currency
            IERC20(_currency).transfer(_receiver, price);
        }
        PetSale storage petSale = PetSales[_saleId];

        shfAffiliate.addBuyCommisionHistory(_receiver, petSale.price * rate / 100);
    }

    /*
        @dev This function will mint a pet of a sale
        Requirements:
        - NFT contract address is allowed
        - saleId is existed
    */
    function buy(
        address _nftContractAddress,
        uint64 _saleId,
        address _currency
    )
        external
        payable
    {
        _buy(_nftContractAddress, _saleId, _currency);
    }

    function _buy(
        address _nftContractAddress,
        uint64 _saleId,
        address _currency
    )
        internal
        returns(uint256)
    {
        PetSale storage petSale = PetSales[_saleId];
        require(acceptedNFTs.contains(_nftContractAddress), "SHFStore: contract address not allowed");
        require(petSale.status == SaleStatus.Ongoing, "SHFStore: Sale must be on going");
        require((_currency == address(0)) || (_currency == binanceUSD), "SHFStore: Currency not allowed");
        require(petSale.limit > petSale.bought, "SHFStore: sale reached limit");
        // mint and transfer nft to buyer
        // TODO: Fix rate of ERC20
        uint256 petSalePrice = petSale.price;
        if (_currency == address(0)) {
            //Native currency
            petSalePrice = getLatestPrice(petSale.price);
            require(msg.value >= petSalePrice, "SHFStore: Not enough balance");
        } else{
            // IERC20 currency
            petSalePrice = petSale.price * 10**18;
            IERC20(_currency).transferFrom(msg.sender, address(this), petSalePrice);
        }
        petSale.bought++;
        ShibaFriendPet(_nftContractAddress).mintBuy(msg.sender, petSale.tier,petSale.batchId);

        // End Sale
        if (petSale.bought == petSale.limit) {
            emit SaleEnded(_nftContractAddress, petSale.batchId, petSale.tier);
        }
        return petSalePrice;
    }

    /*
        @dev This function will mint a pet of a sale for airdrop
        Requirements:
        - msg sender will be airdrop
    */
    function airdrop(
        address _nftContractAddress,
        uint64 _tier, // For random the design
        address _repicient
    )
        external
        payable
    {
        require(acceptedNFTs.contains(_nftContractAddress), "SHFStore: contract address not allowed");
        require(
            hasRole(AIRDROP_ROLE, msg.sender),
            "SHFStore: Caller is not an airdroper"
        );
        uint _saleId = getRandomSaleId(_tier);
        ShibaFriendPet(_nftContractAddress).mintBuy(_repicient, PetSales[_saleId].tier,PetSales[_saleId].batchId);
    }

    function getRandomSaleId(uint64 _tier)
        internal
        view
        returns (uint _saleId)
    {
        uint[] memory listSales = new uint[](PetSales.length);
        uint saleLength;
        for (uint i=0; i<PetSales.length; i++) {
           if(PetSales[i].status == SaleStatus.Ongoing && PetSales[i].tier == _tier){
               listSales[saleLength] = i;
               saleLength++;
           }
        }
        uint randomHash = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, uint(0))));
        uint randomNumber = randomHash % saleLength;
        return listSales[randomNumber];
    }

    function deactiveSale(uint256 saleId ) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFStore: Caller is not an admin"
        );
        require(PetSales[saleId].status == SaleStatus.Ongoing, "SHFStore: Sale not found");
        PetSales[saleId].status = SaleStatus.Expired;
    }

    function activeSale(uint256 saleId ) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFStore: Caller is not an admin"
        );
        require(PetSales[saleId].status == SaleStatus.Expired, "SHFStore: Sale not found");
        PetSales[saleId].status = SaleStatus.Ongoing;
    }

    function addSale(
        address nftContractAddress,
        uint128 price,
        uint64 batchId,
        uint64 tier,
        uint32 limit
        )
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFStore: Caller is not an admin"
        );
        require(acceptedNFTs.contains(nftContractAddress), "SHFStore: contract address not allowed");
        require(price > 0, "SHFStore: Price should positive");
        require(tier > 0, "SHFStore: Tier should positive");
        require(batchId > 0, "SHFStore: Batch id should positive");
        require(limit > 0, "SHFStore: Limit buy must greater than 0");

        uint64 _startedAt = uint64(block.timestamp);
        PetSales.push(PetSale(nftContractAddress, price, _startedAt, SaleStatus.Ongoing , batchId, tier, limit, 0));
        emit SaleCreated(nftContractAddress, price, _startedAt, SaleStatus.Ongoing, batchId, tier);
    }

    function getAllSales() public view returns (PetSale[] memory) {
        return PetSales;
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address currencyAddress)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFStore: Caller is not an admin"
        );
        // withdraw native currency
        if (currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    // priceFeed should be something like BUSD/BNB or DAI/BNB
    function setBnbPriceFeed(address _priceFeed, string calldata _description) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bnbPriceFeed = AggregatorV3Interface(_priceFeed);
        require(memcmp(bytes(bnbPriceFeed.description()), bytes(_description)),"SHFStore: Incorrect Feed");
    }

    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool) {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function getLatestPrice(uint256 salePrice) public view returns (uint) {
        (
            , int price, , ,
        ) = bnbPriceFeed.latestRoundData();
        // rateDecimals = bnbPriceFeed.decimals();
        // price is BUSD / BNB * (amount)
        require(price > 0, "SHFStore: Invalid price");
        return uint(price) * salePrice; // since rateDecimals is 18, the same as BNB, we don't need to do anything
    }
}