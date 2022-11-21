// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC1155.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';


contract TokensHandler {

    function transferTokens(
        address from, 
        address to, 
        address[] memory nftAddresses, 
        uint[] memory nftIds,
        uint[] memory nftAmounts,
        uint32[] memory nftTypes
    ) public {
        uint length = nftAddresses.length;
        require(length == nftIds.length && nftTypes.length == length);
        for(uint i = 0; i < length; ++i) {
            if ( nftTypes[i] == 0 ) {
                IERC721(nftAddresses[i]).safeTransferFrom(from,to,nftIds[i]);
            } else {
                IERC1155(nftAddresses[i]).safeTransferFrom(from,to,nftIds[i],nftAmounts[i],'0x00');
            }
        }
    }

    function checkTokensApproval(
        address from,
        address currency
    ) public view returns(uint256) {
        return IERC20(currency).allowance(from,address(this));
    }

    function checkItemsApproval(
        address sender,
        address[] memory nftAddressArray, 
        uint256[] memory nftTokenIdArray,
        uint32[] memory nftTokenTypeArray
    ) public view {
        for(uint256 i = 0; i < nftAddressArray.length; ++i) 
            if ( nftTokenTypeArray[i] == 0 )
                require(IERC721(nftAddressArray[i]).getApproved(nftTokenIdArray[i]) == address(this));
            else 
                require(
                    IERC1155(nftAddressArray[i]).isApprovedForAll(sender,address(this))
                );
    }

}