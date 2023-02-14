// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interface/VBep20Interface.sol";

import "../../../libraries/HedgepieLibraryBsc.sol";
import "../../../interfaces/IHedgepieInvestorBsc.sol";
import "../../../interfaces/IHedgepieAdapterInfoBsc.sol";

interface IStrategy {
    function mint(uint256 amount) external;

    function redeem(uint256 amount) external;
}

contract VenusLendAdapterBsc is BaseAdapterBsc {
    /**
     * @notice Construct
     * @param _strategy  address of strategy
     * @param _stakingToken  address of staking token
     * @param _repayToken  address of repay token
     * @param _swapRouter  address of swap router
     * @param _wbnb  address of wbnb
     * @param _name  adatper name
     */
    constructor(
        address _strategy,
        address _stakingToken,
        address _repayToken,
        address _swapRouter,
        address _wbnb,
        string memory _name
    ) {
        require(
            VBep20Interface(_strategy).isVToken(),
            "Error: Invalid vToken address"
        );
        require(
            VBep20Interface(_strategy).underlying() != address(0),
            "Error: Invalid underlying address"
        );

        strategy = _strategy;
        stakingToken = _stakingToken;
        repayToken = _repayToken;
        swapRouter = _swapRouter;
        wbnb = _wbnb;
        name = _name;
    }

    /**
     * @notice Deposit with BNB
     * @param _tokenId YBNFT token id
     * @param _account user wallet address
     * @param _amountIn BNB amount
     */
    function deposit(
        uint256 _tokenId,
        uint256 _amountIn,
        address _account
    )
        external
        payable
        override
        onlyInvestor
        returns (
            uint256 amount,
            uint256 invested,
            uint256 userShares,
            uint256 userShares1
        )
    {
        require(msg.value == _amountIn, "Error: msg.value is not correct");
        AdapterInfo storage adapterInfo = adapterInfos[_tokenId];

        uint256 amountOut = HedgepieLibraryBsc.swapOnRouter(
            _amountIn,
            address(this),
            stakingToken,
            swapRouter,
            wbnb
        );

        uint256 repayAmt = IBEP20(repayToken).balanceOf(address(this));
        IBEP20(stakingToken).approve(strategy, amountOut);
        IStrategy(strategy).mint(amountOut);
        repayAmt = IBEP20(repayToken).balanceOf(address(this)) - repayAmt;

        adapterInfo.totalStaked += amountOut;
        amount = repayAmt;
        invested = _amountIn;

        // Update adapterInfo contract
        address adapterInfoBnbAddr = IHedgepieInvestorBsc(investor)
            .adapterInfo();
        IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateTVLInfo(
            _tokenId,
            _amountIn,
            true
        );
        IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateTradedInfo(
            _tokenId,
            _amountIn,
            true
        );
        IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateParticipantInfo(
            _tokenId,
            _account,
            true
        );
    }

    /**
     * @notice Withdraw the deposited Bnb
     * @param _tokenId YBNFT token id
     * @param _account user wallet address
     * @param _userInfo user adapter infor from TradeNFT
     */
    function withdraw(
        uint256 _tokenId,
        address _account,
        UserAdapterInfo memory _userInfo
    ) external payable override onlyInvestor returns (uint256 amountOut) {
        AdapterInfo storage adapterInfo = adapterInfos[_tokenId];

        uint256 repayAmt;

        amountOut = IBEP20(stakingToken).balanceOf(address(this));
        repayAmt = IBEP20(repayToken).balanceOf(address(this));

        IBEP20(repayToken).approve(strategy, _userInfo.amount);
        IStrategy(strategy).redeem(_userInfo.amount);

        repayAmt = repayAmt - IBEP20(repayToken).balanceOf(address(this));
        amountOut = IBEP20(stakingToken).balanceOf(address(this)) - amountOut;

        require(repayAmt == _userInfo.amount, "Error: Redeem failed");

        amountOut = HedgepieLibraryBsc.swapforBnb(
            amountOut,
            address(this),
            stakingToken,
            swapRouter,
            wbnb
        );

        (uint256 reward, ) = HedgepieLibraryBsc.getRewards(
            _tokenId,
            address(this),
            _userInfo
        );

        uint256 rewardBnb;
        if (reward != 0) {
            rewardBnb = HedgepieLibraryBsc.swapforBnb(
                reward,
                address(this),
                rewardToken,
                swapRouter,
                wbnb
            );
        }

        address adapterInfoBnbAddr = IHedgepieInvestorBsc(investor)
            .adapterInfo();

        if (rewardBnb != 0) {
            amountOut += rewardBnb;
            IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateProfitInfo(
                _tokenId,
                rewardBnb,
                true
            );
        }

        // Update adapterInfo contract
        IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateTVLInfo(
            _tokenId,
            _userInfo.invested,
            false
        );
        IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateTradedInfo(
            _tokenId,
            _userInfo.invested,
            true
        );
        IHedgepieAdapterInfoBsc(adapterInfoBnbAddr).updateParticipantInfo(
            _tokenId,
            _account,
            false
        );

        adapterInfo.totalStaked -= _userInfo.amount;

        if (amountOut != 0) {
            bool success;
            if (rewardBnb != 0) {
                rewardBnb =
                    (rewardBnb *
                        IYBNFT(IHedgepieInvestorBsc(investor).ybnft())
                            .performanceFee(_tokenId)) /
                    1e4;
                (success, ) = payable(IHedgepieInvestorBsc(investor).treasury())
                    .call{value: rewardBnb}("");
                require(success, "Failed to send bnb to Treasury");
            }

            (success, ) = payable(_account).call{value: amountOut - rewardBnb}(
                ""
            );
            require(success, "Failed to send bnb");
        }
    }

    receive() external payable {}
}