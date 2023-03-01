// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IBasket } from "./Interfaces/IBasket.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IERC721ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import { ERC721Upgradeable, IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC1155ReceiverUpgradeable, IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
/**
 * Mint a single ERC721 which can hold NFTs
 */
contract Basket is IBasket, ERC721Upgradeable {

    using SafeERC20 for IERC20;

    constructor () {
        _disableInitializers();
    }

    function initialize(address _curator) external override initializer {
        __ERC721_init("NibblBasket", "NB");
        _mint(_curator, 0);
    }

    function supportsInterface(bytes4 interfaceId) public view override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return
            super.supportsInterface(interfaceId) || interfaceId == type(IBasket).interfaceId;
    }

    /// @notice withdraw an ERC721 token from this contract into your wallet
    /// @param _token the address of the NFT you are withdrawing
    /// @param _tokenId the ID of the NFT you are withdrawing
    function withdrawERC721(address _token, uint256 _tokenId, address _to) external override {
        require(_isApprovedOrOwner(msg.sender, 0), "withdraw:not allowed");
        IERC721(_token).safeTransferFrom(address(this), _to, _tokenId);
        emit WithdrawERC721(_token, _tokenId, _to);
    }

    function withdrawMultipleERC721(address[] calldata _tokens, uint256[] calldata _tokenId, address _to) external override {
        require(_isApprovedOrOwner(msg.sender, 0), "withdraw:not allowed");
        uint256 _length = _tokens.length;
        for (uint256 i; i < _length; ++i) {
            IERC721(_tokens[i]).safeTransferFrom(address(this), _to, _tokenId[i]);
            emit WithdrawERC721(_tokens[i], _tokenId[i], _to);
        }
    }
    
    /// @notice withdraw an ERC721 token from this contract into your wallet
    /// @param _token the address of the NFT you are withdrawing
    /// @param _tokenId the ID of the NFT you are withdrawing
    function withdrawERC721Unsafe(address _token, uint256 _tokenId, address _to) external override {
        require(_isApprovedOrOwner(msg.sender, 0), "withdraw:not allowed");
        IERC721(_token).transferFrom(address(this), _to, _tokenId);
        emit WithdrawERC721(_token, _tokenId, _to);
    }
    
    /// @notice withdraw an ERC721 token from this contract into your wallet
    /// @param _token the address of the NFT you are withdrawing
    /// @param _tokenId the ID of the NFT you are withdrawing
    function withdrawERC1155(address _token, uint256 _tokenId, address _to) external override {
        require(_isApprovedOrOwner(msg.sender, 0), "withdraw:not allowed");
        uint256 _balance = IERC1155(_token).balanceOf(address(this),  _tokenId);
        IERC1155(_token).safeTransferFrom(address(this), _to, _tokenId, _balance, "");
        emit WithdrawERC1155(_token, _tokenId, _balance, _to);
    }

    function withdrawMultipleERC1155(address[] calldata _tokens, uint256[] calldata _tokenIds, address _to) external override {
        require(_isApprovedOrOwner(msg.sender, 0), "withdraw:not allowed");
        uint256 _length = _tokens.length;
        for (uint256 i; i < _length; ++i) {
            uint256 _balance = IERC1155(_tokens[i]).balanceOf(address(this),  _tokenIds[i]);
            IERC1155(_tokens[i]).safeTransferFrom(address(this), _to, _tokenIds[i], _balance, "");
            emit WithdrawERC1155(_tokens[i], _tokenIds[i], _balance, _to);
        }
    }

    /// @notice withdraw ETH in the case a held NFT earned ETH (ie. euler beats)
    function withdrawETH(address payable _to) external override {
        require(_isApprovedOrOwner(msg.sender, 0), "withdraw:not allowed");
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
        emit WithdrawETH(_to);
    }

    /// @notice withdraw ERC20 in the case a held NFT earned ERC20
    function withdrawERC20(address _token, address _to) external override {
        require(_isApprovedOrOwner(msg.sender, 0), "withdraw:not allowed");
        IERC20(_token).safeTransfer(_to, IERC20(_token).balanceOf(address(this)));
        emit WithdrawERC20(_token, msg.sender);
    }

    function withdrawMultipleERC20(address[] calldata _tokens, address _to) external override {
        require(_isApprovedOrOwner(msg.sender, 0), "withdraw:not allowed");
        uint256 _length = _tokens.length;
        for (uint256 i; i < _length; ++i) {
            IERC20(_tokens[i]).safeTransfer(_to, IERC20(_tokens[i]).balanceOf(address(this)));
            emit WithdrawERC20(_tokens[i], msg.sender);
        }
    }

    function onERC721Received(address, address from, uint256 id, bytes memory) public override returns(bytes4) {
        emit DepositERC721(msg.sender, id, from);
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address from, uint256 id, uint256 amount, bytes memory) external virtual override returns (bytes4) {
        emit DepositERC1155(msg.sender, id, amount, from);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address from, uint256[] calldata ids, uint256[] calldata amounts, bytes memory) external virtual override returns (bytes4) {
        emit DepositERC1155Bulk(msg.sender, ids, amounts, from);
        return this.onERC1155BatchReceived.selector;
    }
    
    receive() external payable {}
}