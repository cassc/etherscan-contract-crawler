//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract AstroX is ERC721A, Ownable, PaymentSplitter, Pausable {
    using SafeMath for uint256;

    event PermanentURI(string _value, uint256 indexed _id);
    bool public presaleM = true;
    bool public publicM = true;

    uint public constant maxSupply = 10000;
    uint public constant _price = .32 ether;
    uint public constant _preprice = .065 ether;
    uint public constant MaxPerMint = 250;
    uint public constant AirDropSupply = 5000;

    string public _contractBaseURI;

    uint256[] private _teamShares = [100];
	address[] private _team = [0x7c51D1517CA849f6D736c697624223dbcE2cC85F];

    constructor(string memory baseURI) 
        ERC721A("AstroX", "AstroX")
        PaymentSplitter(_team, _teamShares)
    {
        _contractBaseURI = baseURI;
    }

    function togglePresale() public onlyOwner { presaleM = !presaleM; }
    function togglePublicSale() public onlyOwner { publicM = !publicM; }
    function pause() public onlyOwner { _pause();}
    function unpause() public onlyOwner { _unpause(); }

    function airdDrop(address to, uint256 quantity) external onlyOwner {
        require(quantity > 0, "Quantity cannot be zero");
        uint totalMinted = totalSupply();
        require(totalMinted.add(quantity) <= AirDropSupply, "No more promo NFTs left");
        _safeMint(to, quantity);
        lockMetadata(quantity);
    }

    function presaleMint(uint256 quantity) external payable whenNotPaused {
        require(presaleM, "PreSale is OFF");
        require(quantity > 0, "Quantity cannot be zero");
        uint totalMinted = totalSupply();
        require(quantity <= MaxPerMint, "Cannot mint that many at once");
        require(totalMinted.add(quantity) < maxSupply, "Not enough NFTs left to mint");
        require(_preprice * quantity <= msg.value, "Insufficient funds sent");
        _safeMint(msg.sender, quantity);
        lockMetadata(quantity);
    }

    function publicSaleMint(uint256 quantity) external payable whenNotPaused {
        require(quantity > 0, "Quantity cannot be zero");
        uint totalMinted = totalSupply();
        require(quantity <= MaxPerMint, "Cannot mint that many at once");
        require(totalMinted.add(quantity) < maxSupply, "Not enough NFTs left to mint");
        require(_price * quantity <= msg.value, "Insufficient funds sent");
        _safeMint(msg.sender, quantity);
        lockMetadata(quantity);
    }
    
    function lockMetadata(uint256 quantity) internal {
        for (uint256 i = quantity; i > 0; i--) {
            uint256 tid = totalSupply() - i;
            emit PermanentURI(tokenURI(tid), tid);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function contractURI() public pure returns (string memory) { return "https://astroxnft.io/assets/opensea/contract_metadata.json"; }

    function _baseURI() internal view override returns (string memory) { return _contractBaseURI; }
}