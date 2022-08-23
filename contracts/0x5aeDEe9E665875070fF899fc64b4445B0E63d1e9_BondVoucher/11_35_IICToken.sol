// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IICToken {

    function mint(
        uint64 term, 
        uint256 amount,
        uint64[] calldata maturities, 
        uint32[] calldata percentages,
        string memory originalInvestor
    ) 
        external 
        returns (uint256 slot, uint256 tokenId);
    
    function vestingPool() external view returns (address);

    function underlying() external view returns (address);

}