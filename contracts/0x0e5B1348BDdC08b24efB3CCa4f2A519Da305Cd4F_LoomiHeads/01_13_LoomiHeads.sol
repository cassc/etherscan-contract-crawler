//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/*
██╗░░░░░░█████╗░░█████╗░███╗░░░███╗██╗  ██╗░░██╗███████╗░█████╗░██████╗░░██████╗
██║░░░░░██╔══██╗██╔══██╗████╗░████║██║  ██║░░██║██╔════╝██╔══██╗██╔══██╗██╔════╝
██║░░░░░██║░░██║██║░░██║██╔████╔██║██║  ███████║█████╗░░███████║██║░░██║╚█████╗░
██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║██║  ██╔══██║██╔══╝░░██╔══██║██║░░██║░╚═══██╗
███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║██║  ██║░░██║███████╗██║░░██║██████╔╝██████╔╝
╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝  ╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═════╝░╚═════╝░
*/
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract LoomiHeads is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 5555;
    uint256 public maxWL = 4300;
    uint256 public publicPrice = 0.088 ether;
    uint256 public presalePrice = 0.066 ether;
    uint256 public reservedForTeam = 100;
    uint256 public teamMints;
    uint256 public maxPublicMints = 3;

    bool public publicSaleStarted = false;
    bool public presaleStarted = false;
    bool public revealed = false;   


      /*  @dev Reference Address to Compare ECDSA Signature
        Fill this in with your own WL Address
        To learn more about signatures check out 
        https://docs.ethers.io/v5/api/signer/#:~:text=A%20Signer%20in%20ethers%20is,on%20the%20sub%2Dclass%20used.
    */ 
    address private whitelistAddress = 0xC95DBB35c338F05e35EF45B014b2EaB8cfbea78B;

    /*@dev holds the address for the LoomiHeads multiSig wallet 
            ***multiSig wallet must be deployed before the main collection to avoid constructor arguments
    */
    address private multiSigAddress = 0xf5b9fb36AEC4B49dE062F700d8eC6c791590A226;

    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = ".json";



      // @dev these mappings track how many one has minted on public and WL respectively
    mapping(address =>uint256) public presaleMints;
    mapping(address =>uint256) public publicMints;

    constructor()
        ERC721A("Loomi Heads", "LOOMI")

    {
        // @dev make sure to keep baseUri as empty string to avoid your metadata being sniped
        setBaseURI("");
        setNotRevealedURI("ipfs://QmfCjj2LMS91xVtMM9rqkKrCkfJRFnMwPdBnK1ptgmcBLQ/hidden.json");
    }



//START SIGNATURE VERIFICATION

      /*  @dev helper function for WL sale
        returns true if reference address and signature match
        false otherwise
        Read more about ECDSA @openzeppelin https://docs.openzeppelin.com/contracts/2.x/utilities    
    */
    function verifyAddressSigner(
        address referenceAddress,
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            referenceAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

     //@dev, helper hash function for WL Mint
    function hashMessage(uint256 number, address sender)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(number, sender));
    }

