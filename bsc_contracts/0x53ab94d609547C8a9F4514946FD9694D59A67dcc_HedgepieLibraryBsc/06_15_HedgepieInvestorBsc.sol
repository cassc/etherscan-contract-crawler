// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./libraries/SafeBEP20.sol";
import "./interfaces/IYBNFT.sol";
import "./interfaces/IAdapterBsc.sol";

contract HedgepieInvestorBsc is Ownable, ReentrancyGuard {
    using SafeBEP20 for IBEP20;

    // ybnft address
    address public ybnft;

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
        address _adapterInfo
    ) {
        require(_ybnft != address(0), "Error: YBNFT address missing");
        require(_treasury != address(0), "Error: treasury address missing");
        require(
            _adapterInfo != address(0),
            "Error: adapterInfo address missing"
        );

        ybnft = _ybnft;
        treasury = _treasury;
        adapterInfo = _adapterInfo;
    }

    /**
     * @notice Deposit with BNB
     * @param _tokenId  YBNft token id
     * @param _amount  BNB amount
     */
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

        for (uint8 i; i < adapterInfos.length; i++) {
            IYBNFT.Adapter memory adapter = adapterInfos[i];

            uint256 amountIn = (_amount * adapter.allocation) / 1e4;
            IAdapterBsc(adapter.addr).deposit{value: amountIn}(
                _tokenId,
                msg.sender
            );
        }

        emit DepositBNB(msg.sender, ybnft, _tokenId, _amount);
    }

    /**
     * @notice Withdraw by BNB
     * @param _tokenId  YBNft token id
     */
    function withdrawBNB(uint256 _tokenId)
        external
        nonReentrant
        onlyValidNFT(_tokenId)
    {
        IYBNFT.Adapter[] memory adapterInfos = IYBNFT(ybnft).getAdapterInfo(
            _tokenId
        );

        uint256 amountOut;
        for (uint8 i; i < adapterInfos.length; i++) {
            amountOut += IAdapterBsc(adapterInfos[i].addr).withdraw(
                _tokenId,
                msg.sender
            );
        }

        emit WithdrawBNB(msg.sender, ybnft, _tokenId, amountOut);
    }

    /**
     * @notice Claim
     * @param _tokenId  YBNft token id
     */
    function claim(uint256 _tokenId)
        external
        nonReentrant
        onlyValidNFT(_tokenId)
    {
        IYBNFT.Adapter[] memory adapterInfos = IYBNFT(ybnft).getAdapterInfo(
            _tokenId
        );

        uint256 amountOut;
        for (uint8 i; i < adapterInfos.length; i++) {
            amountOut += IAdapterBsc(adapterInfos[i].addr).claim(
                _tokenId,
                msg.sender
            );
        }

        emit Claimed(msg.sender, amountOut);
        emit YieldWithdrawn(_tokenId, amountOut);
    }

    /**
     * @notice pendingReward
     * @param _tokenId  YBNft token id
     * @param _account  user address
     */
    function pendingReward(uint256 _tokenId, address _account)
        public
        view
        returns (uint256 amountOut)
    {
        if (!IYBNFT(ybnft).exists(_tokenId)) return 0;

        IYBNFT.Adapter[] memory adapterInfos = IYBNFT(ybnft).getAdapterInfo(
            _tokenId
        );

        for (uint8 i; i < adapterInfos.length; i++) {
            amountOut += IAdapterBsc(adapterInfos[i].addr).pendingReward(
                _tokenId,
                _account
            );
        }
    }

    /**
     * @notice Set strategy manager contract
     * @param _adapterManager  nft address
     */
    function setAdapterManager(address _adapterManager) external onlyOwner {
        require(_adapterManager != address(0), "Error: Invalid NFT address");

        adapterManager = _adapterManager;
        emit AdapterManagerChanged(msg.sender, _adapterManager);
    }

    /**
     * @notice Set treasury address
     * @param _treasury new treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Error: Invalid NFT address");

        treasury = _treasury;
        emit TreasuryChanged(treasury);
    }

    receive() external payable {}
}