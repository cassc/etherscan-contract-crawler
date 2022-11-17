// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./erc721-operator-filter/ERC721AOperatorFilterUpgradeable.sol";
import "./OnlyDevMultiSigUpgradeable.sol";

contract Refund is
    ReentrancyGuardUpgradeable,
    OnlyDevMultiSigUpgradeable,
    ERC721AOperatorFilterUpgradeable
{
    error InsufficientContractBalance();
    error CallerNotUser();
    error CallerNotOwner();
    error SetRefundVaultToZeroAddress();
    error RefundNotEnabled();
    error RefundFailed();
    error OnlyMinterCanRefund();

    event Refunded(address from, address to, uint256 tokenId);
    event RefundConfigUpdated(RefundConfig config);

    struct RefundConfig {
        bool enabled;
        address vault;
    }

    RefundConfig public refundConfig;

    struct MintedToken {
        address minter;
        uint64 mintPrice;
    }

    mapping(uint256 => MintedToken) public _mintedToken;

    /**
     * @notice Caller is an externally owned account
     */
    modifier callerIsUser() {
        if (tx.origin != _msgSenderERC721A()) {
            revert CallerNotUser();
        }
        _;
    }

    // refund
    /**
     * @notice Allow owners to refund their tokens, only available in ethereum chain
     * @param tokenId token to be refunded
     */
    function refund(uint256 tokenId) external callerIsUser nonReentrant {
        address minter = _mintedToken[tokenId].minter;
        uint256 mintPrice = _mintedToken[tokenId].mintPrice;

        if (!isRefundEnabled()) {
            revert RefundNotEnabled();
        }

        if (_msgSenderERC721A() != minter) {
            revert OnlyMinterCanRefund();
        }

        if (address(this).balance < mintPrice) {
            revert InsufficientContractBalance();
        }

        address from = _msgSenderERC721A();
        address to = refundConfig.vault;

        if (ownerOf(tokenId) != from) {
            revert CallerNotOwner();
        }

        safeTransferFrom(from, to, tokenId);
        emit Refunded(from, to, tokenId);
        (bool success, ) = from.call{value: mintPrice}("");
        if (!success) {
            revert RefundFailed();
        }
    }

    /**
     * @notice Indicate if the refund process is enabled
     */
    function isRefundEnabled() public view returns (bool) {
        return refundConfig.enabled && refundConfig.vault != address(0);
    }

    /**
     * @notice Enable and configure refund process
     * @param config refund config
     */
    function setRefundConfig(RefundConfig calldata config) external onlyOwner {
        if (config.vault == address(0)) {
            revert SetRefundVaultToZeroAddress();
        }
        refundConfig = config;
        emit RefundConfigUpdated(config);
    }
}