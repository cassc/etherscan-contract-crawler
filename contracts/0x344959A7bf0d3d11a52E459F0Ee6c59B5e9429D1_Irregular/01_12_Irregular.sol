// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//@author Crawl Labs
//@title Irregular


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "./ERC721A.sol";

contract Irregular is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;

    enum Step {
        Before,
        WhitelistSale,
        PublicSale,
        SoldOut,
        Reveal
    }

    string public baseURI;
    Step public sellingStep;

    uint private constant MAX_SUPPLY = 14;


    uint public publicSalePrice = 1.5 ether;

    //Using MerkleRoot for the whitelist sale
    bytes32 public merkleRoot;

    //using timestamp
    uint public saleStartTime = 1658073600;

    //Limit the amount of NFT for a Public address
    mapping(address => uint) public amountNFTsperWalletPublicSale;

    //Team Profit Sharing
    uint private teamLength;

    constructor(address[] memory _team, uint[] memory _teamShares, bytes32 _merkleRoot, string memory _baseURI) ERC721A("Irregular", "IRGL")
    PaymentSplitter(_team, _teamShares) {
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
        teamLength = _team.length;
    }

    //Protect re-entrency attack
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }


    function publicSaleMint(address _account, uint _quantity) external payable callerIsUser {
        uint price = publicSalePrice;
        require(price != 0, "Price is 0");
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(amountNFTsperWalletPublicSale[msg.sender] + _quantity <= 1, "You can only get 1 NFT on the Public Sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletPublicSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }


    //Only Owner of the contract can use this 
    function gift(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max Supply");
        _safeMint(_to, _quantity);
    }

    function setSaleStartTime(uint _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setPublicSalePrice(uint _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }
    
    function currentTime() internal view returns(uint) {
        return block.timestamp;
    }


    //set the step of the sale (before, whitelist, etc..)
    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }


    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    //return the url of a token base on his Id
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    //Whitelist
    //Change or add other whitelist member
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    //ReleaseALL
    function releaseAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    receive() override external payable {
        revert('Only if you mint');
    }


}