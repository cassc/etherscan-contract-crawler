//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UglyDuck is ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 9999;
    uint256 public currentSupply = 0;

    uint256 public p1Limit = 2000;
    uint256 public p1Minted = 0;

    uint256 public p2Limit = 3000;
    uint256 public p2Minted = 0;

    uint256 public maxPerWallet = 1;
    uint256 public phase = 0;

    address private freeAddress = address(0x06c77D5fF190e1930b2A4FFC4E010afd5690B083);
    address private wallet = address(0x88a79630bd588e0b49b6F4B5822baA225958304F);

    string private baseURI;
    string private notRevealedUri = "ipfs://";

    bool public revealed = false;
    bool public baseLocked = false;

    mapping( address => uint256 ) public mintLog;

    constructor()
        ERC721("Ugly Duck WTF", "UglyDuck")
    {
        transferOwnership( msg.sender );
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address( this ).balance;
        payable( wallet ).transfer( _balance );
    }

    function setWallet( address _newWallet ) public onlyOwner {
        wallet = _newWallet;
    }

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    function setMaxPerWallet( uint256 _amount ) external onlyOwner {
        maxPerWallet = _amount;
    }

    function validateSignature( address _addr, bytes memory _s ) internal view returns (bool){
        bytes32 messageHash = keccak256(
            abi.encodePacked( address(this), msg.sender)
        );

        address signer = messageHash.toEthSignedMessageHash().recover(_s);

        if( _addr == signer ) {
            return true;
        } else {
            return false;
        }
    }

    //Batch minting
    function mintBatch(
        address to,
        uint256 baseId,
        uint256 number
    ) internal {

        for (uint256 i = 0; i < number; i++) {
            _safeMint(to, baseId + i);
        }

    }

    /**
        Mint-a-Duck WTF WL
     */
    function whitelistMint( uint256 _amount, bytes calldata signature ) external {
        require( phase > 0 && phase < 4, "WTF?!? WL Mint is not active!");
        require(
            validateSignature(
                freeAddress,
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        
        uint256 allowedAmount = 1;

        if( phase == 1 ) {
            //5 WL, 2k NFTs
            allowedAmount = 5;

            require( 
                p1Minted + _amount <= p1Limit, 
                "UglyDuck: You cant mint that many, phase 1 supply exceeded!" 
            );

            p1Minted += _amount;

        } else if( phase == 2 ) {

            //2 WL, 3k NFTs
            allowedAmount = 2;

            require( 
                p2Minted + _amount <= p2Limit, 
                "UglyDuck: You cant mint that many, phase 2 supply exceeded!" 
            );

            p2Minted += _amount;

        } 

        uint256 supply = currentSupply;

        require( 
            mintLog[ msg.sender ] + _amount <= allowedAmount, 
            "UglyDuck: You cant mint that many!." 
        );

        require(
            supply + _amount <= maxSupply,
            "UglyDuck: Mint too large, exceeding the collection supply"
        );


        mintLog[ msg.sender ] += _amount;
        currentSupply += _amount;

        mintBatch(msg.sender, supply, _amount);
    }

    /**
        Mint-a-Duck WTF Public
     */
    function publicMint( uint256 _amount) external {
        require( phase == 4, "WTF?!? Public Mint is not active!");
      
        uint256 supply = currentSupply;

        require( 
            mintLog[ msg.sender ] + _amount <= maxPerWallet, 
            "UglyDuck: You cant mint that many!." 
        );

        require(
            supply + _amount <= maxSupply,
            "UglyDuck: Mint too large, exceeding the collection supply"
        );


        mintLog[ msg.sender ] += _amount;
        currentSupply += _amount;

        mintBatch(msg.sender, supply, _amount);
    }

    function forceMint( uint256 number, address receiver ) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "UglyDuck: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch( receiver, supply, number);
    }

    function ownerMint(uint256 number) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "UglyDuck: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch(msg.sender, supply, number);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI( string memory _notRevealedURI ) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI( string memory _newBaseURI ) public onlyOwner {
        require( baseLocked == false, "Base URI change has been disabled permanently");

        baseURI = _newBaseURI;
    }

    function setPhase( uint256 p ) public onlyOwner {
        require( p >= 0 && p <= 4, "Valid phases are 0 to 4");

        phase = p;
    }

    function setP1Limit( uint256 l ) public onlyOwner {
        p1Limit = l;
    }

    function setP2Limit( uint256 l ) public onlyOwner {
        p2Limit = l;
    }

    //Lock base security - your nfts can never be changed.
    function lockBase() public onlyOwner {
        baseLocked = true;
    }

    // FACTORY
    function tokenURI( uint256 tokenId )
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),'.json'))
                : "";
    }
 
}