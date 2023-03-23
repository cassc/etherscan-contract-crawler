// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IDataStructures } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol";

import { ILiquidStakingManager } from "../interfaces/ILiquidStakingManager.sol";

import { StakingFundsVault } from "./StakingFundsVault.sol";
import { LPToken } from "./LPToken.sol";
import { ETHPoolLPFactory } from "./ETHPoolLPFactory.sol";
import { LPTokenFactory } from "./LPTokenFactory.sol";
import { ETHTransferHelper } from "../transfer/ETHTransferHelper.sol";

contract SavETHVault is Initializable, ETHPoolLPFactory, ReentrancyGuard, ETHTransferHelper {

    /// @notice signalize transfer of dETH to depositor
    event DETHRedeemed(address depositor, uint256 amount);

    /// @notice signalize withdrawal of ETH for staking
    event ETHWithdrawnForStaking(address withdrawalAddress, address liquidStakingManager, uint256 amount);

    /// @notice signalize deposit of dETH and isolation of KNOT in the index
    event DETHDeposited(bytes blsPublicKeyOfKnot, uint128 dETHDeposited, uint256 lpTokensIssued);

    /// @notice Liquid staking manager instance
    ILiquidStakingManager public liquidStakingManager;

    /// @notice index id of the savETH index owned by the vault
    uint256 public indexOwnedByTheVault;

    /// @notice Amount of tokens minted each time a KNOT is added to the universe. Denominated in ether due to redemption rights
    uint256 public constant KNOT_BATCH_AMOUNT = 24 ether;

    /// @notice dETH related details for a KNOT
    /// @dev If dETH is not withdrawn, then for a non-existing dETH balance
    /// the structure would result in zero balance even though dETH isn't withdrawn for KNOT
    /// withdrawn parameter tracks the status of dETH for a KNOT
    struct KnotDETHDetails {
        uint256 savETHBalance;
        bool withdrawn;
    }

    /// @notice dETH associated with the KNOT
    mapping(bytes => KnotDETHDetails) public dETHForKnot;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(address _liquidStakingManagerAddress, LPTokenFactory _lpTokenFactory) external virtual initializer {
        _init(_liquidStakingManagerAddress, _lpTokenFactory);
    }

    modifier onlyManager {
        require(msg.sender == address(liquidStakingManager), "Not the savETH vault manager");
        _;
    }

    /// @notice Stake ETH against multiple BLS keys and specify the amount of ETH being supplied for each key
    /// @param _blsPublicKeyOfKnots BLS public key of the validators being staked and that are registered with the LSD network
    /// @param _amounts Amount of ETH being supplied for the BLS public key at the same array index
    function batchDepositETHForStaking(bytes[] calldata _blsPublicKeyOfKnots, uint256[] calldata _amounts) external payable {
        uint256 numOfValidators = _blsPublicKeyOfKnots.length;
        require(numOfValidators > 0, "Empty arrays");
        require(numOfValidators == _amounts.length, "Inconsistent array lengths");

        uint256 totalAmount;
        for (uint256 i; i < numOfValidators; ++i) {
            require(liquidStakingManager.isBLSPublicKeyBanned(_blsPublicKeyOfKnots[i]) == false, "BLS public key is not part of LSD network");
            require(
                getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnots[i]) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
                "Lifecycle status must be one"
            );

            uint256 amount = _amounts[i];
            totalAmount += amount;
            _depositETHForStaking(_blsPublicKeyOfKnots[i], amount, false);
        }

        // Ensure that the sum of LP tokens issued equals the ETH deposited into the contract
        require(msg.value == totalAmount, "Invalid ETH amount attached");
    }

    /// @notice function to allow users to deposit any amount of ETH for staking
    /// @param _blsPublicKeyOfKnot BLS Public Key of the potential KNOT for which user is contributing
    /// @param _amount number of ETH (input in wei) contributed by the user for staking
    /// @return amount of ETH contributed for staking by the user
    function depositETHForStaking(bytes calldata _blsPublicKeyOfKnot, uint256 _amount) public payable returns (uint256) {
        require(liquidStakingManager.isBLSPublicKeyBanned(_blsPublicKeyOfKnot) == false, "BLS public key is banned or not a part of LSD network");
        require(
            getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnot) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
            "Lifecycle status must be one"
        );

        require(msg.value == _amount, "Must provide correct amount of ETH");
        _depositETHForStaking(_blsPublicKeyOfKnot, _amount, false);

        return _amount;
    }
    
    /// @notice fetch dETH required to be deposited to isolate KNOT in the index
    /// @param _blsPublicKeyOfKnot BLS public key of the KNOT to be isolated
    /// @return uint128 dETH amount
    function dETHRequiredToIsolateWithdrawnKnot(bytes calldata _blsPublicKeyOfKnot) public view returns (uint128) {

        KnotDETHDetails memory dETHDetails = dETHForKnot[_blsPublicKeyOfKnot];
        require(dETHDetails.withdrawn == true, "KNOT is already isolated");

        LPToken token = lpTokenForKnot[_blsPublicKeyOfKnot];
        uint256 lpSharesBurned = KNOT_BATCH_AMOUNT - token.totalSupply();

        uint256 dETHRequiredForIsolation = KNOT_BATCH_AMOUNT + getSavETHRegistry().dETHRewardsMintedForKnot(_blsPublicKeyOfKnot);

        uint256 savETHBurnt = (dETHDetails.savETHBalance * lpSharesBurned) / KNOT_BATCH_AMOUNT;
        uint256 currentSavETH = dETHDetails.savETHBalance - savETHBurnt;
        uint256 currentDETH = getSavETHRegistry().savETHToDETH(currentSavETH);

        return uint128(dETHRequiredForIsolation - currentDETH);
    }

    /// @notice function to allows users to deposit dETH in exchange of LP shares
    /// @param _blsPublicKeyOfKnot BLS Public Key of the KNOT for which user is contributing
    /// @param _amount number of dETH (input in wei) contributed by the user
    /// @return amount of LP shares issued to the user
    function depositDETHForStaking(bytes calldata _blsPublicKeyOfKnot, uint128 _amount) public returns (uint256) {
        require(_amount >= uint128(0.001 ether), "Amount must be at least 0.001 ether");
        
        // only allow dETH deposits for KNOTs that have minted derivatives
        require(
            getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnot) == IDataStructures.LifecycleStatus.TOKENS_MINTED,
            "Lifecycle status must be three"
        );

        uint128 requiredDETH = dETHRequiredToIsolateWithdrawnKnot(_blsPublicKeyOfKnot);
        require(_amount == requiredDETH, "Amount must be equal to dETH required to isolate");
        require(uint128(getDETH().balanceOf(msg.sender)) >= _amount, "Insufficient dETH balance");

        // transfer dETH from user to the pool
        getDETH().transferFrom(msg.sender, address(this), uint256(_amount));
        getSavETHRegistry().deposit(address(this), _amount);

        getSavETHRegistry().isolateKnotFromOpenIndex(
            liquidStakingManager.stakehouse(),
            _blsPublicKeyOfKnot,
            indexOwnedByTheVault
        );

        LPToken token = lpTokenForKnot[_blsPublicKeyOfKnot];
        uint256 lpSharesBurned = KNOT_BATCH_AMOUNT - token.totalSupply();
        // mint the previously burned LP shares
        token.mint(msg.sender, lpSharesBurned);

        KnotDETHDetails storage dETHDetails = dETHForKnot[_blsPublicKeyOfKnot];
        // update withdrawn status to allow future withdrawals
        dETHDetails.withdrawn = false;
        dETHDetails.savETHBalance = 0;

        emit DETHDeposited(_blsPublicKeyOfKnot, _amount, lpSharesBurned);

        return lpSharesBurned;
    }

    /// @notice Burn multiple LP tokens in a batch to claim either ETH (if not staked) or dETH (if derivatives minted)
    /// @param _blsPublicKeys List of BLS public keys that have received liquidity
    /// @param _amounts Amount of each LP token that the user wants to burn in exchange for either ETH (if not staked) or dETH (if derivatives minted)
    function burnLPTokensByBLS(bytes[] calldata _blsPublicKeys, uint256[] calldata _amounts) external {
        uint256 numOfTokens = _blsPublicKeys.length;
        require(numOfTokens > 0, "Empty arrays");
        require(numOfTokens == _amounts.length, "Inconsistent array length");
        for (uint256 i; i < numOfTokens; ++i) {
            LPToken token = lpTokenForKnot[_blsPublicKeys[i]];
            burnLPToken(token, _amounts[i]);
        }
    }

    /// @notice Burn multiple LP tokens in a batch to claim either ETH (if not staked) or dETH (if derivatives minted)
    /// @param _lpTokens List of LP token addresses held by the caller
    /// @param _amounts Amount of each LP token that the user wants to burn in exchange for either ETH (if not staked) or dETH (if derivatives minted)
    function burnLPTokens(LPToken[] calldata _lpTokens, uint256[] calldata _amounts) external {
        uint256 numOfTokens = _lpTokens.length;
        require(numOfTokens > 0, "Empty arrays");
        require(numOfTokens == _amounts.length, "Inconsisent array length");
        for (uint256 i; i < numOfTokens; ++i) {
            burnLPToken(_lpTokens[i], _amounts[i]);
        }
    }

    /// @notice function to allow users to burn LP token in exchange of ETH or dETH
    /// @param _lpToken instance of LP token to be burnt
    /// @param _amount number of LP tokens the user wants to burn
    /// @return amount of ETH withdrawn
    function burnLPToken(LPToken _lpToken, uint256 _amount) public nonReentrant returns (uint256) {
        require(_amount >= MIN_STAKING_AMOUNT, "Amount cannot be zero");
        require(_amount <= _lpToken.balanceOf(msg.sender), "Not enough balance");

        // get BLS public key for the LP token
        bytes memory blsPublicKeyOfKnot = KnotAssociatedWithLPToken[_lpToken];
        IDataStructures.LifecycleStatus validatorStatus = getAccountManager().blsPublicKeyToLifecycleStatus(blsPublicKeyOfKnot);

        require(
            validatorStatus == IDataStructures.LifecycleStatus.INITIALS_REGISTERED ||
            validatorStatus == IDataStructures.LifecycleStatus.TOKENS_MINTED,
            "Cannot burn LP tokens"
        );

        // before burning, check the last LP token interaction and make sure its more than 30 mins old before permitting ETH withdrawals
        bool isStaleLiquidity = _lpToken.lastInteractedTimestamp(msg.sender) + 30 minutes < block.timestamp;

        // burn the amount of LP token from depositor's wallet
        _lpToken.burn(msg.sender, _amount);
        emit LPTokenBurnt(blsPublicKeyOfKnot, address(_lpToken), msg.sender, _amount);

        if(validatorStatus == IDataStructures.LifecycleStatus.TOKENS_MINTED) {
            // return dETH
            // amount of dETH redeemed by user for given LP token
            uint256 redemptionValue;

            KnotDETHDetails storage dETHDetails = dETHForKnot[blsPublicKeyOfKnot];

            if(!dETHDetails.withdrawn) {
                // withdraw dETH if not done already

                // get dETH balance for the KNOT
                uint256 dETHBalance = getSavETHRegistry().knotDETHBalanceInIndex(indexOwnedByTheVault, blsPublicKeyOfKnot);
                uint256 savETHBalance = getSavETHRegistry().dETHToSavETH(dETHBalance);
                // This require should never fail but is there for sanity purposes
                require(dETHBalance >= 24 ether, "Nothing to withdraw");

                // withdraw savETH from savETH index to the savETH vault
                // contract gets savETH and not the dETH
                getSavETHRegistry().addKnotToOpenIndex(liquidStakingManager.stakehouse(), blsPublicKeyOfKnot, address(this));

                // update mapping
                dETHDetails.withdrawn = true;
                dETHDetails.savETHBalance = savETHBalance;
                dETHForKnot[blsPublicKeyOfKnot] = dETHDetails;
            }

            // redeem savETH from the vault
            redemptionValue = (dETHDetails.savETHBalance * _amount) / 24 ether;

            // withdraw dETH (after burning the savETH)
            getSavETHRegistry().withdraw(msg.sender, uint128(redemptionValue));

            uint256 dETHRedeemed = getSavETHRegistry().savETHToDETH(redemptionValue);

            emit DETHRedeemed(msg.sender, dETHRedeemed);
            return redemptionValue;
        }

        // Before allowing ETH withdrawals we check the value of isStaleLiquidity fetched before burn
        require(isStaleLiquidity, "Liquidity is still fresh");

        // return ETH for LifecycleStatus.INITIALS_REGISTERED
        _transferETH(msg.sender, _amount);
        emit ETHWithdrawnByDepositor(msg.sender, _amount);

        return _amount;
    }

    /// @notice function to allow liquid staking manager to withdraw ETH for staking
    /// @param _smartWallet address of the smart wallet that receives ETH
    /// @param _amount amount of ETH to be withdrawn
    /// @return amount of ETH withdrawn
    function withdrawETHForStaking(
        address _smartWallet,
        uint256 _amount
    ) public onlyManager nonReentrant returns (uint256) {
        require(_amount >= 24 ether, "Amount cannot be less than 24 ether");
        require(address(this).balance >= _amount, "Insufficient withdrawal amount");
        require(_smartWallet != address(0), "Zero address");
        require(_smartWallet != address(this), "This address");

        _transferETH(_smartWallet, _amount);

        emit ETHWithdrawnForStaking(_smartWallet, msg.sender, _amount);

        return _amount;
    }

    /// @notice Utility function that proxies through to the liquid staking manager to check whether the BLS key ever registered with the network
    function isBLSPublicKeyPartOfLSDNetwork(bytes calldata _blsPublicKeyOfKnot) public virtual view returns (bool) {
        return liquidStakingManager.isBLSPublicKeyPartOfLSDNetwork(_blsPublicKeyOfKnot);
    }

    /// @notice Utility function that proxies through to the liquid staking manager to check whether the BLS key ever registered with the network but is now banned
    function isBLSPublicKeyBanned(bytes calldata _blsPublicKeyOfKnot) public view returns (bool) {
        return liquidStakingManager.isBLSPublicKeyBanned(_blsPublicKeyOfKnot);
    }

    /// @notice Utility function that determins whether an LP can be burned for dETH if the associated derivatives have been minted
    function isDETHReadyForWithdrawal(address _lpTokenAddress) external view returns (bool) {
        bytes memory blsPublicKeyOfKnot = KnotAssociatedWithLPToken[LPToken(_lpTokenAddress)];
        IDataStructures.LifecycleStatus validatorStatus = getAccountManager().blsPublicKeyToLifecycleStatus(blsPublicKeyOfKnot);
        return validatorStatus == IDataStructures.LifecycleStatus.TOKENS_MINTED;
    }

    /// @dev Logic required for initialization
    function _init(address _liquidStakingManagerAddress, LPTokenFactory _lpTokenFactory) internal {
        require(_liquidStakingManagerAddress != address(0), "Zero address");
        require(address(_lpTokenFactory) != address(0), "Zero address");

        lpTokenFactory = _lpTokenFactory;
        liquidStakingManager = ILiquidStakingManager(_liquidStakingManagerAddress);

        baseLPTokenName = "dstETHToken_";
        baseLPTokenSymbol = "dstETH_";
        maxStakingAmountPerValidator = 24 ether;

        // create a savETH index owned by the vault
        indexOwnedByTheVault = getSavETHRegistry().createIndex(address(this));
    }
}