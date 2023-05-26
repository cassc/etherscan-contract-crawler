// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//@author Johnleouf21

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract Electricblockchain is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;

    enum Step {
        Before,
        PublicSale,
        SoldOut,
        Reveal
    }

    string public baseURI;
    string public notRevealedURI;
    string public baseExtension = ".json";

    Step public sellingStep;

    uint private constant MAX_SUPPLY = 777;
    uint private constant MAX_GIFT = 77;
    uint public max_mint = 10;

    bool public revealed = false;
    bool public paused = false;

    uint public priceSale = 0.06 ether;


    mapping(address => uint) public amountNFTsperWallet;

    uint private teamLength;

    address[] private _team = [        
        0x0F3F8d97e620e41Ed3102EC820eb29398CEd933A
    ];

    uint[] private _teamShares = [
        100
    ];

    constructor(string memory _notRevealedURI, string memory _baseURI) ERC721A("Electricblockchain", "LIGHT") PaymentSplitter(_team, _teamShares) {
        baseURI = _baseURI;
        notRevealedURI = _notRevealedURI;
        teamLength = _team.length;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function saleMint(address _account, uint _quantity) external payable callerIsUser {
        uint price = priceSale;
        require(price != 0, "Price is 0");
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(totalSupply() + _quantity <= MAX_SUPPLY - MAX_GIFT, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        require(amountNFTsperWallet[_account] + _quantity <= max_mint, "You can only get 4 NFT on the Sale");
        if(totalSupply() + _quantity == MAX_SUPPLY) {
            sellingStep = Step.SoldOut;   
        }
        _safeMint(_account, _quantity);
    }

    function gift(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_GIFT, "Reached max Supply");
        _safeMint(_to, _quantity);
    }

    function setnotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }


    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function reveal() external onlyOwner{
        revealed = true;
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if(revealed == false) {
            return notRevealedURI;
        }

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function changeMaxMintAllowed(uint _maxmint) external onlyOwner {
        max_mint = _maxmint;
    }

    function changePriceSale(uint _priceSale) external onlyOwner {
        priceSale = _priceSale;
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