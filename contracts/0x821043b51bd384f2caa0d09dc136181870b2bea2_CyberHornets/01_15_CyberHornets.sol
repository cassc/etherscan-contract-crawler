// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract CyberHornets is ERC721Enumerable, Ownable, PaymentSplitter {

    using Strings for uint256;

    uint256 private _price = 0.08 ether;

    string private extension = '.json';

    string public _baseTokenURI = '';
    
    string public HORNET_PROVENANCE = '';

    uint256 public MAX_TOKENS_PER_TRANSACTION = 8;

    uint256 public MAX_SUPPLY = 8888;

    uint256 public _startTime = 1633687200;
    uint256 public _presaleStartTime = 1633600800;

    string public LICENSE_TEXT = ""; // IT IS WHAT IT SAYS

    bool licenseLocked = false; // TEAM CAN'T EDIT THE LICENSE AFTER THIS GETS TRUE

    mapping(uint => string) private _owners;

    event licenseisLocked(string _licenseText);

    mapping(address => bool) private _hasPresaleAccess;

    // Withdrawal addresses
    address t1 = 0xda73C4DFa2F04B189A7f8EafB586501b4D0B73dC;
    address t2 = 0xe26CD2A3d583a1141f62Ec16c4A0a2d8f95027c9;

    address[] addressList = [t1, t2];
    uint256[] shareList = [10, 90];

    constructor()
    ERC721("Cyber Hornets Colony Club", "CHCC")
    PaymentSplitter(addressList, shareList)  {}

    function tokenURI(uint256 tokenId) public override(ERC721) view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), extension)) : "";
    }

    function mint(uint256 _count) public payable {
        uint256 supply = totalSupply();
        require( block.timestamp >= _presaleStartTime,                           "Presale has not started yet" );
        require( block.timestamp >= _startTime || _hasPresaleAccess[msg.sender], "General sale has not started yet" );
        
        uint256 currentBalance = balanceOf(msg.sender);
        require( currentBalance + _count <= MAX_TOKENS_PER_TRANSACTION,          "You can mint a maximum of 8 Hornets in total" );

        require( supply + _count <= MAX_SUPPLY,                                  "Exceeds max Hornet supply" );
        require( msg.value >= _price * _count,                                   "Ether sent is not correct" );

        for(uint256 i; i < _count; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function airdrop(address _wallet, uint256 _count) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _count <= MAX_SUPPLY, "Exceeds maximum Hornet supply");
        
        for(uint256 i; i < _count; i++){
            _safeMint(_wallet, supply + i );
        }
    }

    // Just in case Eth does some crazy stuff
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        HORNET_PROVENANCE = _provenanceHash;
    }
    
    // Returns the license for tokens
    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Invalid ID");
        return LICENSE_TEXT;
    }
    
    // Locks the license to prevent further changes 
    function lockLicense() public onlyOwner {
        licenseLocked =  true;
        emit licenseisLocked(LICENSE_TEXT);
    }
    
    // Change the license
    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "License already locked");
        LICENSE_TEXT = _license;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setStartTime(uint256 _newStartTime) public onlyOwner {
        _startTime = _newStartTime;
    }
    
    function setPresaleStartTime(uint256 _newStartTime) public onlyOwner {
        _presaleStartTime = _newStartTime;
    }

    function setPresaleAccessList(address[] memory _addressList) public onlyOwner {
        for(uint256 i; i < _addressList.length; i++){
            _hasPresaleAccess[_addressList[i]] = true;
        }
    }

    function hasPresaleAccess(address wallet) public view returns(bool) {
        return _hasPresaleAccess[wallet];
    }
}