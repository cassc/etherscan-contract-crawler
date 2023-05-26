// contracts/IFilterMapper.sol
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;


interface IFilterMapper {

    function mapFilter(address _contract) external view returns(address);
    
}