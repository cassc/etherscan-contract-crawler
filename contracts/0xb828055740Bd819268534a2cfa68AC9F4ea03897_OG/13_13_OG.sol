// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.12;

//    ___     ____ 
//   / _ \   / ___|
//  | | | | | |  _ 
//  | |_| | | |_| |
//   \___/   \____|
    
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract OG is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;

    enum Step {
        Before,
        FreeMint,
        PublicSale,
        SoldOut,
        Reveal
    }

    //URI of the NFTs when revealed
    string public baseURI;
    //URI of the NFTs when not revealed
    string public notRevealedURI;
    //Are the NFTs revealed yet ?
    bool public revealed = false;

    Step public sellingStep;

    uint private constant MAX_SUPPLY = 2000;
    uint private constant MAX_FREEMINT = 990;
    uint private constant MAX_PUBLIC = 985;
    uint private constant MAX_GIFT = 25;

    uint public publicSalePrice = 0.0055 ether;

    uint public saleStartTime = 1672434006;

    mapping(address => uint) public amountNFTsperWallet;

    uint private constant MAX_PER_ADDRESS = 1;

    uint private teamLength;
        address [] private _team = [
            0x485f728a9fDaD1730857eA96fD5De692c3baAeD9,
            0xCfDA2c868e82778E288Ad5CDFEeF3171f23bD65c
        ];
        uint[] private _teamShares = [
            35,
            65
        ];

    constructor(string memory _notRevealedURI, string memory _baseURI) ERC721A("Original Gangster by 2F", "OG")
    PaymentSplitter(_team, _teamShares) {
        baseURI = _baseURI;
        notRevealedURI = _notRevealedURI;
        teamLength = _team.length;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function freeMint(address _account, uint _quantity) external callerIsUser {
        require(currentTime() >= saleStartTime, "Sale are not started yet");
        require(sellingStep == Step.FreeMint, "Mint is not activated yet");
        require(totalSupply() + _quantity <= MAX_FREEMINT, "Max supply exceeded");
        require(amountNFTsperWallet[msg.sender] + _quantity <= MAX_PER_ADDRESS, "You can only get 1 NFT inside your wallet");
        amountNFTsperWallet[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function publicSaleMint(address _account, uint _quantity) external payable callerIsUser {
        uint price = publicSalePrice;
        require(price != 0, "Price is 0");  
        require(currentTime() >= saleStartTime, "Sale are not started yet");
        require(sellingStep == Step.PublicSale, "Mint is not activated yet");
        require(totalSupply() + _quantity <= MAX_PUBLIC, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWallet[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function gift(address _to, uint _quantity) external onlyOwner {
        require(sellingStep > Step.PublicSale, "Gift is after the public sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max Supply");
        _safeMint(_to, _quantity);
    }

    function setSaleStartTime(uint _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function currentTime() internal view returns(uint) {
        return block.timestamp;
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