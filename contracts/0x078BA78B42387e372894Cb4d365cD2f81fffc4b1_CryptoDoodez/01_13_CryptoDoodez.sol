// SPDX-License-Identifier: MIT
// Creator: Chiru Labs
// Amended by: KronicLabz

pragma solidity ^0.8.0;

/*********************************************
 *              CryptoDoodez!!               *
 *   A collection of some of the greatest    *
 *   derivative pfp project in the space!    *
 *********************************************
 *All minters granted 100% FULL rights to the*
 *IP of every CryptoDoodez NFT they mint. IP *
 *rights granted in this contract only apply *
 *to the original minter. Transfer of rights *
 * to subsequent owner (secondary) is at the *
 *    decision  of the original minter.      *
 *            -Happy Degening-               *
 ********************************************/

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CryptoDoodez is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 2350;
    uint256 public constant MAX_PUBLIC_MINT = 3;
    uint256 public constant MAX_ALLOW_LIST_MINT = 3;
    uint256 public constant PUBLIC_SALE_PRICE = .0 ether;
    uint256 public constant ALLOW_LIST_SALE_PRICE = .0 ether;

    string private  baseTokenUri;
    string public   placeholderTokenUri;

    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale 
    //2 days later toggle reveal
    bool public isRevealed;
    bool public publicSale;
    bool public allowListSale;
    bool public pause;
    bool public teamMinted;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalAllowListMint;

    constructor() ERC721A("CryptoDoodez", "DOODEZ"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "CryptoDoodez :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "CryptoDoodez :: Its closed.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "CryptoDoodez :: Nothing to see here");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "CryptoDoodez :: Already minted 3 times!");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "CryptoDoodez :: Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function allowListMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(allowListSale, "CryptoDoodez :: Minting is on Pause");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "CryptoDoodez :: Cannot mint beyond max supply");
        require((totalAllowListMint[msg.sender] + _quantity)  <= MAX_ALLOW_LIST_MINT, "CryptoDoodez :: Cannot mint beyond whitelist max mint!");
        require(msg.value >= (ALLOW_LIST_SALE_PRICE * _quantity), "CryptoDoodez :: Payment is below the price");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "CryptoDoodez :: You're not on the allowList.");

        totalAllowListMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "CryptoDoodez :: Minted already!");
        teamMinted = true;
        _safeMint(msg.sender, 75);
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

    function toggleAllowListSale() external onlyOwner{
        allowListSale = allowListSale;
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
    
    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }
      function withdraw() external onlyOwner{
        uint256 withdrawAmount_100 = address(this).balance * 100/100;
        payable(0x86f2aD57b59bb5BE8091A0a5fDBecb168b63cA17).transfer(withdrawAmount_100);
    }
}