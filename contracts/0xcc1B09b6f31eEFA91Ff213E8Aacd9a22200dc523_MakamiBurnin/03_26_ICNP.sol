// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface ICNP is IERC721 {
    function minterMint(address _address, uint256 _amount) external;

    function burnerBurn(address _address, uint256[] calldata tokenIds) external;
}