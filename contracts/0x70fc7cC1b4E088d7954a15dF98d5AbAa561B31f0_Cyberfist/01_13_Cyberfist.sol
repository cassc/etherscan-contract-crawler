//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Cyberfist is ERC721A, Ownable, ReentrancyGuard{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PUBLIC_MINT = 100;
    uint256 public constant MAX_ALLOWLIST_MINT = 5;
    uint256 public constant PUBLIC_SALE_PRICE = .08 ether;
    uint256 public constant ALLOWLIST_SALE_PRICE = .08 ether;

    string private  baseTokenUri;
    string public   placeholderTokenUri;

    //deploy smart contract, toggle AL, toggle WL when done, toggle publicSale 
    //2 days later toggle reveal
    bool public isRevealed;
    bool public publicSale;
    bool public allowListSale;
    bool public pause;
    bool public teamMinted;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalAllowlistMint;
    address[] public allowlist;

    constructor() ERC721A("Cyberfist", "CF"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cyberfist :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "Cyberfist :: Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Cyberfist :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Cyberfist :: Already minted 100 tokens!");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Cyberfist :: Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function allowlistMint(uint256 _quantity) external payable callerIsUser{
        require(allowListSale, "Cyberfist :: Minting is Paused");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Cyberfist :: Cannot mint beyond max supply");
        require((totalAllowlistMint[msg.sender] + _quantity)  <= MAX_ALLOWLIST_MINT, "Cyberfist :: Cannot mint beyond allowlist max mint!");
        require(msg.value >= (ALLOWLIST_SALE_PRICE * _quantity), "Cyberfist :: Payment is below the price");
        require(isAllowlisted(msg.sender), "Not on allowlist");

        totalAllowlistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "Cyberfist :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 69);
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

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function toggleAllowListSale() external onlyOwner{
        allowListSale = !allowListSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function withdraw() external nonReentrant onlyOwner{
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function addAllowlist(address[] calldata _users) public onlyOwner {
        delete allowlist;
        allowlist = _users;
    }
    function isAllowlisted(address _user) public view returns (bool) {
        for (uint i = 0; i < allowlist.length; i++) {
            if (allowlist[i] == _user) {
                return true;
            }
        }
        return false;                               
  }


}