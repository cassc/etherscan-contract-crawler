// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TokenTool {
    using SafeERC20 for IERC20;

    constructor() {}

    function multipleTransferErc20(
        address _erc20,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external {
        require(_recipients.length == _amounts.length, "Invalid length input");
        IERC20 erc20 = IERC20(_erc20);
        for (uint256 i = 0; i < _recipients.length; i++) {
            erc20.safeTransferFrom(
                address(msg.sender),
                _recipients[i],
                _amounts[i]
            );
        }
    }

    function multipleTransferErc721(
        address _erc721,
        address[] calldata _recipients,
        uint256[] calldata _tokenIds
    ) external {
        require(_recipients.length == _tokenIds.length, "Invalid length input");
        IERC721 erc721 = IERC721(_erc721);
        for (uint256 i = 0; i < _recipients.length; i++) {
            erc721.safeTransferFrom(
                address(msg.sender),
                _recipients[i],
                _tokenIds[i]
            );
        }
    }
}