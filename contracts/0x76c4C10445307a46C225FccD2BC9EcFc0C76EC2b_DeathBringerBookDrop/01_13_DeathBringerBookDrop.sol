// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

// ISBN Hardcover: 978-3-910579-00-2	
// ISBN Paperback: 978-3-910579-01-9	
// ISBN eBook: 978-3-910579-02-6
// ISBN Audiobook: 978-3-910579-03-3

// oooooooooo.                           .   oooo                oooooooooo.            o8o                                            
// `888'   `Y8b                        .o8   `888                `888'   `Y8b           `"'                                            
//  888      888  .ooooo.   .oooo.   .o888oo  888 .oo.            888     888 oooo d8b oooo  ooo. .oo.    .oooooooo  .ooooo.  oooo d8b 
//  888      888 d88' `88b `P  )88b    888    888P"Y88b           888oooo888' `888""8P `888  `888P"Y88b  888' `88b  d88' `88b `888""8P 
//  888      888 888ooo888  .oP"888    888    888   888  8888888  888    `88b  888      888   888   888  888   888  888ooo888  888     
//  888     d88' 888    .o d8(  888    888 .  888   888           888    .88P  888      888   888   888  `88bod8P'  888    .o  888     
// o888bood8P'   `Y8bod8P' `Y888""8o   "888" o888o o888o         o888bood8P'  d888b    o888o o888o o888o `8oooooo.  `Y8bod8P' d888b    
//                                                                                                       d"     YD                     
//                                                                                                       "Y88888P'                     
                                                                                                                                    




contract DeathBringerBookDrop is ERC1155, Ownable, DefaultOperatorFilterer {
    
  string public name;
  string public symbol;
  //token id 0
  uint256 public maxSupplyBronze = 2000;
  //token id 1
  uint256 public maxSupplySilver = 500;
  uint256 public totalSupply;
  uint256 public totalMinted;
  uint256 public totalMintedBronze;
  uint256 public totalMintedSilver;
  uint256 public maxMintPerWallet = 10;
  uint256 public priceBronze = 0.02 ether;
  uint256 public priceSilver = 0.05 ether;
  
  


  mapping (address => uint256) public publicsaleAddressMintedBronze;
  mapping (address => uint256) public publicsaleAddressMintedSilver;
  mapping(uint => string) public tokenURI;

  enum State { OFF, PUBLIC }
  State public saleState = State.OFF;


  constructor() ERC1155("") {
    name = "Death Bringer Book Drop";
    symbol = "DBBD";
  }



  function mintBronze(uint _amount) external payable {
    require(msg.value == priceBronze * _amount, "NOT ENOUGH ETH SENT");
    require(_amount <= 10, "JUST 10 NFT PER TXN");
    require(saleState == State.PUBLIC, "Sale is not active");
    require(totalMintedBronze + _amount <= maxSupplyBronze , "Your mint would exceed max supply");
    require(publicsaleAddressMintedBronze[msg.sender] + _amount <= maxMintPerWallet, "Can only mint 10 per wallet");
     totalMintedBronze = totalMintedBronze + _amount;
     totalSupply = totalMintedBronze + totalMintedSilver;
     publicsaleAddressMintedBronze[msg.sender] += _amount;
     _mint(msg.sender, 0, _amount, ""); 
  }

   function mintSilver(uint _amount) external payable {
    require(msg.value == priceSilver * _amount, "NOT ENOUGH ETH SENT");
    require(_amount <= 1, "JUST 1 NFT PER TXN");
    require(saleState == State.PUBLIC, "Sale is not active");
    require(totalMintedSilver + _amount <= maxSupplySilver , "Your mint would exceed max supply");
    require(publicsaleAddressMintedSilver[msg.sender] + _amount <= maxMintPerWallet, "Can only mint 10 per wallet");
     totalMintedSilver = totalMintedSilver + _amount;
     totalSupply = totalMintedSilver + totalMintedBronze;
     publicsaleAddressMintedSilver[msg.sender] += _amount;
     _mint(msg.sender, 1, _amount, ""); 
  }

    function mintAuctionPieces(uint _amount, uint256 _tokenId) external onlyOwner {
     _mint(msg.sender, _tokenId, _amount, "");
     totalSupply++;
  }

  

  function setURI(uint _id, string memory _uri) external onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }

//Switch sales states

  function disableMint() external onlyOwner {
        saleState = State.OFF;
    } 
    
   function enablePublicMint() external onlyOwner {
        saleState = State.PUBLIC;
    }


    function DevMint(uint _amount, uint256 _tokenId) external onlyOwner {
     _mint(msg.sender, _tokenId, _amount, "");
     totalSupply ++;
  }

  function DevMintBronze(uint _amount) external onlyOwner {
    _mint(msg.sender, 0, _amount, "");
     totalMintedBronze = totalMintedBronze + _amount;
     totalSupply = totalMintedBronze + totalMintedSilver;
  }

  function DevMintSilver(uint _amount) external onlyOwner {
    _mint(msg.sender, 1, _amount, "");
     totalMintedSilver = totalMintedSilver + _amount;
     totalSupply = totalMintedSilver + totalMintedBronze;
  }

  function DevMintPresale(uint _amount) external onlyOwner {
    _mint(msg.sender, 7, _amount, "");
    totalSupply += _amount;
  }


    address public a1 = 0xeDe53D18fD2c1b75Ad3DEc1331a00296d3436644;
    function withdrawFunds() external onlyOwner {
              
        uint256 _balance = address(this).balance;  
        require(payable(a1).send(_balance));
   
    }




        function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

}