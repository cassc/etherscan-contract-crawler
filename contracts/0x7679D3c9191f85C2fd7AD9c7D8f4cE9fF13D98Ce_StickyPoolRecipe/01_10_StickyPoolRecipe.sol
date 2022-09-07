pragma solidity 0.8.6;

import "IJellyFactory.sol";
import "IJellyContract.sol";
import "IJellyAccessControls.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";

/**
* @title StickyPool Recipe:
*
*              ,,,,
*            [email protected]@@@@@K
*           [email protected]@@@@@@@P
*            [email protected]@@@@@@"                   [email protected]@@  [email protected]@@
*             "*NNM"                     [email protected]@@  [email protected]@@
*                                        [email protected]@@  [email protected]@@
*             ,[email protected]@@g        ,,[email protected],     [email protected]@@  [email protected]@@ ,ggg          ,ggg
*            @@@@@@@@p    [email protected]@@[email protected]@W   [email protected]@@  [email protected]@@  [email protected]@g        ,@@@Y
*           [email protected]@@@@@@@@   @@@P      ]@@@  [email protected]@@  [email protected]@@   [email protected]@g      ,@@@Y
*           [email protected]@@@@@@@@  [email protected]@D,,,,,,,,]@@@ [email protected]@@  [email protected]@@   '@@@p     @@@Y
*           [email protected]@@@@@@@@  @@@@EEEEEEEEEEEE [email protected]@@  [email protected]@@    "@@@p   @@@Y
*           [email protected]@@@@@@@@  [email protected]@K             [email protected]@@  [email protected]@@     '@@@, @@@Y
*            @@@@@@@@@   %@@@,    ,[email protected]@@  [email protected]@@  [email protected]@@      ^@@@@@@Y
*            "@@@@@@@@    "[email protected]@@@@@@@E'   [email protected]@@  [email protected]@@       "*@@@Y
*             "[email protected]@@@@@        "**""       '''   '''        @@@Y
*    ,[email protected]@g    "[email protected]@@P                                     @@@Y
*   @@@@@@@@p    [email protected]@'                                    @@@Y
*   @@@@@@@@P    [email protected]                                    RNNY
*   '[email protected]@@@@@     $P
*       "[email protected]@@p"'
*
*
*/

/**
* @author ProfWobble 
* @dev
*  - Wrapper deployment of all the StickyPool contracts.
*  - Supports Merkle proofs using the JellyList interface.
*
*/


interface IStickyPool {
    function setDescriptor(address) external;
    function setDocumentController(address) external;
    function changeController(address) external;
    function setTokenDetails(string memory, string memory ) external;
    function create_lock_for(uint _value, uint _lock_duration, address _to) external returns (uint);

}


interface IPriceOracle {
    function getRateToEth(address srcToken, bool useSrcWrappers) external view returns (uint256 weightedRate);
}

