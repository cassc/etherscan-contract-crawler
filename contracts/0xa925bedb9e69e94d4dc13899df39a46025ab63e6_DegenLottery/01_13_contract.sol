// SPDX-License-Identifier: Unlicensed
// Developer - ReservedSnow (https://linktr.ee/reservedsnow)

/*

  _____  ______ _____ ______ _   _   _      ____ _______ _______ ______ _______     __ 
 |  __ \|  ____/ ____|  ____| \ | | | |    / __ \__   __|__   __|  ____|  __ \ \   / / 
 | |  | | |__ | |  __| |__  |  \| | | |   | |  | | | |     | |  | |__  | |__) \ \_/ /  
 | |  | |  __|| | |_ |  __| | . ` | | |   | |  | | | |     | |  |  __| |  _  / \   /   
 | |__| | |___| |__| | |____| |\  | | |___| |__| | | |     | |  | |____| | \ \  | |    
 |_____/|______\_____|______|_| \_| |______\____/  |_|     |_|  |______|_|  \_\ |_|    
                                                                                       
                                                                                        
*/



import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'erc721a/contracts/ERC721A.sol';


pragma solidity >=0.8.15 <0.9.0;

contract DegenLottery is ERC721A, Ownable, ReentrancyGuard, ERC2981 {

  using Strings for uint256;

// ================== Variables Start =======================

  string internal uri;
  string public suffix= ".json";
  string public hiddenMetadataUri;
  uint256 public price = 0 ether;
  uint256 public supplyLimit = 5555;
  uint256 public maxMintAmountPerTx = 4;
  uint256 public maxLimitPerWallet = 4;
  bool public publicSale = false;
  bool public revealed = true;
  mapping(address => uint256) public mintCountByAccount;
  uint256 internal Winner;
  string public contractURI = "";
  uint96 royaltyFraction = 1000;

// ================== Variables End =======================  

// ================== Constructor Start =======================

  constructor(
    string memory _uri
  ) ERC721A("Degen Lottery", "DGLT")  {
    seturi(_uri);
    _mint(msg.sender, 1);
    setRoyaltyInfo(address(this), royaltyFraction);
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================

  function PublicMint(uint256 _mintAmount) public payable {
    
    // Normal requirements 
    require(publicSale, 'The PublicSale is paused!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(mintCountByAccount[msg.sender] + _mintAmount <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= price * _mintAmount, 'Insufficient funds!');

    // Mapping update 
    mintCountByAccount[msg.sender] += _mintAmount;

    // Mint
     _safeMint(_msgSender(), _mintAmount);
  }  

  function Airdrop(uint256 _mintAmount, address destination) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(destination, _mintAmount);
  }

// ================== Mint Functions End =======================  

// ================== Set Functions Start =======================

  function ConfigureCollection(string memory _uri, uint256 _costInWEI, uint256 _supplyLimit, uint256 _maxMintAmountPerTx, uint256 _maxLimitPerWallet) public onlyOwner {
     uri = _uri;
     price = _costInWEI;
     supplyLimit = _supplyLimit;
     maxMintAmountPerTx = _maxMintAmountPerTx;
     maxLimitPerWallet = _maxLimitPerWallet;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function togglepublicSale() public onlyOwner {
    publicSale = !publicSale;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

  function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
  }  

  function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
  }

  function setRoyaltyTokens(uint _tokenId, address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setTokenRoyalty(_tokenId ,_receiver, _royaltyFeesInBips);
    }    
 

// ================== Set Functions End =======================

// ================== Withdraw Function Start =======================
  
  function withdrawEthToGoldenWinner(address _winnerAddress) public onlyOwner nonReentrant {
    uint balance = address(this).balance;
    payable(_winnerAddress).transfer(balance * 1000 / 1000); // winner
  }

  function withdrawEthToWinner(address _winnerAddress) public onlyOwner nonReentrant {
      uint balance = address(this).balance;
      payable(_winnerAddress).transfer(balance * 500 / 1000); // winner
      payable(0x077f13f2241149B03DacbF802e82F9F4AcAC1Dc3).transfer(balance * 125 / 1000);
      payable(0xf9C5b24A98298c602B5fA45e1AB01cb0072FCedf).transfer(balance * 250 / 1000);
      payable(0x0831f57D496429942Ad8afa2FfF8a92Ae371e215).transfer(balance * 125 / 1000);
    }  

  function withdrawERC20TokenToWinner(address _tokenContract, address _winnerAddress) external {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(_winnerAddress, balance * 500 / 1000); // winner
        tokenContract.transfer(0x077f13f2241149B03DacbF802e82F9F4AcAC1Dc3, balance * 125 / 1000);
        tokenContract.transfer(0xf9C5b24A98298c602B5fA45e1AB01cb0072FCedf, balance * 250 / 1000);
        tokenContract.transfer(0x0831f57D496429942Ad8afa2FfF8a92Ae371e215, balance * 125 / 1000);
    }

  function withdrawERC20TokenToGoldednWinner(address _tokenContract, address _winnerAddress) external {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(_winnerAddress, balance * 1000 / 1000); // winner
    }      

// ================== Withdraw Function End=======================  

// ================== Read Functions Start =======================

  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
        uint256[] memory a = new uint256[](balanceOf(owner)); 
        uint256 end = _nextTokenId();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        for (uint256 i; i < end; i++) {
            TokenOwnership memory ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                a[tokenIdsIdx++] = i;
            }
        }
        return a;    
    }
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
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(),suffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  function contractBalance() public view returns (uint256 Ether) {
    return address(this).balance / 1e18;
  }

  event ethReceived(address, uint);
    receive() external payable {
        emit ethReceived(msg.sender, msg.value);
    }


  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }   

  function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) internal override(ERC721A) {
        ERC721A._beforeTokenTransfers(from, to, tokenId,quantity);
        payable(owner()).transfer( msg.value * royaltyFraction / 10000); // mint included
  }

// ================== Read Functions End =======================  

// ================== Lottery Winner Drawing Function Start =======================

    function getRandom()internal returns (uint256){   
      uint updatedNumAvailable = 9999;
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this),
                    updatedNumAvailable
                )
            )
        );
        uint256 randomIndex = randomNum % updatedNumAvailable;
        return randomIndex;
    }

    function getWinningNumber() public onlyOwner{
       uint256 winningNum = getRandom();
       Winner = winningNum;
    }

    function currentWinner() public view returns (uint256 CurrentWinnerIs){
      return Winner;
    }



// ================== Lottery Winner Drawing Function End =======================

// Developer - ReservedSnow (https://linktr.ee/reservedsnow)

}