// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/utils/Strings.sol';


//           ::::::                           ::::.           
//         :::: ::::                        :::::::::         
// :              ::                        ::              : 
// :             :::                        :::             : 
//::            ::::                        ::::            ::
// ::          :::::                        :::::          :: 
//  :::        :::::::                     ::::::        :::: 
//   ::::     :::::::::::::  :  B:::   :::::::::::     ::::   
//     ::::::: ::::::. ::::::: P ::::::: ::::::::  :::::::    
//        ::::::::::::::::: :::::::  ::::::::::::::::::       
//               .:   :::::: BBBBB ::::::  ::::::             
//                    : :::::: BB:::::: ::                    
//               ::: : ::     :::      : : ::::               
//             :: : :::B     ^B  B     B::::::  :             
//              @@@@@ ::::BBBB: :BBBBB:::[email protected]@@@@@@             
//            @@@   @@ ::B. B : ::B .  ::@@   @@@@            
//             @@@@@@ :::: BB::@:: B ::: @@@@@@@@             
//              ::::::: :::::::@::::::: ::::::                
//                      :::::::@::::@::                       
//                       ::@::: :::@::                        
//                        ::@@ @@@@::                         
//                         :::   :::                          
//                           :  ::                            
//                            &&&                             
//                             ::                             
//                             ::                             
//                            ::::                            
//                           ::::::                           
//                 :::::::  :::::::: :::::::                  
//               ::::::::::  BBBBBB  ::::::::::               
//                        B:B ::::B :   B                     
//                :: ::::::: BB BBB::::    :::                
//                ::::: @B:::BBBBB.::[email protected]@ : :::                
//               ::::: @@@:::: BB  :: @@B::::::               
//               ::::::::::::::::: ::::::::::::               
//              ::::: : @@@:: :::: : @@@::::::::              
//              :::::: : @ : BB: BB:: :^:::::::::             
//              :::: :::::: BBBBBBBB:::: : ::::::             
//             ::::: ::  .B:::BBBB :: : :  :::::::            
//             ::::: : ... :B::: :::B:::: B::::::::           
//            :::::: : ... ::: :::B:::::::::::::::::          
//            :::::: ::....::::  :::::::::: ::::::::: 
// The terms of our IP can be found here: 
// ipfs://QmNpaJ9gsF3UsM2evuqTsGiYNncve1KiLzXUAm3UoGsc4T
/**
 * @title Los Diablos Contract
 * @notice This contract handles minting and distribution of Los Diablos tokens.
 */


contract LosDiablos is ERC721AQueryable, ERC2981, Ownable, ReentrancyGuard {

  using SafeMath for uint256;
  using Strings for uint256;
	
  //Metadata
  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  string public contractURI;
  address public royaltyAddress;
  address payable public payments;
  uint256 public royaltyFee;

  // Token Data
  uint256 public mintCost;
  uint256 public maxMintSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public constant reservedTokenSupply = 100;
  uint256 public totalTokensReserved = 0;
  
  
  //Merkle Roots
  bytes32 public merkleRoot;

  //Allowlist Token Counter
  mapping(address => bool) public allowlistAddressesClaimed;  

  // Sale Switches
  bool public isContractPaused = true;
  bool public isAllowlistMintEnabled = false;
  bool public isCollectionRevealed = false;

  constructor(
    string memory name,
    string memory symbol,
    uint256 _mintCost,
    uint256 _maxMintSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
	  uint96 _royaltyFeeInBips,
	  string memory _contractURI,
    address _payments
  ) ERC721A(name, symbol) {
    setCost(_mintCost);
    maxMintSupply = _maxMintSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
	  setRoyaltyInfo(msg.sender, _royaltyFeeInBips);
	  contractURI = _contractURI;
    payments = payable(_payments);
  }

	/* Reserved for Collection Marketing */
	function reserveDiablos(address to, uint256 numOfTokensReserving) public onlyOwner {
			require(
					totalSupply().add(numOfTokensReserving) <= maxMintSupply,
					"This would exceed max supply of Tokens"
			);
			require(
					totalTokensReserved.add(numOfTokensReserving) <= reservedTokenSupply,
					"This would exceed max reservation of Tokens"
			);

			
			_safeMint(to, numOfTokensReserving);
			

			// update totalTokensReserved
			totalTokensReserved = totalTokensReserved.add(numOfTokensReserving);
	}


  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxMintSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= mintCost * _mintAmount, 'Insufficient funds!');
    _;
  }

  // Allowlist Mint
  function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify allowlist requirements
    require(isAllowlistMintEnabled, 'Whitelist sale is not yet active!');
    require(!allowlistAddressesClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    allowlistAddressesClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  // Mint
  function mintDiablo(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!isContractPaused, 'The contract is paused!');

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

    if (isCollectionRevealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  //2981 interface
	function supportsInterface(bytes4 interfaceId)
				public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
  
	//Set and Change Royalty Receiver and Fees
	function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeInBips) public onlyOwner {
				_setDefaultRoyalty(_receiver, _royaltyFeeInBips);
        royaltyAddress = _receiver;
        royaltyFee = _royaltyFeeInBips;
	}

	//Legacy Marketplace Contract Metadata
	function setContractURI(string calldata _contractURI) public onlyOwner {
			contractURI = _contractURI;
	}

  //External Accounts Burn
  function burnDiablo(uint256 tokenId)
    public onlyOwner {
      _burn(tokenId);
  }



  //Setters
  function setRevealed(bool _state) public onlyOwner {
    isCollectionRevealed = _state;
  }

  function setCost(uint256 _mintCost) public onlyOwner {
    mintCost = _mintCost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxMintSuppy(uint256 _maxMintSupply) public onlyOwner {
    maxMintSupply = _maxMintSupply;
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

  function setPaused(bool _state) public onlyOwner {
    isContractPaused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setAllowlistMintEnabled(bool _state) public onlyOwner {
    isAllowlistMintEnabled = _state;
  }


  //Withdraw
  function withdrawBalance() public onlyOwner nonReentrant {
    (bool os, ) = payable(payments).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}