//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interface/IPoolDeployer.sol";
import "./interface/INFTDeployer.sol";
import "./interface/IOriginationCore.sol";
import "./interface/IFungibleOriginationPool.sol";
import "./interface/IxTokenManager.sol";
import "./interface/IOriginationProxyAdmin.sol";

/**
 * Core contract responsible for deploying token sale pools
 */
contract OriginationCore is
    IOriginationCore,
    Initializable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;
    //--------------------------------------------------------------------------
    // State variables
    //--------------------------------------------------------------------------

    // flat fee on deployment
    uint256 public listingFee;

    // Premium deployment fees for select partners
    mapping(address => uint256) public customListingFee;
    // True if premium fee is enabled
    mapping(address => bool) public customListingFeeEnabled;

    // percent fee share of purchases
    // 1e18 = 100% fee. 1e16 = 1% fee
    uint256 public originationFee;

    // this should refer to a universal proxyAdmin contract customized to let pool admins
    // use the same address for upgrading implementation if necessary and also interacting
    // with the proxy instance
    // nb: transparentupgradeableproxy pattern has a limitation where proxyAdmin can't interact
    // directly with contract b/c address's txs are routed to proxy logic, not implementation
    IOriginationProxyAdmin public proxyAdmin;

    // The xTokenManager in charge of the revenue controller that will claim fees
    IxTokenManager private xTokenManager;

    // Pool deployer address responsible for deploying pool proxies
    IPoolDeployer public poolDeployer;

    // NFT deployer address responsible for deploying pool proxies
    INFTDeployer public nftDeployer;

    //--------------------------------------------------------------------------
    // Events
    //--------------------------------------------------------------------------

    event CreateFungibleListing(address indexed pool, address indexed owner);
    event SetListingFee(uint256 fee);
    event CustomListingFeeEnabled(address indexed deployer, uint256 customFee);
    event CustomListingFeeDisabled(address indexed deployer);
    event TokenFeeWithdraw(address indexed token, uint256 amount);
    event EthFeeWithdraw(uint256 amount);

    //--------------------------------------------------------------------------
    // Constructor / Initializer
    //--------------------------------------------------------------------------

    // Initialize the implementation
    constructor() initializer {}

    /**
     * @dev Initializes the origination core contract
     *
     * @param _listingFee The listing fee
     * @param _originationFee The origination fee
     * @param _xTokenManager The xtoken manager contract
     * @param _poolDeployer The contract which deploys origination pools
     * @param _nftDeployer The contract which deploys nft vesting contracts
     * @param _proxyAdmin Proxy admin of deployed pools
     */
    function initialize(
        uint256 _listingFee,
        uint256 _originationFee,
        IxTokenManager _xTokenManager,
        IPoolDeployer _poolDeployer,
        INFTDeployer _nftDeployer,
        IOriginationProxyAdmin _proxyAdmin
    ) external initializer {
        __Ownable_init();

        listingFee = _listingFee;

        require(_originationFee <= 1e18, "Invalid origination fee");
        originationFee = _originationFee;

        xTokenManager = _xTokenManager;
        poolDeployer = _poolDeployer;
        nftDeployer = _nftDeployer;
        proxyAdmin = _proxyAdmin;
    }

    //--------------------------------------------------------------------------
    // User Functions
    //--------------------------------------------------------------------------

    /**
     * @dev Creates a new token listing
     * @dev Must pay the listing fee
     *
     * @param saleParams The token sale params
     * @return originationPool address of the deployed pool
     */
    function createFungibleListing(
        IFungibleOriginationPool.SaleParams calldata saleParams
    ) external payable returns (address originationPool) {
        uint256 feeOwed = customListingFeeEnabled[msg.sender]
            ? customListingFee[msg.sender]
            : listingFee;
        require(msg.value == feeOwed, "Incorrect listing fee");
        require(
            saleParams.offerToken != saleParams.purchaseToken,
            "Invalid offering"
        );
        require(
            saleParams.vestingPeriod >= saleParams.cliffPeriod,
            "Invalid vesting terms"
        );

        // Deploy the pool
        originationPool = poolDeployer.deployFungibleOriginationPool(
            address(proxyAdmin)
        );
        // Deploy the vesting entry nft if there is a vesting period
        address vestingEntryNFT = address(0);
        if (saleParams.vestingPeriod > 0) {
            vestingEntryNFT = nftDeployer.deployVestingEntryNFT();
        }

        // Set proxy admin
        proxyAdmin.setProxyAdmin(originationPool, msg.sender);

        // Initialize the proxy
        IFungibleOriginationPool(originationPool).initialize(
            originationFee,
            this,
            msg.sender,
            vestingEntryNFT,
            saleParams
        );

        // emit event
        emit CreateFungibleListing(originationPool, msg.sender);
    }

    //--------------------------------------------------------------------------
    // Admin Functions
    //--------------------------------------------------------------------------

    /**
     * @dev Sets the listing fee
     *
     * @param _listingFee The new listing fee
     */
    function setListingFee(uint256 _listingFee) external onlyOwner {
        listingFee = _listingFee;

        emit SetListingFee(_listingFee);
    }

    /**
     * @notice Enable custom pool deployment fee for a given address
     * @param deployer address to enable fee for
     * @param feeAmount fee amount in eth
     */
    function enableCustomListingFee(address deployer, uint256 feeAmount)
        public
        onlyOwner
    {
        customListingFeeEnabled[deployer] = true;
        customListingFee[deployer] = feeAmount;
        emit CustomListingFeeEnabled(deployer, feeAmount);
    }

    /**
     * @notice Disable custom pool deployment fee for a given address
     * @param deployer address to disable fee for
     */
    function disableCustomListingFee(address deployer) public onlyOwner {
        customListingFeeEnabled[deployer] = false;
        emit CustomListingFeeDisabled(deployer);
    }

    /**
     * @dev Claims the accrued fees in the origination pools
     *
     * @param _feeToken The token address of the fee to claim
     */
    function claimFees(address _feeToken) external {
        require(
            xTokenManager.isRevenueController(msg.sender),
            "Only callable by revenue controller."
        );

        if (_feeToken == address(0)) {
            (bool success, ) = msg.sender.call{value: address(this).balance}(
                ""
            );
            require(success);
            emit EthFeeWithdraw(address(this).balance);
        } else {
            uint256 fees = IERC20(_feeToken).balanceOf(address(this));
            IERC20(_feeToken).safeTransfer(
                msg.sender,
                fees
            );
            emit TokenFeeWithdraw(_feeToken, fees);
        }
    }

    /**
     * @dev Withdraw unclaimed fees from origination pool
     * @dev Callable only if there are any unclaimed fees
     * @dev Callable only after owner claims sale purchase tokens
     *
     * @param _pool the pool address
     * @param _feeToken The token address of the fee to claim
     */
    function withdrawFees(address _pool, address _feeToken) external {
        require(
            xTokenManager.isRevenueController(msg.sender),
            "Only callable by revenue controller."
        );

        uint256 feeAmount = IFungibleOriginationPool(_pool).originationCoreFees();

        IERC20(_feeToken).transferFrom(_pool, msg.sender, feeAmount);
        emit TokenFeeWithdraw(_feeToken, feeAmount);
    }

    /**
     * @dev Function used by origination pools to send the origination fees to this contract
     * @dev Only used after a token sale has finished successfully on claiming the tokens
     */
    function receiveFees() external payable override {}
}