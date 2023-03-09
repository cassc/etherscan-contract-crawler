// SPDX-License-Identifier: UNLICENSED
/**
*****************
TEMPLATE CONTRACT
*****************
Although this code is available for viewing on GitHub and here, the general public is NOT given a license to freely deploy smart contracts based on this code, on any blockchains.
To prevent confusion and increase trust in the audited code bases of smart contracts we produce, we intend for there to be only ONE official Factory address on the blockchain producing the corresponding smart contracts, and we are going to point a blockchain domain name at it.
Copyright (c) Intercoin Inc. All rights reserved.
ALLOWED USAGE.
Provided they agree to all the conditions of this Agreement listed below, anyone is welcome to interact with the official Factory Contract at the this address to produce smart contract instances, or to interact with instances produced in this manner by others.
Any user of software powered by this code MUST agree to the following, in order to use it. If you do not agree, refrain from using the software:
DISCLAIMERS AND DISCLOSURES.
Customer expressly recognizes that nearly any software may contain unforeseen bugs or other defects, due to the nature of software development. Moreover, because of the immutable nature of smart contracts, any such defects will persist in the software once it is deployed onto the blockchain. Customer therefore expressly acknowledges that any responsibility to obtain outside audits and analysis of any software produced by Developer rests solely with Customer.
Customer understands and acknowledges that the Software is being delivered as-is, and may contain potential defects. While Developer and its staff and partners have exercised care and best efforts in an attempt to produce solid, working software products, Developer EXPRESSLY DISCLAIMS MAKING ANY GUARANTEES, REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED, ABOUT THE FITNESS OF THE SOFTWARE, INCLUDING LACK OF DEFECTS, MERCHANTABILITY OR SUITABILITY FOR A PARTICULAR PURPOSE.
Customer agrees that neither Developer nor any other party has made any representations or warranties, nor has the Customer relied on any representations or warranties, express or implied, including any implied warranty of merchantability or fitness for any particular purpose with respect to the Software. Customer acknowledges that no affirmation of fact or statement (whether written or oral) made by Developer, its representatives, or any other party outside of this Agreement with respect to the Software shall be deemed to create any express or implied warranty on the part of Developer or its representatives.
INDEMNIFICATION.
Customer agrees to indemnify, defend and hold Developer and its officers, directors, employees, agents and contractors harmless from any loss, cost, expense (including attorney’s fees and expenses), associated with or related to any demand, claim, liability, damages or cause of action of any kind or character (collectively referred to as “claim”), in any manner arising out of or relating to any third party demand, dispute, mediation, arbitration, litigation, or any violation or breach of any provision of this Agreement by Customer.
NO WARRANTY.
THE SOFTWARE IS PROVIDED “AS IS” WITHOUT WARRANTY. DEVELOPER SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES FOR BREACH OF THE LIMITED WARRANTY. TO THE MAXIMUM EXTENT PERMITTED BY LAW, DEVELOPER EXPRESSLY DISCLAIMS, AND CUSTOMER EXPRESSLY WAIVES, ALL OTHER WARRANTIES, WHETHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT LIMITATION ALL IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR USE, OR ANY WARRANTY ARISING OUT OF ANY PROPOSAL, SPECIFICATION, OR SAMPLE, AS WELL AS ANY WARRANTIES THAT THE SOFTWARE (OR ANY ELEMENTS THEREOF) WILL ACHIEVE A PARTICULAR RESULT, OR WILL BE UNINTERRUPTED OR ERROR-FREE. THE TERM OF ANY IMPLIED WARRANTIES THAT CANNOT BE DISCLAIMED UNDER APPLICABLE LAW SHALL BE LIMITED TO THE DURATION OF THE FOREGOING EXPRESS WARRANTY PERIOD. SOME STATES DO NOT ALLOW THE EXCLUSION OF IMPLIED WARRANTIES AND/OR DO NOT ALLOW LIMITATIONS ON THE AMOUNT OF TIME AN IMPLIED WARRANTY LASTS, SO THE ABOVE LIMITATIONS MAY NOT APPLY TO CUSTOMER. THIS LIMITED WARRANTY GIVES CUSTOMER SPECIFIC LEGAL RIGHTS. CUSTOMER MAY HAVE OTHER RIGHTS WHICH VARY FROM STATE TO STATE. 
LIMITATION OF LIABILITY. 
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL DEVELOPER BE LIABLE UNDER ANY THEORY OF LIABILITY FOR ANY CONSEQUENTIAL, INDIRECT, INCIDENTAL, SPECIAL, PUNITIVE OR EXEMPLARY DAMAGES OF ANY KIND, INCLUDING, WITHOUT LIMITATION, DAMAGES ARISING FROM LOSS OF PROFITS, REVENUE, DATA OR USE, OR FROM INTERRUPTED COMMUNICATIONS OR DAMAGED DATA, OR FROM ANY DEFECT OR ERROR OR IN CONNECTION WITH CUSTOMER'S ACQUISITION OF SUBSTITUTE GOODS OR SERVICES OR MALFUNCTION OF THE SOFTWARE, OR ANY SUCH DAMAGES ARISING FROM BREACH OF CONTRACT OR WARRANTY OR FROM NEGLIGENCE OR STRICT LIABILITY, EVEN IF DEVELOPER OR ANY OTHER PERSON HAS BEEN ADVISED OR SHOULD KNOW OF THE POSSIBILITY OF SUCH DAMAGES, AND NOTWITHSTANDING THE FAILURE OF ANY REMEDY TO ACHIEVE ITS INTENDED PURPOSE. WITHOUT LIMITING THE FOREGOING OR ANY OTHER LIMITATION OF LIABILITY HEREIN, REGARDLESS OF THE FORM OF ACTION, WHETHER FOR BREACH OF CONTRACT, WARRANTY, NEGLIGENCE, STRICT LIABILITY IN TORT OR OTHERWISE, CUSTOMER'S EXCLUSIVE REMEDY AND THE TOTAL LIABILITY OF DEVELOPER OR ANY SUPPLIER OF SERVICES TO DEVELOPER FOR ANY CLAIMS ARISING IN ANY WAY IN CONNECTION WITH OR RELATED TO THIS AGREEMENT, THE SOFTWARE, FOR ANY CAUSE WHATSOEVER, SHALL NOT EXCEED 1,000 USD.
TRADEMARKS.
This Agreement does not grant you any right in any trademark or logo of Developer or its affiliates.
LINK REQUIREMENTS.
Operators of any Websites and Apps which make use of smart contracts based on this code must conspicuously include the following phrase in their website, featuring a clickable link that takes users to intercoin.app:
"Visit https://intercoin.app to launch your own NFTs, DAOs and other Web3 solutions."
STAKING OR SPENDING REQUIREMENTS.
In the future, Developer may begin requiring staking or spending of Intercoin tokens in order to take further actions (such as producing series and minting tokens). Any staking or spending requirements will first be announced on Developer's website (intercoin.org) four weeks in advance. Staking requirements will not apply to any actions already taken before they are put in place.
CUSTOM ARRANGEMENTS.
Reach out to us at intercoin.org if you are looking to obtain Intercoin tokens in bulk, remove link requirements forever, remove staking requirements forever, or get custom work done with your Web3 projects.
ENTIRE AGREEMENT
This Agreement contains the entire agreement and understanding among the parties hereto with respect to the subject matter hereof, and supersedes all prior and contemporaneous agreements, understandings, inducements and conditions, express or implied, oral or written, of any nature whatsoever with respect to the subject matter hereof. The express terms hereof control and supersede any course of performance and/or usage of the trade inconsistent with any of the terms hereof. Provisions from previous Agreements executed between Customer and Developer., which are not expressly dealt with in this Agreement, will remain in effect.
SUCCESSORS AND ASSIGNS
This Agreement shall continue to apply to any successors or assigns of either party, or any corporation or other entity acquiring all or substantially all the assets and business of either party whether by operation of law or otherwise.
ARBITRATION
All disputes related to this agreement shall be governed by and interpreted in accordance with the laws of New York, without regard to principles of conflict of laws. The parties to this agreement will submit all disputes arising under this agreement to arbitration in New York City, New York before a single arbitrator of the American Arbitration Association (“AAA”). The arbitrator shall be selected by application of the rules of the AAA, or by mutual agreement of the parties, except that such arbitrator shall be an attorney admitted to practice law New York. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section.
**/
pragma solidity ^0.8.11;
//import "./interfaces/IHook.sol"; exists in PoolStakesLib
import "./interfaces/ITaxes.sol";
import "./interfaces/IDonationRewards.sol";

