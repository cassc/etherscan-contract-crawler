// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface CNPMInterface {
    function _tokenData(uint256) external view returns (uint128 recordState, uint128 sideChangeTime);
    function tokensOfOwner(address) external view returns (uint256[] memory);
}

contract CNPMusicTokensUtility
{
    /**
     * Variables
     */
    address public cnpmAddress = 0xF0aFf3F05c0d060da10674FE58DfE769F673690B;

    CNPMInterface public cnpmContract = CNPMInterface(cnpmAddress);


    /**
     * Error functions
     */
    error ZeroAddress();


    /**
     * Constructor
     */
    constructor() {

    }


    /**
     * Functions
     */
    function tokensOfOwnerByRecordStatus(uint128 recordStatus, address owner)
        external
        view
        returns (uint256[] memory)
    {
        if(cnpmAddress == address(0)) revert ZeroAddress();
        
        uint256[] memory tokens = cnpmContract.tokensOfOwner(owner);
        uint256 idx_size;
        uint256 idx;

        for(uint256 i=0; i<tokens.length; i++) {
            uint128 tmpStatus;
            (tmpStatus,) = cnpmContract._tokenData(tokens[i]);
            if(tmpStatus == recordStatus) {
                idx_size++;
            }
        }

        uint256[] memory tokensByRecordStatus = new uint[](idx_size);

        for(uint256 i=0; i<tokens.length; i++) {
            uint128 tmpStatus;
            (tmpStatus,) = cnpmContract._tokenData(tokens[i]);
            if(tmpStatus == recordStatus) {
                tokensByRecordStatus[idx] = (tokens[i]);
                idx++;
            }
        }

        return tokensByRecordStatus;
    }
}