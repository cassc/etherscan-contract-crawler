pragma solidity ^0.8.0;

import './ERC721Tradable.sol';

contract APONFT is ERC721Tradable{

    uint256 private idsLength;

    constructor() ERC721Tradable("HYEMCOIN", "HYE",0xa5409ec958C83C3f309868babACA7c86DCB077c1,"https://vcs-nftmarketplace.s3.us-east-2.amazonaws.com/item/") {
        idsLength = 100;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setIdsLength(uint256 newLength) public onlyOwner {
        idsLength = newLength;
    }

    function getIdsLength() public view returns (uint256) {
        return idsLength;
    }

    function mintBatch(address _to, uint256[] memory ids) public {
        require(ids.length <= idsLength,"NFT: token Ids length exceeding the limit");
        for (uint256 index = 0; index < ids.length; index++) {
            mint(_to, ids[index]);
        }
    }

    function transferBatch(address from, address to, uint256[] memory ids) public {
        require(ids.length <= idsLength,"NFT: token Ids length exceeding the limit");
        for (uint256 index = 0; index < ids.length; index++) {
            safeTransferFrom(from, to, ids[index]);
        }
    }
}