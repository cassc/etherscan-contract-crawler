// SPDX-License-Identifier: MIT

//BUBBLEPEEPEE - GACHA-MINT IMPLEMENTATION
/*******************************************************************************
//******************************************************************************
//******************************************************************************
//***********************************@@,,,,,,*@@,*******************************
//*******************************(@,,,,    ,**,,,,@*****************************
//******************************@,,,,    ,,,,****,,(/***************************
//******************************%,  ,,,,,,,,*****,,,&***************************
//******************************@,,,..,,,,,,,,,,,,,@****************************
//****************@,,  ,,,&*******@,,,,,,,,,,,,,,@/*******@@%*******************
//**************&*.  ,,,,,%**********#@,,,****@*********((.  *((****************
/////////////////%,,,,,%@/////////**#@%********@*//////////@@@&/////////////////
//////////////////////////*@@#,,,,,,,,,,,,,,,,,,,***,*@@#///////////////////////
/////////////////////*@&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*@(//////////////////
//////////////////%@,,,,    ..       ..,,,,,,,,,,,,,,,,,..  ,,,#@///////////////
////////////////@,,,,@.,,..          ,,,,,,,,,,******,,,,,.,.   ,,@(////////////
//////////////@,,,,,,,... .     .,....,,,,,,,,,*****&&**&@@,,,..  ,,@///////////
////////////#(,,,,,*@.,   ,,@*.........,,,,,,,,***@,       ,@,,,.. ,,*&/////////
///////////(#,,,,,%%,        ,@.....,,,,,,,,,,****, &       ,&#,,,..,,*#////////
///////////@,,,,,,@,      &%%@@.,,,,,,,,,,,,*****(@(%&      ,@&,,,,.,,,@////////
///////////@,,.,,,(@,,    ./@&,,,,,,,,,,,**********(&@@@@@%(/,,,,,,,,,,@////////
///////////@,,.,,,,,,,*****,,,,,,,,,***********************,,,,,,,,.,,,@////////
//*********@%,..********************,********,**********,,,,,,,,,,,,,,@*********
//***********@,,.,,,,,,,,,,***********&@%&@(/*******,,,,******,,,,,,,@**********
//************&,,..,,,,,,,,,,,,,,,,,,,%,,(.,#*,,,,,,,,********,,,,,@/***********
//**************&%,,,,,,,,,,,,,,,,,,,,,&...%,,,,,,,,,,**,**,,,,,,@**************
//*****************@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@/****************
//********************,@@.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#@/********************
//**************************,@@@/,,,,,,,,,,,,,,,,,@@@(,*************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//*****************************************************************************/

//We hope to bring a new innovative way of minting for the NFTs and inspire other NFT projects in little bit possible

pragma solidity >=0.8.0 <0.9.0;