contract StickyPoolRecipe {

    using SafeMath for uint256;
    using SafeERC20 for OZIERC20;

    IJellyFactory public jellyFactory;
    uint256 public tokenFeeAmount;
    uint256 public ethFeeAmount;
    uint256 public lockDuration;

    address public documentController;
    address payable public jellyVault;
    bool public locked;

    /// @notice Address that manages approvals.
    IJellyAccessControls public accessControls;
    IPriceOracle public oracle;

    /// @notice Jelly template id for the pool factory.
    uint256 public constant TEMPLATE_TYPE = 4;
    bytes32 public constant TEMPLATE_ID = keccak256("STICKY_POOL_RECIPE");
    string public imageURL;
    uint256 public maxPercentage;

    bytes32 public constant POOL_ID = keccak256("STICKY_POOL");
    bytes32 public constant DESCRIPTOR_ID = keccak256("STICKY_DESCRIPTOR");
    bytes32 public constant ACCESS_ID = keccak256("OPERATOR_ACCESS");
    uint256 private constant PERCENTAGE_PRECISION = 10000;

    address ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    event StickyPoolDeployed(address indexed pool, address indexed token);
    event Recovered(address indexed token, uint256 amount);
    event LockSet(bool locked);


    /** 
     * @notice Jelly Airdrop Recipe
     * @param _jellyFactory - A factory that makes fresh Jelly
    */
    constructor(
        address _accessControls,
        address _jellyFactory,
        address payable _jellyVault,
        uint256 _tokenFeeAmount,
        uint256 _ethFeeAmount,
        address _oracle,
        address _documentController
    ) {
        accessControls = IJellyAccessControls(_accessControls);
        jellyFactory = IJellyFactory(_jellyFactory);
        jellyVault = _jellyVault;
        tokenFeeAmount =_tokenFeeAmount;
        ethFeeAmount =_ethFeeAmount;

        oracle = IPriceOracle(_oracle);
        documentController = _documentController;
        lockDuration = 365 * 24 * 60 * 60;
        locked = true;
        maxPercentage = 10e18;
        // imageURL = "https://raw.githubusercontent.com/JellyProtocol/JellyAssets/main/Images/PoolNFTs/blue_jelly.png";
    }

    //--------------------------------------------------------
    // Setters
    //-------------------------------------------------------- 
    /**
     * @notice Sets the recipe to be locked or unlocked.
     * @dev When locked, the public cannot use the recipe.
     * @param _locked bool.
     */
    function setLocked(bool _locked) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setLocked: Sender must be admin"
        );
        locked = _locked;
        emit LockSet(_locked);
    }

    /// @notice Setter functions for setting lock duration
    function setLockDuration(uint256 _lockDuration) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setLockDuration: Sender must be admin"
        );
        lockDuration = _lockDuration;
    }

    /**
     * @notice Sets the vault address.
     * @param _vault Jelly Vault address.
     */
    function setVault(address payable _vault) external {
        require(accessControls.hasAdminRole(msg.sender), "setVault: Sender must be admin");
        require(_vault != address(0));
        jellyVault = _vault;
    }

    /**
     * @notice Sets the oracle address.
     * @param _oracle Price oracle address.
     */
    function setOracle(address _oracle) external {
        require(accessControls.hasAdminRole(msg.sender), "setVault: Sender must be admin");
        require(_oracle != address(0));
        oracle = IPriceOracle(_oracle);
    }

    /**
     * @notice Sets the access controls address.
     * @param _accessControls Access controls address.
     */
    function setAccessControls(address _accessControls) external {
        require(accessControls.hasAdminRole(msg.sender), "setAccessControls: Sender must be admin");
        require(_accessControls != address(0));
        accessControls = IJellyAccessControls(_accessControls);
    }

    /**
     * @notice Sets the current fee percentage to deploy, paid in tokens.
     * @param _ethFeeAmount The fee amount priced in ETH
     */
    function setEthFeeAmount(uint256 _ethFeeAmount) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setFeeAmount: Sender must be admin"
        );
        ethFeeAmount = _ethFeeAmount;
    }

    /**
     * @notice Sets the current fee percentage to deploy, paid in ETH.
     * @param _tokenFeeAmount The fee amount priced in ETH
     */
    function setTokenFeeAmount(uint256 _tokenFeeAmount) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setFeeAmount: Sender must be admin"
        );
        tokenFeeAmount = _tokenFeeAmount;
    }

    /**
     * @notice Sets the default image descriptor settings.
     * @param _imageURL Project logo URL
     * @param _maxPercentage Percentage staked for full sized image
     */
    function setDescriptorSettings(string calldata _imageURL, uint256 _maxPercentage) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setFeeAmount: Sender must be admin"
        );
        imageURL = _imageURL;
        maxPercentage = _maxPercentage;
    }

    /**
     * @notice Sets the global document.
     * @param _documentController Address of the global document contract
     */
    function setDocumentController(address _documentController) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setDocumentController: Sender must be admin"
        );
        documentController = _documentController;
    }


    //--------------------------------------------------------
    // Getters
    //-------------------------------------------------------- 

    function getFeeInTokens(address _addr) public view returns (uint256)  {
        uint256 rate = 0;
        if (address(oracle) != address(0)) {
            try oracle.getRateToEth(_addr, false) returns (uint256 _rate) {
                rate = _rate;
            } 
            catch {
                try oracle.getRateToEth(_addr, true) returns (uint256 _rate) {
                    rate = _rate;
                } catch {}
            }
        }

        if (rate == 0) {
            return 0;
        }
        return 1e18 * tokenFeeAmount / rate;
    }

    function poolTemplate() external view returns (address) {
        return jellyFactory.getContractTemplate(POOL_ID);
    }

    function descriptorTemplate() external view returns (address) {
        return jellyFactory.getContractTemplate(DESCRIPTOR_ID);
    }

    //--------------------------------------------------------
    // Recipe
    //-------------------------------------------------------- 
    /**
     * @notice Creates a StickyPool contract using a recipe from the JellyFactory.
     * @param _poolAdmin Address which will be the admin for the new contract.
     * @param _stakedToken Token used for staking into the StickyPool.
     * @dev This contract needs an approval for the stakedToken.
     * @dev Fees are paid in the stakedToken with a percentage locked in the StickyPool.  
     */

    function prepareStickyPool(
        address _poolAdmin,
        address _stakedToken
    )
        external 
        returns (address)
    {
        address sticky_pool = _deployContracts(_poolAdmin, _stakedToken);
        uint256 feeTokens = getFeeInTokens(_stakedToken);

        require(feeTokens > 0, "No liquidity pool found.");
        OZIERC20(_stakedToken).safeTransferFrom(
            msg.sender,
            address(this),
            feeTokens
        );
        OZIERC20(_stakedToken).safeApprove(sticky_pool, feeTokens/2);
        IStickyPool(sticky_pool).create_lock_for(feeTokens/2, lockDuration, jellyVault);
        OZIERC20(_stakedToken).safeTransfer(
            jellyVault,
            feeTokens/2
        );
        return sticky_pool;
    }

    /**
     * @notice Creates a StickyPool contract using a recipe from the JellyFactory.
     * @param _poolAdmin Address which will be the admin for the new contract.
     * @param _stakedToken Token used for staking into the StickyPool.
     * @dev Fees are paid in ETH, set by the feeAmount.  
     */
    function prepareStickyPoolNoLiquidity(
        address _poolAdmin,
        address _stakedToken
    )
        external payable
        returns (address)
    {
        require(msg.value >= ethFeeAmount, "Failed to transfer minimumFee.");
        if (msg.value > 0) {
            jellyVault.transfer(msg.value);
        }
        // Clone sticky pool from factory
        address sticky_pool = _deployContracts(_poolAdmin, _stakedToken);
        return sticky_pool;
    }


    //--------------------------------------------------------
    // Internals
    //-------------------------------------------------------- 

    receive() external payable {
        revert();
    }

    function _deployContracts(
        address _poolAdmin,
        address _stakedToken
    )
        internal
        returns (address)
    {
        require(_poolAdmin != address(0), "Admin address not set");
        require(_stakedToken != address(0), "Token address not set");
        require(IERC20(_stakedToken).decimals() == 18, "Token needs to have 18 decimals");
        
        /// @dev If the contract is locked, only admin and minters can deploy. 
        if (locked) {
            require(accessControls.hasAdminRole(msg.sender) 
                    || accessControls.hasMinterRole(msg.sender),
                "prepareJellyFarm: Sender must be minter if locked"
            );
        }

        // Clone contracts from factory
        address access_controls = jellyFactory.deployContract(
            ACCESS_ID,
            jellyVault, 
            "");
        IJellyAccessControls(access_controls).initAccessControls(address(this));

        // Clone sticky pool from factory
        address sticky_pool = jellyFactory.deployContract(
            POOL_ID,
            jellyVault, 
            "");

        IJellyContract(sticky_pool).initContract(abi.encode(_stakedToken, access_controls)); 

        // Clone descriptor from factory
        address pool_descriptor = jellyFactory.deployContract(
            DESCRIPTOR_ID,
            jellyVault, 
            "");
        
        uint256 veBalanceForFullImage = IERC20(_stakedToken).totalSupply() / 1000; // 0.1% 

        IJellyContract(pool_descriptor).initContract(abi.encode(sticky_pool, access_controls, veBalanceForFullImage)); 

        // Contract config
        IStickyPool(sticky_pool).setDescriptor(pool_descriptor);
        IStickyPool(sticky_pool).changeController(_poolAdmin); 
        IStickyPool(sticky_pool).setTokenDetails("Sticky Pool","veNFT"); 
        IStickyPool(sticky_pool).setDocumentController(documentController); 

        IJellyAccessControls(access_controls).addAdminRole(_poolAdmin);
        IJellyAccessControls(access_controls).removeAdminRole(address(this));

        emit StickyPoolDeployed(sticky_pool, _stakedToken);
        return sticky_pool;
    }


    //--------------------------------------------------------
    // Admin
    //-------------------------------------------------------- 

    /// @notice allows for the recovery of incorrect ERC20 tokens sent to contract
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "recoverERC20: Sender must be admin"
        );
        // OZIERC20 uses SafeERC20.sol, which hasn't overriden `transfer` method of OZIERC20. Shifting to `safeTransfer` may help
        OZIERC20(tokenAddress).transfer(jellyVault, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

}