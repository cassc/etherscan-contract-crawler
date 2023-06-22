// SPDX-License-Identifier: UNLICENSED
// @Credits Defi Site Network 2021

// Presale contract. Version 1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../interfaces/IWETH.sol";
import "../TransferHelper.sol";
import "./SharedStructs.sol";
import "./PresaleLockForwarder.sol";
import "../PresaleSettings.sol";

contract PresaleV1 is ReentrancyGuard {
    /// @notice Presale Contract Version, used to choose the correct ABI to decode the contract
    //   uint256 public contract_version = 1;

    struct PresaleFeeInfo {
        uint256 raised_fee; // divided by 100
        uint256 sold_fee; // divided by 100
        uint256 referral_fee; // divided by 100
        address payable raise_fee_address;
        address payable sole_fee_address;
        address payable referral_fee_address; // if this is not address(0), there is a valid referral
    }

    struct PresaleStatus {
        bool lp_generation_complete; // final flag required to end a presale and enable withdrawls
        bool force_failed; // set this flag to force fail the presale
        uint256 raised_amount; // total base currency raised (usually ETH)
        uint256 sold_amount; // total presale tokens sold
        uint256 token_withdraw; // total tokens withdrawn post successful presale
        uint256 base_withdraw; // total base tokens withdrawn on presale failure
        uint256 num_buyers; // number of unique participants
    }

    struct BuyerInfo {
        uint256 base; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
        uint256 sale; // num presale tokens a user is owed, can be withdrawn on presale success
    }

    struct TokenInfo {
        string name;
        string symbol;
        uint256 totalsupply;
        uint256 decimal;
    }

    SharedStructs.PresaleInfo public presale_info;
    PresaleStatus public status;
    SharedStructs.PresaleLink public link;
    PresaleFeeInfo public presale_fee_info;
    TokenInfo public tokeninfo;

    address manage_addr;

    // IUniswapV2Factory public uniswapfactory;
    IWETH private WETH;
    PresaleSettings public presale_setting;
    PresaleLockForwarder public presale_lock_forwarder;

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
        presale_setting = PresaleSettings(setting);

        require(
            msg.value >= presale_setting.getLockFee(),
            "Balance is insufficent"
        );

        manage_addr = manage;

        // uniswapfactory = IUniswapV2Factory(uniswapfact);
        WETH = IWETH(wethfact);

        presale_lock_forwarder = PresaleLockForwarder(lockaddr);
    }

    function init_private(SharedStructs.PresaleInfo memory _presale_info)
        external
    {
        require(msg.sender == manage_addr, "Only manage address is available");

        presale_info = _presale_info;

        //Set token token info
        tokeninfo.name = IERC20Metadata(_presale_info.sale_token).name();
        tokeninfo.symbol = IERC20Metadata(_presale_info.sale_token).symbol();
        tokeninfo.decimal = IERC20Metadata(_presale_info.sale_token).decimals();
        tokeninfo.totalsupply = IERC20Metadata(_presale_info.sale_token)
            .totalSupply();
    }

    function init_link(SharedStructs.PresaleLink memory _link) external {
        require(msg.sender == manage_addr, "Only manage address is available");

        link = _link;
    }

    function init_fee() external {
        require(msg.sender == manage_addr, "Only manage address is available");

        presale_fee_info.raised_fee = presale_setting.getRasiedFee(); // divided by 100
        presale_fee_info.sold_fee = presale_setting.getSoldFee(); // divided by 100
        presale_fee_info.referral_fee = presale_setting.getRefferralFee(); // divided by 100
        presale_fee_info.raise_fee_address = presale_setting
            .getRaisedFeeAddress();
        presale_fee_info.sole_fee_address = presale_setting.getSoleFeeAddress();
        presale_fee_info.referral_fee_address = presale_setting
            .getReferralFeeAddress(); // if this is not address(0), there is a valid referral
    }

    modifier onlyPresaleOwner() {
        require(presale_info.presale_owner == msg.sender, "NOT PRESALE OWNER");
        _;
    }

    //   uint256 tempstatus;

    //   function setTempStatus(uint256 flag) public {
    //       tempstatus = flag;
    //   }

    function presaleStatus() public view returns (uint256) {
        // return tempstatus;
        if (status.force_failed) {
            return 3; // FAILED - force fail
        }
        if (
            (block.timestamp > presale_info.presale_end) &&
            (status.raised_amount < presale_info.softcap)
        ) {
            return 3;
        }
        if (status.raised_amount >= presale_info.hardcap) {
            return 2; // SUCCESS - hardcap met
        }
        if (
            (block.timestamp > presale_info.presale_end) &&
            (status.raised_amount >= presale_info.softcap)
        ) {
            return 2; // SUCCESS - preslae end and soft cap reached
        }
        if (
            (block.timestamp >= presale_info.presale_start) &&
            (block.timestamp <= presale_info.presale_end)
        ) {
            return 1; // ACTIVE - deposits enabled
        }
        return 0; // QUED - awaiting start block
    }

    // accepts msg.value for eth or _amount for ERC20 tokens
    function userDeposit() public payable nonReentrant {
        require(presaleStatus() == 1, "NOT ACTIVE"); //
        require(presale_info.raise_min <= msg.value, "balance is insufficent");
        require(presale_info.raise_max >= msg.value, "balance is too much");

        BuyerInfo storage buyer = buyers[msg.sender];

        uint256 amount_in = msg.value;
        uint256 allowance = presale_info.raise_max - buyer.base;
        uint256 remaining = presale_info.hardcap - status.raised_amount;
        allowance = allowance > remaining ? remaining : allowance;
        if (amount_in > allowance) {
            amount_in = allowance;
        }
        uint256 tokensSold = (amount_in * presale_info.token_rate) / (10**18);
        require(tokensSold > 0, "ZERO TOKENS");
        require(
            tokensSold <=
                IERC20(presale_info.sale_token).balanceOf(address(this)),
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

    // withdraw presale tokens
    // percentile withdrawls allows fee on transfer or rebasing tokens to still work
    function userWithdrawTokens() public nonReentrant {
        require(status.lp_generation_complete, "AWAITING LP GENERATION");
        BuyerInfo storage buyer = buyers[msg.sender];
        uint256 tokensRemainingDenominator = status.sold_amount -
            status.token_withdraw;
        uint256 tokensOwed = (IERC20(presale_info.sale_token).balanceOf(
            address(this)
        ) * buyer.sale) / tokensRemainingDenominator;
        require(tokensOwed > 0, "NOTHING TO WITHDRAW");
        status.token_withdraw = status.token_withdraw + buyer.sale;
        buyers[msg.sender].sale = 0;
        buyers[msg.sender].base = 0;
        TransferHelper.safeTransfer(
            address(presale_info.sale_token),
            msg.sender,
            tokensOwed
        );

        emit UserWithdrawTokensSuccess(tokensOwed);
    }

    // on presale failure
    // percentile withdrawls allows fee on transfer or rebasing tokens to still work
    function userWithdrawBaseTokens() public nonReentrant {
        require(presaleStatus() == 3, "NOT FAILED"); // FAILED

        if (msg.sender == presale_info.presale_owner) {
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
        // TransferHelper.safeTransferBaseToken(address(presale_info.base_token), msg.sender, tokensOwed, false);
    }

    // on presale failure
    // allows the owner to withdraw the tokens they sent for presale & initial liquidity
    function ownerWithdrawTokens() private onlyPresaleOwner {
        require(presaleStatus() == 3, "Only failed status"); // FAILED
        TransferHelper.safeTransfer(
            address(presale_info.sale_token),
            presale_info.presale_owner,
            IERC20(presale_info.sale_token).balanceOf(address(this))
        );

        emit UserWithdrawSuccess(
            IERC20(presale_info.sale_token).balanceOf(address(this))
        );
    }

    // Can be called at any stage before or during the presale to cancel it before it ends.
    // If the pair already exists on uniswap and it contains the presale token as liquidity
    // the final stage of the presale 'addLiquidity()' will fail. This function
    // allows anyone to end the presale prematurely to release funds in such a case.
    function forceFailIfPairExists() public {
        require(!status.lp_generation_complete && !status.force_failed);
        if (
            presale_lock_forwarder.uniswapPairIsInitialised(
                address(presale_info.sale_token),
                address(WETH)
            )
        ) {
            status.force_failed = true;
        }
    }

    // if something goes wrong in LP generation
    // function forceFail () external {
    //     require(msg.sender == OCTOFI_FEE_ADDRESS);
    //     status.force_failed = true;
    // }

    // on presale success, this is the final step to end the presale, lock liquidity and enable withdrawls of the sale token.
    // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic
    // are not taken into account at this stage to ensure stated liquidity is locked and the pool is initialised according to
    // the presale parameters and fixed prices.
    function addLiquidity() public nonReentrant onlyPresaleOwner {
        require(!status.lp_generation_complete, "GENERATION COMPLETE");
        require(presaleStatus() == 2, "NOT SUCCESS"); // SUCCESS
        // Fail the presale if the pair exists and contains presale token liquidity

        if (
            presale_lock_forwarder.uniswapPairIsInitialised(
                address(presale_info.sale_token),
                address(WETH)
            )
        ) {
            status.force_failed = true;
            emit AddLiquidtySuccess(0);
            return;
        }

        // require(!presale_lock_forwarder.uniswapPairIsInitialised(address(presale_info.sale_token), address(WETH)), "Liqudity exist");

        uint256 presale_raisedfee = (status.raised_amount *
            presale_setting.getRasiedFee()) / 100;

        // base token liquidity
        uint256 baseLiquidity = ((status.raised_amount - presale_raisedfee) *
            (presale_info.liqudity_percent)) / 100;

        // WETH.deposit{value : baseLiquidity}();

        // require(WETH.approve(address(presale_lock_forwarder), baseLiquidity), 'approve failed.');

        // TransferHelper.safeApprove(address(presale_info.base_token), address(presale_lock_forwarder), baseLiquidity);

        // sale token liquidity
        uint256 tokenLiquidity = (baseLiquidity * presale_info.listing_rate) /
            (10**18);
        require(tokenLiquidity > 0, "ZERO Tokens");
        TransferHelper.safeApprove(
            address(presale_info.sale_token),
            address(presale_lock_forwarder),
            tokenLiquidity
        );

        presale_lock_forwarder.lockLiquidity{
            value: presale_setting.getLockFee() + baseLiquidity
        }(
            address(presale_info.sale_token),
            baseLiquidity,
            tokenLiquidity,
            presale_info.lock_end,
            presale_info.presale_owner
        );

        uint256 presaleSoldFee = (status.sold_amount *
            presale_setting.getSoldFee()) / 100;

        address payable reciver = payable(
            address(presale_fee_info.raise_fee_address)
        );
        reciver.transfer(presale_raisedfee);

        // TransferHelper.safeTransferBaseToken(address(presale_info.base_token), presale_fee_info.raise_fee_address, presale_raisedfee, false);
        TransferHelper.safeTransfer(
            address(presale_info.sale_token),
            presale_fee_info.sole_fee_address,
            presaleSoldFee
        );

        // burn unsold tokens
        uint256 remainingSBalance = IERC20(presale_info.sale_token).balanceOf(
            address(this)
        );
        if (remainingSBalance > status.sold_amount) {
            uint256 burnAmount = remainingSBalance - status.sold_amount;
            TransferHelper.safeTransfer(
                address(presale_info.sale_token),
                0x000000000000000000000000000000000000dEaD,
                burnAmount
            );
        }

        // send remaining base tokens to presale owner
        uint256 remainingBaseBalance = address(this).balance;

        address payable presale_fee_reciver = payable(
            address(presale_info.presale_owner)
        );
        presale_fee_reciver.transfer(remainingBaseBalance);

        status.lp_generation_complete = true;
        emit AddLiquidtySuccess(1);
    }

    function destroy() public {
        require(status.lp_generation_complete, "lp generation incomplete");
        selfdestruct(presale_info.presale_owner);
    }

    //   function getTokenNmae() public view returns (string memory) {
    //       return presale_info.sale_token.name();
    //   }

    //   function getTokenSymbol() public view returns (string memory) {
    //       return presale_info.sale_token.symbol();
    //   }
}