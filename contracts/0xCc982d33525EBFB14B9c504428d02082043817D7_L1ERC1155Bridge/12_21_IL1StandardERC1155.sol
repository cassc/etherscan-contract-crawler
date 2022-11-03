// SPDX-License-Identifier: MIT
pragma solidity >0.7.5;

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IL1StandardERC1155 is IERC165, IERC1155 {
    function l2Contract() external returns (address);

    function mint(address _to, uint256 _tokenId, uint256 _amount, bytes memory _data) external;

    function burn(address _from, uint256 _tokenId, uint256 _amount) external;

    function mintBatch(address _to, uint256[] memory _tokenIds, uint256[] memory _amounts, bytes memory _data) external;

    function burnBatch(address _from, uint256[] memory _tokenIds, uint256[] memory _amounts) external;

    event Mint(address indexed _account, uint256 _tokenId, uint256 _amount);
    event Burn(address indexed _from, uint256 _tokenId, uint256 _amount);

    event MintBatch(address indexed _account, uint256[] _tokenIds, uint256[] _amounts);
    event BurnBatch(address indexed _from, uint256[] _tokenIds, uint256[] _amounts);
}