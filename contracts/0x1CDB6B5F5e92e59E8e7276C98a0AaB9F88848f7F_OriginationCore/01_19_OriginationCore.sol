//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

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
     */
    function createFungibleListing(
        IFungibleOriginationPool.SaleParams calldata saleParams
    ) external payable {
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
        address originationPool = poolDeployer.deployFungibleOriginationPool(
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
        } else {
            bool success = IERC20(_feeToken).transfer(
                msg.sender,
                IERC20(_feeToken).balanceOf(address(this))
            );
            require(success);
        }
    }

    /**
     * @dev Function used by origination pools to send the origination fees to this contract
     * @dev Only used after a token sale has finished successfully on claiming the tokens
     */
    function receiveFees() external payable override {}
}