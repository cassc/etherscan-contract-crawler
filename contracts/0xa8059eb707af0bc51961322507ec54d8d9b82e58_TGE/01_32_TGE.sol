// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITokenERC1155.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IVesting.sol";
import "./libraries/ExceptionsLibrary.sol";
import "./interfaces/IPausable.sol";

/**
    * @title Token Generation Event Contract
    * @notice The Token Generation Event (TGE) is the cornerstone of everything related to tokens issued on the CompanyDAO protocol. TGE contracts contain the rules and deadlines for token distribution events and can influence the pool's operational activities even after they have ended.
    The launch of the TGE event takes place simultaneously with the deployment of the contract, after which the option to purchase tokens becomes immediately available. Tokens purchased by a user can be partially or fully minted to the buyer's address and can also be placed in the vesting reserve either in full or for the remaining portion. Additionally, tokens acquired during the TGE and held in the buyer's balance may have their transfer functionality locked (the user owns, uses them as votes, delegates, but cannot transfer the tokens to another address).
    * @dev TGE events differ by the type of tokens being distributed:
    - Governance Token Generation Event
    - Preference Token Generation Event
    When deploying the TGE contract, among other arguments, the callData field contains the token field, which contains the address of the token contract that will interact with the TGE contract. The token type can be determined from the TokenType state variable of the token contract.
    Differences between these types:
    - Governance Token Generation Event involves charging a ProtocolTokenFee in the amount set in the Service:protocolTokenFee value (percentages in DENOM notation). This fee is collected through the transferFunds() transaction after the completion of the Governance token distribution event (the funds collected from buyers go to the pool balance, and the protocolTokenFee is minted and sent to the Service:protocolTreasury).
    - Governance Token Generation Event has a mandatory minPurchase limit equal to the Service:protocolTokenFee (in the smallest indivisible token parts, taking into account Decimals and DENOM). This is done to avoid rounding conflicts or overcharges when calculating the fee for each issued token volume.
    - In addition to being launched as a result of a proposal execution, a Governance Token Generation Event can be launched by the pool Owner as long as the pool has not acquired DAO status. Preference Token Generation Event can only be launched as a result of a proposal execution.
    - A successful Governance Token Generation Event (see TGE states later) leads to the pool becoming a DAO if it didn't previously have that status.
    @dev **TGE events differ by the number of previous launches:**
    - primary TGE
    - secondary TGE
    As long as the sum of the totalSupply and the vesting reserve of the distributed token does not equal the cap, a TGE can be launched to issue some more of these tokens.
    The first TGE for the distribution of any token is called primary, and all subsequent ones are called secondary.
    Differences between these types:
    - A transaction to launch a primary TGE involves the simultaneous deployment of the token contract, while a secondary TGE only works with an existing token contract.
    - A secondary TGE does not have a softcap parameter, meaning that after at least one minPurchase of tokens, the TGE is considered successful.
    - When validating the hardcap (i.e., the maximum possible number of tokens available for sale/distribution within the TGE) during the creation of a primary TGE, only a formal check is performed (hardcap must not be less than softcap and not greater than cap). For a secondary TGE, tokens that will be minted during vesting claims are also taken into account.
    - In case of failure of a primary TGE for any token, that token is not considered to have any application within the protocol. It is no longer possible to conduct a TGE for such a token.
    */

