//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import ".deps/npm/@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract DasMinions is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 666;

    uint256 public constant MAX_QUANTITY = 2;

    uint256 public constant PUBLIC_PRICE = 0.009 ether;
    uint256 public constant WHITELIST_PRICE = 0.009 ether;

    address public constant CREATOR1_WALLET = 0x07451963226322e4f9dA108747f6CCc65911c6ea;

    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;
    
    mapping(address => uint256) public publicMint;

    bool public wlMintTime = false;
    bool public publicMintTime = false;

    string private baseTokenUri = "https://stfupals.mypinata.cloud/ipfs/QmeNJ2ToFbXE5cgMt24TWDrWUXapRNFgeDVLnWCAD5FQu7/";

    constructor() ERC721A("Das Minions", "DM") {

        _safeMint(CREATOR1_WALLET, 1);


    }

    function whitelistMint(uint256 _quantity) external payable {
        
        require(_quantity > 0, "Quantity Cant be 0");
        require(msg.value >= _quantity * WHITELIST_PRICE, "Not enough Ether");
        require(presalerList[msg.sender], "You are not Whitelisted!");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Out Of Stock!");
        require(wlMintTime, "It is not time to mint");
        require(presalerListPurchases[msg.sender] + _quantity <= MAX_QUANTITY, "Already Minted!");

            presalerListPurchases[msg.sender]+= _quantity;
            _safeMint(msg.sender, _quantity);

    }

    function mint(uint256 _quantity) external payable {

        require(_quantity > 0, "Quantity Cant be 0");
        require(msg.value >= _quantity * PUBLIC_PRICE, "Not enough Ether");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Out Of Stock!");
        require(publicMintTime, "It is not time to mint");
        require(publicMint[msg.sender] + _quantity <= MAX_QUANTITY, "Already Minted!");
            
            
            publicMint[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);

    }

    function addToWhitelist(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            //require(entry != address(0), "NULL_ADDRESS");
            //require(!presalerList[entry], "DUPLICATE_ENTRY");
            presalerList[entries[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");

            presalerList[entry] = false;
        }
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId;

        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    function setTokenURI(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function flipStateWL() public onlyOwner {

        wlMintTime = !wlMintTime;
    }

    function flipStatePublic() public onlyOwner {

        publicMintTime = !publicMintTime;
    }


    function withdraw() external onlyOwner {

        uint256 balance = address(this).balance;

        Address.sendValue(payable(owner()), balance);
    }

}