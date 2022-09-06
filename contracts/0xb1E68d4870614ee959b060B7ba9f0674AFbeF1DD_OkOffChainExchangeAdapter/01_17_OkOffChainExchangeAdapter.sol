// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../tools/SecurityBaseFor8.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OkOffChainExchangeAdapter is
    SecurityBaseFor8,
    ReentrancyGuard,
    ERC1155Holder,
    ERC721Holder
{
    using SafeERC20 for IERC20;

    address public tokenTransferProxy;
    address public offChainExchangeAddress;
    address public transferManagerAddress;

    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

    constructor(
        address _tokenTransferProxy,
        address _offChainExchangeAddress,
        address _transferManagerAddress
    ) {
        tokenTransferProxy = _tokenTransferProxy;
        offChainExchangeAddress = _offChainExchangeAddress;
        transferManagerAddress = _transferManagerAddress;
    }

    /// @dev set tokenTransferProxy address
    ///
    /// @param _tokenTransferProxy new tokenTransferProxy address
    function setTokenTransferProxyAddress(address _tokenTransferProxy)
        external
        onlyOwner
    {
        tokenTransferProxy = _tokenTransferProxy;
    }

    /// @dev set offChainExchangeAddress address
    ///
    /// @param _offChainExchangeAddress new offChainExchangeAddress address
    function setupExchangeAddress(address _offChainExchangeAddress)
        external
        onlyOwner
    {
        offChainExchangeAddress = _offChainExchangeAddress;
    }

    /// @dev set transferManagerAddress address
    ///
    /// @param _transferManagerAddress new transferManagerAddress address
    function setupTransferManagerAddress(address _transferManagerAddress)
        external
        onlyOwner
    {
        transferManagerAddress = _transferManagerAddress;
    }

    function buyERC20(
        bytes calldata _calldata,
        address buyer,
        address tokenAddress,
        uint256 amount
    ) external nonReentrant{
        IERC20(tokenAddress).safeTransferFrom(buyer, address(this), amount);
        //approve tokenTransferProxy to transfer erc20
        IERC20(tokenAddress).safeApprove(tokenTransferProxy, amount);

        (bool success, ) = offChainExchangeAddress.call(_calldata);
        require(success, "Buy failed");
    }

    function acceptOfferERC20(
        bytes calldata _calldata,
        address seller,
        address buyer,
        address NFTAddress,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external nonReentrant{
        _transferNFT(seller, address(this), NFTAddress, amount, tokenId);
        _approveNFT(transferManagerAddress, NFTAddress, tokenId, true);

        (bool success, ) = offChainExchangeAddress.call(_calldata);
        require(success, "Accept offer failed");

        //value should give back to seller
        uint256 giveBackValue = IERC20(tokenAddress).balanceOf(address(this));
        if (giveBackValue > 0) {
            IERC20(tokenAddress).safeTransfer(seller, giveBackValue);
        }
    }

    function _transferNFT(
        address from,
        address to,
        address NFTAddress,
        uint256 amount,
        uint256 tokenId
    ) internal {
        if (IERC165(NFTAddress).supportsInterface(IID_IERC721)) {
            IERC721(NFTAddress).safeTransferFrom(from, to, tokenId);
        } else if (IERC165(NFTAddress).supportsInterface(IID_IERC1155)) {
            IERC1155(NFTAddress).safeTransferFrom(
                from,
                to,
                tokenId,
                amount,
                ""
            );
        } else {
            revert("Unsupported interface");
        }
    }

    function _approveNFT(
        address operator,
        address NFTAddress,
        uint256 tokenId,
        bool isApproved
    ) internal {
        if (IERC165(NFTAddress).supportsInterface(IID_IERC721)) {
            IERC721(NFTAddress).approve(operator, tokenId);
        } else if (IERC165(NFTAddress).supportsInterface(IID_IERC1155)) {
            IERC1155(NFTAddress).setApprovalForAll(operator, isApproved);
        } else {
            revert("Unsupported interface");
        }
    }

    function withdrawNFT(
        address to,
        address NFTAddress,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _transferNFT(address(this), to, NFTAddress, amount, tokenId);
    }
}