contract TGE is Initializable, ReentrancyGuardUpgradeable, ITGE {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // CONSTANTS

    /** 
    * @notice Denominator for shares (such as thresholds)
    * @dev The constant Service.sol:DENOM is used to work with percentage values of QuorumThreshold and DecisionThreshold thresholds, as well as for calculating the ProtocolTokenFee. In this version, it is equal to 1,000,000, for clarity stored as 100 * 10 ^ 4.
    10^4 corresponds to one percent, and 100 * 10^4 corresponds to one hundred percent.
    The value of 12.3456% will be written as 123,456, and 78.9% as 789,000.
    This notation allows specifying ratios with an accuracy of up to four decimal places in percentage notation (six decimal places in decimal notation).
    When working with the CompanyDAO frontend, the application scripts automatically convert the familiar percentage notation into the required format. When using the contracts independently, this feature of value notation should be taken into account.
    */
    uint256 private constant DENOM = 100 * 10 ** 4;

    /// @notice The address of the ERC20/ERC1155 token being distributed in this TGE
    /// @dev Mandatory setting for TGE, only one token can be distributed in a single TGE event
    address public token;

    /// @notice The identifier of the ERC1155 token collection
    /// @dev For ERC1155, there is an additional restriction that units of only one collection of such tokens can be distributed in a single TGE
    uint256 public tokenId;

    /// @dev Parameters for conducting the TGE, described by the ITGE.sol:TGEInfo interface
    TGEInfo public info;

    /**
    * @notice A whitelist of addresses allowed to participate in this TGE
    * @dev A TGE can be public or private. To make the event public, simply leave the whitelist empty.
    The TGE contract can act as an airdrop - a free token distribution. To do this, set the price value to zero.
    To create a DAO with a finite number of participants, each of whom should receive an equal share of tokens, you can set the whitelist when launching the TGE as a list of the participants' addresses, and set both minPurchase and maxPurchase equal to the expression (hardcap / number of participants). To make the pool obtain DAO status only if the distribution is successful under such conditions for all project participants, you can set the softcap value equal to the hardcap. With these settings, the company will become a DAO only if all the initial participants have an equal voting power.
    */
    mapping(address => bool) private _isUserWhitelisted;

    /// @dev The block on which the TGE contract was deployed and the event begins
    uint256 public createdAt;

    /// @dev A mapping that stores the amount of token units purchased by each address that plays a key role in the TGE.
    mapping(address => uint256) public purchaseOf;

    /// @dev Total amount of tokens purchased during the TGE
    uint256 public totalPurchased;

    /// @notice Achievement of the pool's TVL as specified by the vesting settings
    /// @dev A flag that irreversibly becomes True only if the pool for which the TGE is being conducted is able to reach or exceed its TVL value specified in the vesting parameters.
    bool public vestingTVLReached;

    /// @notice Achievement of the pool's TVL as specified by the lockup settings
    /// @dev A flag that irreversibly becomes True only if the pool for which the TGE is being conducted is able to reach or exceed its TVL value specified in the lockup parameters.
    bool public lockupTVLReached;

    /** 
    * @notice A mapping that contains the amount of token units placed in vesting for a specific account
    * @dev The TGE event may continue to affect other components of the protocol even after its completion and status change to "Successful" and, less frequently, "Failed". Vesting can be set up to distribute tokens over a significant period of time after the end of the TGE.
    The vesting time calculation begins with the block ending the TGE. The calculation of uniform time intervals is carried out either from the end of the cliff period block or each subsequent interval is counted from the end of the previous block.
    The Vesting.unlockedBalanceOf method shows how much of the tokens for a particular TGE may be available for a claim by an address if that address has not requested a withdrawal of any amount of tokens. The Vesting.claimableBalanceOf method shows how many tokens in total within a particular TGE an address has already requested and successfully received for withdrawal. Subtracting the second value from the first using the same arguments for method calls will give you the number of tokens currently available for withdrawal by that address.
    Additionally, one of the conditions for unlocking tokens under the vesting program can be setting a cumulative pool balance of a specified amount. The compliance with this condition starts to be tracked by the backend, and as soon as the pool balance reaches or exceeds the specified amount even for a moment, the backend, on behalf of the wallet with the SERVICE_MANAGER role, sends a transaction to the vesting contract's setClaimTVLReached(address tge) method. Executing this transaction changes the value of the flag in the mapping mapping(address => bool) with a key equal to the TGE address. Raising this flag is irreversible, meaning that a one-time occurrence of the condition guarantees that the token request now depends only on the second part of the conditions related to the passage of time. The calculation of the cliff period and additional distribution intervals is not related to raising this flag, both conditions are independent of each other, not mandatory for simultaneous use in settings, but mandatory for simultaneous compliance if they were used in one set of settings.
    The vesting of one TGE does not affect the vesting of another TGE.
    */
    mapping(address => uint256) public vestedBalanceOf;

    /// @dev Total number of tokens to be distributed within the vesting period
    uint256 public totalVested;

    /// @notice Protocol fee at the time of TGE creation
    /// @dev Since the protocol fee can be changed, the actual value at the time of contract deployment is fixed in the contract's memory to avoid dependencies on future states of the Service contract.
    uint256 public protocolFee;

    /// @notice Protocol fee payment
    /// @dev A flag that irreversibly becomes True after a successful transfer of the protocol fee to the address specified in the Service contract.
    /// @dev Used only for Governance Token Generation Event.
    bool public isProtocolTokenFeeClaimed;

    /// @dev Total number of token units that make up the protocol fee
    uint256 public totalProtocolFee;

    /** 
    * @notice Vesting contract address
    * @dev The TGE contract works closely with the Vesting contract, with a separate instance being issued for each token generation event, while there is only one Vesting contract. Together, they contain the most comprehensive information about a user's purchases, tokens in reserve but not yet issued, and the conditions for locking and unlocking tokens. Moreover, the TGE contract has a token buyback function under specific conditions (see the "Redeem" section for more details).
    One TGE contract is used for the distribution of only one protocol token (the token contract address is specified when launching the TGE). At any given time, there can be only one active TGE for a single token.
    */
    IVesting public vesting;

    // EVENTS

    /**
     * @dev Event emitted upon successful purchase (or distribution if the token unit price is 0)
     * @param buyer Address of the token recipient (buyer)
     * @param amount Number of token units acquired
     */
    event Purchased(address buyer, uint256 amount);

    /**
     * @dev Event emitted after successful claiming of the protocol fee
     * @param token Address of the token contract
     * @param tokenFee Amount of tokens transferred as payment for the protocol fee
     */
    event ProtocolTokenFeeClaimed(address token, uint256 tokenFee);

    /**
     * @dev Event emitted upon redeeming tokens in case of a failed TGE.
     * @param account Redeemer address
     * @param refundValue Refund value
     */
    event Redeemed(address account, uint256 refundValue);

    /**
     * @dev Event emitted upon transferring the raised funds to the pool contract address.
     * @param amount Amount of tokens/ETH transferred
     */
    event FundsTransferred(uint256 amount);

    event Refund(address account, uint256 amount);

    // INITIALIZER AND CONSTRUCTOR

    /**
     * @notice Contract constructor.
     * @dev This contract uses OpenZeppelin upgrades and has no need for a constructor function.
     * The constructor is replaced with an initializer function.
     * This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Constructor function, can only be called once. In this method, settings for the TGE event are assigned, such as the contract of the token implemented using TGE, as well as the TGEInfo structure, which includes the parameters of purchase, vesting, and lockup. If no lockup or vesting conditions were set for the TVL value when creating the TGE, then the TVL achievement flag is set to true from the very beginning.
     * @param _service Service contract
     * @param _token TGE's token
     * @param _tokenId TGE's tokenId
     * @param _tokenId ERC1155TGE's tokenId (token series)
     * @param _uri Metadata URL for the ERC1155 token collection
     * @param _info TGE parameters
     * @param _protocolFee Protocol fee snapshot
     */
    function initialize(
        address _service,
        address _token,
        uint256 _tokenId,
        string memory _uri,
        TGEInfo calldata _info,
        uint256 _protocolFee
    ) external initializer {
        __ReentrancyGuard_init();

        //if tge is creating for erc20 token
        tokenId = _tokenId;
        if (tokenId == 0) {
            IService(_service).validateTGEInfo(
                _info,
                IToken(_token).cap(),
                IToken(_token).totalSupplyWithReserves(),
                IToken(_token).tokenType()
            );
        } else {
            //if tge is creating for erc155 token
            if (ITokenERC1155(_token).cap(tokenId) != 0) {
                IService(_service).validateTGEInfo(
                    _info,
                    ITokenERC1155(_token).cap(tokenId),
                    ITokenERC1155(_token).totalSupplyWithReserves(tokenId),
                    IToken(_token).tokenType()
                );
            } else {
                ITokenERC1155(_token).setLastTokenId(_tokenId);
                ITokenERC1155(_token).setURI(_tokenId, _uri);
            }
        }
        vesting = IService(_service).vesting();
        token = _token;

        info = _info;
        protocolFee = _protocolFee;
        lockupTVLReached = (_info.lockupTVL == 0);

        for (uint256 i = 0; i < _info.userWhitelist.length; i++) {
            _isUserWhitelisted[_info.userWhitelist[i]] = true;
        }

        createdAt = block.number;
    }

    // PUBLIC FUNCTIONS

    /**
    * @notice This method is used for purchasing pool tokens.
    * @dev Any blockchain address can act as a buyer (TGE contract user) of tokens if the following conditions are met:
    - active event status (TGE.sol:state method returns the Active code value / "1")
    - the event is public (TGE.sol:info.Whitelist is empty) or the user's address is on the whitelist of addresses admitted to the event
    - the number of tokens purchased by the address is not less than TGE.sol:minPurchase (a common rule for all participants) and not more than TGE.sol:maxPurchaseOf(address) (calculated individually for each address)
    The TGEInfo of each such event also contains settings for the order in which token buyers receive their purchases and from when and to what extent they can start managing them.
    However, in any case, each address that made a purchase is mentioned in the TGE.sol:purchaseOf[] mapping. This record serves as proof of full payment for the purchase and confirmation of the buyer's status, even if as a result of the transaction, not a single token was credited to the buyer's address.
    After each purchase transaction, TGE.sol:purchase calculates what part of the purchase should be issued and immediately transferred to the buyer's balance, and what part should be left as a reserve (records, not issued tokens) in vesting until the prescribed settings for unlocking these tokens occur.
     */
    function purchase(
        uint256 amount
    )
        external
        payable
        onlyWhitelistedUser
        onlyState(State.Active)
        nonReentrant
        whenPoolNotPaused
    {
        // Check purchase price transfer depending on unit of account
        address unitOfAccount = info.unitOfAccount;
        uint256 purchasePrice = (amount * info.price + (1 ether - 1)) / 1 ether;
        if (unitOfAccount == address(0)) {
            require(
                msg.value >= purchasePrice,
                ExceptionsLibrary.INCORRECT_ETH_PASSED
            );
        } else {
            IERC20Upgradeable(unitOfAccount).safeTransferFrom(
                msg.sender,
                address(this),
                purchasePrice
            );
        }
        this.proceedPurchase(msg.sender, amount);
    }

    /**
     * @notice Executes a token purchase for a given account using fiat during the token generation event (TGE).
     * @dev The function can only be called by an executor, when the contract state is active, the pool is not paused, and ensures no reentrancy.
     * @param account The address of the account to execute the purchase for.
     * @param amount The amount of tokens to be purchased.
     */

    function externalPurchase(
        address account,
        uint256 amount
    )
        external
        onlyExecutor
        onlyState(State.Active)
        nonReentrant
        whenPoolNotPaused
    {
        try this.proceedPurchase(account, amount) {
            return;
        } catch {
            _refund(account, amount);
            return;
        }
    }

    function _refund(address account, uint256 amount) private {
        uint256 refundValue = (amount * info.price + (1 ether - 1)) / 1 ether;
        if (info.unitOfAccount == address(0)) {
            payable(msg.sender).sendValue(refundValue);
        } else {
            IERC20Upgradeable(info.unitOfAccount).safeTransfer(
                msg.sender,
                refundValue
            );
        }
        emit Refund(account, amount);
    }

    /**
    * @notice Redeem acquired tokens with a refund of the spent assets.
    * @dev In the contract of an unsuccessful TGE, the redeem() method becomes active, allowing any token buyer to return them to the contract for subsequent burning. As a result of this transaction, the records of the user's purchases within this TGE will be zeroed out (or reduced), and the spent ETH or ERC20 tokens will be returned to their balance.
    If the buyer has a record of tokens locked under the vesting program for this TGE, they will not be burned, and the record of the vesting payment will simply be deleted. In this case, the transaction will also end with a transfer of the spent funds back to the buyer.
    The buyer cannot return more tokens than they purchased in this TGE; this contract keeps a record of the user's total purchase amount and reduces it with each call of the redeem token method. This can happen if the purchased tokens were distributed to other wallets, and after the end of the TGE, the buyer requests redemption after each transfer back to the purchase address.
     */
    function redeem()
        external
        onlyState(State.Failed)
        nonReentrant
        whenPoolNotPaused
    {
        // User can't claim more than he bought in this event (in case somebody else has transferred him tokens)
        require(
            purchaseOf[msg.sender] > 0,
            ExceptionsLibrary.ZERO_PURCHASE_AMOUNT
        );

        uint256 refundAmount = 0;

        // Calculate redeem from vesting
        uint256 vestedBalance = vesting.vested(address(this), msg.sender);
        if (vestedBalance > 0) {
            // Account vested tokens
            purchaseOf[msg.sender] -= vestedBalance;
            refundAmount += vestedBalance;

            // Cancel vesting
            vesting.cancel(address(this), msg.sender);

            // Decrease reserved tokens
            if (isERC1155TGE()) {
                ITokenERC1155(token).setTGEVestedTokens(
                    ITokenERC1155(token).getTotalTGEVestedTokens(tokenId) -
                        vestedBalance,
                    tokenId
                );
            } else {
                IToken(token).setTGEVestedTokens(
                    IToken(token).getTotalTGEVestedTokens() - vestedBalance
                );
            }
        }

        // Calculate redeemed balance
        uint256 balanceToRedeem;
        if (isERC1155TGE()) {
            balanceToRedeem = MathUpgradeable.min(
                ITokenERC1155(token).balanceOf(msg.sender, tokenId),
                purchaseOf[msg.sender]
            );
        } else {
            balanceToRedeem = MathUpgradeable.min(
                IToken(token).balanceOf(msg.sender),
                purchaseOf[msg.sender]
            );
        }
        if (balanceToRedeem > 0) {
            purchaseOf[msg.sender] -= balanceToRedeem;
            refundAmount += balanceToRedeem;
            if (isERC1155TGE()) {
                ITokenERC1155(token).burn(msg.sender, tokenId, balanceToRedeem);
            } else {
                IToken(token).burn(msg.sender, balanceToRedeem);
            }
        }

        // Check that there is anything to refund
        require(refundAmount > 0, ExceptionsLibrary.NOTHING_TO_REDEEM);

        // Transfer refund value
        uint256 refundValue = (refundAmount * info.price + (1 ether - 1)) /
            1 ether;
        if (info.unitOfAccount == address(0)) {
            payable(msg.sender).sendValue(refundValue);
        } else {
            IERC20Upgradeable(info.unitOfAccount).safeTransfer(
                msg.sender,
                refundValue
            );
        }

        // Decrease reserved protocol fee
        uint256 tokenFee = getProtocolTokenFee(refundAmount);
        if (tokenFee > 0) {
            totalProtocolFee -= tokenFee;
            if (isERC1155TGE()) {
                ITokenERC1155(token).setProtocolFeeReserved(
                    ITokenERC1155(token).getTotalProtocolFeeReserved(tokenId) -
                        tokenFee,
                    tokenId
                );
            } else {
                IToken(token).setProtocolFeeReserved(
                    IToken(token).getTotalProtocolFeeReserved() - tokenFee
                );
            }
        }

        // Emit event
        emit Redeemed(msg.sender, refundValue);
    }

    /// @dev Set the flag that the condition for achieving the pool balance of the value specified in the lockup settings is met. The action is irreversible.
    function setLockupTVLReached()
        external
        whenPoolNotPaused
        onlyManager
        onlyState(State.Successful)
    {
        // Check that TVL has not been reached yet
        require(!lockupTVLReached, ExceptionsLibrary.LOCKUP_TVL_REACHED);

        // Mark as reached
        lockupTVLReached = true;
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev This method is used to perform the following actions for a successful TGE after its completion: transfer funds collected from buyers in the form of info.unitofaccount tokens or ETH to the address of the pool to which TGE belongs (if info.price is 0, then this action is not performed), as well as for Governance tokens make a minting of the percentage of the amount of all user purchases specified in the Service.sol protocolTokenFee contract and transfer it to the address specified in the Service.sol contract in the protocolTreasury() getter. Can be executed only once. Any address can call the method.
     */
    function transferFunds()
        external
        onlyState(State.Successful)
        whenPoolNotPaused
    {
        // Return if nothing to transfer
        if (totalPurchased == 0) {
            return;
        }

        // Claim protocol fee
        _claimProtocolTokenFee();

        // Transfer remaining funds to pool
        address unitOfAccount = info.unitOfAccount;

        address pool = IToken(token).pool();

        uint256 balance = 0;
        if (info.price != 0) {
            if (unitOfAccount == address(0)) {
                balance = address(this).balance;
                payable(pool).sendValue(balance);
            } else {
                balance = IERC20Upgradeable(unitOfAccount).balanceOf(
                    address(this)
                );
                IERC20Upgradeable(unitOfAccount).safeTransfer(pool, balance);
            }
        }

        // Emit event
        emit FundsTransferred(balance);

        IToken(token).service().registry().log(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(ITGE.transferFunds.selector)
        );
    }

    /**
     * @notice This method is used to transfer funds raised during the TGE to the address of the pool contract that conducted the TGE.
     * @dev The method can be called by any address. For safe execution, this method does not take any call arguments and only triggers for successful TGEs.
     */
    function _claimProtocolTokenFee() private {
        // Return if already claimed
        if (isProtocolTokenFeeClaimed) {
            return;
        }

        // Return for preference token
        if (IToken(token).tokenType() == IToken.TokenType.Preference) {
            return;
        }

        // Mark fee as claimed
        isProtocolTokenFeeClaimed = true;

        // Mint fee to treasury
        uint256 tokenFee = totalProtocolFee;
        if (totalProtocolFee > 0) {
            totalProtocolFee = 0;
            if (isERC1155TGE()) {
                ITokenERC1155(token).mint(
                    ITokenERC1155(token).service().protocolTreasury(),
                    tokenId,
                    tokenFee
                );
                ITokenERC1155(token).setProtocolFeeReserved(
                    ITokenERC1155(token).getTotalProtocolFeeReserved(tokenId) -
                        tokenFee,
                    tokenId
                );
            } else {
                IToken(token).mint(
                    IToken(token).service().protocolTreasury(),
                    tokenFee
                );
                IToken(token).setProtocolFeeReserved(
                    IToken(token).getTotalProtocolFeeReserved() - tokenFee
                );
            }
        }

        // Emit event
        emit ProtocolTokenFeeClaimed(token, tokenFee);
    }

    // VIEW FUNCTIONS

    /**
     * @dev Shows the maximum possible number of tokens to be purchased by a specific address, taking into account whether the user is on the white list and 0 what amount of purchases he made within this TGE.
     * @return Amount of tokens
     */
    function maxPurchaseOf(address account) public view returns (uint256) {
        if (!isUserWhitelisted(account)) {
            return 0;
        }
        return
            MathUpgradeable.min(
                info.maxPurchase - purchaseOf[account],
                info.hardcap - totalPurchased
            );
    }

    /**
    * @notice A state of a Token Generation Event
    * @dev A TGE event can be in one of the following states:
    - Active
    - Failed
    - Successful
    In TGEInfo, the three most important parameters used to determine the event's state are specified:
    - hardcap - the maximum number of tokens that can be distributed during the event (the value is stored considering the token's Decimals)
    - softcap - the minimum expected number of tokens that should be distributed during the event (the value is stored considering the token's Decimals)
    - duration - the duration of the event (the number of blocks since the TGE deployment transaction)
    A successful outcome of the event and the assignment of the "Successful" status to the TGE occurs if:
    - no fewer than duration blocks have passed since the TGE launch, and no fewer than softcap tokens have been acquired
    OR
    - 100% of the hardcap tokens have been acquired at any point during the event
    If no fewer than duration blocks have passed since the TGE launch and fewer than softcap tokens have been acquired, the event is considered "Failed".
    If fewer than 100% of the hardcap tokens have been acquired, but fewer than duration blocks have passed since the TGE launch, the event is considered "Active".
     * @return State code
     */
    function state() public view returns (State) {
        // If hardcap is reached TGE is successfull
        if (totalPurchased == info.hardcap) {
            return State.Successful;
        }

        // If deadline not reached TGE is active
        if (block.number < createdAt + info.duration) {
            return State.Active;
        }

        // If it's not primary TGE it's successfull (if anything is purchased)
        if (isERC1155TGE()) {
            if (
                address(this) != ITokenERC1155(token).getTGEList(tokenId)[0] &&
                totalPurchased > 0
            ) {
                return State.Successful;
            }
        } else {
            if (
                address(this) != IToken(token).getTGEList()[0] &&
                totalPurchased > 0
            ) {
                return State.Successful;
            }
        }

        // If softcap is reached TGE is successfull
        if (totalPurchased >= info.softcap && totalPurchased > 0) {
            return State.Successful;
        }

        // Otherwise it's failed primary TGE
        return State.Failed;
    }

    /**
     * @notice The given getter shows whether the transfer method is available for tokens that were distributed using a specific TGE contract. If the lockup period is over or if the lockup was not provided for this TGE, the getter always returns true.
     * @dev In contrast to vesting, lockup contains a simplified system of conditions (no additional distribution spread over equal time intervals), affects tokens located in the contract address, and does not involve actions related to minting or burning tokens.
    To configure lockup in TGEInfo, only two settings are specified: "lockupDuration" and "lockupTVL" (pool balance). The lockup duration is counted from the TGE creation block.
    Lockup locks the transfer of tokens purchased during the TGE for a period equal to the lockupDuration blocks and does not allow unlocking until the pool balance reaches lockupTVL. The address can use these tokens for Governance activities; they are on the balance and counted as votes.
    Unlocking by TVL occurs with a transaction similar to vesting. The SERVICE_MANAGER address can send a setLockupTVLReached() transaction to the TGE contract, which irreversibly changes the value of this condition flag to "true".
    Vesting and lockup are completely parallel entities. Tokens can be unlocked under the lockup program but remain in vesting. The lockup of one TGE does not affect the lockup of another TGE.
     * @return bool Is transfer available
     */
    function transferUnlocked() public view returns (bool) {
        return
            lockupTVLReached && block.number >= createdAt + info.lockupDuration;
    }

    /**
     * @dev Shows the number of TGE tokens blocked in this contract. If the lockup is completed or has not been assigned, the method returns 0 (all tokens on the address balance are available for transfer). If the lockup period is still active, then the difference between the tokens purchased by the user and those in the vesting is shown (both parameters are only for this TGE).
     * @param account Account address
     * @return Locked balance
     */
    function lockedBalanceOf(address account) external view returns (uint256) {
        return
            transferUnlocked()
                ? 0
                : (purchaseOf[account] -
                    vesting.vestedBalanceOf(address(this), account));
    }

    /**
     * @dev Shows the number of TGE tokens available for redeem for `account`
     * @param account Account address
     * @return Redeemable balance of the address
     */
    function redeemableBalanceOf(
        address account
    ) external view returns (uint256) {
        if (purchaseOf[account] == 0) return 0;
        if (state() != State.Failed) return 0;

        if (isERC1155TGE()) {
            return
                MathUpgradeable.min(
                    ITokenERC1155(token).balanceOf(account, tokenId) +
                        vesting.vestedBalanceOf(address(this), account),
                    purchaseOf[account]
                );
        } else {
            return
                MathUpgradeable.min(
                    IToken(token).balanceOf(account) +
                        vesting.vestedBalanceOf(address(this), account),
                    purchaseOf[account]
                );
        }
    }

    /**
     * @dev The given getter shows how much info.unitofaccount was collected within this TGE. To do this, the amount of tokens purchased by all buyers is multiplied by info.price.
     * @return uint256 Total value
     */
    function getTotalPurchasedValue() public view returns (uint256) {
        return (totalPurchased * info.price) / 10 ** 18;
    }

    /**
     * @dev This getter shows the total value of all tokens that are in the vesting. Tokens that were transferred to user’s wallet addresses upon request for successful TGEs and that were burned as a result of user funds refund for unsuccessful TGEs are not taken into account.
     * @return uint256 Total value
     */
    function getTotalVestedValue() public view returns (uint256) {
        return (vesting.totalVested(address(this)) * info.price) / 10 ** 18;
    }

    /**
     * @dev This method returns the full list of addresses allowed to participate in the TGE.
     * @return address An array of whitelist addresses
     */
    function getUserWhitelist() external view returns (address[] memory) {
        return info.userWhitelist;
    }

    /**
     * @dev Checks if user is whitelisted.
     * @param account User address
     * @return 'True' if the whitelist is empty (public TGE) or if the address is found in the whitelist, 'False' otherwise.
     */
    function isUserWhitelisted(address account) public view returns (bool) {
        return info.userWhitelist.length == 0 || _isUserWhitelisted[account];
    }

    /**
     * @dev This method indicates whether this event was launched to implement ERC1155 tokens.
     * @return bool Flag if ERC1155 TGE
     */
    function isERC1155TGE() public view returns (bool) {
        return tokenId == 0 ? false : true;
    }

    /**
     * @dev Returns the block number at which the event ends.
     * @return uint256 Block number
     */
    function getEnd() external view returns (uint256) {
        return createdAt + info.duration;
    }

    /**
    * @notice This method returns the immutable settings with which the TGE was launched.
    * @dev The rules for conducting an event are defined in the TGEInfo structure, which is passed within the calldata when calling one of the TGEFactory contract functions responsible for launching the TGE. For more information about the structure, see the "Interfaces" section. The variables mentioned below should be understood as attributes of the TGEInfo structure.
    A TGE can be public or private. To make the event public, simply leave the whitelist empty.
    The TGE contract can act as an airdrop - a free token distribution. To do this, set the price value to zero.
    To create a DAO with a finite number of participants, each of whom should receive an equal share of tokens, you can set the whitelist when launching the TGE as a list of the participants' addresses, and set both minPurchase and maxPurchase equal to the expression (hardcap / number of participants). To make the pool obtain DAO status only if the distribution is successful under such conditions for all project participants, you can set the softcap value equal to the hardcap. With these settings, the company will become a DAO only if all the initial participants have an equal voting power.
    * @return The settings in the form of a TGEInfo structure
    */
    function getInfo() external view returns (TGEInfo memory) {
        return info;
    }

    /**
     * @dev This method returns the number of tokens that are currently due as protocol fees during the TGE.
     * @return The number of tokens
     */
    function getProtocolTokenFee(uint256 amount) public view returns (uint256) {
        if (IToken(token).tokenType() == IToken.TokenType.Preference) {
            return 0;
        }
        return (amount * protocolFee + (DENOM - 1)) / DENOM;
    }

    /// @notice Determine if a purchase is valid for a specific account and amount.
    /// @dev Returns true if the amount is within the permitted purchase range for the account.
    /// @param account The address of the account to validate the purchase for.
    /// @param amount The amount of the purchase to validate.
    /// @return A boolean value indicating if the purchase is valid.
    function validatePurchase(
        address account,
        uint256 amount
    ) public view returns (bool) {
        return amount >= info.minPurchase && amount <= maxPurchaseOf(account);
    }

    //PRIVATE FUNCTIONS

    function proceedPurchase(address account, uint256 amount) public {
        require(msg.sender == address(this), ExceptionsLibrary.INVALID_USER);

        require(
            validatePurchase(account, amount),
            ExceptionsLibrary.INVALID_PURCHASE_AMOUNT
        );

        // Accrue TGE stats
        totalPurchased += amount;
        purchaseOf[account] += amount;

        // Mint tokens directly to user
        uint256 vestedAmount = (amount *
            info.vestingParams.vestedShare +
            (DENOM - 1)) / DENOM;

        if (amount - vestedAmount > 0) {
            if (isERC1155TGE()) {
                ITokenERC1155(token).mint(
                    account,
                    tokenId,
                    amount - vestedAmount
                );
            } else {
                IToken(token).mint(account, amount - vestedAmount);
            }
        }

        // Vest tokens
        if (vestedAmount > 0) {
            if (isERC1155TGE()) {
                ITokenERC1155(token).setTGEVestedTokens(
                    ITokenERC1155(token).getTotalTGEVestedTokens(tokenId) +
                        vestedAmount,
                    tokenId
                );
            } else {
                IToken(token).setTGEVestedTokens(
                    IToken(token).getTotalTGEVestedTokens() + vestedAmount
                );
            }

            vesting.vest(account, vestedAmount);
        }

        // Increase reserved protocol fee
        uint256 tokenFee = getProtocolTokenFee(amount);
        if (tokenFee > 0) {
            totalProtocolFee += tokenFee;
            if (isERC1155TGE()) {
                ITokenERC1155(token).setProtocolFeeReserved(
                    ITokenERC1155(token).getTotalProtocolFeeReserved(tokenId) +
                        tokenFee,
                    tokenId
                );
            } else {
                IToken(token).setProtocolFeeReserved(
                    IToken(token).getTotalProtocolFeeReserved() + tokenFee
                );
            }
        }

        // Emit event
        emit Purchased(account, amount);

        IToken(token).service().registry().log(
            account,
            address(this),
            0,
            abi.encodeWithSelector(ITGE.purchase.selector, amount)
        );
    }

    // MODIFIER

    /// @notice Modifier that allows the method to be called only if the TGE state is equal to the specified state.
    modifier onlyState(State state_) {
        require(state() == state_, ExceptionsLibrary.WRONG_STATE);
        _;
    }

    /// @notice Modifier that allows the method to be called only by an account that is whitelisted for the TGE or if the TGE is created as public.
    modifier onlyWhitelistedUser() {
        require(
            isUserWhitelisted(msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only by an account that has the ADMIN role in the Service contract.
    modifier onlyManager() {
        IService service = IToken(token).service();
        require(
            service.hasRole(service.SERVICE_MANAGER_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only if the pool associated with the event is not in a paused state.
    modifier whenPoolNotPaused() {
        require(
            !IPausable(IToken(token).pool()).paused(),
            ExceptionsLibrary.SERVICE_PAUSED
        );
        _;
    }

    modifier onlyExecutor() {
        IService service = IToken(token).service();
        require(
            service.hasRole(service.EXECUTOR_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }
}