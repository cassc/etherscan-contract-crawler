// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { TwoStepOwnable } from "./access/TwoStepOwnable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Retriever is TwoStepOwnable {
    function withdrawERC721(
        address _token,
        address _to,
        uint256 _id
    ) external onlyOwner {
        IERC721(_token).transferFrom(address(this), _to, _id);
    }

    function withdrawERC20(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

    function withdrawERC1155(
        address _token,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external onlyOwner {
        IERC1155(_token).safeTransferFrom(address(this), _to, _id, _amount, _data);
    }

    function withdrawETH() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{ value: address(this).balance }(new bytes(0));
        require(success, "eth withdrawal failed");
    }
}