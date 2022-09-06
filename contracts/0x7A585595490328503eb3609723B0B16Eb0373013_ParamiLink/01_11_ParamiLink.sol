pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC721H.sol";

contract ParamiLink {

    function setHNFTLink(address contractAddress, uint256 tokenId, string calldata value) external {
        ERC721 erc721Contract = (ERC721)(contractAddress);
        require(erc721Contract.ownerOf(tokenId) == msg.sender, "not token owner");
        
        IERC721H hContract = (IERC721H)(contractAddress);
        hContract.authorizeSlotTo(tokenId, address(this));
        hContract.setSlotUri(tokenId, value);
    }
}