//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error SaleNotStarted();
error RoundSoldOut();
error PublicSaleStillLive();
error MaxMints();
error SoldOut();
error ValueTooLow();
error NotWL();
error NotVIP();
error AlreadyMinted();


/*
Contract created by
Twitter: @0xSimon_
*/
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract BTBM is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;


    //@dev adjust these values for your collection
    uint public price = .055 ether; 
    
    uint16 public maxSupply = 4000;

    //testnet value
    uint16 reservedForTeam = 50;
    uint16 teamMints;
    uint8 maxPublicMints = 10;

    //@dev byte-pack bools and address to save gas
    bool public presaleStarted;
    bool public publicStarted;
    bool revealed;


    /*@dev Reference Address to Compare ECDSA Signature
    Fill this in with your own WL Address
    To learn more about signatures check out 
    https://docs.ethers.io/v5/api/signer/#:~:text=A%20Signer%20in%20ethers%20is,on%20the%20sub%2Dclass%20used.*/ 
    address private whitelistAddress = 0xB4383955C070a2C49FefC940d4aCADE471cBcE2b;

    
    /* @dev Used in TokenURI Function for exchanges.
        For more information about this standard check out 
        https://docs.opensea.io/docs/metadata-standards
    */
    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = ".json";


    // @dev these mappings track how many one has minted on public and WL respectively
    mapping(address=>uint8) public tokensMinted;
    mapping(address => uint8) public publicTokensMinted;

    

    constructor()
        ERC721A("Born To Be Me", "BTBM")

    {
        // @dev make sure to keep baseUri as empty string to avoid your metadata being sniped
        setBaseURI("");
        setNotRevealedURI("ipfs://QmbfcBFpFroR3ftceMEoyXwko128M6Nzk4NLfkfhjM6nFL/hidden.json");
        teamMint(0xeDc49086A2CE64A3054141F7569c48B802d94cEa ,50);
        transferOwnership(0x72F12eCC28bbe7C12745A1a0FE52fE48877CbD33);
    }



       //SIGNATURE VERIFICATION

    /*@dev helper function for WL sale
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


    // @dev, helper hash function for WL Mint
    function hashMessage(uint8 max, address sender)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(max, sender));
    }

    //END SIGNATURE VERIFICATION


    /* MINTING */
    function teamMint(address to ,uint8 amount) public onlyOwner{
        uint256 supply = totalSupply();
        require(teamMints + amount <= reservedForTeam);
        if(supply + amount > maxSupply) revert SoldOut();
        teamMints+=amount;
        _safeMint(to,amount);
    }

 
  


    //@dev The Max Someone Can Mint is Encoded In The Signature. Be careful

    function whitelistMint(uint8 amount, uint8 max, bytes memory signature)  external payable nonReentrant {
       uint256 supply = totalSupply();

       if(!verifyAddressSigner(whitelistAddress, hashMessage(max,msg.sender), signature)) revert NotWL();
       if(supply + amount > maxSupply) revert SoldOut();
       if(!presaleStarted) revert SaleNotStarted();
       if(msg.value < amount * price) revert ValueTooLow();
       if(tokensMinted[_msgSender()]>0) revert AlreadyMinted();
       if(tokensMinted[_msgSender()] + amount > max) revert MaxMints();
       
        tokensMinted[msg.sender]+=amount;
        _mint(msg.sender,amount);
        
    }

    function publicMint(uint8 amount) external payable nonReentrant {
        uint supply = totalSupply();
        if(!publicStarted) revert SaleNotStarted();
        if(supply + amount > maxSupply) revert SoldOut();
        if(msg.value < amount * price) revert ValueTooLow();
        if(publicTokensMinted[_msgSender()] + amount > maxPublicMints) revert MaxMints();
        
         publicTokensMinted[msg.sender]+=amount;
         _mint(msg.sender,amount);

    }
     /* END MINT */



    //END GETTERS

    
    //SETTERS

        //@dev Turns Reveal On
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWlAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        whitelistAddress = _newAddress;
    }
   
    function setUriSuffix(string memory _newSuffix) external onlyOwner{
        uriSuffix = _newSuffix;
    }

   
   function setPresaleStatus(bool status) external onlyOwner {
    
       presaleStarted = status;
   }
   function setPublicStatus(bool status) external onlyOwner {
    
    publicStarted = status;
}

function setReservedForTeam(uint16 amount) external onlyOwner {
    reservedForTeam = amount;
}

   



    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }
    

  


    //END SETTERS

 


    // FACTORY

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
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),uriSuffix))
                : "";
    }


    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        (bool r1, ) = payable(owner()).call{value: balance }("");
        require(r1);
  }

}