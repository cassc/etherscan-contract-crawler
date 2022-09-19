// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./Interfaces.sol";

//
//
//
//   ________  ________   _______   ________  ___  __        ___    ___      ________  ___       ________      ___    ___ _______   ________  ________      
//  |\   ____\|\   ___  \|\  ___ \ |\   __  \|\  \|\  \     |\  \  /  /|    |\   __  \|\  \     |\   __  \    |\  \  /  /|\  ___ \ |\   __  \|\   ____\     
//  \ \  \___|\ \  \\ \  \ \   __/|\ \  \|\  \ \  \/  /|_   \ \  \/  / /    \ \  \|\  \ \  \    \ \  \|\  \   \ \  \/  / | \   __/|\ \  \|\  \ \  \___|_    
//   \ \_____  \ \  \\ \  \ \  \_|/_\ \   __  \ \   ___  \   \ \    / /      \ \   ____\ \  \    \ \   __  \   \ \    / / \ \  \_|/_\ \   _  _\ \_____  \   
//    \|____|\  \ \  \\ \  \ \  \_|\ \ \  \ \  \ \  \\ \  \   \/  /  /        \ \  \___|\ \  \____\ \  \ \  \   \/  /  /   \ \  \_|\ \ \  \\  \\|____|\  \  
//      ____\_\  \ \__\\ \__\ \_______\ \__\ \__\ \__\\ \__\__/  / /           \ \__\    \ \_______\ \__\ \__\__/  / /      \ \_______\ \__\\ _\ ____\_\  \ 
//     |\_________\|__| \|__|\|_______|\|__|\|__|\|__| \|__|\___/ /             \|__|     \|_______|\|__|\|__|\___/ /        \|_______|\|__|\|__|\_________\
//     \|_________|                                        \|___|/                                           \|___|/                            \|_________|
//                                                                                                                                                          
//                                                                                                                                                          
//                                                                                                                                                          
//                                                                                                                                                          
//                                                                                                                                                          
//                                                                                                                                                          
                                                                                                                                                        
  
contract SneakyPlayers is ERC1155, Ownable, ReentrancyGuard{

    uint public availableNFTs = 1095;   //available for sale
    uint public mintPrice;   
    
    
    string public name = "Sneaky Players - Mr. Smith 2B";
    string public symbol = "SP" ;
    uint256 public totalSupply = 1095;
    string public unrevealedURI;
    string public revealedURI;
    
    bool public revealedStatus = false;

    bool public preSale = false;
    bool public publicSale = false;


    address payable communityWallet = payable(0x249b1C18f1Ab295762AE72B52Ae5C2029B3cAae4); 


    constructor() ERC1155("") {}

    function mint(uint[] memory ids, uint[] memory quantity) external payable  {
        if(!preSale && !publicSale){
            revert("Sale has not been started yet.");
        }
        else{
        address msgSender = msg.sender;
        uint256 idsLength = ids.length;
        uint256 msgValue = msg.value;
    
        require(msgValue >= idsLength * mintPrice, "Not enough Ethers sent");
        require(availableNFTs - idsLength >= 0, "Not Enough NFTs left");
        (bool success,) = communityWallet.call{value:msgValue} ("");  
        require(success == true, "There was a problem in sending the Ethers.");
        _mintBatch(msgSender, ids, quantity, '');
        availableNFTs -= idsLength;
        }
    }


    function setSaleStatus() public onlyOwner{
        preSale = !preSale;
        publicSale = !preSale;

        if(preSale == true){
            setMintPrice(0.025 ether);
        } else if (publicSale == true){
            setMintPrice(0.027 ether);
        }
    }

    function setCommunityWallet(address payable _communityWallet) external onlyOwner nonReentrant{
        require(_communityWallet != address(0) &&
        _communityWallet != 0x000000000000000000000000000000000000dEaD, "address can't be set to address(0) or deadAddress");
        communityWallet = _communityWallet;
    }

    function setMintPrice(uint _newMintPrice) public onlyOwner nonReentrant{
        require(_newMintPrice > 0, "price can't be set to zero");
        mintPrice = _newMintPrice;
    }
    
    function setRevealedURI(string memory _revealedURI) external onlyOwner nonReentrant{
        require(bytes(_revealedURI).length > 0, "URI can't be zero");
        revealedURI = _revealedURI;
    } 

    function setUnrevealedURI(string memory _unrevealedURI) external onlyOwner nonReentrant{
        require(bytes(_unrevealedURI).length > 0, "URI can't be zero");
        unrevealedURI = _unrevealedURI;
    } 


    function setRevealedStatus() external onlyOwner nonReentrant{
        revealedStatus = !revealedStatus;
    }


    function uri(uint256 _id) public view override returns (string memory TOKEN_URI) {
            require(_id > 0 && _id <= 1095, "NONEXISTENT_TOKEN"); 
         
            if(revealedStatus == false){
            TOKEN_URI =  string(bytes(abi.encodePacked(unrevealedURI)));
            } else if(revealedStatus == true){
            TOKEN_URI =  string(bytes(abi.encodePacked(revealedURI,Strings.toString(_id),".json")));
    
        }
    }

}