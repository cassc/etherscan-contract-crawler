// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../dependencies/cryptopunk/ICryptoPunk.sol';
import '../dependencies/cryptopunk/IWrappedPunk.sol';
import '../dependencies/weth/IWETH.sol';

import '../libraries/types/DataTypes.sol';
import '../interfaces/IOpenSkySettings.sol';
import '../interfaces/IOpenSkyPool.sol';
import '../interfaces/IOpenSkyLoan.sol';
import '../interfaces/IOpenSkyPunkGateway.sol';

contract OpenSkyPunkGateway is Context, ERC721Holder, IOpenSkyPunkGateway {
    using SafeERC20 for IERC20;

    IOpenSkySettings public immutable SETTINGS;
    ICryptoPunk public immutable PUNK;
    IWrappedPunk public immutable WPUNK;
    IWETH public immutable WETH;

    address public immutable WPUNK_PROXY_ADDRESS;

    constructor(
        address SETTINGS_,
        address PUNK_,
        address WPUNK_,
        address WETH_
    ) {
        SETTINGS = IOpenSkySettings(SETTINGS_);
        PUNK = ICryptoPunk(PUNK_);
        WPUNK = IWrappedPunk(WPUNK_);
        WETH = IWETH(WETH_);

        WPUNK.registerProxy();
        WPUNK_PROXY_ADDRESS = WPUNK.proxyInfo(address(this));

        IERC721(address(WPUNK)).setApprovalForAll(SETTINGS.poolAddress(), true);
    }

    function borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        uint256 punkIndex
    ) external override {
        address underlyingAsset = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(reserveId).underlyingAsset;

        uint256 loanId = _borrow(reserveId, amount, duration, punkIndex);
        IERC20(underlyingAsset).safeTransfer(_msgSender(), amount);

        emit Borrow(reserveId, _msgSender(), amount, duration, punkIndex, loanId);
    }

    function borrowETH(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        uint256 punkIndex
    ) external {
        address underlyingAsset = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(reserveId).underlyingAsset;
        require(underlyingAsset == address(WETH), 'BORROW_ETH_RESERVE_ASSET_NOT_MATCH');

        uint256 loanId = _borrow(reserveId, amount, duration, punkIndex);

        WETH.withdraw(amount);
        _safeTransferETH(_msgSender(), amount);

        emit BorrowETH(reserveId, _msgSender(), amount, duration, punkIndex, loanId);
    }

    /// @notice Only loan NFT owner can repay
    function repay(uint256 loanId) external override {
        IOpenSkyLoan loanNFT = IOpenSkyLoan(SETTINGS.loanAddress());
        DataTypes.LoanData memory loanData = loanNFT.getLoanData(loanId);
        address underlyingAsset = IOpenSkyPool(SETTINGS.poolAddress())
            .getReserveData(loanData.reserveId)
            .underlyingAsset;
        uint256 borrowBalance = loanNFT.getBorrowBalance(loanId);
        uint256 penalty = loanNFT.getPenalty(loanId);
        uint256 repayAmount = borrowBalance + penalty;

        IERC20(underlyingAsset).safeTransferFrom(_msgSender(), address(this), repayAmount);

        _repay(loanId, loanData, underlyingAsset, repayAmount);

        emit Repay(loanData.reserveId, _msgSender(), loanData.tokenId, loanId);
    }

    function repayETH(uint256 loanId) external payable {
        IOpenSkyLoan loanNFT = IOpenSkyLoan(SETTINGS.loanAddress());
        DataTypes.LoanData memory loanData = loanNFT.getLoanData(loanId);

        address underlyingAsset = IOpenSkyPool(SETTINGS.poolAddress())
            .getReserveData(loanData.reserveId)
            .underlyingAsset;
        require(underlyingAsset == address(WETH), 'REPAY_ETH_RESERVE_ASSET_NOT_MATCH');

        uint256 borrowBalance = loanNFT.getBorrowBalance(loanId);
        uint256 penalty = loanNFT.getPenalty(loanId);
        uint256 repayAmount = borrowBalance + penalty;

        require(msg.value >= repayAmount, 'REPAY_ETH_NOT_ENOUGH');

        // prepare weth
        WETH.deposit{value: repayAmount}();

        _repay(loanId, loanData, underlyingAsset, repayAmount);

        if (msg.value > repayAmount) {
            _safeTransferETH(_msgSender(), msg.value - repayAmount);
        }

        emit RepayETH(loanData.reserveId, _msgSender(), loanData.tokenId, loanId);
    }

    function _borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        uint256 punkIndex
    ) internal returns (uint256) {
        address owner = PUNK.punkIndexToAddress(punkIndex);
        require(owner == _msgSender(), 'BORROW_NOT_OWNER_OF_PUNK');

        // deposit punk
        PUNK.buyPunk(punkIndex);
        PUNK.transferPunk(WPUNK_PROXY_ADDRESS, punkIndex);
        WPUNK.mint(punkIndex);

        // borrow
        uint256 loanId = IOpenSkyPool(SETTINGS.poolAddress()).borrow(
            reserveId,
            amount,
            duration,
            address(WPUNK),
            punkIndex,
            _msgSender()
        );
        return loanId;
    }

    function _repay(
        uint256 loanId,
        DataTypes.LoanData memory loanData,
        address underlyingAsset,
        uint256 repayAmount
    ) internal {
        address owner = IERC721(SETTINGS.loanAddress()).ownerOf(loanId);

        // approve underlyingAsset
        IERC20(underlyingAsset).safeApprove(SETTINGS.poolAddress(), repayAmount);

        uint256 repaid = IOpenSkyPool(SETTINGS.poolAddress()).repay(loanId);
        require(repaid == repayAmount, 'REPAY_AMOUNT_NOT_MATCH');

        // withdrawPunk
        WPUNK.burn(loanData.tokenId);
        PUNK.transferPunk(owner, loanData.tokenId);
    }

    function _safeTransferETH(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'ETH_TRANSFER_FAILED');
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }
}