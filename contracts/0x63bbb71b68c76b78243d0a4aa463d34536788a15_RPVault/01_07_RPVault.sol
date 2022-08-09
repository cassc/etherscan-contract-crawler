//.██████..███████.███████.██.....██████..██████...██████.
//.██...██.██......██......██.....██...██.██...██.██....██
//.██████..█████...█████...██.....██████..██████..██....██
//.██...██.██......██......██.....██......██...██.██....██
//.██...██.███████.██......██.....██......██...██..██████.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Auth, Authority } from "solmate/auth/Auth.sol";
import { ERC4626Accounting } from "./ERC4626Accounting.sol";
import { IVaultConfig } from "./interfaces/IVaultConfig.sol";

/// @title RPVault
/// @notice epoch-based fund management contract that uses ERC4626 accounting logic.
/// @dev in this version, the contract does not actually use ERC4626 base functions.
/// @dev all vault tokens are stored in-contract, owned by farmer address.
/// @dev all assets are sent to farmer address each epoch change;
/// @dev except for: stored fee, pending withdrawals, & pending deposits.
/// @author mathdroid (https://github.com/mathdroid)
contract RPVault is ERC4626Accounting, Auth {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /// ██████████████ vault metadata ████████████████████████████████████████

    /// @notice aum = **external** assets under management
    uint256 public aum = 0;
    /// @notice aumCap = maximum aum allowed to be stored in the contract
    uint256 public aumCap = 0;
    /// @notice epoch = period of time where aum is being managed
    uint256 public epoch = 0;
    /// @notice farmer = administrative address, responsible for managing aum
    /// @dev the address where funds will go from/to the contract
    address public immutable farmer;
    /// @notice managementBlocksDuration = number of blocks where farmer can make amendments to the contract
    /// @dev this is to prevent mistakes when progressing epoch
    uint256 public managementBlocksDuration = 6000; // avg block time is 15 seconds, so this is ~24 hours
    /// @notice vault config contract
    address public vaultConfigAddress;

    /// ██████████████ fees ███████████████████████████████████████████████████

    /// @notice isFeeEnabled = flag to enable/disable fees
    bool public isFeeEnabled = false;
    /// @notice feeDistributor = address to receive fees from the contract
    address public feeDistributor;
    /// @notice managementFeeBps = management fee in basis points per second
    /// @dev only charged when delta AUM is positive in an epoch
    /// @dev management fee = (assetsExternalEnd - assetsExternalStart) * managementFeeBps / 1e5
    uint256 public managementFeeBps = 2000;
    /// @notice entry/exit fees are charged when a user enters/exits the contract
    uint256 public entryFeeBps = 100;
    /// @notice entry/exit fees are charged when a user enters/exits the contract
    uint256 public exitFeeBps = 100;
    /// @notice storedFee = the amount of stored fee in the contract
    uint256 public storedFee;
    /// @notice helper for fee calculation
    uint256 private constant BASIS = 10000;

    /// ██████████████ vault state per epoch ██████████████████████████████████
    struct VaultState {
        /// @dev starting AUM this epoch
        uint256 assetsExternalStart;
        /// @dev assets deposited by users during this epoch
        uint256 assetsToDeposit;
        /// @dev shares unlocked during this epoch
        uint256 sharesToRedeem;
        /// @dev the number of external AUM at the end of epoch (after fees)
        uint256 assetsExternalEnd;
        /// @dev management fee captured this epoch. maybe 0 if delta AUM <= 0
        /// @dev managementFee + assetsExternalEnd == aum input by farmer
        uint256 managementFee;
        /// @dev total vault tokens supply
        /// @dev no difference start/end of the epoch
        uint256 totalSupply;
        /// @dev last block number where farmer can edit the aum
        /// @dev only farmer can interact with contract before this blocknumber
        uint256 lastManagementBlock;
    }
    /// @notice vaultState = array of vault states per epoch
    mapping(uint256 => VaultState) public vaultStates;

    /// ██████████████ user balances ██████████████████████████████████████████
    struct VaultUser {
        /// @dev assets currently deposited, not yet included in aum
        /// @dev should be zeroed after epoch change (shares minted)
        uint256 assetsDeposited;
        /// @dev last epoch where user deposited assets
        uint256 epochLastDeposited;
        /// @dev glorified `balanceOf`
        uint256 vaultShares;
        /// @dev shares to be unlocked next epoch
        uint256 sharesToRedeem;
        /// @dev the epoch where user can start withdrawing the unlocked shares
        /// @dev use this epoch's redemption rate (aum/totalSupply) to calculate the amount of assets to be withdrawn
        uint256 epochToRedeem;
    }
    /// @notice vaultUsers = array of user balances per address
    mapping(address => VaultUser) public vaultUsers;

    /// ██████████████ errors █████████████████████████████████████████████████

    /// ░░░░░░░░░░░░░░ internal ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice transaction will result in zero shares given
    error DepositReturnsZeroShares();
    /// @notice transaction will result in zero assets given
    error RedeemReturnsZeroAssets();
    /// ░░░░░░░░░░░░░░ epoch ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice vault is still initializing
    error VaultIsInitializing();
    /// @notice vault has been initialized
    error VaultAlreadyInitialized();

    /// ░░░░░░░░░░░░░░ management phase ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice farmer function called outside management phase
    error OnlyAtManagementPhase();
    /// @notice public function called during management phase
    error OnlyOutsideManagementPhase();

    /// ░░░░░░░░░░░░░░ farmer ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice wrong aum cap value (lower than current aum, etc)
    error AumCapInvalid();
    /// @notice wrong ending aum value (infinite growth)
    error AumInvalid();
    /// @notice farmer asset allowance insufficient
    error FarmerInsufficientAllowance();
    /// @notice farmer asset balance insufficient
    error FarmerInsufficientBalance();

    /// ░░░░░░░░░░░░░░ fee ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice error setting fee config
    error FeeSettingsInvalid();
    /// @notice stored fees = 0;
    error FeeIsZero();

    /// ░░░░░░░░░░░░░░ deposit ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice deposit > aum cap
    error DepositExceedsAumCap();
    /// @notice deposit negated by config contract
    error DepositRequirementsNotMet();
    /// @notice deposit fees larger than sent amount
    error DepositFeeExceedsAssets();
    /// @notice has a pending withdrawal
    error DepositBlockedByWithdrawal();

    /// ░░░░░░░░░░░░░░ unlock ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice has a pending withdrawal already
    error UnlockBlockedByWithdrawal();
    /// @notice invalid amount e.g. 0
    error UnlockSharesAmountInvalid();
    /// @notice
    error UnlockExceedsShareBalance();

    /// ░░░░░░░░░░░░░░ withdraw ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice not the epoch to withdraw
    error WithdrawNotAvailableYet();

    /// ██████████████ events █████████████████████████████████████████████████
    /// @notice user events
    event UserDeposit(address indexed user, uint256 amount);
    event UserUnlock(address indexed user, uint256 amount);
    event UserWithdraw(address indexed user, address withdrawalAddress, uint256 amount);

    /// @notice vault events
    event EpochEnd(uint256 epoch, uint256 endingAssets);
    event EpochUpdated(uint256 epoch, uint256 endingAssets);
    event AumCapUpdated(uint256 aumCap);

    /// @notice fee events
    event StoredFeeSent(uint256 amount);
    event FeeUpdated(bool isFeeEnabled, uint256 entryFee, uint256 exitFee, uint256 managementFee);
    event FeeReceiverUpdated(address feeDistributor);

    /// ██████████████ modifiers ██████████████████████████████████████████████

    /// requiresAuth -> from solmate/Auth

    modifier onlyEpochZero() {
        if (epoch != 0) revert VaultAlreadyInitialized();
        _;
    }

    modifier exceptEpochZero() {
        if (epoch < 1) revert VaultIsInitializing();
        _;
    }

    modifier onlyManagementPhase() {
        if (!isManagementPhase()) {
            revert OnlyAtManagementPhase();
        }
        _;
    }

    modifier exceptManagementPhase() {
        if (isManagementPhase()) {
            revert OnlyOutsideManagementPhase();
        }
        _;
    }

    modifier canDeposit(address _user, uint256 _assets) {
        if (userHasPendingWithdrawal(_user)) {
            revert DepositBlockedByWithdrawal();
        }
        // cap must be higher than current AUM + pending deposit + incoming deposit
        if (_assets + getEffectiveAssets() > aumCap) {
            revert DepositExceedsAumCap();
        }

        if (vaultConfigAddress != address(0) && !IVaultConfig(vaultConfigAddress).canDeposit(_user, _assets)) {
            revert DepositRequirementsNotMet();
        }
        _;
    }

    modifier canUnlock(address _user, uint256 _shares) {
        if (_shares < 1) revert UnlockSharesAmountInvalid();
        if (msg.sender != _user) {
            uint256 allowed = allowance[_user][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[_user][msg.sender] = allowed - _shares;
        }

        if (userHasPendingWithdrawal(_user)) revert UnlockBlockedByWithdrawal();
        _;
    }

    modifier canWithdraw(address _user) {
        if (!userHasPendingWithdrawal(_user)) {
            revert WithdrawNotAvailableYet();
        }
        _;
    }

    modifier updatesPendingDeposit(address _user) {
        updatePendingDepositState(_user);
        _;
    }

    /// ██████████████ ERC4626 ████████████████████████████████████████████████
    /// ░░░░░░░░░░░░░░ constructor ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice create an RPVault
    /// @param _name token name, also used as vault name in the UI, omitting `Token` postfix
    /// @param _symbol token symbol, also used as vault symbol in the UI
    /// @param _farmer farmer address, responsible for managing aum
    /// @param _feeDistributor address to receive fees from the contract
    /// @param _underlying asset to be used as underlying asset for the vault
    /// @param _vaultConfig contract address to be used as vault config contract. if 0x0, default config will be used
    constructor(
        string memory _name,
        string memory _symbol,
        address _farmer,
        address _feeDistributor,
        address _underlying,
        address _vaultConfig
    ) ERC4626Accounting(ERC20(_underlying), _name, _symbol) Auth(_farmer, Authority(address(0))) {
        farmer = _farmer;
        feeDistributor = _feeDistributor;
        vaultConfigAddress = _vaultConfig;
    }

    /// @notice Get the amount of productive underlying tokens
    /// @dev used at self deposits/redeems at epoch change
    /// @return aum, total external productive assets
    function totalAssets() public view override returns (uint256) {
        return aum;
    }

    /// ██████████████ farmer functions ███████████████████████████████████████
    /*
        farmer's actions:
            - [x] starts vault with initial settings
            - [x] progress epoch
            - [x] update aum (management phase only)
            - [x] end management phase (management phase only)
            - [x] update aum cap
            - [x] enable/disable fees
            - [x] update fees
            - [x] update fee distributor
            - [x] update vault config address
    */

    /// @notice starts the vault with a custom initial aum
    /// @dev in most cases, initial aum = 0
    /// @param _initialExternalAsset initial aum, must be held by farmer
    /// @param _aumCap maximum asset that can be stored
    function startVault(uint256 _initialExternalAsset, uint256 _aumCap) external onlyEpochZero requiresAuth {
        if (_aumCap < _initialExternalAsset) {
            revert AumCapInvalid();
        }
        if (_initialExternalAsset != 0) {
            uint256 initialShare = _selfDeposit(_initialExternalAsset);
            vaultUsers[msg.sender].vaultShares = initialShare;
        }
        aumCap = _aumCap;
        epoch = 1;
        vaultStates[epoch].assetsExternalStart = aum;
        vaultStates[epoch].totalSupply = totalSupply;
        vaultStates[epoch].lastManagementBlock = block.number;
        emit EpochEnd(0, aum);
    }

    /// @notice Increment epoch from n to (n + 1)
    /// @dev goes to management phase after this function is called
    /// @param _assetsExternalEndBeforeFees current external asset (manual counting by farmer)
    /// @return newAUM (external asset)
    function progressEpoch(uint256 _assetsExternalEndBeforeFees) public requiresAuth exceptEpochZero returns (uint256) {
        // end epoch n
        (
            bool shouldTransferToFarm,
            uint256 totalAssetsToTransfer,
            bool shouldDepositDelta,
            uint256 deltaAssets,
            uint256 managementFee,
            uint256 assetsExternalEnd
        ) = previewProgress(_assetsExternalEndBeforeFees, epoch);

        storedFee += managementFee;
        vaultStates[epoch].managementFee = managementFee;

        aum = assetsExternalEnd;
        vaultStates[epoch].assetsExternalEnd = assetsExternalEnd;

        emit EpochEnd(epoch, aum);
        epoch++;

        // start epoch n + 1
        // transfer assets
        if (totalAssetsToTransfer > 0) {
            if (shouldTransferToFarm) {
                // if there are assets to be transferred to the farm, do it
                transferAssetToFarmer(totalAssetsToTransfer);
            } else {
                // transfer back to contract
                // msg.sender is farmer address
                transferAssetToContract(totalAssetsToTransfer);
            }
        }

        // self deposit/redeem delta
        if (deltaAssets > 0) {
            if (shouldDepositDelta) {
                // self-deposit, update aum
                _selfDeposit(deltaAssets);
            } else {
                // self-redeem, update aum
                _selfRedeem(convertToShares(deltaAssets));
            }
        }

        // if new aum is higher than the cap, increase the cap
        if (aum > aumCap) {
            aumCap = aum;
            emit AumCapUpdated(aumCap);
        }

        //  update vault state
        vaultStates[epoch].assetsExternalStart = aum;
        vaultStates[epoch].totalSupply = totalSupply;
        vaultStates[epoch].lastManagementBlock = block.number + managementBlocksDuration;
        return aum;
    }

    /// @notice amends last epoch's aum update
    /// @dev callable at management phase only
    /// @param _assetsExternalEndBeforeFees current external asset (manual counting by farmer)
    /// @return newAUM (external asset)
    // solhint-disable-next-line code-complexity
    function editAUM(uint256 _assetsExternalEndBeforeFees)
        public
        onlyManagementPhase
        requiresAuth
        returns (uint256 newAUM)
    {
        uint256 lastEpoch = epoch - 1;
        uint256 lastAssetsExternalEnd = vaultStates[lastEpoch].assetsExternalEnd;
        uint256 lastManagementFee = vaultStates[lastEpoch].managementFee;
        uint256 lastTotalSupply = vaultStates[lastEpoch].totalSupply;

        if (_assetsExternalEndBeforeFees == lastAssetsExternalEnd + lastManagementFee) {
            // no change in aum
            return lastAssetsExternalEnd;
        }
        (
            bool didTransferToFarm,
            uint256 totalAssetsTransferred, // bool didDepositDelta,
            ,
            ,
            ,

        ) = previewProgress(lastAssetsExternalEnd + lastManagementFee, lastEpoch);

        /// @dev rather than saving gas by combining these into 1 transfers but with overflow handling, we do it in 2
        /// @dev gas is paid by farmer (upkeep)

        // revert transfers
        if (totalAssetsTransferred > 0) {
            if (didTransferToFarm) {
                // revert
                transferAssetToContract(totalAssetsTransferred);
            } else {
                transferAssetToFarmer(totalAssetsTransferred);
            }
        }

        // // revert deposit/redeem using latest rate, update aum automatically
        if (totalSupply > lastTotalSupply) {
            _burn(address(this), totalSupply - lastTotalSupply);
        }

        if (totalSupply < lastTotalSupply) {
            _mint(address(this), lastTotalSupply - totalSupply);
        }

        // /// @dev by this point, aum should be the same as last epoch's aum
        storedFee -= lastManagementFee;
        epoch = lastEpoch;
        return progressEpoch(_assetsExternalEndBeforeFees);
    }

    /// @notice ends management phase, allow users to deposit/unlock/withdraw
    function endManagementPhase() public requiresAuth onlyManagementPhase {
        vaultStates[epoch].lastManagementBlock = block.number;
    }

    /// @notice change AUM cap
    /// @param _aumCap new AUM cap
    function updateAumCap(uint256 _aumCap) public requiresAuth {
        if (aumCap < getEffectiveAssets()) {
            revert AumCapInvalid();
        }
        aumCap = _aumCap;
    }

    /// @notice toggle fees on/off
    /// @param _isFeeEnabled true to enable fees, false to disable fees
    function setIsFeeEnabled(bool _isFeeEnabled) public requiresAuth {
        if (isFeeEnabled == _isFeeEnabled) {
            revert FeeSettingsInvalid();
        }
        isFeeEnabled = _isFeeEnabled;
    }

    /// @notice update fees
    function setFees(
        uint256 _managementFeeBps,
        uint256 _entryFeeBps,
        uint256 _exitFeeBps
    ) public requiresAuth {
        if (_managementFeeBps > BASIS || _entryFeeBps > BASIS || _exitFeeBps > BASIS) {
            revert FeeSettingsInvalid();
        }
        managementFeeBps = _managementFeeBps;
        entryFeeBps = _entryFeeBps;
        exitFeeBps = _exitFeeBps;
    }

    /// @notice update fee distributor
    function setFeeDistributor(address _feeDistributor) public requiresAuth {
        if (_feeDistributor == address(0)) {
            revert FeeSettingsInvalid();
        }
        feeDistributor = _feeDistributor;
    }

    function setVaultConfigAddress(address _vaultConfigAddress) public requiresAuth {
        vaultConfigAddress = _vaultConfigAddress;
    }

    /// ██████████████ user functions █████████████████████████████████████████
    /*
        A user can only do:
            - [x] deposit (not to be confused with ERC4626 deposit)
                - minimum/maximum rule set in the vaultConfig contract
            - [x] unlock
            - [x] withdraw (not to be confused with ERC4626 withdraw)

    */

    /// ░░░░░░░░░░░░░░ deposit ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice a user stores assets in the contract to enter in the next epoch
    /// @dev funds should be withdrawable before epoch progresses
    /// @dev actual share minting happens at the epoch progression
    /// @dev share minting uses next epoch's starting exchange rate
    function deposit(uint256 _assets) external exceptEpochZero exceptManagementPhase returns (uint256) {
        return deposit(_assets, msg.sender);
    }

    function deposit(uint256 _assets, address _for)
        public
        exceptEpochZero
        exceptManagementPhase
        canDeposit(_for, _assets)
        updatesPendingDeposit(_for)
        returns (uint256)
    {
        uint256 depositFee = getDepositFee(_assets, _for);
        if (depositFee >= _assets) {
            revert DepositFeeExceedsAssets();
        }
        uint256 netAssets = _assets - depositFee;

        storedFee += depositFee;

        /// last deposit epoch = 0
        /// assetDeposited = 0

        vaultUsers[_for].epochLastDeposited = epoch;
        vaultUsers[_for].assetsDeposited += netAssets;

        // update vault state
        vaultStates[epoch].assetsToDeposit += netAssets;

        // transfer asset to vault
        asset.safeTransferFrom(msg.sender, address(this), _assets);
        emit UserDeposit(_for, netAssets);
        return netAssets;
    }

    /// ░░░░░░░░░░░░░░ unlock (withdraw 1/2) ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice unlock _shares for withdrawal at next available epoch
    function unlock(uint256 _shares) external exceptEpochZero exceptManagementPhase returns (uint256) {
        return unlock(_shares, msg.sender);
    }

    function unlock(uint256 _shares, address _owner)
        public
        exceptEpochZero
        exceptManagementPhase
        canUnlock(_owner, _shares)
        updatesPendingDeposit(_owner)
        returns (uint256)
    {
        // updatePendingDepositState(msg.sender);

        if (vaultUsers[_owner].vaultShares < vaultUsers[_owner].sharesToRedeem + _shares) {
            revert UnlockExceedsShareBalance();
        }

        vaultUsers[_owner].sharesToRedeem += _shares;
        vaultUsers[_owner].epochToRedeem = epoch + 1;
        vaultStates[epoch].sharesToRedeem += _shares;

        emit UserUnlock(_owner, _shares);
        return _shares;
    }

    /// ░░░░░░░░░░░░░░ finalize (withdraw 2/2) ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice withdraw all available asset for user
    function withdraw() external exceptEpochZero exceptManagementPhase returns (uint256) {
        return withdraw(msg.sender);
    }

    function withdraw(address _to)
        public
        exceptEpochZero
        exceptManagementPhase
        canWithdraw(msg.sender)
        updatesPendingDeposit(msg.sender)
        returns (uint256)
    {
        (uint256 totalAssetValue, uint256 withdrawalFee) = getWithdrawalAmount(msg.sender);

        vaultUsers[msg.sender].vaultShares -= vaultUsers[msg.sender].sharesToRedeem;
        vaultUsers[msg.sender].sharesToRedeem = 0;
        vaultUsers[msg.sender].epochToRedeem = 0;
        storedFee += withdrawalFee;

        if (withdrawalFee == totalAssetValue) {
            // @dev for really small values, we can't afford to lose precision
            return 0;
        }

        uint256 transferValue = totalAssetValue - withdrawalFee;
        asset.transfer(_to, transferValue);

        emit UserWithdraw(msg.sender, _to, transferValue);
        return transferValue;
    }

    /// ██████████████ public functions ███████████████████████████████████████
    /*
        public functions:
            - [x] preview funds flow from/to contract next epoch
            - [x] check if user can deposit/unlock/withdraw
            - [x] send stored fees to fee distributor
            - [x] get maximum deposit amount
    */
    /// @notice preview funds flow from/to contract next epoch
    /// @dev assets to transfer = deltaAssets - managementFee
    /// @dev sign shows direction of transfer (true = to farm, false = to contract)
    /// @param _assetsExternalEndBeforeFees amount of external aum before fees
    /// @return shouldTransferToFarm direction of funds to transfer
    /// @return totalAssetsToTransfer amount of assets to transfer
    /// @return shouldDepositDelta true if deltaAssets should be deposited, false if deltaAssets should be redeemed
    /// @return deltaAssets amount of assets to deposit/redeem
    /// @return managementFee amount of management fee for next epoch
    /// @return assetsExternalEnd amount of vault ending aum. assetsExternalEnd = _assetsExternalEndBeforeFees - fees
    function previewProgress(uint256 _assetsExternalEndBeforeFees)
        public
        view
        returns (
            bool shouldTransferToFarm,
            uint256 totalAssetsToTransfer,
            bool shouldDepositDelta,
            uint256 deltaAssets,
            uint256 managementFee,
            uint256 assetsExternalEnd
        )
    {
        return previewProgress(_assetsExternalEndBeforeFees, epoch);
    }

    function previewProgress(uint256 _assetsExternalEndBeforeFees, uint256 _epoch)
        public
        view
        returns (
            bool shouldTransferToFarm,
            uint256 totalAssetsToTransfer,
            bool shouldDepositDelta,
            uint256 deltaAssets,
            uint256 managementFee,
            uint256 assetsExternalEnd
        )
    {
        uint256 epochTotalSupply = _epoch == epoch ? totalSupply : vaultStates[_epoch].totalSupply;

        uint256 assetsExternalStart = vaultStates[_epoch].assetsExternalStart;
        uint256 assetsToDeposit = vaultStates[_epoch].assetsToDeposit;
        uint256 sharesToRedeem = vaultStates[_epoch].sharesToRedeem;

        if (assetsExternalStart == 0 && _assetsExternalEndBeforeFees > 0) {
            revert AumInvalid();
        }

        managementFee = getManagementFee(assetsExternalStart, _assetsExternalEndBeforeFees);
        assetsExternalEnd = _assetsExternalEndBeforeFees - managementFee;

        /// @dev at 0 supply, rate is 1:1
        uint256 redeemAssetValue = epochTotalSupply == 0
            ? sharesToRedeem
            : sharesToRedeem.mulDivDown(assetsExternalEnd, epochTotalSupply);

        /// @dev if true, the delta (deltaAssets) will be used in selfDeposit.
        /// @dev if false, the delta will be "soft-used" in selfRedeem(shares);

        shouldDepositDelta = assetsToDeposit > redeemAssetValue;
        deltaAssets = shouldDepositDelta ? assetsToDeposit - redeemAssetValue : redeemAssetValue - assetsToDeposit;

        if (shouldDepositDelta) {
            // if deposit is bigger, transfer to farm
            // subtract by management fee
            if (managementFee > deltaAssets) {
                // reverse if fee > delta
                totalAssetsToTransfer = managementFee - deltaAssets;
                shouldTransferToFarm = false;
            } else {
                totalAssetsToTransfer = deltaAssets - managementFee;
                shouldTransferToFarm = true;
            }
        } else {
            // if redeem value is bigger, transfer to contract
            // add management fee
            totalAssetsToTransfer = deltaAssets + managementFee;
            shouldTransferToFarm = false;
        }

        return (
            shouldTransferToFarm,
            totalAssetsToTransfer,
            shouldDepositDelta,
            deltaAssets,
            managementFee,
            assetsExternalEnd
        );
    }

    function isManagementPhase() public view returns (bool) {
        return block.number <= vaultStates[epoch].lastManagementBlock;
    }

    /// @notice sends stored fee to fee distributor
    function sendFee() public exceptManagementPhase {
        if (storedFee == 0) {
            revert FeeIsZero();
        }
        uint256 amount = storedFee;
        storedFee = 0;
        asset.transfer(feeDistributor, amount);
        emit StoredFeeSent(storedFee);
    }

    /// @notice get maximum deposit amount
    function getMaxDeposit() public view returns (uint256) {
        return aumCap - getEffectiveAssets();
    }

    /// @notice preview deposit on epoch
    function previewDepositEpoch(uint256 _assets, uint256 _epoch) public view returns (uint256) {
        if (vaultStates[_epoch].totalSupply == 0 || vaultStates[_epoch].assetsExternalStart == 0) {
            return _assets;
        }
        return _assets.mulDivDown(vaultStates[_epoch].totalSupply, vaultStates[_epoch].assetsExternalStart);
    }

    /// ██████████████ internals ██████████████████████████████████████████████
    // TODO: internalize before deploy
    /// @notice self-deposit, uses ERC4626 calculations, without actual transfer
    /// @dev updates AUM
    /// @param _assets number of assets to deposit
    /// @return shares minted
    function _selfDeposit(uint256 _assets) internal returns (uint256) {
        uint256 shares;
        if ((shares = previewDeposit(_assets)) == 0) revert DepositReturnsZeroShares();

        _mint(address(this), shares);
        aum += _assets;

        emit Deposit(msg.sender, address(this), _assets, shares);

        return shares;
    }

    /// @notice self-redeem, uses ERC4626 calculations, without actual transfer
    /// @dev updates AUM
    /// @param _shares number of shares to redeem
    /// @return assets value of burned shares
    function _selfRedeem(uint256 _shares) internal returns (uint256) {
        uint256 assets;
        // Check for rounding error since we round down in previewRedeem.
        if ((assets = previewRedeem(_shares)) == 0) revert RedeemReturnsZeroAssets();

        _burn(address(this), _shares);
        aum -= assets;

        emit Withdraw(msg.sender, address(this), address(this), assets, _shares);
        return assets;
    }

    /// @notice calculate management fee based on aum change
    /// @param _assetsExternalStart assets at start of epoch
    /// @param _assetsExternalEndBeforeFees assets at end of epoch
    /// @return managementFee management fees in asset
    function getManagementFee(uint256 _assetsExternalStart, uint256 _assetsExternalEndBeforeFees)
        internal
        view
        returns (uint256)
    {
        if (!isFeeEnabled) {
            return 0;
        }
        return
            (_assetsExternalEndBeforeFees > _assetsExternalStart && managementFeeBps > 0)
                ? managementFeeBps.mulDivUp(_assetsExternalEndBeforeFees - _assetsExternalStart, BASIS)
                : 0;
    }

    function transferAssetToFarmer(uint256 _assets) internal returns (bool) {
        return asset.transfer(farmer, _assets);
    }

    function transferAssetToContract(uint256 _assets) internal {
        if (asset.allowance(msg.sender, address(this)) < _assets) {
            revert FarmerInsufficientAllowance();
        }
        if (asset.balanceOf(msg.sender) < _assets) {
            revert FarmerInsufficientBalance();
        }
        return asset.safeTransferFrom(msg.sender, address(this), _assets);
    }

    function getEffectiveAssets() internal view returns (uint256) {
        return aum + vaultStates[epoch].assetsToDeposit;
    }

    /// @notice update VaultUser's data if they have pending deposits
    /// @param _user address of the VaultUser
    /// @dev after this, last deposit epoch = 0, assetDeposited = 0
    /// @dev can be manually called
    function updatePendingDepositState(address _user) public {
        // @dev check if user has already stored assets
        if (userHasPendingDeposit(_user)) {
            // @dev user should already have shares here, let's increment
            vaultUsers[_user].vaultShares += previewDepositEpoch(
                vaultUsers[_user].assetsDeposited,
                vaultUsers[_user].epochLastDeposited + 1
            );

            vaultUsers[_user].assetsDeposited = 0;
            vaultUsers[_user].epochLastDeposited = 0;
        }
    }

    /// @notice check if user has pending deposits
    /// @param _user address of the VaultUser
    /// @return true if user has pending deposits
    function userHasPendingDeposit(address _user) public view returns (bool) {
        uint256 userEpoch = vaultUsers[_user].epochLastDeposited;
        return userEpoch != 0 && epoch > userEpoch;
    }

    /// @notice get deposit fee for user
    function getDepositFee(uint256 _assets, address _user) public view returns (uint256) {
        if (vaultConfigAddress != address(0) && IVaultConfig(vaultConfigAddress).isFeeEnabled(_user)) {
            return _assets.mulDivUp(IVaultConfig(vaultConfigAddress).entryFeeBps(_user), BASIS);
        } else {
            return isFeeEnabled ? _assets.mulDivUp(entryFeeBps, BASIS) : 0;
        }
    }

    /// @notice check if a user has pending, unlocked funds to withdraw
    function userHasPendingWithdrawal(address _user) public view returns (bool) {
        return vaultUsers[_user].epochToRedeem > 0 && vaultUsers[_user].epochToRedeem <= epoch;
    }

    function getStoredValue(address _user) public view returns (uint256 userAssetValue) {
        VaultUser memory user = vaultUsers[_user];

        uint256 userShares = user.vaultShares;

        if (userHasPendingDeposit(_user)) {
            // shares has been minted, user state not yet updated
            userShares += previewDepositEpoch(user.assetsDeposited, user.epochLastDeposited + 1);
        } else {
            // still currently pending (no minted shares yet)
            userAssetValue += user.assetsDeposited;
        }

        userAssetValue += convertToAssets(userShares);
    }

    function getWithdrawalFee(uint256 _assets, address _user) public view returns (uint256) {
        if (vaultConfigAddress != address(0) && IVaultConfig(vaultConfigAddress).isFeeEnabled(_user)) {
            return _assets.mulDivUp(IVaultConfig(vaultConfigAddress).exitFeeBps(_user), BASIS);
        } else {
            return isFeeEnabled ? _assets.mulDivUp(exitFeeBps, BASIS) : 0;
        }
    }

    function getWithdrawalAmount(address _owner) public view returns (uint256, uint256) {
        if (!userHasPendingWithdrawal(_owner)) return (0, 0);
        uint256 epochToRedeem = vaultUsers[_owner].epochToRedeem;
        uint256 sharesToRedeem = vaultUsers[_owner].sharesToRedeem;
        uint256 assetsExternalStart = vaultStates[epochToRedeem].assetsExternalStart;
        uint256 totalSupplyAtRedeem = vaultStates[epochToRedeem].totalSupply;

        if (assetsExternalStart == 0 || totalSupplyAtRedeem == 0) {
            return (0, 0);
        }

        uint256 totalAssetValue = sharesToRedeem.mulDivDown(
            vaultStates[epochToRedeem].assetsExternalStart,
            vaultStates[epochToRedeem].totalSupply
        );
        uint256 fee = getWithdrawalFee(totalAssetValue, _owner);

        return (totalAssetValue, fee);
    }
}