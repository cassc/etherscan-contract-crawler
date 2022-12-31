// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract TokenHelper is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function balanceListOf(
        address owner,
        address[] calldata tokenList
    ) external view returns (uint256[] memory balanceList) {
        balanceList = new uint256[](tokenList.length + 1);
        for (uint256 index = 0; index < tokenList.length; index++) {
            IERC20 erc20 = IERC20(tokenList[index]);
            uint256 balance = erc20.balanceOf(owner);
            balanceList[index] = balance;
        }
        balanceList[tokenList.length] = owner.balance;
    }

    function balanceListOfList(
        address[] calldata accountList,
        address[] calldata tokenList
    ) external view returns (uint256[][] memory balanceList) {
        uint256 length = accountList.length;
        balanceList = new uint256[][](length);
        for (uint256 index = 0; index < accountList.length; index++) {
            uint256[] memory data = this.balanceListOf(accountList[index], tokenList);
            balanceList[index] = data;
        }
    }

    function balanceListOfMulti(
        address[] calldata accountList,
        address[] calldata tokenList
    ) external view returns (uint256[] memory balanceList) {
        uint256 length = accountList.length * (tokenList.length + 1);
        balanceList = new uint256[](length);
        uint256 index = 0;
        for (uint256 a = 0; a < accountList.length; a++) {
            address account = accountList[a];
            for (uint256 i = 0; i < tokenList.length; i++) {
                IERC20 erc20 = IERC20(tokenList[i]);
                uint256 balance = erc20.balanceOf(account);
                balanceList[index] = balance;
                index++;
            }
            balanceList[index] = account.balance;
            index++;
        }
    }

    function tokenIdListOfOwner(
        address owner,
        address target
    ) external view returns (uint256[] memory tokenIdList) {
        IERC721Enumerable erc721 = IERC721Enumerable(target);
        uint256 balance = erc721.balanceOf(owner);
        tokenIdList = new uint256[](balance);
        for (uint256 index = 0; index < balance; index++) {
            tokenIdList[index] = erc721.tokenOfOwnerByIndex(owner, index);
        }
    }
}