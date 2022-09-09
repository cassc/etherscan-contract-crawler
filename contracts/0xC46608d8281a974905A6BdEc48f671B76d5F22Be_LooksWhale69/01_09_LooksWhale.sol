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
error WalkThePlank();
error ArraysDontMatch();
error LookAtMeIAmTheCaptainNow();
error iM_a_TrAdEr();
error ExtinctionBaby();
contract LooksWhale69 is ERC721AQueryable, Ownable{
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint constant public maxSupply = 6969;
    uint constant public maxOnWhaleMint = 699;
    uint public whaleMintCounter;
    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = ".json";


    address private captain = 0xeC19af89f554B66c1FF80D353cdb2919b784Bb41;
    bool public revealed;
    uint public constant degenPrice = .00420 ether;
    uint public constant publicPrice = .00690 ether;
    uint public constant publicMax  = 2;

    //False on mainnet
    enum SaleStatus  {INACTIVE,WHALE_OR_DEGEN,PUBLIC}
    SaleStatus public saleStatus = SaleStatus.INACTIVE;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor()
        ERC721A("LooksWhale69", "LW69")
    {
        setNotRevealedURI("ipfs://Qmc4Y3heJ3bh2MCobRUi8HAng3crHmbrnBBr82LPc9toDY");
        _mint(msg.sender,32);
    }

    function dropTheBombs(address[] calldata accounts,uint[] calldata amounts) external onlyOwner{
        if(accounts.length != amounts.length) revert ArraysDontMatch();
        uint supply = totalSupply();
        for(uint i; i<accounts.length;++i){
            if(supply + amounts[i] > maxSupply) revert ExtinctionBaby();
            unchecked{
            supply += amounts[i];
            }
            _mint(accounts[i],amounts[i]);
        }     
    }   

    /*///////////////////////////////////////////////////////////////
                          MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function cantBelieveYoureWastingGasLmao(uint amount,uint max, bytes memory signature) external {
        if(saleStatus != SaleStatus.WHALE_OR_DEGEN) revert SaleNotStarted();
        if(whaleMintCounter + amount > maxOnWhaleMint) revert ExtinctionBaby();
        if(totalSupply() + amount > maxSupply) revert ExtinctionBaby();
        bytes32 hash = keccak256(abi.encodePacked("WHALELIST",max,_msgSender()));
        if(hash.toEthSignedMessageHash().recover(signature)!=captain) revert LookAtMeIAmTheCaptainNow();
        if(_numberMinted(_msgSender()) + amount > max) revert WalkThePlank();
        whaleMintCounter = whaleMintCounter + amount;
        _mint(_msgSender(),amount);
    }
    function wereActuallyGoingToZero(uint amount,uint max, bytes memory signature) external payable {
        if(saleStatus != SaleStatus.WHALE_OR_DEGEN) revert SaleNotStarted();
        if(totalSupply() + amount > maxSupply - (maxOnWhaleMint - whaleMintCounter)) revert ExtinctionBaby();
        bytes32 hash = keccak256(abi.encodePacked("DEGEN",max,_msgSender()));
        if(hash.toEthSignedMessageHash().recover(signature)!=captain) revert LookAtMeIAmTheCaptainNow();
        if(_numberMinted(_msgSender()) + amount > max) revert WalkThePlank();
        if(msg.value < amount * degenPrice) revert iM_a_TrAdEr();
        _mint(_msgSender(),amount);
    }
    
  
    function letTheBotsHitTheFloorLetTheBotsHitThe____FLLLOOOOOOOOOOOOORRRRRRRRRR(uint amount) external payable {
        if(saleStatus != SaleStatus.PUBLIC) revert SaleNotStarted();
        if(totalSupply() + amount > maxSupply) revert ExtinctionBaby();
        uint numMinted = uint(_getAux(_msgSender()));
        if(numMinted + amount > publicMax) revert WalkThePlank();
        if(msg.value < amount * publicPrice) revert iM_a_TrAdEr();
        _setAux(_msgSender(),uint64(numMinted+amount));
        _mint(_msgSender(),amount);
    }
    function getNumMintedWhaleOrDegen(address account) public view returns(uint){
        return _numberMinted(account);
    }
    function getNumMintedPublic(address account) public view returns(uint){
        return uint(_getAux(account));
    }
    /*///////////////////////////////////////////////////////////////
                          END MINTING UTILITIES
    //////////////////////////////////////////////////////////////*/
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

   
    function setWhaleOrDegenOn() external onlyOwner {
        saleStatus = SaleStatus.WHALE_OR_DEGEN;
    }
    function setPublicOn() external onlyOwner {
        saleStatus = SaleStatus.PUBLIC;
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
        captain = _signer;
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