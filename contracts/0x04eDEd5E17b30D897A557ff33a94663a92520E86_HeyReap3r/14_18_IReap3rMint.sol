pragma solidity ^0.8.0;

import "../ERC721A.sol";

interface IReap3rMint {
    /**
     * @dev Generate NFT by `num` with given `to`.
     */
    function mint(address to, uint256 num) external;
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);
}