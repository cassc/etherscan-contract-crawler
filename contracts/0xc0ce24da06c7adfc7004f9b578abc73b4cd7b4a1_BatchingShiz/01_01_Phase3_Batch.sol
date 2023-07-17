// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract BatchingShiz
{
    IChainContract private ChainContract = IChainContract(address(0xF647f29860335E064fAc9f1Fe28BC8C9fd5331b0));

    function toggleMadGoodies(uint256[] memory _tokens) public
    {
        for(uint256 i=0; i<_tokens.length; ++i)
        {
            ChainContract.toggleTokenGoodies(_tokens[i]);
        }
    }
}

interface IChainContract
{
    function toggleTokenGoodies(uint256 _tokenId) external;
}