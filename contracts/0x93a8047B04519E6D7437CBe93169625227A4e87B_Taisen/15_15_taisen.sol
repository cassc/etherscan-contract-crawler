// SPDX-License-Identifier: MIT

/*
 _____     _             __        __         _     _                      
|_   _|_ _(_)___  ___ _ _\ \      / /__  _ __| | __| |  ___ ___  _ __ ___  
  | |/ _` | / __|/ _ \ '_ \ \ /\ / / _ \| '__| |/ _` | / __/ _ \| '_ ` _ \ 
  | | (_| | \__ \  __/ | | \ V  V / (_) | |  | | (_| || (_| (_) | | | | | |
  |_|\__,_|_|___/\___|_| |_|\_/\_/ \___/|_|  |_|\__,_(_)___\___/|_| |_| |_|

*/

pragma solidity ^0.8.7;
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./Markle.sol";


contract Taisen is ERC721A, Ownable{
    using Strings for uint256;
   
    uint public tokenPrice = 0.04 ether;
    uint public presalePrice = 0.035 ether;
    uint constant maxSupply = 6666;
    bool public ogs_status = false;
    bool public Presale_status = false;
    bool public public_sale_status = false;
    bool public isBurnEnabled=false;
    bytes32 public whitelistMerkleRoot;
    bytes32 public OgsMerkleRoot;
    
    mapping(address => bool) private ogList;
    string public baseURI;
    
    mapping(uint256 => address) public burnedby;

    uint public maxPerTransaction = 5;  //Max Limit Per TX
    uint public maxPerWalletPresale = 3; //Max Limit for Presale
    uint public maxPerOgs = 1;
             
    constructor() ERC721A("Taisen", "Taisen"){}


    function Public_mint(uint _count) public payable{
        require(public_sale_status == true, "Sale is Paused.");
        require(_count > 0, "mint at least one token");
        require(totalSupply() + _count <= maxSupply, "Sold Out!");
        require(msg.value >= tokenPrice * _count, "incorrect ether amount");
        require(_count <= maxPerTransaction, "ONLY 5 NFTS ALLOWED PER TRANSACTION");
            _safeMint(msg.sender, _count);
   }

    function Whitelist_mint(uint _count, bytes32[] calldata merkleProof) external payable{ 
        
        require(Presale_status == true, "MINT HAS NOT STARTED YET");
        require(MerkleProof.verify(merkleProof,whitelistMerkleRoot,keccak256(abi.encodePacked(msg.sender))),"YOUR WALLET IS NOT WHITELISTED");
        require(balanceOf(msg.sender) <= maxPerWalletPresale, "ONLY 3 NFTS ALLOWED IN PRESALE");
        require(_count <= maxPerWalletPresale, "ONLY 3 NFTS ALLOWED PER TRANSACTION");
        require(totalSupply() + _count <= maxSupply, "Sold Out!");
        require(msg.value >= presalePrice * _count, "incorrect ether amount");
        _safeMint(msg.sender, _count);
    }

     function ogs_mint(uint _count, bytes32[] calldata merkleProof) external{ 
        require(ogs_status == true, "MINT HAS NOT STARTED YET");
        require(MerkleProof.verify(merkleProof,OgsMerkleRoot,keccak256(abi.encodePacked(msg.sender))),"YOUR WALLET IS NOT WHITELISTED");
        require(!ogList[msg.sender], "YOU HAVE ALREADY CLAIMED YOUR NFT");
        require(_count <= maxPerOgs, "max per transaction 1");
        require(totalSupply() + _count<= maxSupply, "Sold Out!");
            _safeMint(msg.sender, _count);
            ogList[msg.sender]=true;
    }

    function adminMint(uint _count) external onlyOwner{
        require(_count > 0, "mint at least one token");
        require(totalSupply() + _count <= maxSupply, "Sold Out!");
        _safeMint(msg.sender, _count);
    }

    function sendGifts(address[] memory _wallets) public onlyOwner{
        require(totalSupply() + _wallets.length <= maxSupply, "Sold Out!");
        for(uint i = 0; i < _wallets.length; i++)
            _safeMint(_wallets[i], 1);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), "")) : "";
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
    function Presale_Status(bool status) external onlyOwner {
        Presale_status = status;
    }
    function ogs_status_update(bool status) external onlyOwner {
        ogs_status = status;
    }
    function Public_status_update(bool status) external onlyOwner {
        public_sale_status = status;
    }
     function update_burning_status(bool status) external onlyOwner {
        isBurnEnabled = status;
    }

    function SetWhitelist(bytes32 merkleRoot) external onlyOwner {
		whitelistMerkleRoot = merkleRoot;
	}
    function SetOgsMarkle(bytes32 merkleRoot) external onlyOwner {
		OgsMerkleRoot = merkleRoot;
	}
  
    function burn(uint256 tokenId) external 
    {
        require(isBurnEnabled, "burning disabled");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "burn caller is not approved"
        );
        _burn(tokenId);
        burnedby[tokenId] = msg.sender;
    }
     function public_sale_price(uint pr) external onlyOwner {
        tokenPrice = pr;
    }
         function pre_sale_price(uint pr) external onlyOwner {
        presalePrice = pr;
    }
         function adjust_limits(uint maxpter,uint maxperwalletpre) external onlyOwner {
         maxPerTransaction = maxpter;  //Max Limit Per TX
         maxPerWalletPresale = maxperwalletpre; //Max Limit for Presale
        
    }
 
    function withdraw() external onlyOwner {
             uint _balance = address(this).balance;
        payable(owner()).transfer(_balance * 54 / 100);
        payable(0x2a49FCED5de896C3b2a70a550B4c3BC8995ede40).transfer(_balance * 33 / 100);
        payable(0x261E28CeEd4B1da2c643d44F7A2439ddfEE1b978).transfer(_balance * 7 / 100);
        payable(0x93A0c561D165054d29F242909A2Ea40e6Ab2bBAd).transfer(_balance * 6 / 100);
    }
}