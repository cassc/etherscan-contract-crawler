/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IERC20Permit} from "../interfaces/IERC20.sol";
import "../interfaces/IGvToken.sol";
import "../interfaces/IBribePot.sol";
import "../interfaces/IRcaController.sol";
import "../interfaces/ITokenSwap.sol";
import "../library/MerkleProof.sol";
import "./Delegable.sol";

// solhint-disable not-rely-on-time
// solhint-disable reason-string
// solhint-disable max-states-count
// solhint-disable no-inline-assembly
// solhint-disable no-empty-blocks

contract GvToken is Delegable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Permit;

    /* ========== STRUCTS ========== */
    struct MetaData {
        string name;
        string symbol;
        uint256 decimals;
    }
    struct Deposit {
        uint128 amount;
        uint128 start;
    }
    struct PermitArgs {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    struct WithdrawRequest {
        uint128 amount;
        uint128 endTime;
    }
    struct SupplyPointer {
        uint128 amount;
        uint128 storedAt;
    }
    struct DelegateDetails {
        address reciever;
        uint256 amount;
    }

    /* ========== CONSTANTS ========== */
    uint64 public constant MAX_PERCENT = 100_000;
    uint32 public constant MAX_GROW = 52 weeks;
    uint32 public constant WEEK = 1 weeks;
    uint256 internal constant MULTIPLIER = 1e18;

    /* ========== STATE ========== */
    IBribePot public pot;
    IERC20Permit public stakingToken;
    IRcaController public rcaController;
    ITokenSwap public tokenSwap;
    /// @notice Timestamp rounded in weeks for earliest vArmor staker
    uint32 public genesis;
    /// @notice total amount of EASE deposited
    uint256 public totalDeposited;
    /// @notice Time delay for withdrawals which will be set by governance
    uint256 public withdrawalDelay;

    /// @notice total supply of gvToken
    uint256 private _totalSupply;
    /// @notice merkle root of vArmor stakers for giving them
    /// extra deposit start time
    bytes32 private _powerRoot;
    MetaData private metadata;
    /// @notice Request by users for withdrawals.
    mapping(address => WithdrawRequest) public withdrawRequests;
    /// @notice amount of gvToken leased to bribe Pot
    mapping(address => uint256) public leasedAmount;

    /// @notice User deposits of ease tokens
    mapping(address => Deposit[]) private _deposits;
    /// @notice total amount of ease deposited on user behalf
    mapping(address => uint256) private _totalDeposit;

    /// @notice Extra power claimed by vArmor holder
    mapping(address => bool) private _claimed;
    /* ========== EVENTS ========== */
    event Deposited(address indexed user, uint256 amount);
    event RedeemRequest(address indexed user, uint256 amount, uint256 endTime);
    event RedeemFinalize(address indexed user, uint256 amount);

    event AdjustStakes(
        address indexed user,
        address[] vaults,
        uint256[] percents
    );

    /* ========== INITIALIZE ========== */
    /// @notice Initialize a new gvToken.
    /// @param _pot Address of a bribe pot.
    /// @param _stakingToken Address of a token to be deposited in exchange
    /// of Growing vote token.
    /// @param _rcaController Address of a RCA controller needed for verifying
    /// active rca vaults.
    /// @param _tokenSwap VArmor to EASE token swap address
    /// @param _genesis Deposit time of first vArmor holder.
    function initialize(
        address _pot,
        address _stakingToken,
        address _rcaController,
        address _tokenSwap,
        uint256 _genesis
    ) external initializer {
        __ERC1967Upgrade_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        pot = IBribePot(_pot);
        stakingToken = IERC20Permit(_stakingToken);
        rcaController = IRcaController(_rcaController);
        tokenSwap = ITokenSwap(_tokenSwap);
        genesis = uint32((_genesis / WEEK) * WEEK);
        metadata = MetaData("Growing Vote Ease", "gvEase", 18);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /// @notice Deposit ease and recieve gvEASE
    /// @param amount Amount of ease to deposit.
    /// @param permit v,r,s and deadline for signed approvals (EIP-2612)
    function deposit(uint256 amount, PermitArgs memory permit) external {
        _deposit(msg.sender, amount, block.timestamp, permit, false);
    }

    /// @notice Deposit for vArmor holders to give them
    /// extra power when migrating
    /// @param amount Amount of EASE
    /// @param depositStart Extra time start for stakers of Armor Token
    /// as promised by EASE DAO when token migration from ARMOR to EASE
    /// @param proof Merkle proof of the vArmor staker
    /// @param permit v,r,s and deadline for signed approvals (EIP-2612)
    function deposit(
        uint256 amount,
        uint256 depositStart,
        bytes32[] memory proof,
        PermitArgs memory permit
    ) external {
        _depositForVArmorHolders(
            msg.sender,
            amount,
            depositStart,
            proof,
            permit
        );
    }

    /// @notice Deposit vArmor and recieve gvEASE with extra start time
    /// @param amount Amount of EASE
    /// @param vArmorAmt Amount in vArmor
    /// @param depositStart Extra time start for stakers of Armor Token
    /// as promised by EASE DAO when token migration from ARMOR to EASE
    /// @param proof Merkle proof of the vArmor staker
    /// @param permit v,r,s and deadline for signed approvals (EIP-2612)
    function depositWithVArmor(
        uint256 amount,
        uint256 vArmorAmt,
        uint256 depositStart,
        bytes32[] memory proof,
        PermitArgs memory permit
    ) external {
        address user = msg.sender;
        tokenSwap.swapVArmorFor(user, vArmorAmt);

        _depositForVArmorHolders(user, amount, depositStart, proof, permit);
    }

    /// @notice Deposit armor and recieve gvEASE
    /// @param amount Amount of armor to deposit.
    /// @param permit v,r,s and deadline for signed approvals (EIP-2612)
    function depositWithArmor(uint256 amount, PermitArgs memory permit)
        external
    {
        address user = msg.sender;
        tokenSwap.swapFor(user, amount);
        _deposit(user, amount, block.timestamp, permit, false);
    }

    /// @notice Request redemption of gvToken back to ease
    /// Has a withdrawal delay which will work in 2 parts(request and finalize)
    /// @param amount The amount of tokens in EASE to withdraw
    /// gvToken from bribe pot if true
    function withdrawRequest(uint256 amount) external {
        address user = msg.sender;
        require(amount <= _totalDeposit[user], "not enough deposit!");
        WithdrawRequest memory currRequest = withdrawRequests[user];

        (uint256 depositBalance, uint256 earnedPower) = _balanceOf(user);

        uint256 gvAmtToWithdraw = _gvTokenValue(
            amount,
            depositBalance,
            earnedPower
        );
        uint256 gvBalance = depositBalance + earnedPower;

        // withdraw form bribe pot if necessary
        _withdrawFromPot(user, gvAmtToWithdraw, gvBalance);

        _updateDeposits(user, amount);

        _updateTotalSupply(gvAmtToWithdraw);

        _updateDelegated(user, gvAmtToWithdraw, gvBalance);

        uint256 endTime = block.timestamp + withdrawalDelay;
        currRequest.endTime = uint32(endTime);
        currRequest.amount += uint128(amount);
        withdrawRequests[user] = currRequest;

        emit RedeemRequest(user, amount, endTime);
    }

    /// @notice Used to exchange gvToken back to ease token and transfers
    /// pending EASE withdrawal amount to the user if withdrawal delay is over
    function withdrawFinalize() external {
        // Finalize withdraw of a user
        address user = msg.sender;

        WithdrawRequest memory userReq = withdrawRequests[user];
        delete withdrawRequests[user];
        require(
            userReq.endTime <= block.timestamp,
            "withdrawal not yet allowed"
        );

        stakingToken.safeTransfer(user, userReq.amount);

        emit RedeemFinalize(user, userReq.amount);
    }

    /// @notice Adjusts stakes of a user to different RCA-vaults
    /// @param vaults Rca vaults user want's to stake
    /// @param percents Percentages of gvTokens user wants to stake
    /// in each RCA-vault
    function adjustStakes(address[] memory vaults, uint256[] memory percents)
        external
    {
        address user = msg.sender;
        uint256 length = vaults.length;
        require(percents.length == length, "length mismatch");
        uint256 totalPercent;
        for (uint256 i; i < length; i++) {
            require(rcaController.activeShields(vaults[i]), "vault not active");
            totalPercent += percents[i];
        }
        require(totalPercent <= MAX_PERCENT, "can't stake more than 100%");
        emit AdjustStakes(user, vaults, percents);
    }

    /// @notice Deposits gvToken of an account to bribe pot
    /// @param amount Amount of gvToken to bribe
    function depositToPot(uint256 amount) external {
        // deposits user gvToken to bribe pot and
        // get rewards against it
        address user = msg.sender;
        uint256 totalPower = balanceOf(user);
        uint256 leased = leasedAmount[user];

        require(totalPower >= (amount + leased), "not enough power");

        leasedAmount[user] += amount;

        pot.deposit(user, amount);
    }

    /// @notice Withdraws bribed gvToken from bribe pot
    /// @param amount Amount in gvToken to withdraw from bribe pot
    function withdrawFromPot(uint256 amount) external {
        // withdraws user gvToken from bribe pot
        leasedAmount[msg.sender] -= amount;
        pot.withdraw(msg.sender, amount);
    }

    /// @notice Allows user to collect rewards.
    function claimReward() external {
        pot.getReward(msg.sender, true);
    }

    /// @notice Allows account to claim rewards from Bribe pot and deposit
    /// to gain more gvToken
    function claimAndDepositReward() external {
        address user = msg.sender;
        // bribe rewards from the pot
        uint256 amount;

        PermitArgs memory permit;
        if (leasedAmount[user] > 0) {
            amount = pot.getReward(user, false);
        }
        if (amount > 0) {
            _deposit(user, amount, block.timestamp, permit, true);
        }
    }

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(metadata.name)),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "gvEASE::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "gvEASE::delegateBySig: invalid nonce"
        );
        require(
            block.timestamp <= expiry,
            "gvEASE::delegateBySig: signature expired"
        );
        return _delegate(signatory, delegatee);
    }

    /* ========== ONLY GOV ========== */

    /// @notice Set root for vArmor holders to get earlier deposit start time.
    /// @param root Merkle root of the vArmor holders.
    function setPower(bytes32 root) external onlyOwner {
        _powerRoot = root;
    }

    /// @notice Change withdrawal delay
    /// @param time Delay time in seconds
    function setDelay(uint256 time) external onlyOwner {
        time = (time / 1 weeks) * 1 weeks;
        require(time >= 1 weeks, "min delay 7 days");
        withdrawalDelay = time;
    }

    /// @notice Update total supply for ecosystem wide grown part
    /// @param newTotalSupply New total supply.(should be > existing supply)
    function setTotalSupply(uint256 newTotalSupply) external onlyOwner {
        uint256 totalEaseDeposit = totalDeposited;

        require(
            newTotalSupply >= totalEaseDeposit &&
                newTotalSupply <= (totalEaseDeposit * 2),
            "not in range"
        );
        // making sure governance can only update for the vote grown part
        require(newTotalSupply > _totalSupply, "existing > new amount");

        _totalSupply = newTotalSupply;
    }

    /// @notice Set Pot address
    /// @param _pot new bribe pot address
    function setPotAddress(address _pot) external onlyOwner {
        pot = IBribePot(_pot);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice EIP-20 token name for this token
    function name() external view returns (string memory) {
        return metadata.name;
    }

    /// @notice EIP-20 token symbol for this token
    function symbol() external view returns (string memory) {
        return metadata.symbol;
    }

    /// @notice EIP-20 token decimals for this token
    function decimals() external view returns (uint8) {
        return uint8(metadata.decimals);
    }

    /// @notice Get total ease deposited by user
    /// @param user The address of the account to get total deposit
    /// @return total ease deposited by the user
    function totalDeposit(address user) external view returns (uint256) {
        return _totalDeposit[user];
    }

    /// @notice Get deposits of a user
    /// @param user The address of the account to get the deposits of
    /// @return Details of deposits in an array
    function getUserDeposits(address user)
        external
        view
        returns (Deposit[] memory)
    {
        return _deposits[user];
    }

    /// @notice Total number of tokens in circulation
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Get the number of tokens held by the `account`
    /// @param user The address of the account to get the balance of
    /// @return The number of tokens held
    function balanceOf(address user) public view override returns (uint256) {
        (uint256 depositAmount, uint256 powerEarned) = _balanceOf(user);
        return depositAmount + powerEarned;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _authorizeUpgrade(address) internal override onlyOwner {}

    ///@notice Deposit EASE to obtain gvToken that grows upto
    ///twice the amount of ease being deposited.
    ///@param user Wallet address to deposit for
    ///@param amount Amount of EASE to deposit
    ///@param depositStart Start time of deposit(current timestamp
    /// for regular deposit and ahead timestart for vArmor holders)
    ///@param permit v,r,s and deadline for signed approvals (EIP-2612)
    ///@param fromBribePot boolean to represent if reward being deposited
    ///for compounding gvPower
    function _deposit(
        address user,
        uint256 amount,
        uint256 depositStart,
        PermitArgs memory permit,
        bool fromBribePot
    ) internal {
        require(amount > 0, "cannot deposit 0!");

        // we only transfer tokens from user if they are
        // depositing from their external wallet if this
        // function is called by claimAndDepositReward we don't
        // need to transfer EASE as it will already be transferred
        // to this contract address
        if (!fromBribePot) {
            _transferStakingToken(user, amount, permit);
        }

        _updateBalances(user, amount, depositStart);

        // update delegates if the depositor has already delegated
        // his votes. This _delegate call will delegate vote grown
        // part too.
        // Example: Let's say user is depositing 100 $EASE on
        // this deposit call. The user has deposited 100 $EASE 6 months
        // before and delegated votes to bob. At current time the total
        // votes delegated by user to bob is 100 $gvEASE but the users
        // balance after updating balance now is 150 $gvEASE + 100 $gvEASE
        // => 250 gvEASE so the below delegate function call will update
        // the delegated amount for the grown part too. Meaning total delegated
        // by the user now will update to 250 $gvEASE from 100 $gvEASE
        if (_delegates[user] != address(0)) {
            _delegate(user, _delegates[user]);
        }

        emit Deposited(user, amount);
    }

    function _depositForVArmorHolders(
        address user,
        uint256 amount,
        uint256 depositStart,
        bytes32[] memory proof,
        PermitArgs memory permit
    ) internal {
        bytes32 leaf = keccak256(abi.encodePacked(user, amount, depositStart));
        require(!_claimed[user], "power already claimed!");
        require(MerkleProof.verify(proof, _powerRoot, leaf), "invalid proof");
        require(depositStart >= genesis, "depositStart < genesis");
        _claimed[user] = true;

        _deposit(user, amount, depositStart, permit, false);
    }

    function _updateBalances(
        address user,
        uint256 amount,
        uint256 depositStart
    ) internal {
        Deposit memory newDeposit = Deposit(
            uint128(amount),
            uint32(depositStart)
        );

        totalDeposited += newDeposit.amount;
        _totalSupply += newDeposit.amount;
        _totalDeposit[user] += newDeposit.amount;
        _deposits[user].push(newDeposit);
    }

    function _transferStakingToken(
        address from,
        uint256 amount,
        PermitArgs memory permit
    ) internal {
        if (permit.r != "") {
            stakingToken.permit(
                from,
                address(this),
                amount,
                permit.deadline,
                permit.v,
                permit.r,
                permit.s
            );
        }
        stakingToken.safeTransferFrom(from, address(this), amount);
    }

    ///@notice Withraw from bribe pot if withdraw amount of gvToken exceeds
    ///(gvToken balance - bribed amount)
    function _withdrawFromPot(
        address user,
        uint256 gvAmountToWithdraw,
        uint256 userTotalGvBal
    ) internal {
        uint256 totalLeased = leasedAmount[user];
        uint256 gvAmtAvailableForBribe = userTotalGvBal - totalLeased;
        // whether user is willing to withdraw from bribe pot
        // we will not add reward amount to withdraw if user doesn't
        // want to withdraw from bribe pot
        if (totalLeased > 0 && gvAmountToWithdraw > gvAmtAvailableForBribe) {
            uint256 amtToWithdrawFromPot = gvAmountToWithdraw -
                gvAmtAvailableForBribe;
            pot.withdraw(user, amtToWithdrawFromPot);
            leasedAmount[user] -= amtToWithdrawFromPot;
        }
    }

    ///@notice Loops through deposits of user from last index and pop's off the
    ///ones that are included in withdraw amount
    function _updateDeposits(address user, uint256 withdrawAmount) internal {
        Deposit memory remainder;
        uint256 totalAmount;
        // current deposit details
        Deposit memory userDeposit;

        totalDeposited -= withdrawAmount;
        _totalDeposit[user] -= withdrawAmount;
        // index to loop from
        uint256 i = _deposits[user].length;
        for (i; i > 0; i--) {
            userDeposit = _deposits[user][i - 1];
            totalAmount += userDeposit.amount;
            // remove last deposit
            _deposits[user].pop();

            // Let's say user tries to withdraw 100 EASE and they have
            // multiple ease deposits [75, 30] EASE when our loop is
            // at index 0 total amount will be 105, that means we need
            // to push the remainder to deposits array
            if (totalAmount >= withdrawAmount) {
                remainder.amount = uint128(totalAmount - withdrawAmount);
                remainder.start = userDeposit.start;
                break;
            }
        }

        // If there is a remainder we need to update the index at which
        // we broke out of loop and push the withdrawan amount to user
        // _deposits withdraw 100 ease from [75, 30] EASE balance becomes
        // [5]
        if (remainder.amount != 0) {
            _deposits[user].push(remainder);
        }
    }

    ///@notice Updates total supply on withdraw request
    /// @param gvAmtToWithdraw Amount of gvToken to withdraw of a user
    function _updateTotalSupply(uint256 gvAmtToWithdraw) internal {
        // if _totalSupply is not in Sync with the grown votes of users
        // and if it's the last user wanting to get out of this contract
        // we need to take consideration of underflow and at the same time
        // set total supply to zero
        if (_totalSupply < gvAmtToWithdraw || totalDeposited == 0) {
            _totalSupply = 0;
        } else {
            _totalSupply -= gvAmtToWithdraw;
        }
    }

    /// @notice Updates delegated votes of a user on withdraw request.
    /// @param user Address of the user requesting withdraw.
    /// @param withdrawAmt Amount of gvToken being withdrawn.
    /// @param gvBalance Total gvToken balance of a user.
    function _updateDelegated(
        address user,
        uint256 withdrawAmt,
        uint256 gvBalance
    ) internal {
        uint256 remainingGvBal = gvBalance - withdrawAmt;
        uint256 delegatedAmt = _delegated[user];
        // this means we need to deduct delegated Amt
        if (remainingGvBal < delegatedAmt) {
            uint256 gvAmtToDeduct = delegatedAmt - remainingGvBal;
            _delegated[user] -= gvAmtToDeduct;
            _moveDelegates(
                _delegates[msg.sender],
                address(0),
                gvAmtToDeduct,
                0
            );
        }
    }

    function _balanceOf(address user)
        internal
        view
        returns (uint256 depositBalance, uint256 powerEarned)
    {
        uint256 timestamp = block.timestamp;
        depositBalance = _totalDeposit[user];

        uint256 i = _deposits[user].length;
        uint256 depositIncluded;
        for (i; i > 0; i--) {
            Deposit memory userDeposit = _deposits[user][i - 1];

            if ((timestamp - userDeposit.start) > MAX_GROW) {
                // if we reach here that means we have max_grow
                // has been achieved for earlier deposits
                break;
            }

            depositIncluded += userDeposit.amount;
            powerEarned += _powerEarned(userDeposit, timestamp);
        }
        // if we break out of the loop and the user has deposits
        // that have gained max power we need to add that deposit amount
        // to power earned because power can only grow upto deposit amount
        powerEarned += (depositBalance - depositIncluded);
    }

    function _powerEarned(Deposit memory userDeposit, uint256 timestamp)
        private
        pure
        returns (uint256 powerGrowth)
    {
        uint256 timeSinceDeposit = timestamp - userDeposit.start;

        if (timeSinceDeposit < MAX_GROW) {
            powerGrowth =
                (userDeposit.amount *
                    ((timeSinceDeposit * MULTIPLIER) / MAX_GROW)) /
                MULTIPLIER;
        } else {
            powerGrowth = userDeposit.amount;
        }
    }

    function _gvTokenValue(
        uint256 easeAmt,
        uint256 depositBalance,
        uint256 earnedPower
    ) internal pure returns (uint256 gvTokenValue) {
        uint256 conversionRate = (((depositBalance + earnedPower) *
            MULTIPLIER) / depositBalance);
        gvTokenValue = (easeAmt * conversionRate) / MULTIPLIER;
    }

    function _percentToGvPower(
        uint256 stakedPercent,
        uint256 gvBalance,
        uint256 bribed
    ) internal pure returns (uint256 stakedGvPower) {
        stakedGvPower = (stakedPercent * (gvBalance - bribed)) / MAX_PERCENT;
    }
}