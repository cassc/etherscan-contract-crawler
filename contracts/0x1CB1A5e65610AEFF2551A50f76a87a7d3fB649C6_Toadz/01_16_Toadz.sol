/*
SPDX-License-Identifier: GPL-3.0

                                            TOADZ


MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:',',,''''''''''''''''''',,'''',':0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkolccccccccccccccccccccccccccccccccccookNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMWXKk;.cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.;kKXWMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMNc.,kXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKk,.cNMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMX;  ,::::::::::::oXM0c:::::::::::::kWMMMMMMO. ;XMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMKkxc;'        .,,;,lXMx.        ';,,;xWMMMMMMKc,cxkKMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMWNNl..xM0,      .dWWWWWMMx.       'OMWWWMMMMMMMMMMWx. lNNWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMO;'lO0NMWKOOOOOO0XMMMMMMMN0OOOOOOO0NMMMMMMMMMMMMMMMx. .',OMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMXxl,  'llllllllllllllllllllllllllllllllllllllllldKMMMMx. .clllxXMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMWK0x;..     .....................................  .kMMMMx. lWNl.;x0KWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMX: ,ONo     oXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK: .kMMMMx. lWMNXO, :XMMMMMMMMMMMMMMM
MMMMMMMMMMMMWx;:oxONMd.    .;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;. .kMMMMx. lWMMMNOxo:;xWMMMMMMMMMMMM
MMMMMMMMMMMMNc .kMMMM0c;.  .;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;c0MMMMx. lWMMMMMMk. cNMMMMMMMMMMMM
MMMMMMMMMMMMNc .kMMMMMMWo..dXNWMMMMMMMNXNWMMMMWNXWMMMMMWNXNMMMMMMMMMMWNXd..oWMMMMMMk. cNMMMMMMMMMMMM
MMMMMMMMMMMMNc .kMMMMMMMX0Oc.:0MMMMMMWo.;OMMMMk,'xWWMMMKc.lXMMMMMMMMM0:.cO0XMMMMMMMk. cNMMMMMMMMMMMM
MMMMMMMMMMMMWOlllcxXMMMMMMWklllcxNMMMWOlllcxXMx. lNWWkclllkNMMMMMMNxclllkWMMMMMMMMMk. cNMMMMMMMMMMMM
MMMMMMMMMMMMMMMXl':xOOOOOO0NMKc':xOOOOOOx. '0Mx. lNWX; .oOOOOOOOOOk:':xOOOOOO0NMWKOd;'dWMMMMMMMMMMMM
MMMMMMMMMMMMMMMMNNk'      .xMMWNx. ..      '0Mx. lNWX:          . .xNk'      .xM0, ;0NWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNo,:dkkkkkxkXMMMMXOxkkx'  ckONMx. lNWW0ko. .okxkkkxOXMNOxkkkkkxc;:dk0WMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNd:codddddddddddddddddo'  :dddd;  ,oodddc. .lddddddddddddddddddc:oKMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMM0,..........................................................kMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKNMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/

pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/payment/PaymentSplitter.sol";

contract Toadz is ERC721, PaymentSplitter, Ownable {
    uint256 public constant maxTokens = 6969;    
    uint256 public constant maxMintsPerTx = 10;
    uint256 public tokenPrice = 69000000000000000; //0.069 ether
    uint256 public startingBlock =999999999;
    string private _contractURI;
    string public provenance;
    uint256 public nextTokenId=1;
    bool public devMintLocked = false;
    bool private initialized = false;

    constructor()
        public
        ERC721("Cryptoadz", "TOADZ")
    {    }

    function initializePaymentSplitter (address[] memory payees, uint256[] memory shares_) 
        external 
        onlyOwner 
    {
        require (
            !initialized,
            "Payment Split Already Initialized!"
            );
        require(
            payees.length == shares_.length,
            "PaymentSplitter: payees and shares length mismatch"
            );
        require(
            payees.length > 0, 
            "PaymentSplitter: no payees"
            );

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
        initialized=true;
    }

    //Set Base URI
    function setBaseURI(string memory _baseURI) 
        external 
        onlyOwner 
    {
        _setBaseURI(_baseURI);
    }


    //Set Contract-level URI
    function setContractURI(string memory contractURI_) 
        external 
        onlyOwner 
    {
        _contractURI = contractURI_;
    }


    //View Contract-level URI
    function contractURI() 
        public 
        view 
        returns (string memory) 
    {
        return _contractURI;
    }

    //Provenance may only be set once irreversibly
    function setProvenance(string memory _provenance) 
        external 
        onlyOwner 
    {
        require(
            bytes(provenance).length == 0,
             "Provenance already set!"
             );
        provenance = _provenance;
    }
    
    //Minting
    function mint(uint256 quantity) 
        external 
        payable 
    {
        require(
             block.number >= startingBlock,
             "Sale hasn't started yet!"
        );
        require(
            quantity <= maxMintsPerTx,
            "There is a limit on minting too many at a time!"
        );
        require(
            nextTokenId -1 + quantity <= maxTokens ,
            "Minting this many would exceed supply!"
        );
        require(
            msg.value >= tokenPrice * quantity,
            "Not enough ether sent!"
        );
        require(
            msg.sender == tx.origin,
            "No contracts!"
        );
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, nextTokenId++);
        }
    }

    //Dev mint special tokens
    function mintSpecial(address [] memory recipients, uint256 [] memory specialId) 
        external 
        onlyOwner 
    {        
        require (!devMintLocked,
            "Dev Mint Permanently Locked"
            );
        for (uint256 i = 0; i < recipients.length; i++) {
            require (specialId[i]!=0);
            _safeMint(recipients[i],specialId[i]*1000000);
        }
    }

    function setStartingBlock(uint256 _startingBlock)
        public
        onlyOwner
    {
        startingBlock=_startingBlock;
    }

    function lockDevMint()
        public
        onlyOwner
    {
        devMintLocked=true;
    }

}