import "./interfaces/ICommunityCoin.sol";
import "./interfaces/ICommunityStakingPool.sol";

import "./interfaces/ICommunityStakingPoolFactory.sol";
//import "./interfaces/IStructs.sol"; exists in ICommunityCoin
import "./RolesManagement.sol";

//import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@artman325/community/contracts/interfaces/ICommunity.sol";
import "@artman325/releasemanager/contracts/CostManagerHelperERC2771Support.sol";

import "./libs/PoolStakesLib.sol";

//import "hardhat/console.sol";

contract CommunityCoin is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    CostManagerHelperERC2771Support,
    ICommunityCoin,
    RolesManagement,
    ERC777Upgradeable,
    IERC777RecipientUpgradeable
{
    //using MinimumsLib for MinimumsLib.UserStruct;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint64 internal constant LOCKUP_INTERVAL = 1 days;//24 * 60 * 60; // day in seconds
    uint64 internal constant LOCKUP_BONUS_INTERVAL = 52000 weeks;//1000 * 365 * 24 * 60 * 60; // 1000 years in seconds
    uint64 public constant FRACTION = 100000; // fractions are expressed as portions of this

    uint64 public constant MAX_REDEEM_TARIFF = 10000; //10%*FRACTION = 0.1 * 100000 = 10000
    uint64 public constant MAX_UNSTAKE_TARIFF = 10000; //10%*FRACTION = 0.1 * 100000 = 10000

    // max constants used in BeforeTransfer
    uint64 public constant MAX_TAX = 10000; //10%*FRACTION = 0.1 * 100000 = 10000
    uint64 public constant MAX_BOOST = 10000; //10%*FRACTION = 0.1 * 100000 = 10000

    address public taxHook;

    uint64 public redeemTariff;
    uint64 public unstakeTariff;

    address public hook; // hook used to bonus calculation
    address public donationRewardsHook; // donation hook rewards

    ICommunityStakingPoolFactory public instanceManagment; // ICommunityStakingPoolFactory

    uint256 internal discountSensitivity;

    // uint256 internal totalUnstakeable;
    // uint256 internal totalRedeemable;
    // // it's how tokens will store in pools. without bonuses.
    // // means totalReserves = SUM(pools.totalSupply)
    // uint256 internal totalReserves;
    IStructs.Total internal total;

    //      instance
    mapping(address => InstanceStruct) internal _instances;

    //bytes32 private constant TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    // Constants for shifts
    uint8 internal constant OPERATION_SHIFT_BITS = 240; // 256 - 16

    // Constants representing operations
    uint8 internal constant OPERATION_INITIALIZE = 0x0;
    uint8 internal constant OPERATION_ISSUE_WALLET_TOKENS = 0x1;
    uint8 internal constant OPERATION_ISSUE_WALLET_TOKENS_BONUS = 0x2;
    uint8 internal constant OPERATION_ISSUE_WALLET_TOKENS_BY_INVITE = 0x3;
    uint8 internal constant OPERATION_ADD_TO_CIRCULATION = 0x4;
    uint8 internal constant OPERATION_REMOVE_FROM_CIRCULATION = 0x5;
    uint8 internal constant OPERATION_PRODUCE = 0x6;
    uint8 internal constant OPERATION_PRODUCE_ERC20 = 0x7;
    uint8 internal constant OPERATION_UNSTAKE = 0x8;
    uint8 internal constant OPERATION_REDEEM = 0x9;
    uint8 internal constant OPERATION_GRANT_ROLE = 0xA;
    uint8 internal constant OPERATION_REVOKE_ROLE = 0xB;
    uint8 internal constant OPERATION_CLAIM = 0xC;
    uint8 internal constant OPERATION_SET_TRUSTEDFORWARDER = 0xD;
    uint8 internal constant OPERATION_SET_TRANSFER_OWNERSHIP = 0xE;
    uint8 internal constant OPERATION_TRANSFER_HOOK = 0xF;

    //      users
    mapping(address => UserData) internal users;

    bool flagHookTransferReentrant;
    bool flagBurnUnstakeRedeem;
    modifier proceedBurnUnstakeRedeem() {
        flagBurnUnstakeRedeem = true;
        _;
        flagBurnUnstakeRedeem = false;
    }
    event RewardGranted(address indexed token, address indexed account, uint256 amount);
    event Staked(address indexed account, uint256 amount, uint256 priceBeforeStake);

    event MaxTaxExceeded();
    event MaxBoostExceeded();

    /**
     * @notice initializing method. called by factory
     * @param tokenName internal token name 
     * @param tokenSymbol internal token symbol.
     * @param impl address of StakingPool implementation. usual it's `${tradedToken}c`
     * @param hook_ address of contract implemented IHook interface and used to calculation bonus tokens amount
     * @param stakingPoolFactory address of contract that managed and cloned pools
     * @param discountSensitivity_ discountSensitivity value that manage amount tokens in redeem process. multiplied by `FRACTION`(10**5 by default)
     * @param communitySettings tuple of IStructs.CommunitySettings. fractionBy, addressCommunity, roles, etc
     * @param costManager_ costManager address
     * @param producedBy_ address that produced instance by factory
     * @custom:calledby StakingFactory contract
     * @custom:shortd initializing contract. called by StakingFactory contract
     */
    function initialize(
        string calldata tokenName,
        string calldata tokenSymbol,
        address impl,
        address hook_,
        address stakingPoolFactory,
        uint256 discountSensitivity_,
        IStructs.CommunitySettings calldata communitySettings,
        address costManager_,
        address producedBy_
    ) external virtual override initializer {
        __CostManagerHelper_init(_msgSender());
        _setCostManager(costManager_);

        __Ownable_init();

        __ERC777_init(tokenName, tokenSymbol, (new address[](0)));

        __ReentrancyGuard_init();

        instanceManagment = ICommunityStakingPoolFactory(stakingPoolFactory); //new ICommunityStakingPoolFactory(impl);
        instanceManagment.initialize(impl);

        hook = hook_;
        if (hook_ != address(0)) {
            IHook(hook).setupCaller();
        }

        discountSensitivity = discountSensitivity_;

        __RolesManagement_init(communitySettings);

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));

        _accountForOperation(OPERATION_INITIALIZE << OPERATION_SHIFT_BITS, uint256(uint160(producedBy_)), 0);
    }

    ////////////////////////////////////////////////////////////////////////
    // external section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
     * @notice method to distribute tokens after user stake. called externally only by pool contract
     * @param account address of user that tokens will mint for
     * @param amount token's amount
     * @param priceBeforeStake price that was before adding liquidity in pool
     * @custom:calledby staking-pool
     * @custom:shortd distribute wallet tokens
     */
    function issueWalletTokens(
        address account,
        uint256 amount,
        uint256 priceBeforeStake,
        uint256 donatedAmount
    ) external override {
        address instance = msg.sender; //here need a msg.sender as a real sender.

        // here need to know that is definetely StakingPool. because with EIP-2771 forwarder can call methods as StakingPool.
        ICommunityStakingPoolFactory.InstanceInfo memory instanceInfo = instanceManagment.getInstanceInfoByPoolAddress(
            instance
        );

        require(instanceInfo.exists == true);

        // just call hook if setup before and that's all
        if (donatedAmount > 0 && donationRewardsHook != address(0)) {
            IDonationRewards(donationRewardsHook).onDonate(instanceInfo.tokenErc20, account, donatedAmount);
            return;
        }


        // calculate bonusAmount
        uint256 bonusAmount = (amount * instanceInfo.bonusTokenFraction) / FRACTION;

        // calculate invitedAmount
        address invitedBy = address(0);
        uint256 invitedAmount = 0;

        if (invitedByFraction != 0) {
            invitedBy = _invitedBy(account);

            if (invitedBy != address(0)) {
                //do invite comission calculation here
                invitedAmount = (amount * invitedByFraction) / FRACTION;
            }
        }

        //forward conversion( LP -> СС)
        amount = (amount * (instanceInfo.numerator)) / (instanceInfo.denominator);
        bonusAmount = (bonusAmount * (instanceInfo.numerator)) / (instanceInfo.denominator);
        invitedAmount = (invitedAmount * (instanceInfo.numerator)) / (instanceInfo.denominator);

        // means extra tokens should not to include into unstakeable and totalUnstakeable, but part of them will be increase totalRedeemable
        // also keep in mind that user can unstake only unstakeable[account].total which saved w/o bonusTokens, but minimums and mint with it.
        // it's provide to use such tokens like transfer but prevent unstake bonus in 1to1 after minimums expiring
        // amount += bonusAmount;

        _instances[instance]._instanceStaked += amount; // + bonusAmount + invitedAmount;

        _instances[instance].unstakeable[account] += amount;
        users[account].unstakeable += amount;

        // _instances[instance].unstakeableBonuses[account] += bonusAmount;
        // users[account].unstakeableBonuses += bonusAmount;
        _insertBonus(instance, account, bonusAmount);

        total.totalUnstakeable += amount;
        total.totalReserves += amount;

        if (invitedBy != address(0)) {
            // _instances[instance].unstakeableBonuses[invitedBy] += invitedAmount;
            // users[invitedBy].unstakeableBonuses += invitedAmount;
            _insertBonus(instance, invitedBy, invitedAmount);
        }

        // mint main part + bonus (@dev here bonus can be zero )
        _mint(account, (amount + bonusAmount), "", "");
        emit Staked(account, (amount + bonusAmount), priceBeforeStake);
        // locked main
        //users[account].tokensLocked._minimumsAdd(amount, instanceInfo.duration, LOCKUP_INTERVAL, false);
        MinimumsLib._minimumsAdd(users[account].tokensLocked, amount, instanceInfo.duration, LOCKUP_INTERVAL, false);

        _accountForOperation(
            OPERATION_ISSUE_WALLET_TOKENS << OPERATION_SHIFT_BITS,
            uint256(uint160(account)),
            amount + bonusAmount
        );

        // locked main
        if (bonusAmount > 0) {
            //users[account].tokensBonus._minimumsAdd(bonusAmount, 1, LOCKUP_BONUS_INTERVAL, false);
            MinimumsLib._minimumsAdd(users[account].tokensBonus, bonusAmount, 1, LOCKUP_BONUS_INTERVAL, false);
            _accountForOperation(
                OPERATION_ISSUE_WALLET_TOKENS_BONUS << OPERATION_SHIFT_BITS,
                uint256(uint160(account)),
                bonusAmount
            );
        }

        if (invitedBy != address(0)) {
            _mint(invitedBy, invitedAmount, "", "");
            //users[invitedBy].tokensBonus._minimumsAdd(invitedAmount, 1, LOCKUP_BONUS_INTERVAL, false);
            MinimumsLib._minimumsAdd(users[invitedBy].tokensBonus, invitedAmount, 1, LOCKUP_BONUS_INTERVAL, false);
            _accountForOperation(
                OPERATION_ISSUE_WALLET_TOKENS_BY_INVITE << OPERATION_SHIFT_BITS,
                uint256(uint160(invitedBy)),
                invitedAmount
            );
        }
    }

    /**
     * @notice method to adding tokens to circulation. called externally only by `CIRCULATION_ROLE`
     * @param account account that will obtain tokens
     * @param amount token's amount
     * @custom:calledby `CIRCULATION_ROLE`
     * @custom:shortd distribute tokens
     */
    function addToCirculation(address account, uint256 amount) external nonReentrant {

        _checkRole(circulationRoleId, _msgSender());

        _mint(account, amount, "", "");

        // dev note.
        // we shouldn't increase totalRedeemable. Circulations tokens raise inflations and calculated by (total-redeemable-unstakeable)
        //total.totalRedeemable += amount; 

        _accountForOperation(OPERATION_ADD_TO_CIRCULATION << OPERATION_SHIFT_BITS, uint256(uint160(account)), amount);

    }

    /**
     * @notice used to catch when used try to redeem by sending wallet tokens directly to contract
     * see more in {IERC777RecipientUpgradeable::tokensReceived}
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @custom:shortd part of {IERC777RecipientUpgradeable}
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        if (!(_msgSender() == address(this) && to == address(this))) {
            revert OwnTokensPermittedOnly();
        }
        _checkRole(redeemRoleId, from);
        __redeem(address(this), from, amount, new address[](0), Strategy.REDEEM);
    }

    ////////////////////////////////////////////////////////////////////////
    // public section //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
     * @notice function for creation erc20 instance pool.
     * @param tokenErc20 address of erc20 token.
     * @param duration duration represented in amount of `LOCKUP_INTERVAL`
     * @param bonusTokenFraction fraction of bonus tokens multiplied by {CommunityStakingPool::FRACTION} that additionally distributed when user stakes
     * @param donations array of tuples donations. address,uint256. if array empty when coins will obtain sender, overwise donation[i].account  will obtain proportionally by ration donation[i].amount
     * @return instance address of created instance pool `CommunityStakingPoolErc20`
     * @custom:shortd creation erc20 instance with simple options
     */
    function produce(
        address tokenErc20,
        uint64 duration,
        uint64 bonusTokenFraction,
        address popularToken,
        IStructs.StructAddrUint256[] memory donations,
        uint64 rewardsRateFraction,
        uint64 numerator,
        uint64 denominator
    ) public onlyOwner returns (address instance) {
        return
            _produce(
                tokenErc20,
                duration,
                bonusTokenFraction,
                popularToken,
                donations,
                rewardsRateFraction,
                numerator,
                denominator
            );
    }

    /**
     * @notice method to obtain tokens: lp or erc20, depends of pool that was staked before. like redeem but can applicable only for own staked tokens that haven't transfer yet. so no need to have redeem role for this
     * @param amount The number of ITRc tokens that will be unstaked.
     * @custom:shortd unstake own ITRc tokens
     */
    function unstake(uint256 amount) public nonReentrant {
        address account = _msgSender();
        _validateUnstake(account, amount);
        _unstake(account, amount, new address[](0), Strategy.UNSTAKE);
        _accountForOperation(OPERATION_UNSTAKE << OPERATION_SHIFT_BITS, uint256(uint160(account)), amount);
    }
    
    /**
     * @dev function has overloaded. wallet tokens will be redeemed from pools in order from deployed
     * @notice way to redeem via approve/transferFrom. Another way is send directly to contract. User will obtain uniswap-LP tokens
     * @param amount The number of wallet tokens that will be redeemed.
     * @custom:shortd redeem tokens
     */
    function redeem(uint256 amount) public nonReentrant {
        _redeem(_msgSender(), amount, new address[](0), Strategy.REDEEM);

        _accountForOperation(OPERATION_REDEEM << OPERATION_SHIFT_BITS, uint256(uint160(_msgSender())), amount);
    }

    /**
     * @dev function has overloaded. wallet tokens will be redeemed from pools in order from `preferredInstances`. tx reverted if amoutn is unsufficient even if it is enough in other pools
     * @notice way to redeem via approve/transferFrom. Another way is send directly to contract. User will obtain uniswap-LP tokens
     * @param amount The number of wallet tokens that will be redeemed.
     * @param preferredInstances preferred instances for redeem first
     * @custom:shortd redeem tokens with preferredInstances
     */
    function redeem(uint256 amount, address[] memory preferredInstances) public nonReentrant {
        _redeem(_msgSender(), amount, preferredInstances, Strategy.REDEEM);

        _accountForOperation(OPERATION_REDEEM << OPERATION_SHIFT_BITS, uint256(uint160(_msgSender())), amount);
    }

    /**
     * @notice way to view locked tokens that still can be unstakeable by user
     * @param account address
     * @custom:shortd view locked tokens
     */
    function viewLockedWalletTokens(address account) public view returns (uint256) {
        //return users[account].tokensLocked._getMinimum() + users[account].tokensBonus._getMinimum();
        return MinimumsLib._getMinimum(users[account].tokensLocked) + MinimumsLib._getMinimum(users[account].tokensBonus);
    }

    /**
     * @notice way to view locked tokens lists(main and bonuses) that still can be unstakeable by user
     * @param account address
     * @custom:shortd view locked tokens lists (main and bonuses)
     */
    function viewLockedWalletTokensList(address account) public view returns (uint256[][] memory, uint256[][] memory) {
        //return (users[account].tokensLocked._getMinimumList(), users[account].tokensBonus._getMinimumList());
        return (MinimumsLib._getMinimumList(users[account].tokensLocked), MinimumsLib._getMinimumList(users[account].tokensBonus));
    }

    // /**
    //  * @dev calculate how much token user will obtain if redeem and remove liquidity token.
    //  * There are steps:
    //  * 1. LP tokens swap to Reserved and Traded Tokens
    //  * 2. TradedToken swap to Reverved
    //  * 3. All Reserved tokens try to swap in order of swapPaths
    //  * @param account address which will be redeem funds from
    //  * @param amount liquidity tokens amount
    //  * @param preferredInstances array of preferred Stakingpool instances which will be redeem funds from
    //  * @param swapPaths array of arrays uniswap swapPath
    //  * @return address destination address
    //  * @return uint256 destination amount
    //  */
    // function simulateRedeemAndRemoveLiquidity(
    //     address account,
    //     uint256 amount, //amountLP,
    //     address[] memory preferredInstances,
    //     address[][] memory swapPaths
    // ) public view returns (address, uint256) {
    //     (
    //         address[] memory instancesToRedeem,
    //         uint256[] memory valuesToRedeem, 
    //         /*uint256[] memory amounts*/, 
    //         /* uint256 len*/ , 
    //         /*uint256 newAmount*/

    //     ) = _poolStakesAvailable(
    //             account,
    //             amount,
    //             preferredInstances,
    //             Strategy.REDEEM_AND_REMOVE_LIQUIDITY,
    //             totalSupply() //totalSupplyBefore
    //         );

    //     return instanceManagment.amountAfterSwapLP(instancesToRedeem, valuesToRedeem, swapPaths);
    // }

    /**
    * @notice calling claim method on Hook Contract. in general it's Rewards contract that can be able to accomulate bonuses. 
    * calling `claim` user can claim them
    */
    function claim() public {
        _accountForOperation(OPERATION_CLAIM << OPERATION_SHIFT_BITS, uint256(uint160(_msgSender())), 0);
        if (hook != address(0)) {
            IRewards(hook).onClaim(_msgSender());
        }
    }

    /**
     * @notice setup trusted forwarder address
     * @param forwarder trustedforwarder's address to set
     * @custom:shortd setup trusted forwarder
     * @custom:calledby owner
     */
    function setTrustedForwarder(address forwarder) public override onlyOwner {
        if (owner() == forwarder) {
            revert TrustedForwarderCanNotBeOwner(forwarder);
        }

        _setTrustedForwarder(forwarder);
        _accountForOperation(
            OPERATION_SET_TRUSTEDFORWARDER << OPERATION_SHIFT_BITS,
            uint256(uint160(_msgSender())),
            uint256(uint160(forwarder))
        );
    }
    /**
    * @notice ownable version transferOwnership with supports ERC2771 
    * @param newOwner new owner address
    * @custom:shortd transferOwnership
    * @custom:calledby owner
    */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        if (_isTrustedForwarder(msg.sender)) {
            revert DeniedForTrustedForwarder(msg.sender);
        }
        if (_isTrustedForwarder(newOwner)) {
            _setTrustedForwarder(address(0));
        }
        _accountForOperation(
            OPERATION_SET_TRANSFER_OWNERSHIP << OPERATION_SHIFT_BITS,
            uint256(uint160(_msgSender())),
            uint256(uint160(newOwner))
        );
        super.transferOwnership(newOwner);
    }

    /**
    * @notice additional tokens for the inviter
    * @param fraction fraction that will send to person which has invite person who staked
    * @custom:shortd set commission for addional tokens
    * @custom:calledby owner
    */
    function setCommission(uint256 fraction) public onlyOwner {
        invitedByFraction = fraction;
    }

    function setTariff(uint64 redeemTariff_, uint64 unstakeTariff_) public {
        _checkRole(tariffRoleId, _msgSender());
        if (redeemTariff_ > MAX_REDEEM_TARIFF || unstakeTariff_ > MAX_UNSTAKE_TARIFF) {
            revert AmountExceedsMaxTariff();
        }
        redeemTariff = redeemTariff_;
        unstakeTariff = unstakeTariff_;
    }

    /**
    * @notice set hook contract, tha implement Beforetransfer methodf and can be managed amount of transferred tokens.
    * @param taxAddress address of TaxHook
    * @custom:shortd set tax hook contract address
    * @custom:calledby owner
    */
    function setupTaxAddress(address taxAddress) public onlyOwner {
        require(taxHook == address(0));
        taxHook = taxAddress;
    }

    /**
    * @notice set donations contract, triggered when someone donate funds ina pool
    * @param addr address of donationRewardsHook
    * @custom:shortd set donations hook contract address
    * @custom:calledby owner
    */
    function setupDonationHookAddress(address addr) public onlyOwner {
        donationRewardsHook = addr;
    }

    ////////////////////////////////////////////////////////////////////////
    // internal section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    function _validateUnstake(address account, uint256 amount) internal view {
        uint256 balance = balanceOf(account);

        if (amount > balance) {
            revert InsufficientBalance(account, amount);
        }

        //uint256 locked = users[account].tokensLocked._getMinimum();
        uint256 locked = MinimumsLib._getMinimum(users[account].tokensLocked);

        uint256 remainingAmount = balance - amount;

        if (locked > remainingAmount) {
            revert StakeNotUnlockedYet(account, locked, remainingAmount);
        }
    }

    function _produce(
        address tokenErc20,
        uint64 duration,
        uint64 bonusTokenFraction,
        address popularToken,
        IStructs.StructAddrUint256[] memory donations,
        uint64 rewardsRateFraction,
        uint64 numerator,
        uint64 denominator
    ) internal returns (address instance) {
        instance = instanceManagment.produce(
            tokenErc20,
            duration,
            bonusTokenFraction,
            popularToken,
            donations,
            rewardsRateFraction,
            numerator,
            denominator
        );
        emit InstanceCreated(tokenErc20, instance);

        _accountForOperation(
            OPERATION_PRODUCE_ERC20 << OPERATION_SHIFT_BITS,
            (duration << (256 - 64)) + (bonusTokenFraction << (256 - 128)) + (numerator << (256 - 192)) + (denominator),
            0
        );
    }

    function _unstake(
        address account,
        uint256 amount,
        address[] memory preferredInstances,
        Strategy strategy
    ) internal proceedBurnUnstakeRedeem {
        // console.log("_unstake#0");
        uint256 totalSupplyBefore = _burn(account, amount);

        (
            address[] memory instancesList,
            uint256[] memory values,
            uint256[] memory amounts,
            uint256 len,
            uint256 newAmount
        ) = _poolStakesAvailable(account, amount, preferredInstances, strategy, totalSupplyBefore);

        // not obviously but we burn all before. not need to burn this things separately
        // `newAmount` just confirm us how much amount using in calculation pools
            


        // console.log("_unstake#2");
        // console.log("len =",len);
        for (uint256 i = 0; i < len; i++) {
            // console.log("i =",i);
            // console.log("amounts[i] =",amounts[i]);
            // console.log("users[account].unstakeable =",users[account].unstakeable);
            // console.log("users[account].unstakeableBonuses =",users[account].unstakeableBonuses);
            //console.log(1);

            _instances[instancesList[i]]._instanceStaked -= amounts[i];

            // in stats we should minus without taxes as we did in burn
            _instances[instancesList[i]].unstakeable[account] -= amounts[i] * amount / newAmount;
            users[account].unstakeable -= amounts[i] * amount / newAmount;
            

            //console.log(4);

            //proceedPool(account, instancesList[i], values[i], strategy);
            PoolStakesLib.proceedPool(instanceManagment, hook, account, instancesList[i], values[i], strategy);
            //console.log(5);
        }
        //console.log(6);
    }

    // create map of instance->amount or LP tokens that need to redeem
    function _poolStakesAvailable(
        address account,
        uint256 amount,
        address[] memory preferredInstances,
        Strategy strategy,
        uint256 totalSupplyBefore
    )
        internal
        view
        returns (
            address[] memory instancesAddress, // instance's addresses
            uint256[] memory values, // amounts to redeem in instance
            uint256[] memory amounts, // itrc amount equivalent(applied num/den)
            uint256 len,
            uint256 newAmount
        )
    {
        newAmount = PoolStakesLib.getAmountLeft(
            account,
            amount,
            totalSupplyBefore,
            strategy,
            total,
            discountSensitivity,
            users,
            unstakeTariff,
            redeemTariff,
            FRACTION
        );
        // console.log("_poolStakesAvailable::amountLeft=", amount);
        (instancesAddress, values, amounts, len) = PoolStakesLib.available(
            account,
            newAmount,
            preferredInstances,
            strategy,
            instanceManagment,
            _instances
        );
    }

    function _redeem(
        address account,
        uint256 amount,
        address[] memory preferredInstances,
        Strategy strategy
    ) internal {
        _checkRole(redeemRoleId, account);

        __redeem(account, account, amount, preferredInstances, strategy);
    }

    function _burn(address account, uint256 amount)
        internal
        proceedBurnUnstakeRedeem
        returns (uint256 totalSupplyBefore)
    {
        totalSupplyBefore = totalSupply();
        if (account != address(this)) {
            //require(allowance(account, address(this))  >= amount, "Amount exceeds allowance");
            if (allowance(account, address(this)) < amount) {
                revert AmountExceedsAllowance(account, amount);
            }
        }

        _burn(account, amount, "", "");
    }

    function __redeem(
        address accountToBurn,
        address accountToRedeem,
        uint256 amount,
        address[] memory preferredInstances,
        Strategy strategy
    ) internal proceedBurnUnstakeRedeem {

        if (amount > total.totalRedeemable) {
            revert InsufficientBalance(accountToRedeem, amount);
        }

        uint256 totalSupplyBefore = _burn(accountToBurn, amount);

        (address[] memory instancesToRedeem, uint256[] memory valuesToRedeem, uint256[] memory amounts, uint256 len, /*uint256 newAmount*/) = _poolStakesAvailable(
            accountToRedeem,
            amount,
            preferredInstances,
            strategy, /*Strategy.REDEEM*/
            totalSupplyBefore
        );

        // not obviously but we burn all before. not need to burn this things separately
        // `newAmount` just confirm us how much amount using in calculation pools
        
        for (uint256 i = 0; i < len; i++) {
            if (_instances[instancesToRedeem[i]].redeemable > 0) {
                _instances[instancesToRedeem[i]].redeemable -= amounts[i];
                
                total.totalRedeemable -= amounts[i];
                total.totalReserves -= amounts[i];

                //proceedPool(accountToRedeem, instancesToRedeem[i], valuesToRedeem[i], strategy);
                PoolStakesLib.proceedPool(instanceManagment, hook, accountToRedeem, instancesToRedeem[i], valuesToRedeem[i], strategy);
            }
        }

    }

    function _send(
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual override {
        
        if (
            from != address(0) && //otherwise minted
            !(from == address(this) && to == address(0)) && //burnt by contract itself
            address(taxHook) != address(0) && // tax hook setup
            !flagHookTransferReentrant // no reentrant here
        ) {
            // hook should return tuple: (success, amountAdjusted)
            //  can return true/false
            // true = revert ;  false -pass tx

            _accountForOperation(
                OPERATION_TRANSFER_HOOK << OPERATION_SHIFT_BITS,
                uint256(uint160(from)),
                uint256(uint160(to))
            );

            flagHookTransferReentrant = true;

            (bool success, uint256 amountAdjusted) = ITaxes(taxHook).beforeTransfer(_msgSender(), from, to, amount);
            if (success == false) {
                revert HookTransferPrevent(from, to, amount);
            }

            if (amount < amountAdjusted) {
                if (amount + amount * MAX_BOOST / FRACTION < amountAdjusted) {
                    amountAdjusted = amount + amount * MAX_BOOST / FRACTION;
                    emit MaxBoostExceeded();
                }
                _mint(to, amountAdjusted - amount, "", "");
            } else if (amount > amountAdjusted) {
                // if amountAdjusted less then amount with max tax
                if (amount - amount * MAX_TAX / FRACTION > amountAdjusted) {
                    amountAdjusted = amount - amount * MAX_TAX / FRACTION;
                    emit MaxTaxExceeded();
                }

                _burn(from, amount - amountAdjusted, "", "");

                amount = amountAdjusted;

            }

            // if amount == amountAdjusted do nothing

            flagHookTransferReentrant = false;
        }

        super._send(from, to, amount, userData, operatorData, requireReceptionAck);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
    
        super._beforeTokenTransfer(operator, from, to, amount);

        if (from != address(0)) {
            // otherwise minted
            if (from == address(this) && to == address(0)) {
                // burnt by contract itself
            } else {
                uint256 balance = balanceOf(from);

                if (balance >= amount) {
                    uint256 remainingAmount = balance - amount;

                    //-------------------
                    // locked sections
                    //-------------------
                    PoolStakesLib.lockedPart(users, from, remainingAmount);
                    //--------------------

                    if (
                        // not calculate if
                        flagBurnUnstakeRedeem || to == address(this) // - burn or unstake or redeem // - send directly to contract
                    ) {

                    } else {
                        //-------------------
                        // unstakeable sections
                        //-------------------
                        PoolStakesLib.unstakeablePart(users, _instances, from, to, total, amount);
                        //--------------------
                        
                    }
                } else {
                    // insufficient balance error would be in {ERC777::_move}
                }
            }
        }

    }

    /**
     * @dev implemented EIP-2771
     * @return signer return address of msg.sender. but consider EIP-2771 for trusted forwarder will return from msg.data payload
     */
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, TrustedForwarder)
        returns (address signer)
    {
        return TrustedForwarder._msgSender();
    }

    function _insertBonus(
        address instance,
        address account,
        uint256 amount
    ) internal {
        if (!users[account].instancesList.contains(instance)) {
            users[account].instancesList.add(instance);
        }
        _instances[instance].unstakeableBonuses[account] += amount;
        users[account].unstakeableBonuses += amount;
    }

    

}