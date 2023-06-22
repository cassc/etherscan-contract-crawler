// SPDX-License-Identifier: UNLICENSED
// @Credits Defi Site Network 2021

// CrowdPool contract. Version 1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../interfaces/IWETH.sol";
import "../TransferHelper.sol";
import "./SharedStructs.sol";
import "./CrowdPoolLockForwarder.sol";
import "../CrowdPoolSettings.sol";

contract CrowdPoolV1 is ReentrancyGuard {
    /// @notice CrowdPool Contract Version, used to choose the correct ABI to decode the contract
    //   uint256 public contract_version = 1;

    struct CrowdPoolFeeInfo {
        uint256 raised_fee; // divided by 100
        uint256 sold_fee; // divided by 100
        uint256 referral_fee; // divided by 100
        address payable raise_fee_address;
        address payable sole_fee_address;
        address payable referral_fee_address; // if this is not address(0), there is a valid referral
    }

    struct CrowdPoolStatus {
        bool lp_generation_complete; // final flag required to end a crowdpool and enable withdrawls
        bool force_failed; // set this flag to force fail the crowdpool
        uint256 raised_amount; // total base currency raised (usually ETH)
        uint256 sold_amount; // total crowdpool tokens sold
        uint256 token_withdraw; // total tokens withdrawn post successful crowdpool
        uint256 base_withdraw; // total base tokens withdrawn on crowdpool failure
        uint256 num_buyers; // number of unique participants
    }

    struct BuyerInfo {
        uint256 base; // total base token (usually ETH) deposited by user, can be withdrawn on crowdpool failure
        uint256 sale; // num crowdpool tokens a user is owed, can be withdrawn on crowdpool success
    }

    struct TokenInfo {
        string name;
        string symbol;
        uint256 totalsupply;
        uint256 decimal;
    }

    SharedStructs.CrowdPoolInfo public crowdpool_info;
    CrowdPoolStatus public status;
    SharedStructs.CrowdPoolLink public link;
    CrowdPoolFeeInfo public crowdpool_fee_info;
    TokenInfo public tokeninfo;

    address manage_addr;

    // IUniswapV2Factory public uniswapfactory;
    IWETH private WETH;
    CrowdPoolSettings public crowdpool_setting;
    CrowdPoolLockForwarder public crowdpool_lock_forwarder;

    mapping(address => BuyerInfo) public buyers;

    event UserDepsitedSuccess(address, uint256);
    event UserWithdrawSuccess(uint256);
    event UserWithdrawTokensSuccess(uint256);
    event AddLiquidtySuccess(uint256);

    constructor(
        address manage,
        address wethfact,
        address setting,
        address lockaddr
    ) payable {
        crowdpool_setting = CrowdPoolSettings(setting);

        require(
            msg.value >= crowdpool_setting.getLockFee(),
            "Balance is insufficent"
        );

        manage_addr = manage;

        // uniswapfactory = IUniswapV2Factory(uniswapfact);
        WETH = IWETH(wethfact);

        crowdpool_lock_forwarder = CrowdPoolLockForwarder(lockaddr);
    }

    function init_private(SharedStructs.CrowdPoolInfo memory _crowdpool_info)
        external
    {
        require(msg.sender == manage_addr, "Only manage address is available");

        crowdpool_info = _crowdpool_info;

        //Set token token info
        tokeninfo.name = IERC20Metadata(_crowdpool_info.pool_token).name();
        tokeninfo.symbol = IERC20Metadata(_crowdpool_info.pool_token).symbol();
        tokeninfo.decimal = IERC20Metadata(_crowdpool_info.pool_token).decimals();
        tokeninfo.totalsupply = IERC20Metadata(_crowdpool_info.pool_token)
            .totalSupply();
    }

    function init_link(SharedStructs.CrowdPoolLink memory _link) external {
        require(msg.sender == manage_addr, "Only manage address is available");

        link = _link;
    }

    function init_fee() external {
        require(msg.sender == manage_addr, "Only manage address is available");

        crowdpool_fee_info.raised_fee = crowdpool_setting.getRasiedFee(); // divided by 100
        crowdpool_fee_info.sold_fee = crowdpool_setting.getSoldFee(); // divided by 100
        crowdpool_fee_info.referral_fee = crowdpool_setting.getRefferralFee(); // divided by 100
        crowdpool_fee_info.raise_fee_address = crowdpool_setting
            .getRaisedFeeAddress();
        crowdpool_fee_info.sole_fee_address = crowdpool_setting.getSoleFeeAddress();
        crowdpool_fee_info.referral_fee_address = crowdpool_setting
            .getReferralFeeAddress(); // if this is not address(0), there is a valid referral
    }

    modifier onlyCrowdPoolOwner() {
        require(crowdpool_info.crowdpool_owner == msg.sender, "NOT CROWDPOOL OWNER");
        _;
    }

    //   uint256 tempstatus;

    //   function setTempStatus(uint256 flag) public {
    //       tempstatus = flag;
    //   }

    function crowdpoolStatus() public view returns (uint256) {
        // return tempstatus;
        if (status.force_failed) {
            return 3; // FAILED - force fail
        }
        if (
            (block.timestamp > crowdpool_info.crowdpool_end) &&
            (status.raised_amount < crowdpool_info.softcap)
        ) {
            return 3;
        }
        if (status.raised_amount >= crowdpool_info.hardcap) {
            return 2; // SUCCESS - hardcap met
        }
        if (
            (block.timestamp > crowdpool_info.crowdpool_end) &&
            (status.raised_amount >= crowdpool_info.softcap)
        ) {
            return 2; // SUCCESS - crowdpool end and soft cap reached
        }
        if (
            (block.timestamp >= crowdpool_info.crowdpool_start) &&
            (block.timestamp <= crowdpool_info.crowdpool_end)
        ) {
            return 1; // ACTIVE - deposits enabled
        }
        return 0; // QUED - awaiting start block
    }

    // accepts msg.value for eth or _amount for ERC20 tokens
    function userDeposit() public payable nonReentrant {
        require(crowdpoolStatus() == 1, "NOT ACTIVE"); //
        require(crowdpool_info.pool_min <= msg.value, "balance is insufficent");
        require(crowdpool_info.pool_max >= msg.value, "balance is too much");

        BuyerInfo storage buyer = buyers[msg.sender];

        uint256 amount_in = msg.value;
        uint256 allowance = crowdpool_info.pool_max - buyer.base;
        uint256 remaining = crowdpool_info.hardcap - status.raised_amount;
        allowance = allowance > remaining ? remaining : allowance;
        if (amount_in > allowance) {
            amount_in = allowance;
        }
        uint256 tokensSold = (amount_in * crowdpool_info.token_rate) / (10**18);
        require(tokensSold > 0, "ZERO TOKENS");
        require(
            tokensSold <=
                IERC20(crowdpool_info.pool_token).balanceOf(address(this)),
            "Token reamin error"
        );
        if (buyer.base == 0) {
            status.num_buyers++;
        }
        buyers[msg.sender].base = buyers[msg.sender].base + amount_in;
        buyers[msg.sender].sale = buyers[msg.sender].sale + tokensSold;
        status.raised_amount = status.raised_amount + amount_in;
        status.sold_amount = status.sold_amount + tokensSold;

        // return unused ETH
        if (amount_in < msg.value) {
            payable(msg.sender).transfer(msg.value - amount_in);
        }

        emit UserDepsitedSuccess(msg.sender, msg.value);
    }

    // withdraw crowdpool tokens
    // percentile withdrawls allows fee on transfer or rebasing tokens to still work
    function userWithdrawTokens() public nonReentrant {
        require(status.lp_generation_complete, "AWAITING LP GENERATION");
        BuyerInfo storage buyer = buyers[msg.sender];
        uint256 tokensRemainingDenominator = status.sold_amount -
            status.token_withdraw;
        uint256 tokensOwed = (IERC20(crowdpool_info.pool_token).balanceOf(
            address(this)
        ) * buyer.sale) / tokensRemainingDenominator;
        require(tokensOwed > 0, "NOTHING TO WITHDRAW");
        status.token_withdraw = status.token_withdraw + buyer.sale;
        buyers[msg.sender].sale = 0;
        buyers[msg.sender].base = 0;
        TransferHelper.safeTransfer(
            address(crowdpool_info.pool_token),
            msg.sender,
            tokensOwed
        );

        emit UserWithdrawTokensSuccess(tokensOwed);
    }

    // on crowdpool failure
    // percentile withdrawls allows fee on transfer or rebasing tokens to still work
    function userWithdrawBaseTokens() public nonReentrant {
        require(crowdpoolStatus() == 3, "NOT FAILED"); // FAILED

        if (msg.sender == crowdpool_info.crowdpool_owner) {
            ownerWithdrawTokens();
            // return;
        }

        BuyerInfo storage buyer = buyers[msg.sender];
        uint256 baseRemainingDenominator = status.raised_amount -
            status.base_withdraw;
        uint256 remainingBaseBalance = address(this).balance;
        uint256 tokensOwed = (remainingBaseBalance * buyer.base) /
            baseRemainingDenominator;
        require(tokensOwed > 0, "NOTHING TO WITHDRAW");
        status.base_withdraw = status.base_withdraw + buyer.base;
        buyer.base = 0;
        buyer.sale = 0;

        address payable reciver = payable(msg.sender);
        reciver.transfer(tokensOwed);

        emit UserWithdrawSuccess(tokensOwed);
        // TransferHelper.safeTransferBaseToken(address(crowdpool_info.base_token), msg.sender, tokensOwed, false);
    }

    // on crowdpool failure
    // allows the owner to withdraw the tokens they sent for crowdpool & initial liquidity
    function ownerWithdrawTokens() private onlyCrowdPoolOwner {
        require(crowdpoolStatus() == 3, "Only failed status"); // FAILED
        TransferHelper.safeTransfer(
            address(crowdpool_info.pool_token),
            crowdpool_info.crowdpool_owner,
            IERC20(crowdpool_info.pool_token).balanceOf(address(this))
        );

        emit UserWithdrawSuccess(
            IERC20(crowdpool_info.pool_token).balanceOf(address(this))
        );
    }

    // Can be called at any stage before or during the crowdpool to cancel it before it ends.
    // If the pair already exists on uniswap and it contains the crowdpool token as liquidity
    // the final stage of the crowdpool 'addLiquidity()' will fail. This function
    // allows anyone to end the crowdpool prematurely to release funds in such a case.
    function forceFailIfPairExists() public {
        require(!status.lp_generation_complete && !status.force_failed);
        if (
            crowdpool_lock_forwarder.uniswapPairIsInitialised(
                address(crowdpool_info.pool_token),
                address(WETH)
            )
        ) {
            status.force_failed = true;
        }
    }

    // if something goes wrong in LP generation
    // function forceFail () external {
    //     require(msg.sender == MGNR_FEE_ADDRESS);
    //     status.force_failed = true;
    // }

    // on crowdpool success, this is the final step to end the crowdpool, lock liquidity and enable withdrawls of the sale token.
    // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic
    // are not taken into account at this stage to ensure stated liquidity is locked and the pool is initialised according to
    // the crowdpool parameters and fixed prices.
    function addLiquidity() public nonReentrant onlyCrowdPoolOwner {
        require(!status.lp_generation_complete, "GENERATION COMPLETE");
        require(crowdpoolStatus() == 2, "NOT SUCCESS"); // SUCCESS
        // Fail the crowdpool if the pair exists and contains crowdpool token liquidity

        if (
            crowdpool_lock_forwarder.uniswapPairIsInitialised(
                address(crowdpool_info.pool_token),
                address(WETH)
            )
        ) {
            status.force_failed = true;
            emit AddLiquidtySuccess(0);
            return;
        }

        // require(!crowdpool_lock_forwarder.uniswapPairIsInitialised(address(crowdpool_info.pool_token), address(WETH)), "Liqudity exist");

        uint256 crowdpool_raisedfee = (status.raised_amount *
            crowdpool_setting.getRasiedFee()) / 100;

        // base token liquidity
        uint256 baseLiquidity = ((status.raised_amount - crowdpool_raisedfee) *
            (crowdpool_info.liqudity_percent)) / 100;

        // WETH.deposit{value : baseLiquidity}();

        // require(WETH.approve(address(crowdpool_lock_forwarder), baseLiquidity), 'approve failed.');

        // TransferHelper.safeApprove(address(crowdpool_info.base_token), address(crowdpool_lock_forwarder), baseLiquidity);

        // sale token liquidity
        uint256 tokenLiquidity = (baseLiquidity * crowdpool_info.listing_rate) /
            (10**18);
        require(tokenLiquidity > 0, "ZERO Tokens");
        TransferHelper.safeApprove(
            address(crowdpool_info.pool_token),
            address(crowdpool_lock_forwarder),
            tokenLiquidity
        );

        crowdpool_lock_forwarder.lockLiquidity{
            value: crowdpool_setting.getLockFee() + baseLiquidity
        }(
            address(crowdpool_info.pool_token),
            baseLiquidity,
            tokenLiquidity,
            crowdpool_info.lock_end,
            crowdpool_info.crowdpool_owner
        );

        uint256 crowdpoolSoldFee = (status.sold_amount *
            crowdpool_setting.getSoldFee()) / 100;

        address payable reciver = payable(
            address(crowdpool_fee_info.raise_fee_address)
        );
        reciver.transfer(crowdpool_raisedfee);

        // TransferHelper.safeTransferBaseToken(address(crowdpool_info.base_token), crowdpool_fee_info.raise_fee_address, crowdpool_raisedfee, false);
        TransferHelper.safeTransfer(
            address(crowdpool_info.pool_token),
            crowdpool_fee_info.sole_fee_address,
            crowdpoolSoldFee
        );

        // burn unsold tokens
        uint256 remainingSBalance = IERC20(crowdpool_info.pool_token).balanceOf(
            address(this)
        );
        if (remainingSBalance > status.sold_amount) {
            uint256 burnAmount = remainingSBalance - status.sold_amount;
            TransferHelper.safeTransfer(
                address(crowdpool_info.pool_token),
                0x000000000000000000000000000000000000dEaD,
                burnAmount
            );
        }

        // send remaining base tokens to crowdpool owner
        uint256 remainingBaseBalance = address(this).balance;

        address payable crowdpool_fee_reciver = payable(
            address(crowdpool_info.crowdpool_owner)
        );
        crowdpool_fee_reciver.transfer(remainingBaseBalance);

        status.lp_generation_complete = true;
        emit AddLiquidtySuccess(1);
    }

    function destroy() public {
        require(status.lp_generation_complete, "lp generation incomplete");
        selfdestruct(crowdpool_info.crowdpool_owner);
    }

    //   function getTokenNmae() public view returns (string memory) {
    //       return crowdpool_info.pool_token.name();
    //   }

    //   function getTokenSymbol() public view returns (string memory) {
    //       return crowdpool_info.pool_token.symbol();
    //   }
}