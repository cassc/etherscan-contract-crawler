// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./libraries/SafeBEP20.sol";
import "./interfaces/IYBNFT.sol";
import "./interfaces/IAdapterBsc.sol";
import "./interfaces/IHedgepieTradeNFT.sol";

contract HedgepieInvestorBsc is Ownable, ReentrancyGuard {
    using SafeBEP20 for IBEP20;

    // ybnft address
    address public ybnft;

    // trade nft address
    address public tradeNFT;

    // strategy manager
    address public adapterManager;

    // treasury address
    address public treasury;

    // adapter info
    address public adapterInfo;

    event DepositBNB(
        address indexed user,
        address nft,
        uint256 nftId,
        uint256 amount
    );
    event WithdrawBNB(
        address indexed user,
        address nft,
        uint256 nftId,
        uint256 amount
    );
    event Claimed(address indexed user, uint256 amount);
    event YieldWithdrawn(uint256 indexed nftId, uint256 amount);
    event AdapterManagerChanged(address indexed user, address adapterManager);
    event TreasuryChanged(address treasury);

    modifier onlyValidNFT(uint256 _tokenId) {
        require(
            IYBNFT(ybnft).exists(_tokenId),
            "Error: nft tokenId is invalid"
        );
        _;
    }

    /**
     * @notice Construct
     * @param _ybnft  address of YBNFT
     */
    constructor(
        address _ybnft,
        address _treasury,
        address _adapterInfo,
        address _tradeNFT
    ) {
        require(_ybnft != address(0), "Error: YBNFT address missing");
        require(_treasury != address(0), "Error: treasury address missing");
        require(
            _adapterInfo != address(0),
            "Error: adapterInfo address missing"
        );
        require(_tradeNFT != address(0), "Error: tradeNFT address missing");

        ybnft = _ybnft;
        treasury = _treasury;
        adapterInfo = _adapterInfo;
        tradeNFT = _tradeNFT;
    }

    /**
     * @notice Deposit with BNB
     * @param _tokenId  YBNft token id
     * @param _amount  BNB amount
     */
    /// #if_succeeds {:msg "Deposit failed"} old(address(msg.sender).balance) > address(msg.sender).balance + _amount;
    function depositBNB(uint256 _tokenId, uint256 _amount)
        external
        payable
        nonReentrant
        onlyValidNFT(_tokenId)
    {
        require(
            msg.value == _amount && _amount != 0,
            "Error: Insufficient BNB"
        );

        IYBNFT.Adapter[] memory adapterInfos = IYBNFT(ybnft).getAdapterInfo(
            _tokenId
        );

        uint256[] memory amounts = new uint256[](adapterInfos.length);
        uint256[] memory invested = new uint256[](adapterInfos.length);
        uint256[] memory userShares = new uint256[](adapterInfos.length);
        uint256[] memory userShares1 = new uint256[](adapterInfos.length);
        for (uint8 i; i < adapterInfos.length; i++) {
            IYBNFT.Adapter memory adapter = adapterInfos[i];

            uint256 amountIn = (_amount * adapter.allocation) / 1e4;
            (
                amounts[i],
                invested[i],
                userShares[i],
                userShares1[i]
            ) = IAdapterBsc(adapter.addr).depth() == 0
                ? IAdapterBsc(adapter.addr).deposit{value: amountIn}(
                    _tokenId,
                    amountIn,
                    msg.sender
                )
                : IAdapterBsc(adapter.addr).deposit{value: amountIn}(
                    _tokenId,
                    amountIn,
                    msg.sender,
                    IHedgepieTradeNFT(tradeNFT).getCurrentTokenId()
                );
        }

        IHedgepieTradeNFT(tradeNFT).mint(
            msg.sender,
            _tokenId,
            amounts,
            invested,
            userShares,
            userShares1
        );

        emit DepositBNB(msg.sender, ybnft, _tokenId, _amount);
    }

    /**
     * @notice Withdraw by BNB
     * @param _tokenId  YBNft token id
     * @param _tradeId  TradeNFT token id
     */
    /// #if_succeeds {:msg "Withdraw failed"} old(address(msg.sender).balance) < address(msg.sender).balance;
    function withdrawBNB(uint256 _tokenId, uint256 _tradeId)
        external
        nonReentrant
        onlyValidNFT(_tokenId)
    {
        require(
            IHedgepieTradeNFT(tradeNFT).ownerOf(_tradeId) == msg.sender,
            "Error: TradeNFT owner is invalid"
        );
        IHedgepieTradeNFT.UserAdapterInfo memory userInfos = IHedgepieTradeNFT(
            tradeNFT
        ).getNFTInfo(_tradeId);
        require(
            userInfos.ybnftId == _tokenId,
            "Error: YBNFT token id mismatch"
        );

        IYBNFT.Adapter[] memory adapterInfos = IYBNFT(ybnft).getAdapterInfo(
            _tokenId
        );

        uint256 amountOut;
        for (uint8 i; i < adapterInfos.length; i++) {
            amountOut += IAdapterBsc(adapterInfos[i].addr).depth() == 0
                ? IAdapterBsc(adapterInfos[i].addr).withdraw(
                    _tokenId,
                    msg.sender,
                    BaseAdapterBsc.UserAdapterInfo(
                        userInfos.amount[i],
                        userInfos.invested[i],
                        userInfos.userShares[i],
                        userInfos.userShares1[i]
                    )
                )
                : IAdapterBsc(adapterInfos[i].addr).withdraw(
                    _tokenId,
                    msg.sender,
                    BaseAdapterBsc.UserAdapterInfo(
                        userInfos.amount[i],
                        userInfos.invested[i],
                        userInfos.userShares[i],
                        userInfos.userShares1[i]
                    ),
                    _tradeId
                );
        }

        IHedgepieTradeNFT(tradeNFT).burn(_tradeId);

        emit WithdrawBNB(msg.sender, ybnft, _tokenId, amountOut);
    }

    /**
     * @notice Claim
     * @param _tokenId  YBNft token id
     * @param _tradeId  TradeNFT token id
     */
    /// #if_succeeds {:msg "Claim failed"} old(address(msg.sender).balance) <= address(msg.sender).balance;
    function claim(uint256 _tokenId, uint256 _tradeId)
        external
        nonReentrant
        onlyValidNFT(_tokenId)
    {
        IYBNFT.Adapter[] memory adapterInfos = IYBNFT(ybnft).getAdapterInfo(
            _tokenId
        );
        require(
            IHedgepieTradeNFT(tradeNFT).ownerOf(_tradeId) == msg.sender,
            "Error: TradeNFT owner is invalid"
        );

        IHedgepieTradeNFT.UserAdapterInfo memory userInfos = IHedgepieTradeNFT(
            tradeNFT
        ).getNFTInfo(_tradeId);
        require(
            userInfos.ybnftId == _tokenId,
            "Error: YBNFT token id mismatch"
        );

        uint256 amountOut;
        uint256[] memory userShares = new uint256[](adapterInfos.length);
        uint256[] memory userShares1 = new uint256[](adapterInfos.length);
        for (uint8 i; i < adapterInfos.length; i++) {
            uint256 rewardAmt;
            (rewardAmt, userShares[i], userShares1[i]) = IAdapterBsc(
                adapterInfos[i].addr
            ).claim(
                    _tokenId,
                    msg.sender,
                    BaseAdapterBsc.UserAdapterInfo(
                        userInfos.amount[i],
                        userInfos.invested[i],
                        userInfos.userShares[i],
                        userInfos.userShares1[i]
                    )
                );
            amountOut += rewardAmt;
        }

        IHedgepieTradeNFT(tradeNFT).updateShares(
            msg.sender,
            _tradeId,
            userShares,
            userShares1
        );

        emit Claimed(msg.sender, amountOut);
        emit YieldWithdrawn(_tokenId, amountOut);
    }

    /**
     * @notice pendingReward
     * @param _tokenId  YBNft token id
     * @param _tradeId  TradeNFT token id
     */
    function pendingReward(uint256 _tokenId, uint256 _tradeId)
        public
        view
        returns (uint256 amountOut)
    {
        if (!IYBNFT(ybnft).exists(_tokenId)) return 0;
        require(
            IHedgepieTradeNFT(tradeNFT).ownerOf(_tradeId) == msg.sender,
            "Error: TradeNFT owner is invalid"
        );

        IHedgepieTradeNFT.UserAdapterInfo memory userInfos = IHedgepieTradeNFT(
            tradeNFT
        ).getNFTInfo(_tradeId);
        require(
            userInfos.ybnftId == _tokenId,
            "Error: YBNFT token id mismatch"
        );

        IYBNFT.Adapter[] memory adapterInfos = IYBNFT(ybnft).getAdapterInfo(
            _tokenId
        );

        for (uint8 i; i < adapterInfos.length; i++) {
            amountOut += IAdapterBsc(adapterInfos[i].addr).pendingReward(
                _tokenId,
                BaseAdapterBsc.UserAdapterInfo(
                    userInfos.amount[i],
                    userInfos.invested[i],
                    userInfos.userShares[i],
                    userInfos.userShares1[i]
                )
            );
        }
    }

    /**
     * @notice Set strategy manager contract
     * @param _adapterManager  nft address
     */
    /// #if_succeeds {:msg "Set adapter failed"} adapterManager == _adapterManager;
    function setAdapterManager(address _adapterManager) external onlyOwner {
        require(_adapterManager != address(0), "Error: Invalid NFT address");

        adapterManager = _adapterManager;
        emit AdapterManagerChanged(msg.sender, _adapterManager);
    }

    /**
     * @notice Set treasury address
     * @param _treasury new treasury address
     */
    /// #if_succeeds {:msg "Set treasury failed"} treasury == _treasury;
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Error: Invalid NFT address");

        treasury = _treasury;
        emit TreasuryChanged(treasury);
    }

    receive() external payable {}
}