//END SIGNATURE VERIFICATION


    /* MINTING */

    modifier onlyManic() {
        require(_msgSender() == 0x8De5224E60107a399f717d17e40eAF517c696402,"Not Manic");
        _;
    }
    function teamMint(address to ,uint256 amount) external onlyManic nonReentrant{
        uint256 supply = totalSupply();
        require(teamMints + amount <= reservedForTeam);
        require(supply + amount <= maxSupply,"Sold Out");
        teamMints+=amount;
        _safeMint(to,amount);
    }
    function publicMint(uint256 amount) external payable nonReentrant{
        uint256 supply = totalSupply();
        require(publicSaleStarted,"Public Sale Is Not Active");
        require(supply + amount <= maxSupply,"Public Sold Out!");
        require(msg.value >= amount * publicPrice,"Not Enough ETH Sent");
        require(publicMints[msg.sender] + amount <=maxPublicMints,"You've Maxed Out Your Mints");

         publicMints[msg.sender]+=amount;
        _safeMint(msg.sender,amount);
        
    }

        //@dev The Max Someone Can Mint is Encoded In The Signature. 

    function presaleMint(uint256 amount, uint256 max, bytes memory signature)  external payable nonReentrant {
        uint256 supply = totalSupply();
        require(presaleStarted,"Pre-Sale Is Not Active");
        require(!publicSaleStarted,"Public is Active");
        require(supply + amount <= maxWL,"WL Sold Out!");
        require(verifyAddressSigner(whitelistAddress,hashMessage(max, msg.sender),signature),"Not Authorized for WL");
        require(msg.value >= amount * presalePrice,"Not Enough ETH Sent");
        require(amount + presaleMints[msg.sender] <= max,"You've Maxed Out Your Mints");

        presaleMints[msg.sender]+=amount;
        _safeMint(msg.sender,amount);

        
    }
     /* END MINT */


   


  

    //END GETTERS

    //SETTERS

    function setMaxSupply(uint256 newSupply) external onlyOwner {
        require(newSupply <= maxSupply,"Can't Increase Supply");
        maxSupply = newSupply;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhitelistAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        whitelistAddress = _newAddress;
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


    function setPublicPrice(uint256 _newPrice) external onlyOwner {
        publicPrice = _newPrice;
    }
    function setPresalePrice(uint256 _newPrice) external onlyOwner{
        presalePrice = _newPrice;
    }




    //END SETTERS

 


    // FACTORY

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


    function withdraw() public payable onlyOwner {
    uint256 balance = address(this).balance;

    (bool r1, ) = payable(0x9376b1b8931f3F02B4119665079fb37C91d05464).call{value: balance * 3125/10000}("");
    require(r1);
     (bool r2, ) = payable(0x4D4658b37b1eaB41a7Dca14c7EF90A8835186853).call{value: balance * 1625/10000}("");
    require(r2);
     (bool r3, ) = payable(0x5bBEC70750169fd75c6b428eca849273a25922aD).call{value: balance * 1500/10000}("");
    require(r3);
     (bool r4, ) = payable(0x79FB7f4F1eD90DCC3a9a2200eFf843038C5DFcB5).call{value: balance * 1400/10000}("");
    require(r4);
     (bool r5, ) = payable(0x0c2f8b7D7A7C8979F8297c14d27e76E7909ac1c0).call{value: balance * 1500/10000}("");
    require(r5);
       (bool r6, ) = payable(0xd9d426f049937F4664d6D450D66c6FD46D3E868D).call{value: balance * 500/10000}("");
    require(r6);
     (bool r7, ) = payable(0x6884efd53b2650679996D3Ea206D116356dA08a9).call{value: balance * 350/10000}("");
    require(r7);

    
  }

   
    

  /* Mutli-Sig Setup*/

//   MODIFIER
    modifier onlyAdmin() {
       require(LoomisMultiSig(multiSigAddress).isAdmin(_msgSender()),"Not Admin");
       _;
    }


    function isAdmin() public view returns(bool){
        return LoomisMultiSig(multiSigAddress).isAdmin(_msgSender());
    }


    /* 
        @dev override transferOwnership from Ownable
         transfer ownership with multisig
    */
      function transferOwnership(address newOwner) public virtual override(Ownable) onlyAdmin nonReentrant {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(LoomisMultiSig(multiSigAddress).isTransferOwnershipApproved(),"MultiSig Hasn't Approved Transfer Ownership");
        LoomisMultiSig(multiSigAddress).incrementBallotNumber();
        _transferOwnership(newOwner);
    }

   


}

interface LoomisMultiSig {

  function isAdmin(address sender) external view returns(bool);
  function isTransferOwnershipApproved() external view returns(bool);
  function incrementBallotNumber() external;
 

}