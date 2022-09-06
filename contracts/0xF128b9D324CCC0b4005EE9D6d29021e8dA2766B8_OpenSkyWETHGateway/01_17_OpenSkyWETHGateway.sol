// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../dependencies/weth/IWETH.sol';
import '../interfaces/IOpenSkyWETHGateway.sol';
import '../interfaces/IOpenSkySettings.sol';
import '../interfaces/IOpenSkyPool.sol';
import '../interfaces/IOpenSkyOToken.sol';
import '../libraries/helpers/Errors.sol';

contract OpenSkyWETHGateway is IOpenSkyWETHGateway, Ownable, ERC721Holder {
    using SafeERC20 for IERC20;

    IWETH public immutable WETH;
    IOpenSkySettings public immutable SETTINGS;

    /**
     * @dev Sets the WETH address and the OpenSkySettings address.
     * @param weth Address of the Wrapped Ether contract
     **/
    constructor(IWETH weth, IOpenSkySettings settings) {
        WETH = weth;
        SETTINGS = settings;
    }

    /**
     * @notice Infinite weth approves OpenSkyPool contract.
     * @dev Only callable by the owner
     **/
    function authorizeLendingPoolWETH() external override onlyOwner {
        address lendingPool = SETTINGS.poolAddress();
        require(WETH.approve(lendingPool, type(uint256).max),Errors.APPROVAL_FAILED);
        emit AuthorizeLendingPoolWETH(_msgSender());
    }

    /**
     * @notice Infinite NFT approves OpenSkyPool contract.
     * @dev Only callable by the owner
     * @param nftAssets addresses of nft assets
     **/
    function authorizeLendingPoolNFT(address[] calldata nftAssets) external override onlyOwner {
        address lendingPool = SETTINGS.poolAddress();
        for (uint256 i = 0; i < nftAssets.length; i++) {
            IERC721(nftAssets[i]).setApprovalForAll(lendingPool, true);
        }
        emit AuthorizeLendingPoolNFT(_msgSender(), nftAssets);
    }

    /**
     * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (aTokens)
     * is minted.
     * @param reserveId address of the targeted underlying lending pool
     * @param onBehalfOf address of the user who will receive the aTokens representing the deposit
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
     **/
    function deposit(
        uint256 reserveId,
        address onBehalfOf,
        uint16 referralCode
    ) external payable override {
        WETH.deposit{value: msg.value}();
        IOpenSkyPool(SETTINGS.poolAddress()).deposit(reserveId, msg.value, onBehalfOf, referralCode);

        emit Deposit(reserveId, onBehalfOf, msg.value);
    }

    /**
     * @dev withdraws the WETH _reserves of msg.sender.
     * @param reserveId address of the targeted underlying lending pool
     * @param amount amount of aWETH to withdraw and receive native ETH
     * @param onBehalfOf address of the user who will receive native ETH
     */
    function withdraw(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf
    ) external override {
        IOpenSkyPool lendingPool = IOpenSkyPool(SETTINGS.poolAddress());
        IERC20 oWETH = IERC20(lendingPool.getReserveData(reserveId).oTokenAddress);
        uint256 userBalance = oWETH.balanceOf(msg.sender);
        uint256 amountToWithdraw = amount;

        // if amount is equal to uint256 max, the user wants to redeem everything
        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        oWETH.safeTransferFrom(msg.sender, address(this), amountToWithdraw);
        lendingPool.withdraw(reserveId, amountToWithdraw, address(this));
        WETH.withdraw(amountToWithdraw);
        _safeTransferETH(onBehalfOf, amountToWithdraw);

        emit Withdraw(reserveId, onBehalfOf, amountToWithdraw);
    }

    /**
     * @dev Borrows ETH from reserve using an NFT as collateral and will receive a loan NFT as receipt.
     * @param reserveId The ID of the reserve
     * @param amount amount of ETH user will borrow
     * @param duration The desired duration of the loan
     * @param nftAddress The collateral NFT address
     * @param tokenId The ID of the NFT
     * @param onBehalfOf address of the user who will receive ETH and loan NFT.
     */
    function borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        address nftAddress,
        uint256 tokenId,
        address onBehalfOf
    ) external override {
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        IOpenSkyPool lendingPool = IOpenSkyPool(SETTINGS.poolAddress());
        uint256 loanId = lendingPool.borrow(reserveId, amount, duration, nftAddress, tokenId, onBehalfOf);
        WETH.withdraw(amount);
        _safeTransferETH(onBehalfOf, amount);

        emit Borrow(reserveId, onBehalfOf, loanId);
    }

    /**
     * @dev repays a borrow on the WETH reserve, for the specified amount (or for the whole amount, if uint256(-1) is specified).
     * @param loanId the id of reserve
     */
    function repay(uint256 loanId) external payable override {
        WETH.deposit{value: msg.value}();

        IOpenSkyPool lendingPool = IOpenSkyPool(SETTINGS.poolAddress());
        uint256 repayAmount = lendingPool.repay(loanId);

        require(msg.value >= repayAmount, Errors.REPAY_MSG_VALUE_ERROR);

        // refund remaining dust eth
        if (msg.value > repayAmount) {
            uint256 refundAmount = msg.value - repayAmount;
            WETH.withdraw(refundAmount);
            _safeTransferETH(msg.sender, refundAmount);
        }
        emit Repay(loanId);
    }

    function extend(
        uint256 loanId,
        uint256 amount,
        uint256 duration
    ) external payable {
        WETH.deposit{value: msg.value}();

        IOpenSkyPool lendingPool = IOpenSkyPool(SETTINGS.poolAddress());
        (uint256 inAmount, uint256 outAmount) = lendingPool.extend(loanId, amount, duration, _msgSender());

        require(msg.value >= inAmount, Errors.EXTEND_MSG_VALUE_ERROR);

        // refund eth
        uint256 refundAmount;
        if (msg.value > inAmount) {
            refundAmount += msg.value - inAmount;
        }
        if (outAmount > 0) {
            refundAmount += outAmount;
        }
        if (refundAmount > 0) {
            WETH.withdraw(refundAmount);
            _safeTransferETH(msg.sender, refundAmount);
        }

        emit Extend(loanId);
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, Errors.ETH_TRANSFER_FAILED);
    }

    /**
     * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
     * direct transfers to the contract address.
     * @param token token to transfer
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) external override onlyOwner {
        IERC20(token).safeTransfer(to, amount);
        emit EmergencyTokenTransfer(_msgSender(), token, to, amount);
    }

    /**
     * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
     * due selfdestructs or transfer ether to pre-computed contract address before deployment.
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyEtherTransfer(address to, uint256 amount) external override onlyOwner {
        _safeTransferETH(to, amount);
        emit EmergencyEtherTransfer(_msgSender(), to, amount);
    }

    /**
     * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
     */
    receive() external payable {
        require(msg.sender == address(WETH), Errors.RECEIVE_NOT_ALLOWED);
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert(Errors.FALLBACK_NOT_ALLOWED);
    }
}