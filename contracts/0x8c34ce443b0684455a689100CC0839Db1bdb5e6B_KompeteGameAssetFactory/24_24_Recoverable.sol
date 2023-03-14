// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

abstract contract Recoverable {
    event ERC721TokenRecovered(address indexed to, address indexed token, uint256 tokenId);
    event ERC1155TokenRecovered(address indexed to, address indexed token, uint256 tokenId, uint256 amount);
    event ERC20TokenRecovered(address indexed to, address indexed token, uint256 amount);
    event EthRecovered(address indexed to, uint256 amount);

    /**
     * @dev Allows to recover ERC721 tokens sent to the contract by mistake
     */
    function _recoverERC721Token(
        address _to,
        address _token,
        uint256 _tokenId
    ) internal {
        IERC721(_token).transferFrom(address(this), _to, _tokenId);
        emit ERC721TokenRecovered(_to, _token, _tokenId);
    }

    /**
     * @dev Allows to recover ERC1155 tokens sent to the contract by mistake
     */
    function _recoverERC1155Token(
        address _to,
        address _token,
        uint256 _tokenId,
        uint256 _amount
    ) internal {
        IERC1155(_token).safeTransferFrom(address(this), _to, _tokenId, _amount, "");
        emit ERC1155TokenRecovered(_to, _token, _tokenId, _amount);
    }

    /**
     * @dev Allows to recover ERC20 tokens sent to the contract by mistake
     */
    function _recoverERC20Token(
        address _to,
        address _token,
        uint256 _amount
    ) internal {
        IERC20(_token).transferFrom(address(this), _to, _amount);
        emit ERC20TokenRecovered(_to, _token, _amount);
    }

    /**
     * @dev Allows to recover ETH sent to the contract by mistake
     */
    function _recoverEth(address payable _to, uint256 _amount) internal {
        _to.transfer(_amount);
        emit EthRecovered(_to, _amount);
    }
}