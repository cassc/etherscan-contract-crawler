//SPDX-License-Identifier: MIT
//MODESTE ART CLUB + BILLIONAIRE

/*                  
                                                                                                                                                                  
                                                                               ,,  
  .g8"""bgd                                                                  `7MM  
.dP'     `M                                                                    MM  
dM'       ` `7Mb,od8 ,6"Yb.`7M'   `MF'.gP"Ya `7M'   `MF',6"Yb.  `7Mb,od8  ,M""bMM  
MM            MM' "'8)   MM  VA   ,V ,M'   Yb  VA   ,V 8)   MM    MM' "',AP    MM  
MM.    `7MMF' MM     ,pm9MM   VA ,V  8M""""""   VA ,V   ,pm9MM    MM    8MI    MM  
`Mb.     MM   MM    8M   MM    VVV   YM.    ,    VVV   8M   MM    MM    `Mb    MM  
  `"bmmmdPY .JMML.  `Moo9^Yo.   W     `Mbmmd'    ,V    `Moo9^Yo..JMML.   `Wbmd"MML.
                                                ,V                                 
                                             OOb"                                  
                                                                                                                                                                                            
*/

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Graveyard is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 3333;

    uint256 public constant MAX_QUANTITY = 2;
    uint256 public constant WHITELIST_MAX_QUANTITY = 5;

    uint256 public constant MINT_PRICE = 1;

    address public constant CREATOR1_WALLET = 0xDffC60457ac6F6Af63cC646B3f7c2241532EDa27;
    address public constant CREATOR2_WALLET = 0x6d0DAB7f71D9a05bb3a7e70F9a183b3FEeAcD223;
    address public constant CREATOR3_WALLET = 0x543CdFf197386ee54aB7a9865b048f7D54d1b71F;
    address public constant CREATOR4_WALLET = 0x8ffe89F69C33E5F4281e0D515cc447141653193b;

    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;
    
    mapping(address => uint256) public publicMint;

    bool public wlMintTime = false;
    bool public publicMintTime = false;

    string private baseTokenUri = "https://crimson-rapid-worm-376.mypinata.cloud/ipfs/QmYd8SAT6BZZaomo3SREDvMp5NoCJfm2s1menrhvV4ZbY5/";

    constructor() ERC721A("Gravestones", "GS") {

        _safeMint(CREATOR1_WALLET, 50);
        _safeMint(CREATOR2_WALLET, 50);
        _safeMint(CREATOR3_WALLET, 50);
        _safeMint(CREATOR4_WALLET, 50);

    }

    function presaleMint() external payable {
        
        uint256 _quantity = msg.value/MINT_PRICE;

        require(presalerList[msg.sender], "You are not Whitelisted!");
        require(msg.sender == tx.origin, "No Bots");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Out Of Stock!");
        require(wlMintTime, "It is not time to mint");
        require(presalerListPurchases[msg.sender] + _quantity <= WHITELIST_MAX_QUANTITY, "Already Minted!");

            presalerListPurchases[msg.sender]+= _quantity;
            _safeMint(msg.sender, _quantity);
        
    }

    function mint() external payable {

        uint256 _quantity = msg.value/MINT_PRICE;

        require(msg.sender == tx.origin, "No Bots");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Out Of Stock!");
        require(publicMintTime, "It is not time to mint");
        require(publicMint[msg.sender] + _quantity <= MAX_QUANTITY, "Already Minted!");
            
            
            publicMint[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);

    }

    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!presalerList[entry], "DUPLICATE_ENTRY");

            presalerList[entry] = true;
        }
    }

    function removeFromPresaleList(address[] calldata entries) external onlyOwner {
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