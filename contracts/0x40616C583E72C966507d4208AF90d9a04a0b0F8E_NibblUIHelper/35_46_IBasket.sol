// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import { IERC721ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC1155ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";

interface IBasket is IERC721Upgradeable, IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable{

    event DepositERC721(address indexed token, uint256 tokenId, address indexed from);
    event WithdrawERC721(address indexed token, uint256 tokenId, address indexed to);
    event DepositERC1155(address indexed token, uint256 tokenId, uint256 amount, address indexed from);
    event DepositERC1155Bulk(address indexed token, uint256[] tokenId, uint256[] amount, address indexed from);
    event WithdrawERC1155(address indexed token, uint256 tokenId, uint256 amount, address indexed from);
    event WithdrawETH(address indexed who);
    event WithdrawERC20(address indexed token, address indexed who);

    function initialize(address _curator) external;
    function withdrawERC721(address _token, uint256 _tokenId, address _to) external;
    function withdrawMultipleERC721(address[] memory _tokens, uint256[] memory _tokenId, address _to) external;
    function withdrawERC721Unsafe(address _token, uint256 _tokenId, address _to) external;
    function withdrawERC1155(address _token, uint256 _tokenId, address _to) external;
    function withdrawMultipleERC1155(address[] memory _tokens, uint256[] memory _tokenIds, address _to) external;
    function withdrawETH(address payable _to) external;
    function withdrawERC20(address _token, address _to) external;
    function withdrawMultipleERC20(address[] memory _tokens, address _to) external;
    
}