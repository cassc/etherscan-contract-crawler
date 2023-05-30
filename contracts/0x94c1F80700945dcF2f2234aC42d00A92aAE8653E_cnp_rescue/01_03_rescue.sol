// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface nft_contract{
    function unsetBlockedTokens(uint256[] calldata tokenIds) external ;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract cnp_rescue is Ownable{

    constructor(){
        setNFTCollection(0x138A5C693279b6Cd82F48d4bEf563251Bc15ADcE);
        setToAddress(0x108Caed2b409b4A73C91e90a0Cf1Aa75c0c54949);
        setFromAddress(0x54BFbC2746A0dC4e4BE19959A72e2EE7676394fd);
    }

    nft_contract public nft;
    address public fromAddress;
    address public toAddress; 

    function rescue(uint256[] calldata tokenIds) public onlyOwner{
        nft.unsetBlockedTokens( tokenIds );
        for (uint256 i=0; i<tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            nft.safeTransferFrom(fromAddress, toAddress, tokenId);
        }
    }

    function setNFTCollection(address _address) public onlyOwner {
        nft = nft_contract(_address);
    }

    function setFromAddress(address _fromAddress) public onlyOwner {
        fromAddress = _fromAddress;
    }

    function setToAddress(address _toAddress) public onlyOwner {
        toAddress = _toAddress;
    }

}