// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./SignatureVerifier.sol";

contract MooseERC721 is ERC721Enumerable, Ownable, SignatureVerifier {
    using SafeMath for uint256;
    using Address for address;

    string private baseURI;

    uint256 public maxSupply;
    uint256 public maxGenCount;
    uint256 public babyCount = 0;
    uint256 public price = 0;

    address public OGSigner;
    address public CapoSigner;

    mapping(address => uint256) public OGMintLedger;
    mapping(address => uint256) public CapoMintLedger;

    bool public OGSaleActive = false;
    bool public CapoSaleActive = false;
    bool public saleActive = false;

    mapping (address => uint256) public balanceGenesis;

    constructor(string memory name, string memory symbol, uint256 supply, uint256 genCount) ERC721(name, symbol) {
        maxSupply = supply;
        maxGenCount = genCount;
    }

    function claimMooselone() public onlyOwner {
        uint256 supply = totalSupply();
        require(supply == 0, "Can only be called once");

        _safeMint(msg.sender, 1);
    }

    function mintOG(string calldata addr, bytes calldata sig, uint256 numberOfMints) external payable {
        require(OGSaleActive,                                       "Sale has not started");
        uint256 supply = totalSupply();

        bool verification = verify(addr, sig, OGSigner);

        require(verification,                                       "You are not whitelisted");
        require(msg.sender == tx.origin,                            "Can't be a contract");
        require(OGMintLedger[msg.sender].add(numberOfMints) <= 2,   "Only 2 mints");
        require(supply.add(numberOfMints) <= maxGenCount,           "Purchase would exceed max supply of Genesis Moose");
        require(price.mul(numberOfMints) == msg.value,              "Ether value sent is not correct");

        OGMintLedger[msg.sender] += numberOfMints;

        for (uint256 i = 1; i <= numberOfMints; i++) {
            _safeMint(msg.sender,  supply + i);
            balanceGenesis[msg.sender]++;
        }
    }

    function mintCapo(string calldata addr, bytes calldata sig, uint256 numberOfMints) external payable {
        require(CapoSaleActive,                                     "Sale has not started");
        uint256 supply = totalSupply();

        bool verification = verify(addr, sig, CapoSigner);

        require(verification,                                       "You are not whitelisted");
        require(msg.sender == tx.origin,                            "Can't be a contract");
        require(CapoMintLedger[msg.sender].add(numberOfMints) <= 1, "Only 1 mint");
        require(supply.add(numberOfMints) <= maxGenCount,           "Purchase would exceed max supply of Genesis Moose");
        require(price.mul(numberOfMints) == msg.value,              "Ether value sent is not correct");

        CapoMintLedger[msg.sender] += numberOfMints;

        for (uint256 i = 1; i <= numberOfMints; i++) {
            _safeMint(msg.sender,  supply + i);
            balanceGenesis[msg.sender]++;
        }
    }
    
   function mintPublic(uint256 numberOfMints) public payable {
        uint256 supply = totalSupply();
        require(saleActive,                                 "Sale must be active to mint");
        require(numberOfMints > 0 && numberOfMints <= 2,     "Invalid purchase amount");
        require(supply.add(numberOfMints) <= maxGenCount,   "Purchase would exceed max supply of Genesis Moose");
        require(price.mul(numberOfMints) == msg.value,      "Ether value sent is not correct");
        
        for(uint256 i = 1; i <= numberOfMints; i++) {
            _safeMint(msg.sender, supply + i);
            balanceGenesis[msg.sender]++;
        }
    }

    function walletOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function toggleSOGale() public onlyOwner {
        OGSaleActive = !OGSaleActive;
    }

    function toggleCapoSale() public onlyOwner {
        CapoSaleActive = !CapoSaleActive;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function setOGSigner(address signer) external onlyOwner {
        OGSigner = signer;
    }

    function setCapoSigner(address signer) external onlyOwner {
        CapoSigner = signer;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }
    
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}