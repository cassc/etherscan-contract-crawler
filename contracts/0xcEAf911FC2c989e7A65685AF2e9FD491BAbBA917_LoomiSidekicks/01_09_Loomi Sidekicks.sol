//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error Paused();
error SoldOut();
error SaleNotStarted();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error MintedOut();
error MaxMints();
error ArraysDontMatch();

contract LoomiSidekicks is ERC721AQueryable, Ownable{
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint constant public maxSupply = 8888;
    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = ".json";

    //0 -> whitelist :: 1->public

    address private signer = 0x1522BbCC7D9247e2131212558Df31362Ec0Da5A2;
    bool public revealed;
    //False on mainnet
    enum SaleStatus  {INACTIVE,HOLDER,COLLAB,RAFFLE}
    SaleStatus public saleStatus = SaleStatus.INACTIVE;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor()
        ERC721A("Loomi Sidekicks", "LKICKS")
    {
        setNotRevealedURI("https://loomiheads.mypinata.cloud/ipfs/QmRGU9Sto4k5SpDeziV4P3rdzYbckTcmdxm27ftvuRGG8b/hidden.json");
        //First 200 Go To Treasury
    }

    function airdrop(address[] calldata accounts,uint[] calldata amounts) external onlyOwner{
        if(accounts.length != amounts.length) revert ArraysDontMatch();
        uint supply = totalSupply();
        for(uint i; i<accounts.length;i++){
            if(supply + amounts[i] > maxSupply) revert SoldOut();
            supply += amounts[i];
            _mint(accounts[i],amounts[i]);
        }     
    }

    /*///////////////////////////////////////////////////////////////
                          MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function holderMint(uint amount,uint max, bytes memory signature) external {
        if(saleStatus != SaleStatus.HOLDER) revert SaleNotStarted();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        bytes32 hash = keccak256(abi.encodePacked("HOLDER",max,_msgSender()));
        if(hash.toEthSignedMessageHash().recover(signature)!=signer) revert NotWhitelisted();
        if(_numberMinted(_msgSender()) + amount > max) revert MaxMints();
        _mint(_msgSender(),amount);
    }
    function collabMint(uint amount,uint max, bytes memory signature) external {
        if(saleStatus != SaleStatus.COLLAB) revert SaleNotStarted();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        bytes32 hash = keccak256(abi.encodePacked("COLLAB",max,_msgSender()));
        if(hash.toEthSignedMessageHash().recover(signature)!=signer) revert NotWhitelisted();
        if(_numberMinted(_msgSender()) + amount > max) revert MaxMints();
        _mint(_msgSender(),amount);
    }
    
  
    function raffleMint(uint amount,uint max,bytes memory signature) external payable {
        if(saleStatus != SaleStatus.RAFFLE) revert SaleNotStarted();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        bytes32 hash = keccak256(abi.encodePacked("RAFFLE",max,_msgSender()));
        if(hash.toEthSignedMessageHash().recover(signature)!=signer) revert NotWhitelisted();
        uint numMinted = uint(_getAux(_msgSender()));
        if(numMinted + amount > max) revert MaxMints();
        _setAux(_msgSender(),uint64(numMinted+amount));
        _mint(_msgSender(),amount);
    }
    function getNumMintedHolderOrCollab(address account) public view returns(uint){
        return _numberMinted(account);
    }
    function getNumMintedPublic(address account) public view returns(uint){
        return uint(_getAux(account));
    }
    /*///////////////////////////////////////////////////////////////
                          MINTING UTILITIES
    //////////////////////////////////////////////////////////////*/
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setHolderMintOn() external onlyOwner {
        saleStatus = SaleStatus.HOLDER;
    }
    function setCollabMintOn() external onlyOwner {
        saleStatus = SaleStatus.COLLAB;
    }
    function setRaffleOn() external onlyOwner {
        saleStatus = SaleStatus.RAFFLE;
    }
    function turnSalesOff() external onlyOwner{
        saleStatus = SaleStatus.INACTIVE;
    }
 
    function switchReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }
    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
    }

    /*///////////////////////////////////////////////////////////////
                                METADATA
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId)
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
                ? string(abi.encodePacked(currentBaseURI, _toString(tokenId),uriSuffix))
                : "";
    }

    /*///////////////////////////////////////////////////////////////
                           WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/
      function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

   

}