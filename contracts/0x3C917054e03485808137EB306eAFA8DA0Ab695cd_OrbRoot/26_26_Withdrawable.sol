// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Withdrawable is Context, AccessControlEnumerable {
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    function withdraw(address to) public {
        require(hasRole(WITHDRAWER_ROLE, _msgSender()), "[Withdraw] must have withdrawer role to withdraw");
        payable(to).transfer(address(this).balance);
    }

    function withdraw(address erc20, address to) public {
        require(hasRole(WITHDRAWER_ROLE, _msgSender()), "[Withdraw] must have withdrawer role to withdraw");
        IERC20(erc20).transfer(to, IERC20(erc20).balanceOf(address(this)));
    }

    function withdraw(
        address erc721,
        address to,
        uint256 id
    ) public virtual {
        require(hasRole(WITHDRAWER_ROLE, _msgSender()), "[Withdraw] must have withdrawer role to withdraw");
        IERC721(erc721).transferFrom(address(this), to, id);
    }

    function withdraw(
        address erc721,
        address to,
        uint256[] memory ids
    ) public virtual {
        require(hasRole(WITHDRAWER_ROLE, _msgSender()), "[Withdraw] must have withdrawer role to withdraw");

        for (uint256 i = 0; i < ids.length; ++i) {
            IERC721(erc721).transferFrom(address(this), to, ids[i]);
        }
    }

    function withdraw(
        address erc1155,
        address to,
        uint256 id,
        uint256 amounts,
        bytes memory data
    ) public {
        require(hasRole(WITHDRAWER_ROLE, _msgSender()), "[Withdraw] must have withdrawer role to withdraw");
        IERC1155(erc1155).safeTransferFrom(address(this), to, id, amounts, data);
    }
}