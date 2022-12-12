// SPDX-License-Identifier: MIT
/** 
                                                  
                              &@@@@@@@@@@@@@@@@@@/                              
                           ,@@@@@@@@&&&&&&&&&@@@@@@@/                           
                        *&&&&&&&&@&&&&&&&&&&&&&&&&@@@&%                         
                      #&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&&&(                       
                     @&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                      
                   (@&&&&@@@@&@&( ,/.#&&&&&&&# .( #&&&&&&&&@     
                 @&@@&&&&@&@&@@&*(* .(&&%(,%&* ,(&&&&&&&&&&&&@                
               #&&&&&@&&&&@&&&&&&&&&&&&. .,. (&&&&&&&&&&&&&&&&&&                
               @&&&&&&&&&&&&&&&&&&&&&&&#///(%&&&&&&&&&&&&&&&&&&&@               
              %&&&&&&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&              
              @&&&&&&&@@@@&&@@&@@@@@@@@@&&&&&@@&&&&@&&&@&&&&&@&&&&              
             &&&&&&&&&&&&@@@@&&@&@@@@&@@@@@@@&@&&@@@@@@@@@&&&&&&&&&@&           
           *&&&&&&&&&&&&&@&&&&&&&&&&&&&&&&@@&@@&&&&&&&&&&&&&&&&&&&&&%           
           *&&&&&&&&&@&&&&@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%%&/          
            &%%%&&&&&&@&&&&&&@&&&@@&&&&&&&&&&&&@&&@&&&&&&&&%%&&&&%%%%           
            (&&%%%&&&&&&&&&&&&&&&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%%##&           
              %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%&&%#%%#&              
              (@%%&%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%&&&&%%%%##                
                &##%%%%&&&%&&&&&&&&&%&%&&&&%&&&&%&&%&&%%%%###(&                 
                  (##%&%%%%%%&%%%&%%%&%%%%&%%%%%%%%%%%%####(                    
                     &##%%%%%%%%%#%%%%%##%%%%%%%%%%((##((.                      
                         .., *@%&@@@     (%&@@      .,                          
                        ...,                       ,.*                          
                      ,.,,.                        ,.,,,                        
                     .. . .                         .....

  _________ ___ ___ .___   _____      _____  ___________ _______      _____    ________    _____   
 /   _____//   |   \|   | /     \    /  _  \ \_   _____/ \      \    /  _  \  /  _____/   /  _  \  
 \_____  \/    ~    \   |/  \ /  \  /  /_\  \ |    __)_  /   |   \  /  /_\  \/   \  ___  /  /_\  \ 
 /        \    Y    /   /    Y    \/    |    \|        \/    |    \/    |    \    \_\  \/    |    \
/_______  /\___|_  /|___\____|__  /\____|__  /_______  /\____|__  /\____|__  /\______  /\____|__  /
        \/       \/             \/         \/        \/         \/         \/        \/         \/                                                                                                        
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
*/

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol";

