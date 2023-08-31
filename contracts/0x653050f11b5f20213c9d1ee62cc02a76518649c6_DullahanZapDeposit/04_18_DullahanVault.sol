//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝


pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import "./base/ScalingERC20.sol";
import "./interfaces/IERC4626.sol";
import "./oz/interfaces/IERC20.sol";
import "./oz/libraries/SafeERC20.sol";
import "./oz/utils/ReentrancyGuard.sol";
import "./oz/utils/Pausable.sol";
import "./interfaces/IStakedAave.sol";
import "./interfaces/IGovernancePowerDelegationToken.sol";
import {Errors} from "./utils/Errors.sol";
import {WadRayMath} from  "./utils/WadRayMath.sol";

/** @title DullahanVault contract
 *  @author Paladin
 *  @notice Main Dullahan Vault. IERC4626 compatible & ScalingERC20 token
 */
contract DullahanVault is IERC4626, ScalingERC20, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    // Constants

    /** @notice Max value for BPS - 100% */
    uint256 public constant MAX_BPS = 10000;
    /** @notice Max value possible for an uint256 */
    uint256 public constant MAX_UINT256 = 2**256 - 1;

    /** @notice Amount to deposit to seed the Vault during initialization */
    uint256 private constant SEED_DEPOSIT = 0.001 ether;

    /** @notice Address of the stkAAVE token */
    address public immutable STK_AAVE;
    /** @notice Address of the AAVE token */
    address public immutable AAVE;


    // Struct

    /** @notice PodsManager struct 
    *   rentingAllowed: Is the Manager allowed to rent from the Vault
    *   totalRented: Total amount rented to the Manager (based on the AAVE max total supply, should be safe)
    */
    struct PodsManager {
        bool rentingAllowed;
        uint248 totalRented;
    }


    // Storage

    /** @notice Is the Vault initialized */
    bool public initialized;

    /** @notice Address of the Vault admin */
    address public admin;
    /** @notice Address of the Vault pending admin */
    address public pendingAdmin;

    /** @notice Total amount of stkAAVE rented to Pod Managers */
    uint256 public totalRentedAmount;

    /** @notice Pod Manager states */
    mapping(address => PodsManager) public podManagers;

    /** @notice Address receiving the delegated voting power from the Vault */
    address public votingPowerManager;
    /** @notice Address receiving the delegated proposal power from the Vault */
    address public proposalPowerManager;

    /** @notice Percentage of funds to stay in the contract for withdraws */
    uint256 public bufferRatio = 500;

    /** @notice Amount accrued as Reserve */
    uint256 public reserveAmount;
    /** @notice Ratio of claimed rewards to be set as Reserve */
    uint256 public reserveRatio;
    /** @notice Address of the Reserve Manager */
    address public reserveManager;


    // Events

    /** @notice Event emitted when the Vault is initialized */
    event Initialized();

    /** @notice Event emitted when stkAAVE is rented to a Pod */
    event RentToPod(address indexed manager, address indexed pod, uint256 amount);
    /** @notice Event emitted when stkAAVE claim is notified by a Pod */
    event NotifyRentedAmount(address indexed manager, address indexed pod, uint256 addedAmount);
    /** @notice Event emitted when stkAAVE is pulled back from a Pod */
    event PullFromPod(address indexed manager, address indexed pod, uint256 amount);

    /** @notice Event emitted when the adminship is transfered */
    event AdminTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );
    /** @notice Event emitted when a new pending admin is set */
    event NewPendingAdmin(
        address indexed previousPendingAdmin,
        address indexed newPendingAdmin
    );

    /** @notice Event emitted when a new Pod Manager is added */
    event NewPodManager(address indexed newManager);
    /** @notice Event emitted when a Pod Manager is blocked */
    event BlockedPodManager(address indexed manager);

    /** @notice Event emitted when depositing in the Reserve */
    event ReserveDeposit(address indexed from, uint256 amount);
    /** @notice Event emitted when withdrawing from the Reserve */
    event ReserveWithdraw(address indexed to, uint256 amount);

    /** @notice Event emitted when the Voting maanger is updated */
    event UpdatedVotingPowerManager(address indexed oldManager, address indexed newManager);
    /** @notice Event emitted when the Proposal maanger is updated */
    event UpdatedProposalPowerManager(address indexed oldManager, address indexed newManager);
    /** @notice Event emitted when the Reserve manager is updated */
    event UpdatedReserveManager(address indexed oldManager, address indexed newManager);
    /** @notice Event emitted when the Buffer ratio is updated */
    event UpdatedBufferRatio(uint256 oldRatio, uint256 newRatio);
    /** @notice Event emitted when the Reserve ratio is updated */
    event UpdatedReserveRatio(uint256 oldRatio, uint256 newRatio);

    /** @notice Event emitted when an ERC20 token is recovered */
    event TokenRecovered(address indexed token, uint256 amount);


    // Modifers

    /** @notice Check that the caller is the admin */
    modifier onlyAdmin() {
        if (msg.sender != admin) revert Errors.CallerNotAdmin();
        _;
    }

    /** @notice Check that the caller is the admin or the Reserve maanger */
    modifier onlyAllowed() {
        if (msg.sender != admin && msg.sender != reserveManager) revert Errors.CallerNotAdmin();
        _;
    }

    /** @notice Check that the contract is initialized */
    modifier isInitialized() {
        if (!initialized) revert Errors.NotInitialized();
        _;
    }


    // Constructor

    constructor(
        address _admin,
        uint256 _reserveRatio,
        address _reserveManager,
        address _aave,
        address _stkAave,
        string memory _name,
        string memory _symbol
    ) ScalingERC20(_name, _symbol) {
        if(_admin == address(0) || _reserveManager == address(0) || _aave == address(0) || _stkAave == address(0)) revert Errors.AddressZero();
        if(_reserveRatio == 0) revert Errors.NullAmount();

        admin = _admin;

        reserveRatio = _reserveRatio;
        reserveManager = _reserveManager;

        AAVE = _aave;
        STK_AAVE = _stkAave;
    }

    /**
    * @notice Initialize the Vault
    * @dev Initialize the Vault by performing a seed deposit & delegating voting power
    * @param _votingPowerManager Address to receive the voting power delegation
    * @param _proposalPowerManager Address to receive the proposal power delegation
    */
    function init(address _votingPowerManager, address _proposalPowerManager) external onlyAdmin {
        if(initialized) revert Errors.AlreadyInitialized();

        initialized = true;

        votingPowerManager = _votingPowerManager;
        proposalPowerManager = _proposalPowerManager;

        // Seed deposit to prevent 1 wei LP token exploit
        _deposit(
            SEED_DEPOSIT,
            msg.sender,
            msg.sender
        );

        // Set the delegates, so any received token updates the delegates power
        IGovernancePowerDelegationToken(STK_AAVE).delegateByType(
            _votingPowerManager,
            IGovernancePowerDelegationToken.DelegationType.VOTING_POWER
        );
        IGovernancePowerDelegationToken(STK_AAVE).delegateByType(
            _proposalPowerManager,
            IGovernancePowerDelegationToken.DelegationType.PROPOSITION_POWER
        );

        emit Initialized();
    }


    // View functions

    /**
    * @notice Get the vault's asset
    * @return address : Address of the asset
    */
    function asset() external view returns (address) {
        return STK_AAVE;
    }

    /**
    * @notice Get the total amount of assets in the Vault
    * @return uint256 : total amount of assets
    */
    function totalAssets() public view returns (uint256) {
        return
            IERC20(STK_AAVE).balanceOf(address(this)) +
            totalRentedAmount -
            reserveAmount;
    }

    /**
    * @notice Get the total supply of shares
    * @return uint256 : Total supply of shares
    */
    function totalSupply()
        public
        view
        override(ScalingERC20, IERC20)
        returns (uint256)
    {
        return totalAssets();
    }

    /**
    * @notice Get the current total amount of asset available in the Vault
    * @return uint256 : Current total amount available
    */
    function totalAvailable() public view returns (uint256) {
        uint256 availableBalance = IERC20(STK_AAVE).balanceOf(address(this));
        availableBalance = reserveAmount >= availableBalance ? 0 : availableBalance - reserveAmount;
        uint256 bufferAmount = (totalAssets() * bufferRatio) / MAX_BPS;
        return availableBalance > bufferAmount ? availableBalance - bufferAmount : 0;
    }

    /**
    * @notice Convert a given amount of assets to shares
    * @param assets amount of assets
    * @return uint256 : amount of shares
    */
    function convertToShares(uint256 assets) public pure returns (uint256) {
        // Because we use a ScalingERC20, shares of the user will grow over time to match the owed assets
        // (assets & shares are always 1:1)
        return assets;
    }

    /**
    * @notice Convert a given amount of shares to assets
    * @param shares amount of shares
    * @return uint256 : amount of assets
    */
    function convertToAssets(uint256 shares) public pure returns (uint256) {
        // Because we use a ScalingERC20, shares of the user will grow over time to match the owed assets
        // (assets & shares are always 1:1)
        return shares;
    }

    /**
    * @notice Return the amount of shares expected for depositing the given assets
    * @param assets Amount of assets to be deposited
    * @return uint256 : amount of shares
    */
    function previewDeposit(uint256 assets) public pure returns (uint256) {
        // Because we use a ScalingERC20, shares of the user will grow over time to match the owed assets
        // (assets & shares are always 1:1)
        return assets;
    }

    /**
    * @notice Return the amount of assets expected for minting the given shares
    * @param shares Amount of shares to be minted
    * @return uint256 : amount of assets
    */
    function previewMint(uint256 shares) public pure returns (uint256) {
        // Because we use a ScalingERC20, shares of the user will grow over time to match the owed assets
        // (assets & shares are always 1:1)
        return shares;
    }

    /**
    * @notice Return the amount of shares expected for withdrawing the given assets
    * @param assets Amount of assets to be withdrawn
    * @return uint256 : amount of shares
    */
    function previewWithdraw(uint256 assets) public pure returns (uint256) {
        // Because we use a ScalingERC20, shares of the user will grow over time to match the owed assets
        // (assets & shares are always 1:1)
        return assets;
    }

    /**
    * @notice Return the amount of assets expected for burning the given shares
    * @param shares Amount of shares to be burned
    * @return uint256 : amount of assets
    */
    function previewRedeem(uint256 shares) public pure returns (uint256) {
        // Because we use a ScalingERC20, shares of the user will grow over time to match the owed assets
        // (assets & shares are always 1:1)
        return shares;
    }

    /**
    * @notice Get the maximum amount that can be deposited by the user
    * @param user User address
    * @return uint256 : Max amount to deposit
    */
    function maxDeposit(address user) public view returns (uint256) {
        return type(uint256).max;
    }

    /**
    * @notice Get the maximum amount that can be minted by the user
    * @param user User address
    * @return uint256 : Max amount to mint
    */
    function maxMint(address user) public view returns (uint256) {
        return type(uint256).max;
    }

    /**
    * @notice Get the maximum amount that can be withdrawn by the user
    * @param owner Owner address
    * @return uint256 : Max amount to withdraw
    */
    function maxWithdraw(address owner) public view returns (uint256) {
        return balanceOf(owner);
    }

    /**
    * @notice Get the maximum amount that can be burned by the user
    * @param owner Owner address
    * @return uint256 : Max amount to burn
    */
    function maxRedeem(address owner) public view returns (uint256) {
        return balanceOf(owner);
    }

    /**
    * @notice Get the current index to convert between balance and scaled balances
    * @return uint256 : Current index
    */
    function getCurrentIndex() public view returns(uint256) {
        return _getCurrentIndex();
    }

    /**
    * @notice Get the current delegates for the Vault voting power & proposal power
    */
    function getDelegates() external view returns(address votingPower, address proposalPower) {
        return (votingPowerManager, proposalPowerManager);
    }


    // State-changing functions

    /**
    * @notice Deposit assets in the Vault & mint shares
    * @param assets Amount to deposit
    * @param receiver Address to receive the shares
    * @return shares - uint256 : Amount of shares minted
    */
    function deposit(
        uint256 assets,
        address receiver
    ) public isInitialized nonReentrant whenNotPaused returns (uint256 shares) {
        (assets, shares) = _deposit(assets, receiver, msg.sender);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
    * @notice Mint vault shares by depositing assets
    * @param shares Amount of shares to mint
    * @param receiver Address to receive the shares
    * @return assets - uint256 : Amount of assets deposited
    */
    function mint(
        uint256 shares,
        address receiver
        ) public isInitialized nonReentrant whenNotPaused returns (uint256 assets) {
        (assets, shares) = _deposit(shares, receiver, msg.sender);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
    * @notice Withdraw from the Vault & burn shares
    * @param assets Amount of assets to withdraw
    * @param receiver Address to receive the assets
    * @param owner Address of the owner of the shares
    * @return shares - uint256 : Amount of shares burned
    */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public isInitialized nonReentrant returns (uint256 shares) {
        (uint256 _withdrawn, uint256 _burntShares) = _withdraw(
            assets,
            owner,
            receiver,
            msg.sender
        );

        emit Withdraw(msg.sender, receiver, owner, _withdrawn, _burntShares);
        return _burntShares;
    }

    /**
    * @notice Burn shares to withdraw from the Vault
    * @param shares Amount of shares to burn
    * @param receiver Address to receive the assets
    * @param owner Address of the owner of the shares
    * @return assets - uint256 : Amount of assets withdrawn
    */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public isInitialized nonReentrant returns (uint256 assets) {
        (uint256 _withdrawn, uint256 _burntShares) = _withdraw(
            shares,
            owner,
            receiver,
            msg.sender
        );

        emit Withdraw(msg.sender, receiver, owner, _withdrawn, _burntShares);
        return _withdrawn;
    }

    /**
    * @notice Claim Safety Module rewards & stake them in stkAAVE
    */
    function updateStkAaveRewards() external nonReentrant {
        _getStkAaveRewards();
    }


    // Pods Manager functions

    /**
    * @notice Rent stkAAVE for a Pod
    * @dev Rent stkAAVE to a Pod, sending the amount & tracking the manager that requested 
    * @param pod Address of the Pod
    * @param amount Amount to rent
    */
    function rentStkAave(address pod, uint256 amount) external nonReentrant {
        address manager = msg.sender;
        if(!podManagers[manager].rentingAllowed) revert Errors.CallerNotAllowedManager();
        if(pod == address(0)) revert Errors.AddressZero();
        if(amount == 0) revert Errors.NullAmount();

        // Fetch Aave Safety Module rewards & stake them into stkAAVE
        _getStkAaveRewards();

        IERC20 _stkAave = IERC20(STK_AAVE);

        // Check that the asked amount is available :
        // - Vault has enough asset for the asked amount
        // - Asked amount does not include the buffer allocated to withdraws
        uint256 availableBalance = _stkAave.balanceOf(address(this));
        availableBalance = reserveAmount >= availableBalance ? 0 : availableBalance - reserveAmount;
        uint256 bufferAmount = (totalAssets() * bufferRatio) / MAX_BPS;
        if(availableBalance < bufferAmount) revert Errors.WithdrawBuffer();
        if(amount > (availableBalance - bufferAmount)) revert Errors.NotEnoughAvailableFunds();

        // Track the amount rented for the manager that requested it
        // & send the token to the Pod
        podManagers[manager].totalRented += safe248(amount);
        totalRentedAmount += amount;
        _stkAave.safeTransfer(pod, amount);
    
        emit RentToPod(manager, pod, amount);
    }

    /**
    * @notice Notify a claim on rented stkAAVE
    * @dev Notify the newly claimed rewards from rented stkAAVE to a Pod & add it as rented to the Pod
    * @param pod Address of the Pod
    * @param addedAmount Amount added
    */
    // To track pods stkAave claims & re-stake into the main balance for ScalingeRC20 logic
    function notifyRentedAmount(address pod, uint256 addedAmount) external nonReentrant {
        address manager = msg.sender;
        if(podManagers[manager].totalRented == 0) revert Errors.NotUndebtedManager();
        if(pod == address(0)) revert Errors.AddressZero();
        if(addedAmount == 0) revert Errors.NullAmount();

        // Update the total amount rented & the amount rented for the specific
        // maanger with the amount claimed from Aave's Safety Module via the Pod
        podManagers[manager].totalRented += safe248(addedAmount);
        totalRentedAmount += addedAmount;

        // Add the part taken as fees to the Reserve
        reserveAmount += (addedAmount * reserveRatio) / MAX_BPS;

        emit NotifyRentedAmount(manager, pod, addedAmount);
    }

    /**
    * @notice Pull rented stkAAVE from a Pod
    * @dev Pull stkAAVE from a Pod & update the tracked rented amount
    * @param pod Address of the Pod
    * @param amount Amount to pull
    */
    function pullRentedStkAave(address pod, uint256 amount) external nonReentrant {
        address manager = msg.sender;
        if(podManagers[manager].totalRented == 0) revert Errors.NotUndebtedManager();
        if(pod == address(0)) revert Errors.AddressZero();
        if(amount == 0) revert Errors.NullAmount();
        if(amount > podManagers[manager].totalRented) revert Errors.AmountExceedsDebt();

        // Fetch Aave Safety Module rewards & stake them into stkAAVE
        _getStkAaveRewards();

        // Pull the tokens from the Pod, and update the tracked rented amount for the
        // corresponding Manager
        podManagers[manager].totalRented -= safe248(amount);
        totalRentedAmount -= amount;
        // We consider that pod give MAX_UINT256 allowance to this contract when created
        IERC20(STK_AAVE).safeTransferFrom(pod, address(this), amount);

        emit PullFromPod(manager, pod, amount);
    }


    // Internal functions

    /**
    * @dev Get the current index to convert between balance and scaled balances
    * @return uint256 : Current index
    */
    function _getCurrentIndex() internal view override returns (uint256) {
        if(_totalSupply == 0) return INITIAL_INDEX;
        return totalAssets().rayDiv(_totalSupply);
    }

    /**
    * @dev Pull assets to deposit in the Vault & mint shares
    * @param amount Amount to deposit
    * @param receiver Address to receive the shares
    * @param depositor Address depositing the assets
    * @return uint256 : Amount of assets deposited
    * @return uint256 : Amount of shares minted
    */
    function _deposit(
        uint256 amount,
        address receiver,
        address depositor
    ) internal returns (uint256, uint256) {
        if (receiver == address(0)) revert Errors.AddressZero();
        if (amount == 0) revert Errors.NullAmount();

        // Fetch Aave Safety Module rewards & stake them into stkAAVE
        _getStkAaveRewards();

        // We need to get the index before pulling the assets
        // so we can have the correct one based on previous stkAave claim
        uint256 _currentIndex = _getCurrentIndex();

        // Pull tokens from the depositor
        IERC20(STK_AAVE).safeTransferFrom(depositor, address(this), amount);

        // Mint the scaled balance of the user to match the deposited amount
        uint256 minted = _mint(receiver, amount, _currentIndex);

        afterDeposit(amount);

        return (amount, minted);
    }

    /**
    * @dev Withdraw assets from the Vault & send to the receiver & burn shares
    * @param amount Amount to withdraw
    * @param owner Address owning the shares
    * @param receiver Address to receive the assets
    * @param sender Address of the caller
    * @return uint256 : Amount of assets withdrawn
    * @return uint256 : Amount of shares burned
    */
    function _withdraw(
        uint256 amount, // if `MAX_UINT256`, just withdraw everything
        address owner,
        address receiver,
        address sender
    ) internal returns (uint256, uint256) {
        if (receiver == address(0) || owner == address(0)) revert Errors.AddressZero();
        if (amount == 0) revert Errors.NullAmount();

        // Fetch Aave Safety Module rewards & stake them into stkAAVE
        _getStkAaveRewards();

        // If the user wants to withdraw their full balance
        bool _maxWithdraw;
        if(amount == MAX_UINT256) {
            amount = balanceOf(owner);
            _maxWithdraw = true;
        }

        // Check that the caller has the allowance to withdraw for the given owner
        if (owner != sender) {
            uint256 allowed = _allowances[owner][sender];
            if (allowed < amount) revert Errors.ERC20_AmountOverAllowance();
            if (allowed != type(uint256).max)
                _allowances[owner][sender] = allowed - amount;
        }

        IERC20 _stkAave = IERC20(STK_AAVE);

        // Check that the Vault has enough stkAave to send
        uint256 availableBalance = _stkAave.balanceOf(address(this));
        availableBalance = reserveAmount >= availableBalance ? 0 : availableBalance - reserveAmount;
        if(amount > availableBalance) revert Errors.NotEnoughAvailableFunds();

        // Burn the scaled balance matching the amount to withdraw
        uint256 burned = _burn(owner, amount, _maxWithdraw);

        beforeWithdraw(amount);

        // Send the tokens to the given receiver
        _stkAave.safeTransfer(receiver, amount);

        return (amount, burned);
    }

    /**
    * @dev Hook exectued before withdrawing
    * @param amount Amount to withdraw
    */
    function beforeWithdraw(uint256 amount) internal {}

    /**
    * @dev Hook exectued after depositing
    * @param amount Amount deposited
    */
    function afterDeposit(uint256 amount) internal {}

    /**
    * @dev Hook executed before each transfer
    * @param from Sender address
    * @param to Receiver address
    * @param amount Amount to transfer
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal isInitialized whenNotPaused override virtual {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
    * @dev Hook executed after each transfer
    * @param from Sender address
    * @param to Receiver address
    * @param amount Amount to transfer
    */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override virtual {
        super._afterTokenTransfer(from, to, amount);
    }

    /**
    * @dev Claim AAVE rewards from the Safety Module & stake them to receive stkAAVE
    */
    function _getStkAaveRewards() internal {
        IStakedAave _stkAave = IStakedAave(STK_AAVE);

        // Get pending rewards amount
        uint256 pendingRewards = _stkAave.getTotalRewardsBalance(address(this));

        if (pendingRewards > 0) {
            // Claim the AAVE tokens
            _stkAave.claimRewards(address(this), pendingRewards);

            // Set a part of the claimed amount as the Reserve (protocol fees)
            reserveAmount += (pendingRewards * reserveRatio) / MAX_BPS;
        }

        IERC20 _aave = IERC20(AAVE);
        uint256 currentBalance = _aave.balanceOf(address(this));
        
        if(currentBalance > 0) {
            // Increase allowance for the Safety Module & stake AAVE into stkAAVE
            _aave.safeIncreaseAllowance(STK_AAVE, currentBalance);
            _stkAave.stake(address(this), currentBalance);
        }
    }


    // Admin 
    
    /**
     * @notice Pause the contract
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /**
    * @notice Set a given address as the new pending admin
    * @param newAdmin Address to be the new admin
    */
    function transferAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert Errors.AddressZero();
        if (newAdmin == admin) revert Errors.CannotBeAdmin();
        address oldPendingAdmin = pendingAdmin;

        pendingAdmin = newAdmin;

        emit NewPendingAdmin(oldPendingAdmin, newAdmin);
    }

    /**
    * @notice Accpet adminship of the contract (must be the pending admin)
    */
    function acceptAdmin() external {
        if (msg.sender != pendingAdmin) revert Errors.CallerNotPendingAdmin();
        address newAdmin = pendingAdmin;
        address oldAdmin = admin;
        admin = newAdmin;
        pendingAdmin = address(0);

        emit AdminTransferred(oldAdmin, newAdmin);
        emit NewPendingAdmin(newAdmin, address(0));
    }

    /**
    * @notice Add a new Pod Manager
    * @param newManager Address of the new manager
    */
    function addPodManager(address newManager) external onlyAdmin {
        if(newManager == address(0)) revert Errors.AddressZero();
        if(podManagers[newManager].rentingAllowed) revert Errors.ManagerAlreadyListed();

        podManagers[newManager].rentingAllowed = true;

        emit NewPodManager(newManager);
    }

    /**
    * @notice Block a Pod Manager
    * @param manager Address of the manager
    */
    function blockPodManager(address manager) external onlyAdmin {
        if(manager == address(0)) revert Errors.AddressZero();
        if(!podManagers[manager].rentingAllowed) revert Errors.ManagerNotListed();

        podManagers[manager].rentingAllowed = false;

        emit BlockedPodManager(manager);
    }

    /**
    * @notice Update the Vault's voting power manager & delegate the voting power to it
    * @param newManager Address of the new manager
    */
    function updateVotingPowerManager(address newManager) external onlyAdmin {
        if(newManager == address(0)) revert Errors.AddressZero();
        if(newManager == votingPowerManager) revert Errors.SameAddress();

        address oldManager = votingPowerManager;
        votingPowerManager = newManager;

        IGovernancePowerDelegationToken(STK_AAVE).delegateByType(
            newManager,
            IGovernancePowerDelegationToken.DelegationType.VOTING_POWER
        );

        emit UpdatedVotingPowerManager(oldManager, newManager);
    }

    /**
    * @notice Update the Vault's proposal power manager & delegate the proposal power to it
    * @param newManager Address of the new manager
    */
    function updateProposalPowerManager(address newManager) external onlyAdmin {
        if(newManager == address(0)) revert Errors.AddressZero();
        if(newManager == proposalPowerManager) revert Errors.SameAddress();

        address oldManager = proposalPowerManager;
        proposalPowerManager = newManager;

        IGovernancePowerDelegationToken(STK_AAVE).delegateByType(
            newManager,
            IGovernancePowerDelegationToken.DelegationType.PROPOSITION_POWER
        );

        emit UpdatedProposalPowerManager(oldManager, newManager);
    }

    /**
    * @notice Update the Vault's Reserve manager
    * @param newManager Address of the new manager
    */
    function updateReserveManager(address newManager) external onlyAdmin {
        if(newManager == address(0)) revert Errors.AddressZero();
        if(newManager == reserveManager) revert Errors.SameAddress();

        address oldManager = reserveManager;
        reserveManager = newManager;

        emit UpdatedReserveManager(oldManager, newManager);
    }

    /**
    * @notice Uodate the reserve ratio parameter
    * @param newRatio New ratio value
    */
    function updateReserveRatio(uint256 newRatio) external onlyAdmin {
        if(newRatio > 1500) revert Errors.InvalidParameter();

        uint256 oldRatio = reserveRatio;
        reserveRatio = newRatio;

        emit UpdatedReserveRatio(oldRatio, newRatio);
    }

    /**
    * @notice Uodate the buffer ratio parameter
    * @param newRatio New ratio value
    */
    function updateBufferRatio(uint256 newRatio) external onlyAdmin {
        if(newRatio > 1500) revert Errors.InvalidParameter();

        uint256 oldRatio = bufferRatio;
        bufferRatio = newRatio;

        emit UpdatedBufferRatio(oldRatio, newRatio);
    }

    /**
     * @notice Deposit token in the reserve
     * @param amount Amount of token to deposit
     */
    function depositToReserve(uint256 amount) external nonReentrant onlyAllowed returns(bool) {
        if(amount == 0) revert Errors.NullAmount();

        // Fetch Aave Safety Module rewards & stake them into stkAAVE
        _getStkAaveRewards();

        IERC20(STK_AAVE).safeTransferFrom(msg.sender, address(this), amount);
        reserveAmount += amount;

        emit ReserveDeposit(msg.sender, amount);

        return true;
    }

    /**
     * @notice Withdraw tokens from the reserve to send to the given receiver
     * @param amount Amount of token to withdraw
     * @param receiver Address to receive the tokens
     */
    function withdrawFromReserve(uint256 amount, address receiver) external nonReentrant onlyAllowed returns(bool) {
        if(amount == 0) revert Errors.NullAmount();
        if(receiver == address(0)) revert Errors.AddressZero();
        if(amount > reserveAmount) revert Errors.ReserveTooLow();

        // Fetch Aave Safety Module rewards & stake them into stkAAVE
        _getStkAaveRewards();

        IERC20(STK_AAVE).safeTransfer(receiver, amount);
        reserveAmount -= amount;

        emit ReserveWithdraw(receiver, amount);

        return true;
    }

    /**
    * @notice Recover ERC2O tokens sent by mistake to the contract
    * @dev Recover ERC2O tokens sent by mistake to the contract
    * @param token Address of the ERC2O token
    * @return bool: success
    */
    function recoverERC20(address token) external onlyAdmin returns(bool) {
        if(token == AAVE || token == STK_AAVE) revert Errors.CannotRecoverToken();

        uint256 amount = IERC20(token).balanceOf(address(this));
        if(amount == 0) revert Errors.NullAmount();
        IERC20(token).safeTransfer(admin, amount);

        emit TokenRecovered(token, amount);

        return true;
    }

    // Maths

    function safe248(uint256 n) internal pure returns (uint248) {
        if(n > type(uint248).max) revert Errors.NumberExceed248Bits();
        return uint248(n);
    }

}