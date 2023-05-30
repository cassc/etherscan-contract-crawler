// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Counters.sol";

contract STONEYs is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

	// baseURI
    string private baseURI;

    // Price
    uint256 private price = 0.042 ether;

    // Current supply
    Counters.Counter public _nextTokenId;

    // Minting
    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public constant MAX_PURCHASE = 10;

    // Sale state
    bool public saleIsActive = false;

    // Withdraw addresses
    address WITHDRAW_ADDRESS_1 = 0x6907495b99FF6270B6de708c04f3DaCAedD40A40;
    address WITHDRAW_ADDRESS_2 = 0x3049112397E7B9948f4Ba6618601B7298319eF5f;

    // Events
    event Mint(uint256 indexed fromTokenId, uint256 amount, address owner);

    /*
     *  Constructor
     */
    constructor(string memory newBaseURI) ERC721("STONEYs", "STONEYs")  {
        _nextTokenId.increment();
        setBaseURI(newBaseURI);
    }

    /*
     *  Minting
     */
    function mint(uint256 _amount) public payable {
        uint256 supply = totalSupply();

        require( saleIsActive, "Sale is not currently active" );
        require( _amount <= MAX_PURCHASE, "Can only mint 10 tokens at a time" );
        require( (supply + _amount) <= MAX_SUPPLY, "Purchase would exceed maximum supply" );
        require( msg.value >= (price * _amount), "Value sent is not correct" );

        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, _nextTokenId.current() - 1);
            _nextTokenId.increment();
        }

        emit Mint(supply, _amount, msg.sender);
    }

    /*
     *  Current Supply
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
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
     *  Withdraw
     */
    function withdraw() public onlyOwner {
        uint256 _each = address(this).balance / 2;
        require(payable(WITHDRAW_ADDRESS_1).send(_each));
        require(payable(WITHDRAW_ADDRESS_2).send(_each));
    }

}