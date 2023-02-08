/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.7.6 <0.9.0;

pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPipeline.sol";
import "./LibFunction.sol";


/**
 * @title LibFlashLoan
 * @author Brean
 **/

library LibFlashLoan {

    enum Type {
        basic,
        singlePaste,
        MultiPaste
    }
    
    // transfer flashed tokens
    function transferTokens(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        address to
    ) internal returns (bool success) {
        for(uint i; i < tokens.length; i++){
            tokens[i].transfer(to, amounts[i]);
        }
        return true;
    }

    // clipboardHelper helps create the clipboard data for an AdvancePipeCall
    /// 
    /// @param useEther Whether or not the call uses ether
    /// @param amount amount of ether to send
    /// @param _type What type the advanceCall is.
    /// @param returnDataIndex which previous advancedPipeCall 
    // to copy from, ordered by execution.
    /// @param copyIndex what index to copy the data from.
    // this will copy 32 bytes from the index.
    /// @param pasteIndex what index to paste the copyData
    // into calldata
    function clipboardHelper (
        bool useEther,
        uint256 amount,
        Type _type,
        uint256 returnDataIndex,
        uint256 copyIndex,
        uint256 pasteIndex
    ) internal pure returns (bytes memory stuff) {
        uint256 clipboardData;
        clipboardData = clipboardData | uint256(_type) << 248;
        
        clipboardData = clipboardData 
            | returnDataIndex << 160
            | (copyIndex * 32) + 32 << 80
            | (pasteIndex * 32) + 36;
        if (useEther) {
            // put 0x1 in second byte 
            // shift left 30 bytes
            clipboardData = clipboardData | 1 << 240;
            return abi.encodePacked(clipboardData, amount);
        } else {
            return abi.encodePacked(clipboardData);
        }
    }

    // TODO: test
    function advancedClipboardHelper(
        bool useEther,
        uint256 amount,
        Type _type,
        uint256[] calldata returnDataIndex,
        uint256[] calldata copyIndex,
        uint256[] calldata pasteIndex
    ) internal pure returns (bytes memory stuff) {
        uint256[] memory clipboardData;
        clipboardData[0] = clipboardData[0] | uint256(_type) << 248;
        if (useEther) {
            clipboardData[0] = clipboardData[0] | 1 << 240;
        }
        for(uint i = 2; i < returnDataIndex.length; ++i){
            clipboardData[i] = clipboardData[i] 
            | returnDataIndex[i-2] << 160
            | (copyIndex[i-2] * 32) + 32 << 80
            | (pasteIndex[i-2] * 32) + 36;
        }
        stuff = abi.encodePacked(clipboardData[0]);
        for(uint i = 1; i < clipboardData.length; i++){
            stuff = abi.encodePacked(stuff,clipboardData[i]);
        }
        stuff = abi.encodePacked(stuff,amount);
    }

}