contract ShimaEnaga is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;

  mapping(address => uint256) public Counter;
  mapping(address => bool) public presaleClaimed;

  bytes32 public merkleRootwl;
  string public uriPrefix = 'ipfs://bafybeiaq7zvwzsaa5rnclkbwbmqssq32cezc4skvrgfy3lnwgkh6va5wwe/';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost1 = 0.03 ether;
  uint256 public cost2 = 0.04 ether;
  uint256 public cost3 = 0.05 ether;
  uint256 public cost4 = 0.06 ether;
  uint256 public cost5 = 0.07 ether;
  uint256 public cost6 = 0.08 ether;
  uint256 public cost7 = 0.09 ether;
  uint256 public cost8 = 0.1 ether;
  uint256 public cost9 = 0.11 ether;
  uint256 public cost10 = 0.12 ether;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerW;

  bool public paused = false;
  bool public revealed = true;
  bool public presaleM = false;
  bool public publicM = true;
  

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxMintAmountPerW,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setMaxMintAmountPerW(_maxMintAmountPerW);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  function currentPrice() public view returns (uint256) {
        require(paused == false, "Sale hasn't started");
        require(totalSupply() < maxSupply, "Sale has already ended");
        uint currentSupply = totalSupply();
        if (currentSupply >= 9000) {
            return cost10;
        } else if (currentSupply >= 8000) {
            return cost9;
        } else if (currentSupply >= 7000) {
            return cost8;
        } else if (currentSupply >= 6000) {
            return cost7;
        } else if (currentSupply >= 5000) {
            return cost6;
        } else if (currentSupply >= 4000) {
            return cost5;
        } else if (currentSupply >= 3000) {
            return cost4;
        } else if (currentSupply >= 2000) {
            return cost3;
        } else if (currentSupply >= 1000) {
            return cost2;
        } else {
            return cost1;
        }
    }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier isValidMerkleProofwl(bytes32[] calldata _proofwl) {
    require(MerkleProof.verify(
    _proofwl,
    merkleRootwl,
    keccak256(abi.encodePacked(msg.sender))
    ) == true, "Not allowed origin");
    _;
}

modifier onlyAccounts () {
    require(msg.sender == tx.origin, "Not allowed origin");
    _;   
}


  function presaleMint(address account,uint256 _mintAmount, bytes32[] calldata _proofwl) public payable mintCompliance(_mintAmount) 
    isValidMerkleProofwl(_proofwl) 
    onlyAccounts {
    // Verify presale requirements
    require(presaleM, 'The presale sale is not enabled!');
    require(!presaleClaimed[_msgSender()], 'Address already claimed!');
    require(msg.sender == account, "Not allowed");
    if (msg.sender != owner()) {
      require(msg.value >= currentPrice() * _mintAmount);
    }
    _safeMint(_msgSender(), _mintAmount);
}    

  function publicSaleMint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, 'The contract is paused!');
    require(publicM, "PublicSale is OFF");
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmountPerTx);
    require(supply + _mintAmount <= maxSupply);
    require(
        Counter[_msgSender()] + _mintAmount <= maxMintAmountPerW,
        "exceeds max per address"
        );
      require(totalSupply() + _mintAmount <= maxSupply, "reached Max Supply");
      
      Counter[_msgSender()] = Counter[_msgSender()] + _mintAmount;
    if (msg.sender != owner()) {
      require(msg.value >= currentPrice() * _mintAmount);
    }

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setcost1(uint256 _cost1) public onlyOwner {
    cost1 = _cost1;
  }  
  function setcost2(uint256 _cost2) public onlyOwner {
    cost2 = _cost2;
  }
  function setcost3(uint256 _cost3) public onlyOwner {
    cost3 = _cost3;
  }
  function setcost4(uint256 _cost4) public onlyOwner {
    cost4 = _cost4;
  }
  function setcost5(uint256 _cost5) public onlyOwner {
    cost5 = _cost5;
  }
  function setcost6(uint256 _cost6) public onlyOwner {
    cost6 = _cost6;
  }
  function setcost7(uint256 _cost7) public onlyOwner {
    cost7 = _cost7;
  }
  function setcost8(uint256 _cost8) public onlyOwner {
    cost8 = _cost8;
  }
  function setcost9(uint256 _cost9) public onlyOwner {
    cost9 = _cost9;
  }
  function setcost10(uint256 _cost10) public onlyOwner {
    cost10 = _cost10;
  }
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function togglePause() public onlyOwner {
    paused = !paused;
}

function setMerkleRoot(bytes32 _merkleRootwl) public onlyOwner {
    merkleRootwl = _merkleRootwl;
}



function togglePresale() public onlyOwner {
    presaleM = !presaleM;
}

function togglePublicSale() public onlyOwner {
    publicM = !publicM;
}


  function setMaxMintAmountPerW(uint256 _maxMintAmountPerW) public onlyOwner {
      maxMintAmountPerW = _maxMintAmountPerW;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}