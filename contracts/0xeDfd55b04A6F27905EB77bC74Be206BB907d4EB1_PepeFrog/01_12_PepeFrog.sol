// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


//https://twitter.com/Pepe_IA1

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract PepeFrog is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;  

    enum Step {
        Before,
        PublicSale,
        SoldOut
    } 

    Step public sellingStep;

    uint private constant MAX_SUPPLY = 158;
    uint private constant MAX_PUBLIC = 158;

    uint public publicSalePrice =  0.0044 ether;

    mapping(address => uint) amountNFTperWalletPublicSale;

    string public baseURI;

    uint private constant maxPerAddressDuringPublicMint =3;

    bool public isPaused;

    uint private teamLenght;

    address[] private _team = [
        0xc633f965fFAbAdF77799DCB6Cc892B9a0C2f7B5B
    ];
    
    uint[] private _teamShares = [
        1000
    ];

    //Constructor
    constructor(string memory _baseURI)
    ERC721A("PepeFrog", "PF")
    PaymentSplitter(_team, _teamShares) {
        teamLenght = _team.length;
         baseURI= _baseURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function publicMint(address _account, uint _quantity) external payable callerIsUser {
        require(!isPaused, "Contract is Paused");
        uint price = publicSalePrice;
        require(price != 0, "Price is 0");
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(amountNFTperWalletPublicSale[msg.sender] + _quantity <= maxPerAddressDuringPublicMint, "You can only get NFTs on the Public Sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds supply!");
        require(msg.value >= price * _quantity, "Invalid mint amount!");
        amountNFTperWalletPublicSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function setPublicSalePrice(uint _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

     function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    function releaseAll() external {
        for(uint i = 0 ; i < teamLenght ; i++) {
            release(payable(payee(i)));
        }
    }

    function tokenURI(uint _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
}