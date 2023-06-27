// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.0;

/* Ammended: KronicLabz
Flinch NFT! 
The worlds first NFT Film Franchise
by Ardor Pictures
 ________  __  __                      __              __    __  ________  ________ 
|        \|  \|  \                    |  \            |  \  |  \|        \|        \
| $$$$$$$$| $$ \$$ _______    _______ | $$____        | $$\ | $$| $$$$$$$$ \$$$$$$$$
| $$__    | $$|  \|       \  /       \| $$    \       | $$$\| $$| $$__       | $$   
| $$  \   | $$| $$| $$$$$$$\|  $$$$$$$| $$$$$$$\      | $$$$\ $$| $$  \      | $$   
| $$$$$   | $$| $$| $$  | $$| $$      | $$  | $$      | $$\$$ $$| $$$$$      | $$   
| $$      | $$| $$| $$  | $$| $$_____ | $$  | $$      | $$ \$$$$| $$         | $$   
| $$      | $$| $$| $$  | $$ \$$     \| $$  | $$      | $$  \$$$| $$         | $$   
 \$$       \$$ \$$ \$$   \$$  \$$$$$$$ \$$   \$$       \$$   \$$ \$$          \$$  
*/

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FlinchNFT is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public constant MAX_PUBLIC_MINT = 9999;
    uint256 public constant MAX_HITLIST_MINT = 3;
    uint256 public constant PUBLIC_SALE_PRICE = .065 ether;
    uint256 public constant HITLIST_SALE_PRICE = .05 ether;

    string private  baseTokenUri;
    string public   placeholderTokenUri;

    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale 
    //2 days later toggle reveal
    bool public isRevealed;
    bool public publicSale;
    bool public hitlistSale;
    bool public pause;
    bool public teamMinted;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalHitlistMint;

    constructor() ERC721A("Flinch NFT", "FLN"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Flinch NFT :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "Flinch NFT :: Slow down James, it's not time.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Flinch NFT :: There's not enough there Doyle");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Flinch NFT :: Already minted 3 times!");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Flinch NFT :: Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function hitlistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(hitlistSale, "Flinch NFT :: Minting is on Pause");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Flinch NFT :: Cannot mint beyond max supply");
        require((totalHitlistMint[msg.sender] + _quantity)  <= MAX_HITLIST_MINT, "Flinch NFT :: Cannot mint beyond whitelist max mint!");
        require(msg.value >= (HITLIST_SALE_PRICE * _quantity), "Flinch NFT :: Payment is below the price");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "Flinch NFT :: You're not on the Hitlist.");

        totalHitlistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "Flinch NFT :: Crew has already grabbed the loot!");
        teamMinted = true;
        _safeMint(msg.sender, 250);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    // @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){}

        return ownerIds;
    }
    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function togglehitlistSale() external onlyOwner{
        hitlistSale = !hitlistSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }
      function withdraw() external onlyOwner{
        //80% to utility/Flinch Franchise Project Wallet
        uint256 withdrawAmount_80 = address(this).balance * 80/100;
        //20% to inverstor/Ardor Pictures Wallet
        uint256 withdrawAmount_20 = address(this).balance * 20/100;
        payable(0x1333e81C131e1D1D0E8Bd42ecA5E45aCd0cE1De3).transfer(withdrawAmount_80);
        payable(0x3587D4a1773D418B95f519c47dB972B939bC7611).transfer(withdrawAmount_20);
        payable(msg.sender).transfer(address(this).balance);
    }
}