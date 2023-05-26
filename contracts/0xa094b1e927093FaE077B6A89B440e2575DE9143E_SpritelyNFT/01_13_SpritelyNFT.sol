// SPDX-License-Identifier: MIT

/**************************************************************************************
*                                                                                     *
*                                       @@    @@                                      *
*      @@@@@@    @@@@@@@@@  @@  @@@@          @@         @@@@@    @@      @@    @@    *
*    @@          @@@@@@@@@  @@@@      @@@@    @@@@@@@  @@     @@  @@      @@    @@    *
*      @@@@@@    @@     @@  @@          @@    @@       @@@@@@@@@  @@      @@    @@    *
*            @@  @@@@@@@@@  @@          @@    @@       @@         @@        @@@@      *
*    @@      @@  @@@@@@@@@  @@          @@    @@       @@         @@          @@      *
*      @@@@@@    @@         @@        @@@@@@    @@@@@    @@@@@@@    @@@@  @@@@        *
*                @@                                                                   *
*                                                                                     *
**************************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract SpritelyNFT is ERC721Enumerable, Ownable {
    bool public saleIsActive = false;
    bool public revealed = false;

    string public baseURI = "";
    string public previewURI = "ipfs://QmWr7eaVQUTkJvcPc2njiyKQ1VfNUicRRThxi3PPfDUGbP";

    uint256 public constant MAX_SUPPLY = 6000;
    uint256 public constant PRICE_PER_TOKEN = 0.03 ether;

    constructor() ERC721("SpritelyNFT", "SPRITE") {}

    // Internal

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Public

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if(!revealed) {
            return previewURI;
        }

        return super.tokenURI(tokenId);
    }

    function mint(uint numToMint) public payable {
        require(saleIsActive, "Sale is not active");

        uint256 ts = totalSupply();
        require(ts + numToMint <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numToMint <= msg.value, "Not enough Ether sent for mint");

        for (uint256 i = 1; i <= numToMint; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    // Only owner

    function setPreviewURI(string memory _newPreviewUri) external onlyOwner {
        previewURI = _newPreviewUri;
    }

    function setBaseURI(string memory _newBaseUri) external onlyOwner {
        baseURI = _newBaseUri;
    }

    function setSaleIsActive(bool _isActive) external onlyOwner {
        saleIsActive = _isActive;
    }

    function revealTokens() external onlyOwner {
        require(bytes(baseURI).length > 0, "baseURI must be set first");
        revealed = true;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}