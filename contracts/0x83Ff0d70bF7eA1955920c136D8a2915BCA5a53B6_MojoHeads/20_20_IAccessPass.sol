//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";


interface IAccessPass is IERC1155, IERC2981 {


    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address[] memory tos,
        uint256[] memory ids,
        uint256 amount,
        bytes memory data
    ) external;

}