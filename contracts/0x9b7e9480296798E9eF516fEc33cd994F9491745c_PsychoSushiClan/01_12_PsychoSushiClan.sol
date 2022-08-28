// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";


interface Staking{
    function NFTLevels(uint256 _tokenId) external view returns(uint256);
    
}


contract PsychoSushiClan is
    ERC721A,
    ERC721ABurnable,
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    uint256 public maxSupply = 3333;
    uint256 public price = 0.029 ether;
    uint256 public regularMintMaxPerTx = 10;
    


    //Staking Logics 
    address public stakingCA;
    string public levelOneURI;
    string public levelTwoURI;
    string public levelThreeURI;
    bool public enableLeveledURI;


    string public _baseTokenURI;
    string public _baseTokenEXT;
    string public notRevealedUri ;

    bool public revealed = false;
    bool public paused = true;
    bool public whitelistSale = true;

    uint256 public whitelistMaxMint = 6;
    uint256 public whitelistPrice = 0.023 ether;
    bytes32 public merkleRoot = 0xcd62d9f63312d797f5ec41a15f03eed0c453116e792171c6ae8f8a686debd0ad;


    mapping(address => uint256 ) public _totalMinted;

    constructor() ERC721A("Psycho Sushi Clan", "PSC") {}

    function mint(uint256 _mintAmount) public payable nonReentrant {
        require(_mintAmount <= regularMintMaxPerTx , "You cannot mint more than 10 per tx ");
        require(!paused, "Contract Minting Paused");
        require(!whitelistSale, ": Cannot Mint During Whitelist Sale");
        require(msg.value >= price * _mintAmount, "Insufficient FUnd");
        uint256 supply = totalSupply();
        require(
            supply + _mintAmount <= maxSupply,
            ": No more NFTs to mint,decrease the quantity or check out OpenSea."
        );
        _safeMint(msg.sender, _mintAmount);
    }

    function WhiteListMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        require(!paused, "Contract Minting Paused");
        require(whitelistSale, ": Whitelist is paused.");
        require(
            _mintAmount + _totalMinted[msg.sender] <=
                whitelistMaxMint,
            "You cant mint more,Decrease MintAmount or Wait For Public Mint"
        );
        require(msg.value >= whitelistPrice * _mintAmount, "Insufficient FUnd");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "You are Not whitelisted"
        );
        uint256 supply = totalSupply();
        require(
            supply + _mintAmount <= maxSupply,
            ": No more NFTs to mint,decrease the quantity or check out OpenSea."
        );
        _safeMint(msg.sender, _mintAmount);
        _totalMinted[msg.sender] += _mintAmount;
    }

    function _airdrop(uint256 amount, address[] memory _address)
        public
        onlyOwner
    {
        uint256 totalSupply = totalSupply();
        require(
            totalSupply + (amount * _address.length) <= maxSupply,
            "Exceeds Max Supply"
        );
        for (uint256 i = 0; i < _address.length; i++) {
            _safeMint(_address[i], amount);
        }
    }

    function startPublicSale() public onlyOwner {
        paused = false;
        whitelistSale = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }

    function setPublicMintMaxPerTx(uint256 newMax) public onlyOwner {
        regularMintMaxPerTx = newMax;
    }

    function setWhiteListMax(uint256 newMax) public onlyOwner {
        whitelistMaxMint = newMax;
    }

    function setStakingAddress(address _stakingCA) public onlyOwner{
        stakingCA = _stakingCA;
    }

    function configLevels(string memory _levelOneURI,string memory _levelTwoURI,string memory _levelThreeURI,bool _enableLeveledURI) public onlyOwner{
        levelOneURI = _levelOneURI;
        levelTwoURI=_levelTwoURI;
        levelThreeURI = _levelThreeURI;
        enableLeveledURI = _enableLeveledURI;     
    }

    function getBaseURIByLevel(uint256 _tokenID) internal view returns(string memory){
        if(!enableLeveledURI){
            return _baseTokenURI;
        }
        uint256 level = Staking(stakingCA).NFTLevels(_tokenID);
        if(level == 0){
            return _baseTokenURI;
        }
        else if(level == 1){
            return levelOneURI;
        }
        else if(level == 2){
            return levelTwoURI;
        }
        return levelThreeURI;
    }



    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A,IERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        } else {
            return
                bytes(_baseTokenURI).length > 0
                    ? string(
                        abi.encodePacked(
                            getBaseURIByLevel(tokenId),
                            tokenId.toString(),
                            _baseTokenEXT
                        )
                    )
                    : "";
        }
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function toogleWhiteList() public onlyOwner {
        whitelistSale = !whitelistSale;
    }

    function toogleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function tooglePause() public onlyOwner {
        paused = !paused;
    }

    function changeURLParams(string memory _nURL, string memory _nBaseExt)
        public
        onlyOwner
    {
        _baseTokenURI = _nURL;
        _baseTokenEXT = _nBaseExt;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setWLPrice(uint256 newPrice) public onlyOwner {
        whitelistPrice = newPrice;
    }

    function setMaxSuuply(uint256 _newSupply) public onlyOwner{
        require(_newSupply <= 6666,"You cannot add more sushi on the market.");
        maxSupply = _newSupply;
    }

    function setMerkleRoot(bytes32 merkleHash) public onlyOwner {
        merkleRoot = merkleHash;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}