// Authored by NoahN w/ Metavate ✌️
pragma solidity ^0.8.11;


import "./ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FineArtMFers is ERC721A, ReentrancyGuard{ 
	using Strings for uint256;


    //------------------//
    //     VARIABLES    //
    //------------------//
	uint256 public cost = 0.022 ether;
	uint256 private _maxSupply = 4200;

	bool public sale = false;
	bool public presale = false;
	bool public adminAccess = true;
    bool public frozen = false;

	string public baseURI;

	address private constant _admin = 0x8DFdD0FF4661abd44B06b1204C6334eACc8575af;
	address private _owner;

	mapping(address => bool) public giftClaimed; 

	bytes32 public mferMerkleRoot;

	error Paused();
	error MaxSupply();
	error BadInput();
	error AccessDenied();
    error EthValue();
    error MintLimit();

	constructor(string memory _name, string memory _symbol)
	ERC721A(_name, _symbol){
		_owner = msg.sender;
		_safeMint(_owner, 1); // the owner always needs the genisis piece, right?
	}

    //------------------//
    //     MODIFIERS    //
    //------------------//

	modifier onlyTeam {
		// the owner will always be an mfer, the admin is up for debate
		if(msg.sender != _owner && msg.sender != admin() ) { revert AccessDenied(); }
		_;
	}
    
    //------------------//
    //       MINT       //
    //------------------//

	function mint(uint256 mintQty) external payable {
		if(sale == false) revert Paused(); // mfers need to wait
		if(mintQty * cost != msg.value) revert EthValue(); // mfers need to pay
		if(mintQty > 10) revert MintLimit(); // mfers cant be greedy
		unchecked {mintQty += mintQty / 5; } // mfers get bonus NFTs
		if(mintQty + _totalMinted() > _maxSupply) revert MaxSupply(); // there are only so many mfers

		_safeMint(msg.sender, mintQty); // mfers incoming
	}


	function mintMferGift(uint256 mintQty, bytes32[] calldata _merkleProof) external payable{
		if(sale == false) revert Paused(); // mfers need to wait
		if(mintQty * cost != msg.value) revert EthValue(); // mfers need to pay
		if(mintQty > 10) revert MintLimit(); // mfers cant be greedy
		unchecked {mintQty += 1 + (mintQty / 5); } // mfers get an 1 bonus NFT, plus 1 additional bonus for every 5 purchased
		if(giftClaimed[msg.sender] == true) revert AccessDenied(); // mfers can only claim this bonus once
		if(mintQty + _totalMinted() > _maxSupply) revert MaxSupply(); // there are only so many mfers
		if(!MerkleProof.verify(_merkleProof, mferMerkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert AccessDenied(); // checking if you are a true mfer
        giftClaimed[msg.sender] = true; // this mfer has claimed their gift now

		_safeMint(msg.sender, mintQty); // mfers incoming
	}

	function mferEarlyMintGift(uint256 mintQty, bytes32[] calldata _merkleProof) external payable{
		if(presale == false) revert Paused(); // mfers need to wait, presale hasn't even started yet
		if(mintQty * cost != msg.value) revert EthValue(); // mfers need to pay
		if(mintQty > 10) revert MintLimit(); // mfers cant be greedy
		unchecked {mintQty += 1 + (mintQty / 5); } // mfers get an 1 bonus NFT, plus 1 additional bonus for every 5 purchased
		if(giftClaimed[msg.sender] == true) revert AccessDenied(); // mfers can only claim this bonus once
		if(mintQty + _totalMinted() > _maxSupply) revert MaxSupply(); // there are only so many mfers
		if(!MerkleProof.verify(_merkleProof, mferMerkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert AccessDenied(); // checking if you are a true mfer
        giftClaimed[msg.sender] = true; // this mfer has claimed their gift now

		_safeMint(msg.sender, mintQty); // mfers incoming
	}



	function mferEarlyMint(uint256 mintQty, bytes32[] calldata _merkleProof) external payable{
		if(presale == false) revert Paused(); // mfers need to wait, presale hasn't even started yet
		if(mintQty * cost != msg.value) revert EthValue(); // mfers need to pay
		if(mintQty > 10) revert MintLimit(); // mfers cant be greedy
		unchecked {mintQty += mintQty / 5; } // mfers get bonus NFTs
		if(mintQty + _totalMinted() > _maxSupply) revert MaxSupply(); // there are only so many mfers		
		if(!MerkleProof.verify(_merkleProof, mferMerkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert AccessDenied(); // checking if you are a true mfer

		_safeMint(msg.sender, mintQty); // mfers incoming
	}


	function devMint(uint256 mintQty, address recipient) external onlyTeam{
		if(mintQty + _totalMinted() > _maxSupply) revert MaxSupply(); // there are only so many mfers
		_safeMint(recipient, mintQty); // mfers incoming
	}

	function devMint(uint[] calldata quantity, address[] calldata recipient) external onlyTeam {
    	if(quantity.length != recipient.length) revert BadInput(); // what are you feeding me mfer?
    	uint totalQuantity = 0;
		// let's see how many mfers we're handing out
    	for(uint i = 0; i < quantity.length; ++i){
    	    totalQuantity += quantity[i];
    	}

		if(totalQuantity + _totalMinted() > _maxSupply) revert MaxSupply(); // there are only so many mfers
        // time to send out those mfers
    	for(uint i = 0; i < recipient.length; ++i){
            _safeMint(recipient[i], quantity[i]);
    	}
	}

    //------------------//
    //      SETTERS     //
    //------------------//

	function setBaseURI(string memory _newBaseURI) external onlyTeam {
        if(frozen == true) { revert Paused(); } // mfer, can you even update the metadata?
		baseURI = _newBaseURI;
	}

	function toggleSale() external onlyTeam {
		sale = !sale; // on your marks, get set go!
	}

	function togglePresale() external onlyTeam {
		presale = !presale; // on your marks, get set go!
	}

    function setCost(uint256 _cost) external onlyTeam {
        cost = _cost; // what is a fair price?
    }

	function setMerkleRoot(bytes32 root) external onlyTeam {
		mferMerkleRoot = root; // did you make it on the list mfer?
	}

    function freezeMetadata() external onlyTeam {
        frozen = true; // thats it, it's over
    }

	function toggleAdminAccess() external {
		if(msg.sender != _owner){revert AccessDenied();}
		adminAccess = !adminAccess; // you're just a regular mfer now
	}

    function reduceMaxSupply(uint256 newSupply) external onlyTeam {
		// don't worry your mfer is safe, there's just less now
        if(newSupply >= _maxSupply || newSupply < _totalMinted()){ revert MaxSupply(); }
        _maxSupply = newSupply; // 
    }

    //------------------//
    //      GETTERS     //
    //------------------//

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
	}

	function maxSupply() external view returns(uint256) {
		return _maxSupply;
	}

	function owner() external view returns(address) {
		return _owner;
	}

	function admin() public view returns(address){
		return adminAccess? _admin : _owner; // is the admin in charge or the owner running the show?
	}

    //------------------//
    //       MISC       //
    //------------------//

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 0; // mfers start at 0
	}

	function withdraw() external nonReentrant {
		require(msg.sender == _owner || msg.sender == _admin, "Not team");
		uint256 initalBalance = address(this).balance;
		payable(_admin).transfer(initalBalance * 25 / 100);
		payable(_owner).transfer(address(this).balance);
	}

	fallback() payable external {}
	receive() payable external {}
}