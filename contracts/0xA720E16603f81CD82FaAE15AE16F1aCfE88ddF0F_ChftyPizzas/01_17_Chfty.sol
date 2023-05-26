// SPDX-License-Identifier: MIT
// Author: CHFTY, developed by BlockStop

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ChftyPizzas is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
    using Strings for uint256;
    bool public saleIsActive = false;
    string public baseTokenURI;
    uint256 public maxMint = 25;
	uint256 private price = 0.07 ether;
    uint256 public constant MAX_SUPPLY = 2777;
    uint256 public presaleTime = 1648058400;
    uint256 public publicTime = 1648148400;

    mapping(address => uint256) private _allowList;

	//share settings
	address[] private addressList = [
	0x04dE4eCbcd3E86179bb1a0769e036a115F33EEEC,
	0xB9116B9129926EC3852c6f6Fa24f0371ec38Fd0f,
    0xE85bf2E09c89C4ae1914DAd5Bf4871c2cBe7262f,
    0xbFcFBDC87780c11a78e995ac2f30b115c9015F31,
    0x80BDBaEEbd351ced1e249E791EE272C83Adc1936,
    0x40d349e3da24019d01791e1B9a0F91F07151D7b4,
    0x34db6e12d588AB2dE211cD9Ef0A13491778449Da,
    0x043eC45A905544995c8DC27e8eB03DC2f3b1F1cB,
    0x706E6345d7661790f06FFD9E7D295FB7D75542fb
	];
	uint[] private shareList = [24, 8, 7, 21, 2, 21, 9, 5, 3];

	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI
	) ERC721A(_name, _symbol)
	PaymentSplitter( addressList, shareList ){
	setBaseURI(_initBaseURI);
	}

    // ensure caller is not another contract (fighting bots FTW)
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // public mint function
	function mint(uint256 _mintAmount) public payable callerIsUser {
        require(saleIsActive, "Public sale is not active");
        require(block.timestamp >= publicTime);
        require(numberMinted(msg.sender) + _mintAmount <= maxMint, "Too many, please mint less" );
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Purchase would exceed max token supply" );
        require(msg.value >= price * _mintAmount, "Ether value sent is not correct" );

        _safeMint(msg.sender, _mintAmount);
	}

    // presale mint function
    function mintPresale(uint256 _mintAmount) public payable callerIsUser {
        uint256 reserve = _allowList[msg.sender];
        require(!saleIsActive, "Public Sale is active, wrong function");
        require(block.timestamp >= presaleTime);
        require(reserve > 0, "not eligible for allowlist mint");
        require(_mintAmount <= reserve, "Try minting less");
        require(msg.value >= price * _mintAmount, "Ether value sent is not correct" );

        _allowList[msg.sender] = reserve - _mintAmount;
        delete reserve;
        _safeMint(msg.sender, _mintAmount);
	}

    //admin reserve minting
	function gift(uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
        require(quantity.length == recipient.length, "Provide quantities and recipients" );

        for(uint i = 0; i < recipient.length; ++i){
                _safeMint(recipient[i], quantity[i]);
        }
	}

    //set URI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
	    baseTokenURI = _newBaseURI;
	}

	// internal view URI
	function _baseURI() internal view virtual override returns (string memory) {
	    return baseTokenURI;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	    require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

    //set WL addresses
    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

	function setPrice(uint256 _newPrice) public onlyOwner {
	    price = _newPrice;
	}

    //on / off switch for public sale
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    //withdraw funds
	function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
	}
}