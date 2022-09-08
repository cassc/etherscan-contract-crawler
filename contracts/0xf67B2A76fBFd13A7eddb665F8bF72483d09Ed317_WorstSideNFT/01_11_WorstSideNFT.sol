// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract WorstSideNFT is ERC721,Ownable{
    using Strings for uint256;


    uint256 public mintPublicPrice;
    uint256 public mintPillPrice;
    uint256 public mintApePrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    string internal baseURI;
    string public baseExtension = ".json";
    bool public isPillMintEnable;
    bool public isPublicMintEnable;
    bool public isApeMintEnable;
    address[]  pilltedAddresses;
    address[]  apelistedAddresses;
    bool public revealed = true;
    string public notRevealedUri;

    constructor(
    ) payable ERC721("Worst Side","WS"){
        setBaseURI("ipfs://Qmd6HW9PDihvwLsP6rMyakhA4HRypQunRGmXCK8D7ZSoJb/");
        setNotRevealedURI("https://ipfs.infura.io/ipfs/QmUzJZhYL9pdLxqqzkmovvXZmJaBdpoSgHEm1MYMGYhivW");

        mintApePrice = 0.01 ether;
        mintPillPrice = 0.015 ether;
        mintPublicPrice = 0.02 ether;
        totalSupply = 0;
        maxSupply = 1000;

    }
    function worstMint(uint256 quantity_) public onlyOwner{

        for(uint256 i=0;i<quantity_; i ++){
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
    }

    function setCostApe(uint256 _cost) public onlyOwner {
        mintApePrice = _cost;
    }
    function setCostPill(uint256 _cost) public onlyOwner {
        mintPillPrice = _cost;
    }
    function setCostPublic(uint256 _cost) public onlyOwner {
        mintPublicPrice = _cost;
    }

    function _baseTokenUri() internal view virtual returns (string memory) {
        return baseURI;
    }

    function reveal() public onlyOwner {
        revealed = false;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }



    function setIsApeMintEnabled() public onlyOwner{
        isApeMintEnable = true;
        if(isApeMintEnable==true){
            isPillMintEnable = false;
            isPublicMintEnable = false;
        }
    }
    function setIsPillMintEnabled() public onlyOwner{
        isPillMintEnable = true;
        if(isPillMintEnable==true){
            isApeMintEnable = false;
            isPublicMintEnable = false;
        }
    }
    function setIsPublicMintEnabled() public onlyOwner{
        isPublicMintEnable = true;
        if(isPublicMintEnable==true){
            isApeMintEnable = false;
            isPillMintEnable = false;
        }
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory){
        require(
            _exists(tokenId_),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if(revealed == true) {
            return notRevealedUri;
        }else{
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId_),baseExtension));
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success ,"withdraw failed");
    }

    function isPillted(address _user) public view returns (bool) {
        for (uint i = 0; i < pilltedAddresses.length; i++) {
            if (pilltedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }
    function isApelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < apelistedAddresses.length; i++) {
            if (apelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function pillUsers(address[] calldata _users) public onlyOwner {
        pilltedAddresses = _users;
    }
    function apelistUsers(address[] calldata _users) public onlyOwner {
        apelistedAddresses = _users;
    }

    function mint(uint256 quantity_) public payable{
        require(isPublicMintEnable,"minting not enable");
        require(msg.value == quantity_ * mintPublicPrice,"wrong mint value");
        require(totalSupply + quantity_ <= maxSupply,"supply not enough");
        require(quantity_ <= 5,"max unit mint per transection");
        for(uint256 i=0;i<quantity_; i ++){
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
    }

    function pillMint(uint256 quantity_) public payable{
        require(isPillMintEnable,"pill minting not enable");
        require(isPillted(msg.sender) || isApelisted(msg.sender), "user is not pillted");
        require(msg.value == quantity_ * mintPillPrice,"wrong mint value");
        require(totalSupply + quantity_ <= maxSupply,"supply not enough");
        require(quantity_ <= 5,"max unit mint per transection");
        for(uint256 i=0;i<quantity_; i ++){
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }

    }

    function apeMint(uint256 quantity_) public payable{
        require(isApeMintEnable,"Ape minting not enable");
        require(isApelisted(msg.sender), "user is not Apelisted");
        require(msg.value == quantity_ * mintApePrice,"wrong mint value");
        require(totalSupply + quantity_ <= maxSupply,"supply not enough");
        require(quantity_ <= 5,"max unit mint per transection");
        for(uint256 i=0;i<quantity_; i ++){
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }

    }


}