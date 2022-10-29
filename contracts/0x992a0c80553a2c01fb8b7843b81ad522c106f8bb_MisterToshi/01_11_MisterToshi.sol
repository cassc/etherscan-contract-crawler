// SPDX-License-Identifier: MIT
/* Hey Zero!! I’ve put together a very simple contract for you below.
Be very careful when you edit the contract! I really suggest you talk to teraTEK or ask someone for help.
You shouldn’t DIY this if you don’t know what you’re doing. If you screw this up… I can’t help you later! */
pragma solidity ^0.8.4;
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MisterToshi is ERC721AQueryable, Ownable, ERC721ABurnable, ReentrancyGuard {

    using Strings for uint256;

    /* [ IPFS Information ] - Okay babe, this is where you connect all of your tokens to the metadata.
    Don’t screw this up okay? Else your “masterpieces” won’t show up properly.
    Make sure to connect the IPFS once launched! */
    string public baseURI;
    string public baseExtension = ".json";
    string notRevealedUri;

    /* [ Collection and Pricing Information ] - Babe, are you sure you want a max supply of 3888?
    There’s barely that many people alive! Don’t forget, supply and demand!
    But I guess you wouldn’t care since you’re an “artist”. */
    uint256 public MAX_SUPPLY = 3888;
    uint256 public MINT_PRICE = 0 ether;

    /* [ Mint Limit ] */
    uint256 public MAX_MINT_PER_TRANSAC = 1;

    /* [ Mint Logistic Params ] */
    bool public paused = true;
    bool public revealed = false;
    mapping(address => uint256) public addressClaimedBalance;

    /* [ Internal ] - Okay babe, you seriously have to triple check above.
    I can’t help you if you launch this and need help later… */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /* [ Treasury ] */
    address treasuryAddr = 0x1a58ec0D23102Bb5603205e5F7ae035629110cE4;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A ("MisterToshi", "MisterToshi") {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        _safeMint(treasuryAddr, 500);
    }

    /* [ === Mint Function === ] Okay overall that’s about it.
    Make sure to delete all of the instruction notes I’ve put in here once you’ve proof read everything. */
    function mint (uint256 quantity) external payable{
        require(totalSupply() + quantity <= MAX_SUPPLY, "MUWHAHA NO MORE, TOO POPULAR.");
        if (msg.sender != owner()){
            require(!paused, "HOLD ON, TOO POPULAR.");
            require(quantity <= MAX_MINT_PER_TRANSAC, "TOO POPULAR, 1 ONLY OKAY?");
            require(msg.value >= (MINT_PRICE * quantity), "NEED MORE ETH FOR GAS!");
            require(addressClaimedBalance[msg.sender] == 0, "UH YOU ALREADY MINTED. TOO POPULAR.");
        }
        // Increment address record
        addressClaimedBalance[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function gift(address _recipient, uint256 _amount) external nonReentrant onlyOwner {
        require(msg.sender == owner(), "ONLY I CAN SEND GIFT");
        require(_totalMinted() + _amount <= MAX_SUPPLY, "OOPS! NO MORE FREE STUFF.");
        _safeMint(_recipient, _amount);
    }

    /* [ === Token Retrieve === ] */
    function tokenURI(uint256 tokenId) override public view virtual returns(string memory){
        require(_exists(tokenId), "CANT FIND TOKEN");
        if (!revealed){
            return string(abi.encodePacked(notRevealedUri, tokenId.toString(), baseExtension));
        }
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
    }

    /* [ === Utilities === ] */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setPaused(bool _bool) public onlyOwner{
        paused = _bool;
    }

    function setRevealed(bool _bool) public onlyOwner{
        revealed = _bool;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner{
        MINT_PRICE = _newMintPrice;
    }

    function setMaxMintPerTransac(uint256 limit) public onlyOwner{
        MAX_MINT_PER_TRANSAC = limit;
    }

    function getAddressClaimedBalance(address _userAddr) public view returns (uint256){
        return addressClaimedBalance[_userAddr];
    }

    function numberMinted(address _userAddr) external view returns (uint256) {
        return _numberMinted(_userAddr);
    }

    /* [ === Withdraw === ] */
    function withdraw() external payable onlyOwner nonReentrant {
        require(msg.sender == owner(), "Caller is not the owner");
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}