//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error SoldOut();
error SaleNotActive();
error Underpriced();
error MaxMints();
error NotOwner();
error NotWhitelisted();
error AlreadyRedeemed();

/*

██████╗░░█████╗░██████╗░██╗░░░░░░█████╗░██████╗░░██████╗
██╔══██╗██╔══██╗██╔══██╗██║░░░░░██╔══██╗██╔══██╗██╔════╝
██████╦╝███████║██║░░██║██║░░░░░███████║██║░░██║╚█████╗░
██╔══██╗██╔══██║██║░░██║██║░░░░░██╔══██║██║░░██║░╚═══██╗
██████╦╝██║░░██║██████╔╝███████╗██║░░██║██████╔╝██████╔╝
╚═════╝░╚═╝░░╚═╝╚═════╝░╚══════╝╚═╝░░╚═╝╚═════╝░╚═════╝░
*/
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";




contract Badlads is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    //Supply & Price
    uint256 public maxSupply = 6000;
    uint256 public price = .01 ether;
   


    //Whitelist Signer
    address private signer = 0x034ff4C93eFD09Cc00f93ba35d79539D49924134;

    //Sale Switches
    bool public publicSaleStarted;
    bool public presaleStarted;
    bool public revealed = true;   


    //Token Factory
    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = ".json";

    // @dev these mappings track how many one has minted on public and WL respectively
    mapping(address =>uint256) public presaleMints;
    mapping(address => bool) public hasRedeemed;

    constructor()
        ERC721A("Badlads", "BLADS")

    {
        setBaseURI("ipfs://QmPW2mX8XXDrVgF4zD2TWtmMZnpGksQv7F8zNoCUQqCFSp/");
    }




    /*///////////////////////////////////////////////////////// 
                            MINT UTILITY
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function teamMint(address to ,uint256 amount) public onlyOwner  {
        if(amount + totalSupply() > maxSupply) revert SoldOut();
        _mint(to,amount);
    }

    function airdrop(address[] calldata accounts, uint[] calldata amounts) external onlyOwner{
        uint supply = totalSupply();
        require(accounts.length == amounts.length,"Arrays Must Match");
        for(uint i; i <accounts.length;i++){
            if(amounts[i] + supply > maxSupply) revert SoldOut();
            _mint(accounts[i],amounts[i]);
        }
    }

    function publicMint(uint256 amount) external payable nonReentrant{
        if(!publicSaleStarted) revert SaleNotActive();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        if(msg.value < amount * price) revert Underpriced();
        _mint(msg.sender,amount);  
    }
    
    function presaleMint(uint256 amount, uint256 max, bytes memory signature)  external payable nonReentrant {
        bytes32 hash = keccak256(abi.encodePacked(max,msg.sender));
        if( hash.toEthSignedMessageHash().recover(signature) != signer) revert NotWhitelisted();
        if(!presaleStarted) revert SaleNotActive();
        if(msg.value < amount * price) revert Underpriced();
        if(presaleMints[msg.sender] + amount > max) revert MaxMints();
        //@notice this line is unecessary.
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        presaleMints[msg.sender]+=amount;
        _mint(msg.sender,amount);
    }


     /*///////////////////////////////////////////////////////// 
                            BURN
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function burnNft(uint tokenId) external {
        if(msg.sender != ownerOf(tokenId)) revert NotOwner();
        _burn(tokenId);
    }

     /*///////////////////////////////////////////////////////// 
                            REDEEM
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
     function redeemOne(uint max, bytes memory signature) external {
        bytes32 hash = keccak256(abi.encodePacked(max,msg.sender));
        if(!presaleStarted) revert SaleNotActive();
        if( hash.toEthSignedMessageHash().recover(signature) != signer) revert NotWhitelisted();
        if(hasRedeemed[msg.sender]) revert AlreadyRedeemed();
        hasRedeemed[msg.sender] = true;
        _mint(msg.sender,1);

     }


     /*///////////////////////////////////////////////////////// 
                           SETTERS
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function setMaxSupply(uint256 newSupply) external onlyOwner {
        require(newSupply <= maxSupply,"Can't Increase Supply");
        maxSupply = newSupply;
    }

    function switchReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSigner(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        signer = _newAddress;
    }
    function setUriSuffix(string memory _newSuffix) external onlyOwner{
        uriSuffix = _newSuffix;
    }

    function setPublicStatus(bool status) external onlyOwner{
        publicSaleStarted = status;
    }
    function setPresaleStatus(bool status) external onlyOwner{
        presaleStarted = status;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    /*///////////////////////////////////////////////////////// 
                           TOKEN FACTORY
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(),uriSuffix))
                : "";
    }



     /*///////////////////////////////////////////////////////// 
                            WITHDRAW
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function withdraw() public payable onlyOwner {
    uint256 balance = address(this).balance;
    (bool r1, ) = payable(owner()).call{value: balance}("");
    require(r1);
    }

   
    


}