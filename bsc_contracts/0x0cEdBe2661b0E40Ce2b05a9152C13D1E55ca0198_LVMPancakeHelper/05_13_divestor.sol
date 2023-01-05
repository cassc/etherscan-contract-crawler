// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract Divestor is Ownable {
    using SafeERC20 for IERC20;
    event Divest(address token, address payee, uint256 value);

    function divest(
        address token_,
        address payee_,
        uint256 value_
    ) external onlyOwner {
        if (token_ == address(0)) {
            payable(payee_).transfer(value_);
            emit Divest(address(0), payee_, value_);
        } else {
            IERC20(token_).safeTransfer(payee_, value_);
            emit Divest(address(token_), payee_, value_);
        }
    }

    function setApprovalForAll(address token_, address _account)
        external
        onlyOwner
    {
        IERC721(token_).setApprovalForAll(_account, true);
    }

    function setApprovalForAll1155(address token_, address _account)
        external
        onlyOwner
    {
        IERC1155(token_).setApprovalForAll(_account, true);
    }
}