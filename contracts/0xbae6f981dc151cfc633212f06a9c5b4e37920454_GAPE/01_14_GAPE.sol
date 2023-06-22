// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract GAPE is ERC721, ERC721Enumerable, Ownable {

    ERC721 bloot = ERC721(0x4F8730E0b32B04beaa5757e5aea3aeF970E5B613);

    string private baseURI = "ipfs://QmTZSvn4tT2oNX1j62AkxPSFemCprVSzAwUpG7Wja1HMj3/";
    string private _contractURI = "ipfs://Qmd1ojL5RLCCKZd1E319SL9RxSnhpNnsdAcrUHv5MYNNWs";

    //calculate and concat the sha256 hash of every image, generate a sha256 of that string
    string public constant PROVANCE = "dede1208618be9b928d791c62334b2e0cea51d600e1cdc615d49194e229e5e3b";

    bool public frozenMetadata;

    event PermanentURI(string _baseURI, string _contractURI);

    constructor() ERC721("GAN APES", "GAPE") {
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseUri(string memory baseURI_) external onlyOwner {
        require(!frozenMetadata,"Metadata already frozen");
        baseURI = baseURI_;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        require(!frozenMetadata,"Metadata already frozen");
        _contractURI = contractURI_;
    }
    
    function freezeMetadata() external onlyOwner {
        frozenMetadata = true;
        emit PermanentURI(baseURI, _contractURI);
    }

    function claimForBlootOwner(uint256 tokenId) public {
        require(tokenId > 0 && tokenId < 8009, "Token ID invalid");
        require(bloot.ownerOf(tokenId) == msg.sender, "Not Bloot owner");
        _safeMint(_msgSender(), tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }    
}