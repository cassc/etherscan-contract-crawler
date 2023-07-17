// SPDX-License-Identifier: MIT

/*


*/

pragma solidity ^0.8.7;
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./Markle.sol";


contract LoveBears is ERC721A, Ownable{
    using Strings for uint256;
   
    uint public PublicPrice = 0.05 ether;
    uint public WhitelistPrice = 0.035 ether;
     uint public RafflePrice = 0.04 ether;
    uint constant maxSupply = 10000;
    bool public Raffle_Status = false;
    bool public Whitelist_Status = false;
    bool public Public_Status = false;
    bool public isBurnEnabled=false;
    bytes32 public WhitelistMerkle;
    bytes32 public RaffleMerkle;

    string public baseURI;
    
    mapping(uint256 => address) public burnedby;

    uint public MaxPerMint = 10;  //Max Limit Per TX

             
    constructor() ERC721A("Love Bears", "LoveBears"){}


    function Public_mint(uint _count) public payable{
        require(Public_Status == true, "Sale is Paused");
        require(_count > 0, "Mint at least one token");
        require(totalSupply() + _count <= maxSupply, "Sold Out!");
        require(msg.value >= PublicPrice * _count, "Incorrect ether amount");
        require(_count <= MaxPerMint, "SELECTED NUMBER OF NFTS NOT ALLOWED IN ONE TRANSACTION");
            _safeMint(msg.sender, _count);
   }

    function Whitelist_mint(uint _count, bytes32[] calldata merkleProof) external payable{ 
        
        require(Whitelist_Status == true, "MINT HAS NOT STARTED YET");
        require(MerkleProof.verify(merkleProof,WhitelistMerkle,keccak256(abi.encodePacked(msg.sender))),"YOUR WALLET IS NOT WHITELISTED");
        require(_count <= MaxPerMint, "SELECTED NUMBER OF NFTS NOT ALLOWED IN ONE TRANSACTION");
        require(totalSupply() + _count <= maxSupply, "Sold Out!");
        require(msg.value >= WhitelistPrice * _count, "Incorrect ether amount");
        _safeMint(msg.sender, _count);
    }

    function Raffle_mint(uint _count, bytes32[] calldata merkleProof) external payable{ 
        require(Raffle_Status == true, "MINT HAS NOT STARTED YET");
        require(MerkleProof.verify(merkleProof,RaffleMerkle,keccak256(abi.encodePacked(msg.sender))),"YOUR WALLET IS NOT LISTED");
        require(msg.value >= RafflePrice * _count, "Incorrect ether amount");
        require(_count <= MaxPerMint, "SELECTED NUMBER OF NFTS NOT ALLOWED IN ONE TRANSACTION");
        require(totalSupply() + _count<= maxSupply, "Sold Out!");
            _safeMint(msg.sender, _count);
            
    }
    function Whitelist_checker(address walletAddress, bytes32[] calldata merkleProof) public view returns (bool){ 
        if(MerkleProof.verify(merkleProof,WhitelistMerkle,keccak256(abi.encodePacked(walletAddress))))
        {
            return true;
        }
        else
        {return false;}
      
    }
    function Raffle_checker(address walletAddress, bytes32[] calldata merkleProof) public view returns (bool){ 
        if(MerkleProof.verify(merkleProof,RaffleMerkle,keccak256(abi.encodePacked(walletAddress))))
        {
            return true;
        }
        else
        {return false;}
      
    }
    function adminMint(uint _count) external onlyOwner{
        require(_count > 0, "Mint at least one token");
        require(totalSupply() + _count <= maxSupply, "Sold Out!");
        _safeMint(msg.sender, _count);
    }

    function Airdrops(address[] memory _wallets) public onlyOwner{
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

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
    function Whitelist_status(bool status) external onlyOwner {
        Whitelist_Status = status;
    }
    function Raffle_status(bool status) external onlyOwner {
        Raffle_Status = status;
    }
    function Public_status(bool status) external onlyOwner {
        Public_Status = status;
    }
     function Burn_status(bool status) external onlyOwner {
        isBurnEnabled = status;
    }

    function SetWhitelistMerkle(bytes32 merkleRoot) external onlyOwner {
		WhitelistMerkle = merkleRoot;
	}
    function SetRaffleMerkle(bytes32 merkleRoot) external onlyOwner {
		RaffleMerkle = merkleRoot;
	}
  
    function burn(uint256 tokenId) external {
        require(isBurnEnabled, "burning disabled");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "burn caller is not approved"
        );
        _burn(tokenId);
        burnedby[tokenId] = msg.sender;
    }
    function Public_price(uint pr) external onlyOwner {
        PublicPrice = pr;
    }
    function Whitelist_price(uint pr) external onlyOwner {
        WhitelistPrice = pr;
    }
    function Raffle_price(uint pr) external onlyOwner {
        RafflePrice = pr;
    } 
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}