// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract PixelWooks is ERC721, Pausable, Ownable {
    
    using Strings for uint256;
    string public baseURI;

    uint16 public constant MAX_WOOKS = 5_000;
    uint16 public constant MAX_ALLSTAR = 113;
    uint8 public maxMintPerAddress = 10;
    uint16 public currentTokenId;

    bool public saleIsActive = false;
    bool public revealed = false;

    event Minted(uint256 indexed _id);
    event CelebMinted(uint256 indexed _id);

    constructor(
        string memory _baseURI
    ) ERC721("Pixelwooks", "pixelwook") {
        baseURI = _baseURI;
    }

    function mintWook(uint numberOfTokens) public payable whenNotPaused {
        if (!saleIsActive) {
            revert("NotActive");
        }
        if (numberOfTokens + currentTokenId > MAX_WOOKS) {
            revert("MaxSupply");
        }
        if (numberOfTokens + balanceOf[msg.sender] > maxMintPerAddress) {
            revert("MaxMint");
        }
        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, currentTokenId);
            emit Minted(currentTokenId);
            ++currentTokenId;
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function reveal(string memory _newBaseURI) public onlyOwner{
        revealed = true;
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (ownerOf[tokenId] == address(0)) {
            revert("NonExistentTokenURI");
        }
        if (!revealed) {
            return baseURI;
        }
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function withdraw(address payable payee) public onlyOwner {
        uint balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert("WithdrawTransfer");
        }
    }

    /**
    * Set some Wooks aside
    */
    function reserveWooks() public onlyOwner {
        // mint standard wooks
        for (uint8 i = 0; i < 100; i++) {
            _safeMint(msg.sender, currentTokenId);
            emit Minted(currentTokenId);
            ++currentTokenId;
        }
        
        // mint allstar wooks
        for (uint16 i=MAX_WOOKS; i < MAX_WOOKS + MAX_ALLSTAR; i++) {
            _safeMint(msg.sender, i);
            emit CelebMinted(i);
        }
    }
}