//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//0xSimon_

error SoldOut();
error SaleNotActive();
error Underpriced();
error MaxMints();
error NotOwner();
error NotWhitelisted();
error AlreadyRedeemed();
error NotEligibleForRedemption();
error MaxRedemptions();

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";




contract UnicornClub is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    //Supply & Price
    uint public maxSupply = 5150;
    uint public presalePrice = .042 ether; 
    uint public publicPrice = .042 ether; 
    uint public maxPresaleMints = 9;
    //Whitelist Signer
    address private signer = 0x034ff4C93eFD09Cc00f93ba35d79539D49924134;
    //Sale Switches
    enum SaleStatus {INACTIVE,OG,PRESALE,PUBLIC}
    SaleStatus public saleStatus = SaleStatus.PUBLIC;
    bool public revealed = true;   
    //Token Factory
    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = ".json";
    mapping(address =>uint256) public presaleMints;
    mapping(address => bool) public isEligibleForSecondRedemption;
    mapping(address => uint) public numRedemptions;

    constructor()
        ERC721A("Unicorn Club", "UCLUB")

    {
        setBaseURI("ipfs://QmVrf2do5VgMALcDqdfPyoYfX5eBoL2x6ufmRJGzf1532v/");
    }

    /*///////////////////////////////////////////////////////// 
                            MINT UTILITY
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function teamMint(address to ,uint256 amount) public onlyOwner  {
        if(amount + totalSupply() > maxSupply ) revert SoldOut();
        _mint(to,amount);
    }

    function airdrop(address[] calldata accounts, uint[] calldata amounts) external onlyOwner{
        require(accounts.length == amounts.length,"Arrays Must Match");
        for(uint i; i <accounts.length;i++){
            if(amounts[i] + totalSupply() > maxSupply) revert SoldOut();
            _mint(accounts[i],amounts[i]);
        }
    }

    function publicMint(uint256 amount) external payable nonReentrant{
        if(saleStatus != SaleStatus.PUBLIC) revert SaleNotActive();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        if(msg.value < amount * publicPrice) revert Underpriced();
        _mint(msg.sender,amount);  
    }
    
    function presaleMint(uint256 amount, uint256 max, bytes memory signature)  external payable nonReentrant {

        uint extraFreeMints;
        bytes32 hash = keccak256(abi.encodePacked("PRESALE",max,msg.sender));
        if( hash.toEthSignedMessageHash().recover(signature) != signer) revert NotWhitelisted();
        if(saleStatus != SaleStatus.PRESALE) revert SaleNotActive();
        if(msg.value < amount * presalePrice) revert Underpriced();
        if(presaleMints[msg.sender] + amount > max) revert MaxMints();
        presaleMints[msg.sender]+=amount;
        
        //If wl user hasn't gotten a free mint yet, give them a free mint
        if(numRedemptions[msg.sender] == 0){
            numRedemptions[msg.sender]++;
            extraFreeMints++;
        }
        if(totalSupply() + amount + extraFreeMints > maxSupply) revert SoldOut();


        _mint(msg.sender,amount + extraFreeMints);
    }
    
    function ogMint(uint256 amount, uint256 max, bytes memory signature)  external payable nonReentrant {
        bytes32 hash = keccak256(abi.encodePacked("OG",max,msg.sender));
        if(hash.toEthSignedMessageHash().recover(signature) != signer) revert NotEligibleForRedemption();
        uint extraFreeMints;

        if(saleStatus != SaleStatus.OG) revert SaleNotActive();
        if(msg.value < amount * presalePrice) revert Underpriced();
        if(presaleMints[msg.sender] + amount > max) revert MaxMints();
        presaleMints[msg.sender]+=amount;
        if(presaleMints[msg.sender] >= maxPresaleMints) isEligibleForSecondRedemption[msg.sender] = true;
        
        // If OG hasnt redeemed and is not minting 10 give them one extra
        if(numRedemptions[msg.sender] == 0 && presaleMints[msg.sender] < maxPresaleMints){
            numRedemptions[msg.sender]++;
            extraFreeMints++;
        }
        //If OG has redeemed once and decided to max mint the 9. Give them one extra
        if(numRedemptions[msg.sender] == 1 && presaleMints[msg.sender] >=maxPresaleMints){
            numRedemptions[msg.sender]++;
            extraFreeMints++;
        }
        //If Og hasnt redeemed and is minting 10, give them 2 extra
        if(numRedemptions[msg.sender] == 0 && presaleMints[msg.sender] >= maxPresaleMints){
            numRedemptions[msg.sender] += 2;
            extraFreeMints+=2;
        }
        if(totalSupply() + amount + extraFreeMints > maxSupply) revert SoldOut();
        
        _mint(msg.sender,amount + extraFreeMints);
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

    function setPublicOn() external onlyOwner{
        saleStatus = SaleStatus.PUBLIC;
    }
    function setPresaleOn() external onlyOwner{
        saleStatus = SaleStatus.PRESALE;
    }
    function setOgOn() external onlyOwner {
        saleStatus = SaleStatus.OG;
    }
    function setAllSalesOff() external onlyOwner{
        saleStatus = SaleStatus.INACTIVE;
    }

    function setPresalePrice(uint256 _newPrice) external onlyOwner {
        presalePrice = _newPrice;
    }
    function setPublicPrice(uint256 _newPrice) external onlyOwner {
        publicPrice = _newPrice;
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
                ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId),uriSuffix))
                : "";
    }



     /*///////////////////////////////////////////////////////// 
                            WITHDRAW
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    (bool r1, ) = payable(0x5C3BD2f60cEd2c1ce8823697665E61Fe030230b0).call{value: balance * 4950/10000}(""); //TURO
    (bool r2, ) = payable(0x866d8Ec5E7072d9eD50b3E535d3De7Afd51f689a).call{value: balance * 4950/10000}(""); //
    (bool r3, ) = payable(0x6884efd53b2650679996D3Ea206D116356dA08a9).call{value: balance * 100/10000}(""); //DEV
    require(r1 && r2 && r3);
    }

   
    


}