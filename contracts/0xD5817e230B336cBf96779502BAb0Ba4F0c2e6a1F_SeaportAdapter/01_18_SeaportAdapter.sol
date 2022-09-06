// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/ISeaportAdapter.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./interfaces/IConduitController.sol";

contract SeaportAdapter is
    Ownable,
    ReentrancyGuard,
    ERC1155Holder,
    ERC721Holder
{
    address public seaport;

    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;

    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

    address public conduitControllerAddress;

    bytes32 public OPENSEA_CONDUIT_KEY =
        0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;

    using SafeERC20 for IERC20;

    receive() external payable {
        // Reject unexpected address sending ether, only accecpt Seaport refunding.
        require(msg.sender == seaport, "Unexpected ether sender");
    }

    constructor(address _seaport) {
        seaport = _seaport;
    }

    /// @dev set seaport address
    ///
    /// @param _seaport new seaport address
    function setSeaportAddress(address _seaport) external onlyOwner {
        seaport = _seaport;
    }

    function setConduitController(address _conduitControllerAddress)
        external
        onlyOwner
    {
        conduitControllerAddress = _conduitControllerAddress;
    }

    function setConduitKey(bytes32 key) external onlyOwner {
        OPENSEA_CONDUIT_KEY = key;
    }

    /// @dev Buy NFT in seaport market place on behalf of user.
    ///
    /// @param _calldata abi encoded calldata to Seaport market place.
    /// @param recipient NFT's final receiver. NOTE: it also used as the refunding receiver instead of the msg.sender。
    ///                  We assume `recipient` is an EOA, otherwise the NFT may stuck in this contract.
    /// @param tokenAddress NFT contract address
    /// @param tokenId token id
    /// @param amount token amount, useful for ERC1155 token
    /// @param payToken address(0) is native,other address is erc20
    /// @param payAmount is price*amount
    function seaportBuy(
        bytes calldata _calldata,
        address recipient,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        address payToken,
        uint256 payAmount
    ) external payable nonReentrant {
        bool success;

        if (payToken != address(0)) {
            IERC20(payToken).safeTransferFrom(
                recipient,
                address(this),
                payAmount
            );

            (address conduit, bool hasConduit) = IConduitController(
                conduitControllerAddress
            ).getConduit(OPENSEA_CONDUIT_KEY);

            require(hasConduit, "conduit controller address error!");

            IERC20(payToken).safeApprove(conduit, payAmount);

            (success, ) = seaport.call(_calldata);
        } else {
            (success, ) = seaport.call{value: msg.value}(_calldata);
        }

        require(success, "Seaport buy failed");

        // NOTE: Caller must guarantee that the `recipient` is the expected NFT receiver.
        _tranferNFT(tokenAddress, address(this), recipient, tokenId, amount);

        if (payToken == address(0)) {
            // Refund to `recipient` when buy NFT failed or Seaport gives back remaining ether.
            // NOTE: Caller must guarantee that the `recipient` is the expected refunding receiver.
            uint256 refund = address(this).balance;
            if (refund > 0) {
                Address.sendValue(payable(recipient), refund);
            }
        }
    }

    /// @dev Accept offer on seaport market place on behalf of user.
    ///
    /// @param _calldata abi encoded calldata to Seaport market place.
    /// @param acceptToken ERC20 token received after accept offer.
    /// @param recipient Accept token receiver and NFT offerer.
    /// @param tokenAddress NFT contract address.
    /// @param tokenId token id.
    /// @param amount token amount, useful for ERC1155 token.
    function seaportAcceptOffer(
        bytes calldata _calldata,
        address acceptToken,
        address recipient,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external nonReentrant {
        // transfer recipient's NFT to this contract.
        _tranferNFT(tokenAddress, recipient, address(this), tokenId, amount);

        (address conduit, bool hasConduit) = IConduitController(
            conduitControllerAddress
        ).getConduit(OPENSEA_CONDUIT_KEY);
        require(hasConduit, "conduit controller address error!");

        // both ERC721 and ERC1155 share the same `setApprovalForAll` method.
        IERC721(tokenAddress).setApprovalForAll(conduit, true);

        // accept offer on seaport.
        (bool success, ) = seaport.call(_calldata);
        require(success, "Seaport accept offer failed");

        // transfer ERC20 to recipient.
        SafeERC20.safeTransfer(
            IERC20(acceptToken),
            recipient,
            IERC20(acceptToken).balanceOf(address(this))
        );

        // revoke approval.
        IERC721(tokenAddress).setApprovalForAll(conduit, false);
    }

    /// @dev In case we can withdraw unexpectedly stucked NFT.
    ///
    /// @param tokenAddress NFT contract address
    /// @param recipient token recipient
    /// @param tokenId token id
    /// @param amount token amount, useful for ERC1155 token
    function withdrawNFT(
        address tokenAddress,
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _tranferNFT(tokenAddress, address(this), recipient, tokenId, amount);
    }

    /// @dev Withdraw eth
    ///
    /// @param recipient ether recipient
    /// @param amount ether amount
    function withdrawETH(address recipient, uint256 amount) external onlyOwner {
        Address.sendValue(payable(recipient), amount);
    }

    /// @dev Withdraw erc20 token
    ///
    /// @param tokenAddress ERC20 token address
    /// @param recipient token recipient
    /// @param amount withraw amount
    function withdrawERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        SafeERC20.safeTransfer(IERC20(tokenAddress), recipient, amount);
    }

    function _tranferNFT(
        address tokenAddress,
        address from,
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (IERC165(tokenAddress).supportsInterface(IID_IERC721)) {
            IERC721(tokenAddress).safeTransferFrom(
                from,
                recipient,
                tokenId,
                ""
            );
        } else if (IERC165(tokenAddress).supportsInterface(IID_IERC1155)) {
            IERC1155(tokenAddress).safeTransferFrom(
                from,
                recipient,
                tokenId,
                amount,
                ""
            );
        } else {
            revert("Unsupported interface");
        }
    }
}