//STANDARD ERC721
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract BubblePeePee is ERC721, Ownable, ERC2981 {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;
  
  // Constant
  string public constant uriSuffix = ".json";
  uint256 public constant maxGoldSupply = 377;
  uint256 public constant maxSupply = 10000;
  uint256 public constant maxMintAmountPerTx = 10;
  uint256 public constant earlyCost = 0.1 ether;
  uint256 public constant maxClaim = 1000;

  // Used for random index assignment
	mapping(uint256 => uint256) public tokenMatrix;
  // Used for gacha %
  mapping(address => uint256) public gachaMatrix;
  // Used for early pee
  mapping(address => bool) public interactionPercentMatrix;
  mapping(address => bool) public earlyPercentMatrix;
  uint256 public currentClaim = 0;
  // Used for minter
  address[] public minterAddresses;

  // Changable variables
  string public uriPrefix = "https://bubblepeepee.mypinata.cloud/ipfs/QmUDv1zLAcCeRTkqHjzcqAmZy729y4YMV12MvtQ2UUZ7b5/"; //BaseURI
  uint256 public leftOverGoldSupply = maxGoldSupply;
  uint256 public cost = 0.15 ether;
  uint256 public endEarlyCostTimestamp = 1660222800; //11 Aug, 1pm UTC
  bool public paused = true;

  address private w1 = 0x2bec3429F1A11879534f1507940d9db06d64E90D;
  address private r1 = 0x0ec7e83F1ea2288Fd84832EbfF5C6B1F6d8ECa2a;

  constructor() 
    ERC721("BubblePeePee", "BPP") { 
      setDefaultRoyalty(r1, 500); //5%
    }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }
  
  function checkEarlyPeeActive() public view returns (bool) {
    if(block.timestamp <= endEarlyCostTimestamp) {
      return true;
    }
    return false;
  }

  function mint(uint256 _mintAmount) public payable {
    require(!paused, "The contract is paused!");
    require(_msgSender() == tx.origin, "Contracts cannot mint");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");

    if(msg.sender != owner()) {
      if(checkEarlyPeeActive()) {
        require(msg.value >= earlyCost * _mintAmount, "Insufficient funds!");
      } else {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
      }
    }

    _mintRandom(msg.sender, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  //For member checking after sold out
  function isMember(address _address) public view returns (bool) {
    uint256[] memory ownedTokenIds = walletOfOwner(_address);
    
    if(ownedTokenIds.length >= 24) {
      return true;
    } else {
      for(uint256 i = 0; i < ownedTokenIds.length; i++) {
        if(ownedTokenIds[i] <= maxGoldSupply) {
          return true;
        }
      }
    }

    return false;
  }

//ONLY OWNER
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setDefaultRoyalty(address _receiver, uint96 _royaltyPercent) public onlyOwner {
    _setDefaultRoyalty(_receiver, _royaltyPercent);
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setInteractionPercentMatrix(address[] calldata _interactionAddresses) public onlyOwner {
    for (uint i=0; i< _interactionAddresses.length ; i++) {
        interactionPercentMatrix[_interactionAddresses[i]] = true;
    }
  }

  function setEndOfEarlyCost(uint256 _timestamp) public onlyOwner {
    endEarlyCostTimestamp = _timestamp;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(w1).call{value: address(this).balance}("");
    require(os);
  }

  function raffleMinter() public view onlyOwner returns (address) {
    uint256 randomNumber = uint256(
			keccak256(
				abi.encodePacked(
					msg.sender,
          tx.gasprice,
					block.number,
					block.difficulty,
					block.timestamp,
          address(this),
          minterAddresses.length
				)
			)
		);
    uint256 random = randomNumber % minterAddresses.length;

    return minterAddresses[random];
  }

//INTERNAL
  // Randomly gets a new token ID and keeps track of the ones that are still available then return next token ID
  // Check the gacha percentage of the current minter to increase their percent per mint
  // Give the ideal minting percentage to the minter to acquire exclusive NFT
	function nextIndex() internal returns (uint256) {

    uint256 maxIndex = maxSupply - supply.current();
    uint256 maxGachaIndex = maxIndex;

    //Recurring gacha user will increase the %
    if (leftOverGoldSupply > 0) {

      if(gachaMatrix[msg.sender] > 0) {
         uint256 currentHitCount = gachaMatrix[msg.sender];

        //Max gacha %
        if(currentHitCount > 50) {
          currentHitCount = 50;
        }

        uint256 currentPercent = currentHitCount * 100 / 100;
        uint256 idealAmount = maxIndex;

        if(currentPercent != 0) {
          idealAmount = leftOverGoldSupply * 100 / currentPercent;

          //Use market since it's more favorable
          if(idealAmount >= maxIndex) {
            idealAmount = maxIndex;
          }
        }
        
        maxGachaIndex = idealAmount;
      } else {
        if(interactionPercentMatrix[msg.sender]) {
          uint256 idealAmount = leftOverGoldSupply * 100 / 5;

          //Use market since it's more favorable
          if(idealAmount >= maxIndex) {
            idealAmount = maxIndex;
          }

          maxGachaIndex = idealAmount;
          interactionPercentMatrix[msg.sender] = false;
        } else if(!earlyPercentMatrix[msg.sender] && currentClaim <= maxClaim) {
          uint256 idealAmount = leftOverGoldSupply * 100 / 5;

          //Use market since it's more favorable
          if(idealAmount >= maxIndex) {
            idealAmount = maxIndex;
          }

          maxGachaIndex = idealAmount;
          earlyPercentMatrix[msg.sender] = true;
          currentClaim++;
        }
      }
    }

		uint256 randomNumber = uint256(
			keccak256(
				abi.encodePacked(
					msg.sender,
          tx.gasprice,
					block.number,
					block.difficulty,
					block.timestamp,
          address(this),
          maxGachaIndex
				)
			)
		);
    uint256 random = randomNumber % maxGachaIndex;

		uint256 value = 0;
    random++; //Avoid index 0
		if (tokenMatrix[random] == 0) {
			// If this matrix position is empty, set the value to the generated random number.
			value = random;
		} else {
			// Otherwise, use the previously stored number from the matrix.
			value = tokenMatrix[random];
		}

		// If the last available tokenID is still unused...
		if (tokenMatrix[maxIndex] == 0) {
			// ...store that ID in the current matrix position.
			tokenMatrix[random] = maxIndex;
		} else {
			// ...otherwise copy over the stored number to the current matrix position.
			tokenMatrix[random] = tokenMatrix[maxIndex];
		}

    gachaMatrix[msg.sender]++;
    supply.increment();

    //Reset gacha %
    if(value <= maxGoldSupply) {
      gachaMatrix[msg.sender] = 0;

      if(tokenMatrix[leftOverGoldSupply] == 0) {
        tokenMatrix[leftOverGoldSupply] = tokenMatrix[random];
        tokenMatrix[random] = leftOverGoldSupply;
      }
      else {
        uint256 temp = tokenMatrix[leftOverGoldSupply];
        tokenMatrix[leftOverGoldSupply] = tokenMatrix[random];
        tokenMatrix[random] = temp;
      }

      leftOverGoldSupply--;
    }

		return value;
	}

  function _mintRandom(address _receiver, uint256 _mintAmount) internal {
		for (uint256 i = 0; i < _mintAmount; i++) {
      uint256 id = nextIndex();
      minterAddresses.push(_receiver);
      _safeMint(_receiver, id);
    }
	}

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}