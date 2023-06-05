// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract PsychoPunks is ERC721Enumerable, Ownable {
    using Strings for uint256;

	// baseURI
    string private baseURI;

    // Price
    uint256 private price = 0.03 ether;

    // Minting
    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public constant MAX_PURCHASE = 20;

    // Sale state
    bool public saleIsActive = false;

    // Giveaways
    uint256 private reserved = 40;

    // Withdraw address
    address withdrawAddress = 0x6907495b99FF6270B6de708c04f3DaCAedD40A40;

    // Events
    event Mint(uint256 indexed tokenId, string twitterUsername, address owner);
    event MintBatch(uint256 fromTokenId, uint256 amount, string twitterUsername, address owner);

    /*
     *  Constructor
     */
    constructor(string memory newBaseURI) ERC721("PsychoPunks", "PsychoPunks")  {    
        setBaseURI(newBaseURI);
    }

    /*
     *  Minting
     */
    function mint(uint256 _amount, string memory _twitterUsername) public payable {
        uint256 supply = totalSupply();

        require( saleIsActive, "Sale is not currently active" );
        require( _amount <= MAX_PURCHASE, "Can only mint 20 tokens at a time" );
        require( (supply + _amount) <= (MAX_SUPPLY - reserved), "Purchase would exceed maximum supply" );
        require( msg.value >= (price * _amount), "Value sent is not correct" );

        for (uint256 i; i < _amount; i++) {
            uint256 tokenId = (supply + i);
            _safeMint(msg.sender, tokenId);
            emit Mint(tokenId, _twitterUsername, msg.sender);
        }

        emit MintBatch(supply, _amount, _twitterUsername, msg.sender);
    }

    /*
     *  baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /*
     *  Price
     */
    function getPrice() public view returns (uint256) {
        return price;
    }

    function setPrice(uint256 _price) public onlyOwner() {
        price = _price;
    }

    /*
     *  Sale state
     */
    function pauseSale() public onlyOwner() {
        require(saleIsActive == true, "Sale is already paused");
        saleIsActive = false;
    }

    function startSale() public onlyOwner() {
        require(saleIsActive == false, "Sale has already started");
        saleIsActive = true;
    }

    /*
     *  Giveaways
     */
    function giveAway(address _to, uint256 _amount, string memory _twitterUsername) external onlyOwner() {
        require(_amount <= reserved, "Exceeds reserved token supply" );

        uint256 supply = totalSupply();
        for (uint256 i; i < _amount; i++) {
            uint256 tokenId = (supply + i);
            _safeMint(_to, tokenId);
            emit Mint(tokenId, _twitterUsername, msg.sender);
        }

        reserved -= _amount;
        emit MintBatch(supply, _amount, _twitterUsername, msg.sender);
    }

    /*
     *  Tokens at address
     */
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /*
     *  Withdraw
     */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(payable(withdrawAddress).send(balance));
    }

}