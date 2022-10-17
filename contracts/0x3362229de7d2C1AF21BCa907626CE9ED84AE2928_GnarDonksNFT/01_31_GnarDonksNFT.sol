// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./common/TrustForwarderAccessControl.sol";
import "./common/ERC2981.sol";
import "./common/meta-transactions/EIP712Base.sol";
import "./common/meta-transactions/Claimable.sol";
import "./common/meta-transactions/Math.sol";
import "./ERC721W.sol";


contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title GnarDonksNFT
 * @custom:a w3box.com
 */
contract GnarDonksNFT is
    ERC721W,
    Pausable,
    Claimable,
    Math,
    EIP712Base,
    ReentrancyGuard,
    TrustForwarderAccessControl,
    ERC2981
{
    using Address for address;
    using SafeMath for uint256;

    modifier onlyAdmin {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    // Constant for Minter Role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private constant MASK_16 = 65535;
    uint256 private constant MASK_32 = 4294967295;
    uint256 private constant MASK_64 = 18446744073709551615;

    uint256[6] private tierPricesInEth = [1 ether, 0, 0, 0, 0, 0];
    uint256[6] private tierPricesInUsd = [0, 5000, 10000, 25000, 150000, 250000];

    // Slippage Limits
    uint256 private slipETH;
    uint256 private slipUSD;

    mapping(address => bool) private acceptedCoins;

    // Proxy Address for Frictionless with OpenSea
    address private immutable proxyRegistryAddress;

    mapping(uint256 => address) private paymentAddresses;
    
    // Declare the priceFeed as an Aggregator Interface
    AggregatorV3Interface internal immutable priceFeed;
    
    // Launch Time
    uint256 internal launchTs;

    // Mapping of Tier Package BitMap to Tier ID
    mapping(uint256 => uint256) internal tiers;
    // Event for Token Minted with ETH
    /**
     * @dev Event when setting the Cost per Token
     * @param payee address of the minter
     * @param tokendId TokenId of the minted token
     * @param amount Amount of Token (Stable or Native)
     * @param tokenAddress timestamp of the token
     */
    event Mint(
        address payee,
        uint256 tokendId,
        uint256 amount,
        address tokenAddress
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _launchTs, // TimeStamp of the launch
        uint256 _totalSupply,
        address _proxyRegistryAddress,
        address _priceFeedAddress // Address of the Aggregator Interface for Getting Price ETH/USD
    )
        ERC721W(
            _name,
            _symbol,
            "https://nft.gnardonks.com/",
            "https://nft.gnardonks.com/gnardonks.json",
            _totalSupply
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        proxyRegistryAddress = _proxyRegistryAddress;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);

        // Launch TimeStamp
        launchTs = _launchTs;

        // Slippage Limits
        slipETH = 1010; // represent 1%
        slipUSD = 1020; // represent 2%

        // TimeStamp Period Limits per Tier
        //[ total supply 16, total_sales 16, sales period 1 32, period supply 16, sales period 1 16, ... sales period 10 16].
        tiers[1] = 5850;
        tiers[2] =
            2500 |
            (0 << 16) |
            (31560000 << 32) |
            (250 << 64); // 250 per year
        tiers[3] =
            1000 |
            (0 << 16) |
            (31560000 << 32) |
            (100 << 64); // 100 per year
        tiers[4] =
            500 |
            (0 << 16) |
            (31560000 << 32) |
            (50 << 64); // 50 per year
        tiers[5] =
            75 |
            (0 << 16) |
            (63120000 << 32) |
            (15 << 64); // 15 every 2 years
        tiers[6] = 10;
    }

    /**
     * @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     * @param _owner The owner of the NFT
     * @param _operator The operator to be added or removed
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }
        return ERC721W.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Implementation / Instance of paused methods() in the ERC1155.
     * @dev See {ERC1155Pausable}.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     */
    function pause(bool status) public onlyAdmin {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

    /** MINT METHOD FOR ETH, USD AND MOONPAY */

    /**
     * @dev Method for Mint a new token, based on Tiers and with Payment in ETH
     * @param to The address of the recipient
     * @param tokenId tokenId of the token to be minted, with this define the tier
     */
    function mint(address to, uint256 tokenId)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(acceptedCoins[address(0)], "Mint with ETH is temporarily disabled");

        uint256 tier = tierOf(tokenId);
        // Pre Check of tier before to mint
        beforeMintOfTier(tier);
        // Get the price of the token
        uint256 price = _mintTierPriceInETH(tier, false);
        // Get the balance of the sender
        uint256 balance = msg.value;
        // Check if the balance is enough to pay the price
        require(
            balance >= price,
            "ERC721: Insufficient funds to pay the price"
        );
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value

        (bool success, ) = paymentAddresses[tier].call{value: balance}("");
        
        require(success,"Address: unable to send value, recipient may have reverted");
        
        // Call the mint method from ERC721W
        _safeMint(to, tokenId);

        // Event when the Smart Contract Send Amount of Native or ERC20 tokens
        emit Mint(to, tokenId, price, address(0));
    }

    /**
     * @dev Method for Mint a new token, based on Tiers and with Payment in USD(Tether, USD Coin, BUSD Coin)
     * @param to The address of the recipient
     * @param tokenId tokenId of the token to be minted, with this define the tier
     */
    function mintWithUSD(
        address to,
        uint256 tokenId,
        address _stableCoin
    ) external
        virtual
        nonReentrant
        whenNotPaused
    {
        require(_stableCoin.isContract(), "Invalid stable coin address");
        require(acceptedCoins[_stableCoin], "ERC721: Stable Coin token not permitted");

        uint256 tier = tierOf(tokenId);
        // Pre Check of tier before to mint
        beforeMintOfTier(tier);
        // Check if the balance is enough to pay the price take account the decimals of the stable coin
        IERC20Metadata _stableToken = IERC20Metadata(_stableCoin);

        // Get the price of the token
        uint256 price = tierPriceInUSD(tier) * (10**_stableToken.decimals());

        require(
            _stableToken.balanceOf(_msgSender()) >= price,
            "ERC721: Not enough Stable Coin"
        );

        // Verify before to Transfer Stable Coin
        _beforeTokenTransfers(address(0), to, tokenId);

        // Transfer the Stable Coin to Split Payment process

        bool success_treasury = _stableToken.transferFrom(
            _msgSender(),
            paymentAddresses[tier],
            price
        );

        require(
            success_treasury,
            "ERC721: Can't create Donks, you don't have enough stable coins"
        );
        // Call the mint method from ERC721W
        _safeMint(to, tokenId);

        // Event when the Smart Contract Send Amount of Native or ERC20 tokens
        emit Mint(to, tokenId, price, _stableCoin);
    }

    /**
     * @dev Method for Internal for Mint a new token, based on Tiers and with Payment in MoonPay
     * @param to The address of the recipient
     * @param tokenId tokenId of the token to be minted, with this define the tier
     */
    function mintTo(address to, uint256 tokenId)
        external
        onlyRole(MINTER_ROLE)
        whenNotPaused
        nonReentrant
    {
        // Pre Check of tier before to mint
        beforeMintOfTier(tierOf(tokenId));
        // Call the mint method from ERC721W
        _safeMint(to, tokenId);
    }

    /**
     * @dev Method for Internal for Mint by Batch a Group of new tokens, based with Verification of Supply by timestamp
     * @param _owner Arrays of addresses of the recipient
     * @param tokenIds Arrays of tokenId of the token to be minted, with any Tier, but with preview verification of Supply by timestamp
     */
    function batchMint(
        address[] calldata _owner,
        uint256[] calldata tokenIds,
        uint64 locktime
    ) 
        external
        onlyRole(MINTER_ROLE)
        whenNotPaused
        nonReentrant
    {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            beforeMintOfTier(tierOf(tokenIds[i]));
        }
        _batchMint(_owner, tokenIds, locktime);
    }

    /**
     * @dev Method for Expose the burn method from ERC721W
     * @param tokenId tokenId of the token to be burned, with any Tier, but with preview verification of Supply by timestamp
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    /** HELPERS FOR TIERS AND PRICES */

    function tierOf(uint256 tokenId) public pure returns (uint256) {
        if (tokenId > 4150) {
            return 1;
        } else if (tokenId > 1650) {
            return 2;
        } else if (tokenId > 650) {
            return 3;
        } else if (tokenId > 150) {
            return 4;
        } else if (tokenId > 50) {
            return 5;
        } else {
            return 6;
        }
    }

    function _mintTierPriceInETH(uint256 tier, bool addSlippage) internal view returns (uint256 price) {
        price = tierPricesInEth[tier - 1];
        if(price == 0) {
            price = addSlippage ? mulDiv(_usdToEth(tierPriceInUSD(tier)), slipETH, 1000) : _usdToEth(tierPriceInUSD(tier));
        }
    }

    function tierPriceInETH(uint256 tier) public view returns (uint256 price) {
        price = _mintTierPriceInETH(tier, true);
    }

    function tierPriceInUSD(uint256 tier) public view returns (uint256 price) {
        price = tierPricesInUsd[tier - 1];
        if (price == 0) {
            price = _ethToUsd(_mintTierPriceInETH(tier, false)) / 1 ether; // the price is 1 ether, and is native in solididty
        }
    }

    /**
     * @dev Method for Internal Getting the convertion of USD to ETH
     * @param amount The amount of USD in decimal to convert
     */
    function _ethToUsd(uint256 amount) internal view returns (uint256) {
        (int256 _price, uint8 _decimals) = _getLatestPrice();
        uint256 price = mulDiv(uint256(_price), slipUSD * (10**15), 10**18); // add Slippage Over to the market price
        return mulDiv(amount, price, 10**(_decimals));
    }

    /**
     * @dev Method for Internal Getting the convertion of ETH to USD
     * @param amount The amount of ETH in decimal to convert
     */
    function _usdToEth(uint256 amount) internal view returns (uint256) {
        require(amount > 0, "Amount must be greater than 0");
        (int256 price, uint8 _decimals) = _getLatestPrice();
        return mulDiv(amount * 10**18, 10**(_decimals), uint256(price));
    }

    /**
     * Returns the latest price and # of decimals to use
     */
    function _getLatestPrice()
        internal
        virtual
        view
        returns (int256 price, uint8 _decimals)
    {
        (, price, , , ) = priceFeed.latestRoundData();
        _decimals = priceFeed.decimals();
        return (price, _decimals);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721W, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(!paused(), "ERC721: Can't transfer tokens while paused");

        super._beforeTokenTransfers(from, to, tokenId);
    }

    /**
     * @dev Method for verify and storage the Tier
     * @param tier uint256
     */
    function beforeMintOfTier(uint256 tier) internal {
        require(
            block.timestamp > launchTs,
            "ERC721: Can't mint, before to start launch"
        );
        // Check total supply x total sales
        uint256 supply = tiers[tier] & MASK_16;
        uint256 sales = (tiers[tier] >> 16) & MASK_16;

        require(sales < supply, "Sales for tier are finished");

        // update total sales
        tiers[tier] = (tiers[tier] & ~(MASK_16 << 16)) | (++sales << 16);

        uint256 period = (tiers[tier] >> 32) & MASK_32;

        if (period > 0) {
            supply = (tiers[tier] >> 64) & MASK_16; // period supply
            period = (block.timestamp - launchTs) / period; // period position
            if (period < 11) {
                // Max period is 11
                sales = (tiers[tier] >> (80 + (period * 16))) & SIZE_MASK; // period sales

                // check total period supply x period sales
                require(
                    sales < supply,
                    "Sales for tier are finished in this period"
                );

                // update tier sales
                tiers[tier] =
                    (tiers[tier] & ~(MASK_16 << (80 + (period * 16)))) |
                    (++sales << (80 + (period * 16)));
            }
        }
    }

    /**
     * @dev Method to Get Available Token per Tier, per Period
     * @param _tier Tier of the Token
     */
    function getAvailableTokenPerTier(uint256 _tier)
        public
        view
        returns (uint256 available)
    {
        require(_tier > 0 && _tier <= 6, "Tier must be between 1 and 6");
        // Check total supply x total sales
        uint256 _totalSupply = tiers[_tier] & MASK_16;
        uint256 _totalSales = (tiers[_tier] >> 16) & MASK_16;
        // Getting Period per Tier
        uint256 period = (tiers[_tier] >> 32) & MASK_32;
        if (period > 0) {
            uint256 supply = (tiers[_tier] >> 64) & MASK_16; // period supply
            period = (block.timestamp - launchTs) / period; // period position
            if (period < 11) {
                // Maximal period is 11
                uint256 sales = (tiers[_tier] >> (80 + (period * 16))) &
                    SIZE_MASK; // period sales
                available = supply > sales ? supply - sales : 0;
            } else {
                available = _totalSupply > _totalSales
                    ? _totalSupply - _totalSales
                    : 0;
            }
        } else {
            available = _totalSupply > _totalSales
                ? _totalSupply - _totalSales
                : 0;
        }
    }

    /**
     * @dev Method to Get Available Token per Tier, per Period
     * @param _tier Tier of the Token
     */
    function getTotalAvailableTokenPerTier(uint256 _tier)
        public
        view
        returns (uint256 available)
    {
        require(_tier > 0 && _tier <= 6, "Tier must be between 1 and 6");
        // Check total supply x total sales
        uint256 _totalSupply = tiers[_tier] & MASK_16;
        uint256 _totalSales = (tiers[_tier] >> 16) & MASK_16;
        available = _totalSupply > _totalSales
            ? _totalSupply - _totalSales
            : 0;
    }

    /**
     * @dev Method for Setting the Price of Each Tier of TokenIds
     * @param _tierPrices Arrays of Tier ETH Price in Decimals
     */
    function setTierPricesInEth(uint256[6] calldata _tierPrices) external onlyAdmin {
        tierPricesInEth = _tierPrices;
    }

    /**
     * @dev Method for Setting the Price of Each Tier of TokenIds
     * @param _tierPrices Arrays of Tier USD Price in Decimals
     */
    function setTierPricesInUsd(uint256[6] calldata _tierPrices) external onlyAdmin {
        tierPricesInUsd = _tierPrices;
    }

    /**
     * @dev Method for Setting the TimeStamps of Each Tier of TokenIds
     * @param limits Arrays of TimeStamp range of Period to Mint an Specific Amount of Tokens, per Tier
     */
    function setTSLimits(uint256[6] calldata limits)
        public
        virtual
        onlyAdmin {
        for (uint256 i = 0; i < limits.length; i++) {
            uint256 newLimit = limits[i] & MASK_32;
            // update Time Stamps of Each Tier
            tiers[i + 1] =
                (tiers[i + 1] & ~(MASK_32 << 32)) |
                (newLimit << 32);
        }
    }

    /**
     * @dev Method for Setting the Amount of Token can Minted per Period/Tier
     * @param limits Arrays of Token can minted per Period/Tier
     */
    function setAmountLimitsPerPeriod(uint256[6] calldata limits)
        public
        virtual
        onlyAdmin
    {
        for (uint256 i = 0; i < limits.length; i++) {
            uint256 newAmount = limits[i] & MASK_16;
            // update Amount Lmits of Each Tier
            tiers[i + 1] =
                (tiers[i + 1] & ~(MASK_16 << 64)) |
                (newAmount << 64);
        }
    }

    /**
     * @dev Method to Add Slippage to the Price of TokenIds in ETH and USD
     * @param _slipETH value in base 1000, where 1001 represent 0.1%, and 1010 represent 1% to represent the slippage in ETH
     * @param _slipUSD value in base 1000, where 1001 represent 0.1%, and 1010 represent 1% to represent the slippage in USD
     */
    function setSlippage(uint256 _slipETH, uint256 _slipUSD)
        external
        onlyAdmin
    {
        require(
            _slipETH > 1000,
            "ERC721: Slippage ETH must be greater than 100"
        );
        require(
            _slipUSD > 1000,
            "ERC721: Slippage USD must be greater than 100"
        );
        slipETH = _slipETH;
        slipUSD = _slipUSD;
    }

    function setPaymentAddress(uint256 _tier, address _paymentAddress)
        public
        onlyAdmin
    {
        paymentAddresses[_tier] = _paymentAddress;
    }

    function getPaymentAddress(uint256 _tier)
        public
        view returns (address)
    {
        return paymentAddresses[_tier];
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyAdmin
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     */
    function claimValues(address _token, address _to)
        external
        onlyAdmin
    {
        _claimValues(_token, _to);
    }

    /**
     * @dev Withdraw ERC721 or ERC1155 deposited for this contract
     * @param _token address of the claimed ERC721 token.
     * @param _to address of the tokens receiver.
     */
    function claimNFTs(address _token, uint256 _tokenId, address _to)
        external
        onlyAdmin
    {
        _claimNFTs(_token, _tokenId, _to);
    }

    /**
     * @dev Enable/disable mints with a stable coin
     */
    function setAcceptedCoin(address _paymentCoin, bool _accepted)
        public
        onlyAdmin
    {
        acceptedCoins[_paymentCoin] = _accepted;
    }

    /** 
     * @dev returns tier sales data
     */
    function getTier(uint256 tier)
        external
        view
        returns (uint256 tierData)
    {
        tierData = tiers[tier];
    }

    /**
     * @notice Method to reduce the friction with Opensea by allowing the Contract URI to be updated
     * @dev This method is only available for the owner of the contract
     * @param _contractURI The new contract URI
     */
    function setContractURI(string memory _contractURI)
        external
        onlyAdmin
    {
        _setContractURI(_contractURI);
    }

    function releasable(address token, address account) external view returns (uint256 total) {
        PaymentSplitter splitter;
        uint256 total = 0;
        for(uint256 i = 1; i < 7; i++) {
            if(paymentAddresses[i].isContract()) {
                splitter = PaymentSplitter(payable(paymentAddresses[i]));
                if(token == address(0)) {
                    total += splitter.releasable(account);
                } else {
                    total += splitter.releasable(IERC20(token), account);
                }
            }
        }
    }

    function release(address token, address payable account) external onlyRole(TRUSTEE_ROLE) {
        PaymentSplitter splitter;
        bool released;
        for(uint256 i = 1; i < 7; i++) {
            if(paymentAddresses[i].isContract()) {
                splitter = PaymentSplitter(payable(paymentAddresses[i]));
                if(token == address(0) && splitter.releasable(account) > 0) {
                    released = true;
                    splitter.release(account);
                } else if(token != address(0) && splitter.releasable(IERC20(token), account) > 0) {
                    released = true;
                    splitter.release(IERC20(token), account);
                }
            }
        }
        require(released, "No shares for this account");
    }
}