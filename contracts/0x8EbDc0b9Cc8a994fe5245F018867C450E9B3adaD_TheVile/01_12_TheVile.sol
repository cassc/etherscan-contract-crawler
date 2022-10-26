// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheVile is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;

    uint256 public constant MAX_PUBLIC_MINT = 5;
    uint256 public constant MAX_VOIDLIST_MINT = 2;
    uint256 public constant MAX_CHOSEN_MINT = 1;

    address[] private _team = [
        0x593f271b0eA340B8B5fB8AA13C767eBa2DE0Dd33, 
        0x260509d4AF8b0C99CcD5259930d54CE48EaF23E1, 
        0x28095b64b11b3eB735e93FaA77a685fC590b3303,
        0x23dfE30a0a4d39100424eBaaa91deC522d68A14a,
        0x705601B211776c2B694Ff67ec0893a7882bFF844
        ];
    
    uint256[] private _teamShares = [
        15,
        3,
        3,
        15,
        64
        ];

    string private baseTokenUri;
    string public placeholderTokenUri;

    uint256 public max_supply = 5555;
    uint256 public sale_price = .041 ether;
    bool public isRevealed;
    bool public publicSale;
    bool public voidListSale;
    bool public chosenSale;
    

    bytes32 private merkleRoot;
    bytes32 private chosenMerkleRoot;
    bytes32 private teamMerkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalVoidListMint;
    mapping(address => uint256) public totalChosenMint;
    mapping(address => uint256) public totalMemberMint;

    constructor() ERC721A("The Vile", "VILE") PaymentSplitter(_team, _teamShares){
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The Vile: Cannot be called by a contract");
        _;
    }

    // Public mint function
    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "The Vile: Public mint not yet Active!");
        require((totalSupply() + _quantity) <= max_supply, "The Vile: Max supply reached!");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "The Vile: Already minted 5 times!");
        require(msg.value >= (sale_price * _quantity), "The Vile: Below mint price!");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // Voidlist mint function
    function voidListMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(voidListSale, "The Vile: Voidlist mint not active!");
        require((totalSupply() + _quantity) <= max_supply, "The Vile: Max supply reached!");
        require((totalVoidListMint[msg.sender] + _quantity)  <= MAX_VOIDLIST_MINT, "The Vile: Cannot mint beyond voidList max mint!");
        require(msg.value >= (sale_price * _quantity), "The Vile: Payment is below the mint price!");
        
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "The Vile: You are not void listed!");

        totalVoidListMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // Chosen mint function
    function chosenMint(bytes32[] memory _merkleProof, uint256 _quantity) external callerIsUser{
        require(chosenSale, "The Vile: Chosen mint not active!");
        require((totalSupply() + _quantity) <= max_supply, "The Vile: Cannot mint beyond max supply!");
        require((totalChosenMint[msg.sender] + _quantity)  <= MAX_CHOSEN_MINT, "The Vile: Already minted 1!");
       
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, chosenMerkleRoot, sender), "The Vile: You are not allowed to chosen mint!");

        totalChosenMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // Team mint function
    function teamMint() external onlyOwner{
        _safeMint(0x42E10684EeB3452124c405aB9fF73c3aa35aa844, 100);
    }

    // Dev mint (for testing)
    function devMint() external onlyOwner{
        _safeMint(msg.sender, 1);
    }

    // Team member mint, for team members only. (Only allowed to mint during chosen sale)
    function teamMemberMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(chosenSale, "The Vile: Team member mint not active!");
        require((totalSupply() + _quantity) <= max_supply, "The Vile: Max supply reached!");
        require((totalMemberMint[msg.sender] + _quantity)  <= MAX_VOIDLIST_MINT, "The Vile: Cannot mint beyond team member max mint!");
        require(msg.value >= (sale_price * _quantity), "The Vile: Payment is below the mint price!");
        
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, teamMerkleRoot, sender), "The Vile: You are not on the team member list!");

        totalMemberMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // Base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    // Return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString())) : "";
    }

    // Set token uri for all tokens
    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }

    // Set the placeholder token uri pre-reveal
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    // Set merkle root for void list
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    // Get merkle root for void list
    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    // Set merkleroot for chosen list
    function setChosenMerkleRoot(bytes32 _chosenMerkleRoot) external onlyOwner{
        chosenMerkleRoot = _chosenMerkleRoot;
    }

    // Get Merkle root for chosen list
    function getChosenMerkleRoot() external view returns (bytes32){
        return chosenMerkleRoot;
    }

    // Toggle voidlist sale
    function toggleVoidListSale() external onlyOwner{
        voidListSale = !voidListSale;
    }

    // Toggle public sale
    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    // Toggle chosen list sale
    function toggleChosenSale() external onlyOwner{
        chosenSale = !chosenSale;
    }
    
    // Function to toggle reveal
    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    // Function to update sale_price
    function setSalePrice(uint256 _newSalePrice) external onlyOwner{
        sale_price = _newSalePrice;
    }

    // Function to change supply
    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner{
        max_supply = _newMaxSupply;
    }

    // Withdraw function
    function withdraw() external onlyOwner{
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }
}