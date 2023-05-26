// SPDX-License-Identifier: GPL-3.0
// Authored by NoahN w/ Metavate ✌️
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



interface IMintPass {
    function setPassUsed(uint256 tokenId) external;
    function getPassUse(uint256 passTokenId) external view returns(bool);
    function ownerOf(uint256 tokenId) external view returns (address owner);
	function totalSupply() external view returns (uint256);
}


contract CollectorsClub456 is ERC721{ 
  	using Strings for uint256;

    uint256 public cost = 0.321 ether;
    uint256 private mintCount = 1;
    uint256 private maxSupply = 4561 - (45 * 5); //225 reserved for early mint pass buyers

    bool public sale = false;
	bool public presale = false;
    bool public claim = false;

	string public baseURI;
	
    bytes32 private merkleRoot;

	address private owner;
	address private admin = 0x8DFdD0FF4661abd44B06b1204C6334eACc8575af;
    address private mintPass;

	mapping(uint256 => bool) public claimed;

	constructor(string memory _name, string memory _symbol) 
	ERC721(_name, _symbol){
	    owner = msg.sender;
    }

	 modifier onlyTeam {
        require(msg.sender == owner || msg.sender == admin, "Not team" );
        _;
    }

    function mint(uint256 mintQty) public payable{
        require(sale, "Sale");
        require(mintQty < 6, "Too many");
        require(mintQty * cost == msg.value, "ETH value");
    	require(mintQty + mintCount < maxSupply, "Max supply");

        minter(mintQty);
    }

	function mintPresale(uint256 mintQty, bytes32[] calldata merkleProof) public payable {
        require(presale, "Off");
    	require(mintQty < 6, "Too many");
    	require(msg.value == cost * mintQty, "ETH value");
    	require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Allowlist");
		require(mintQty + mintCount < maxSupply, "Max supply");

        minter(mintQty);
	}

	function mintWithPass(uint256 tokenId) public {
		require(claim, "Claim");
		require(!claimed[tokenId], "Claimed");
		require(IMintPass(mintPass).ownerOf(tokenId) == msg.sender, "Owner");
		
        claimed[tokenId] = true;
        IMintPass(mintPass).setPassUsed(tokenId);
		
        minter(5);
	}

    function minter(uint256 mintQty) internal {
        uint256 current = mintCount;
        mintCount += mintQty;
    	for(uint256 i; i < mintQty; i++){
        	_safeMint(msg.sender, current + i, "");
    	}
    	delete current;
    }

	function gift(uint[] calldata quantity, address[] calldata recipient) external onlyTeam{
    	require(quantity.length == recipient.length, "Matching lists" ); // Require quantity and recipient lists to be of the same length
    	uint totalQuantity = 0;
    	uint256 s = mintCount;
		// Sum the total amount of NFTs being gifted
    	for(uint i = 0; i < quantity.length; ++i){
    	    totalQuantity += quantity[i];
    	}
		mintCount += totalQuantity;
		delete totalQuantity;
    	for(uint i = 0; i < recipient.length; ++i){
        	for(uint j = 0; j < quantity[i]; ++j){
        	    _safeMint( recipient[i], s++, "" );
        	}
    	}
    	delete s;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    	require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
    	string memory currentBaseURI = _baseURI();
    	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
	}

	function setCost(uint256 _cost) public onlyTeam {
	    cost = _cost;
	}

    function setMerkleRoot(bytes32 _merkleRoot) public onlyTeam{
	    merkleRoot = _merkleRoot;
	}

    function setPassAddress(address mintPassAddress) public onlyTeam{
        mintPass = mintPassAddress;
    }

	function setBaseURI(string memory _newBaseURI) public onlyTeam {
	    baseURI = _newBaseURI;
	}
    
	function toggleSale() public onlyTeam {
	    sale = !sale;
	}

	function togglePresale() public onlyTeam {
		presale  = !presale;
	}
	
    function toggleClaim() public onlyTeam {
		claim = !claim;
	}

	function _baseURI() internal view virtual override returns (string memory) {
	    return baseURI;
	}

	function totalSupply() public view returns (uint256) {
        return mintCount - 1;
    }

    function withdraw()  public onlyTeam {
        payable(admin).transfer(address(this).balance * 75 / 1000);
        payable(owner).transfer(address(this).balance);
    }
}