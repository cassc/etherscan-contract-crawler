// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./CommunityStakingPoolBase.sol";
import "./interfaces/ICommunityStakingPoolErc20.sol";

//import "hardhat/console.sol";

contract CommunityStakingPoolErc20 is CommunityStakingPoolBase, ICommunityStakingPoolErc20 {
    /**
     * @custom:shortd address of ERC20 token.
     * @notice address of ERC20 token. ie investor token - ITR
     */
    address public erc20Token;

    error Denied();
    ////////////////////////////////////////////////////////////////////////
    // external section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
     * @notice Special function receive ether
     */
    receive() external payable {
        revert Denied();
    }

    // left when will be implemented
    // function tokensToSend(
    //     address operator,
    //     address from,
    //     address to,
    //     uint256 amount,
    //     bytes calldata userData,
    //     bytes calldata operatorData
    // )   override
    //     virtual
    //     external
    // {
    // }

    /**
     * @notice initialize method. Called once by the factory at time of deployment
     * @param stakingProducedBy_ address of Community Coin token.
     * @param erc20Token_ address of ERC20 token.
     * @param donations_ array of tuples donations. address,uint256. if array empty when coins will obtain sender, overwise donation[i].account  will obtain proportionally by ration donation[i].amount
     * @param lpFraction_ fraction of LP token multiplied by `FRACTION`.
     * @param lpFractionBeneficiary_ beneficiary's address which obtain lpFraction of LP tokens. if address(0) then it would be owner()
     * @custom:shortd initialize method. Called once by the factory at time of deployment
     */
    function initialize(
        address stakingProducedBy_,
        address erc20Token_,
        IStructs.StructAddrUint256[] memory donations_,
        uint64 lpFraction_,
        address lpFractionBeneficiary_,
        uint64 rewardsRateFraction_
    ) external override initializer {
        CommunityStakingPoolBase_init(
            stakingProducedBy_,
            donations_,
            lpFraction_,
            lpFractionBeneficiary_,
            rewardsRateFraction_
        );

        erc20Token = erc20Token_;
    }

    ////////////////////////////////////////////////////////////////////////
    // public section //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
     * @notice way to redeem via approve/transferFrom. Another way is send directly to contract.
     * @param account account address will redeemed from
     * @param amount The number of shares that will be redeemed
     * @custom:calledby staking contract
     * @custom:shortd redeem erc20 tokens
     */
    function redeem(address account, uint256 amount)
        external
        //override
        onlyStaking
        returns (uint256 affectedLPAmount, uint64 rewardsRate)
    {
        affectedLPAmount = _redeem(account, amount);
        rewardsRate = rewardsRateFraction;
    }

    function stake(uint256 tokenAmount, address beneficiary) public nonReentrant {
        address account = _msgSender();
        IERC20Upgradeable(erc20Token).transferFrom(account, address(this), tokenAmount);
        _stake(beneficiary, tokenAmount, 0);
    }

    /**
     * @param tokenAddress token that will swap to `erc20Address` token
     * @param tokenAmount amount of `tokenAddress` token
     * @param beneficiary wallet which obtain LP tokens
     * @notice method will receive `tokenAmount` of token `tokenAddress` then will swap all to `erc20address` and finally stake it. Beneficiary will obtain shares
     * @custom:shortd  the way to receive `tokenAmount` of token `tokenAddress` then will swap all to `erc20address` and finally stake it. Beneficiary will obtain shares
     */
    function buyAndStake(
        address tokenAddress,
        uint256 tokenAmount,
        address beneficiary
    ) public nonReentrant {
        IERC20Upgradeable(tokenAddress).transferFrom(_msgSender(), address(this), tokenAmount);

        address pair = IUniswapV2Factory(uniswapRouterFactory).getPair(erc20Token, tokenAddress);
        require(pair != address(0), "NO_UNISWAP_V2_PAIR");
        //uniswapV2Pair = IUniswapV2Pair(pair);

        uint256 erc20TokenAmount = doSwapOnUniswap(tokenAddress, erc20Token, tokenAmount);
        require(erc20TokenAmount != 0, "insufficient on uniswap");
        _stake(beneficiary, erc20TokenAmount, 0);
    }

    ////////////////////////////////////////////////////////////////////////
    // internal section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    function _redeem(address account, uint256 amount) internal returns (uint256 affectedLPAmount) {
        affectedLPAmount = __redeem(account, amount);
        IERC20Upgradeable(erc20Token).transfer(account, affectedLPAmount);
    }

    ////////////////////////////////////////////////////////////////////////
    // private section /////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    function __redeem(address sender, uint256 amount) private returns (uint256 amount2Redeem) {
        emit Redeemed(sender, amount);

        // validate free amount to redeem was moved to method _beforeTokenTransfer
        // transfer and burn moved to upper level
        amount2Redeem = _fractionAmountSend(
            erc20Token,
            amount,
            lpFraction,
            lpFractionBeneficiary == address(0) ? stakingProducedBy : lpFractionBeneficiary,
            address(0)
        );
    }
}