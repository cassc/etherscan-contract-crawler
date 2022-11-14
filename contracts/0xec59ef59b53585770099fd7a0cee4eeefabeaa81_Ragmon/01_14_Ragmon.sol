//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Ragmon is IERC2981, AccessControl, ERC721ABurnable, ReentrancyGuard {
    //event
    event Withdraw(address _to, uint256 _amount);
    //error
    error IncorrectQuantity();
    error NotInWhitelist();
    error ExceededNFTsLimitPerUser(uint16 _expectedNFTs, uint16 _currentLimitNumber);
    error ExceededNFTsLimit(uint256 _expectedNFTs, uint16 _currentLimitNumber);
    error OutOfNFTs(uint256 _expectedNFTs, uint16 _Maximum);
    error SaleEnds();
    error SaleNotOpen(uint256 _currentTime, uint32 _openingTime);
    error InsufficientValue(uint256 _currentPrice, uint256 _receivedPrice);
    error WithdrawFailed();
    error NoRoyaltyInfo();
    error NeverSetUpTwice();
    error MustBeSameSize(uint256 _userListSize, uint256 _quantitySize);
    error NotInAirdropList();
    using Strings for uint;

    bytes32 public constant MANAGER = 0xaf290d8680820aad922855f39b306097b20e28774d6c1ad35a20325630c3a02c;
    address public constant owner = 0x2fbFD62FD5ED9408c49e55F706AA91c545f73954;
    //royalty
    address public royaltyAddress;
    uint16 public royaltyPercent;

    //Ragmon URI
    string public ragmonURI;
    bool public ragmonURILock;

    //Whitelist
    bytes32 public merkleRoot;
    bytes32 public merkleRootForAirdrop; 

    //The number of 
    struct UserInfo{
        bool joinedAlready;
        bool joinedAirdrop;
        uint16[2] numOfPublicMint;
    }
    mapping(address=>UserInfo) internal users;


    
    uint8 public publicRound = 1;
    uint8 public privateRound = 1;
    uint16 public userPrivateMintLimit = 5;
    uint16[2] public userPublicMintLimit = [10,10];
    uint16 public constant MAXIMUM_NFTS = 10000;
    uint16[2] public privateLimits = [500,500];
    uint16[2] public publicLimits = [2000,3000];
    uint32[2] public privateTimes;
    uint32[2] public publicTimes; 
    uint256 public privatePrice;
    uint256 public publicPrice;
    

 
    constructor(
        string memory name_ ,
        string memory symbol_,
        uint32[2] memory _privateTimes,
        uint32[2] memory _publicTimes,
        uint256 _privatePrice,
        uint256 _publicPrice
    ) 
        ERC721A(name_, symbol_) 
    {
        _setupRole(DEFAULT_ADMIN_ROLE,owner);
        _setupRole(MANAGER,owner);
        _setupRole(MANAGER, msg.sender);
        privateTimes = _privateTimes;
        publicTimes = _publicTimes;
        privatePrice = _privatePrice;
        publicPrice = _publicPrice;
        royaltyAddress = msg.sender;
        royaltyPercent = 7;
    }
    
    function privateMintRagmon(uint16 _quantity, bytes32[] calldata _merkleProof) external payable {
        uint8 _currentRound = privateRound;
        if(_currentRound == 0 || _currentRound>= 3){
            revert SaleEnds();
        }
        uint8 _index = _currentRound-1;
        uint16 _userPrivateMintLimit = userPrivateMintLimit;
        if(_quantity == 0 || _quantity > _userPrivateMintLimit) {
            revert IncorrectQuantity();
        }

   
        uint32 _currentSaleTime = privateTimes[_index];
        if(_currentSaleTime > block.timestamp){
            revert SaleNotOpen(block.timestamp,_currentSaleTime);
        }

        UserInfo storage _currentUserInfo = users[msg.sender];


        if(!MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))||_currentUserInfo.joinedAlready) {
            revert NotInWhitelist(); 
        }
        
        uint16 _currentMintAvailability = privateLimits[_index];
        uint256 _latestId = currentTokenId();
        uint256 _expectedNewNFTs = _latestId+_quantity;

        if(_currentMintAvailability<_quantity) {
            revert ExceededNFTsLimit(_quantity, _currentMintAvailability);
        }

        if (MAXIMUM_NFTS<_expectedNewNFTs) {
            revert OutOfNFTs(_expectedNewNFTs, MAXIMUM_NFTS); 
        }

        uint256 _currentPrice = privatePrice * _quantity;
        if (_currentPrice != msg.value) {
            revert InsufficientValue(_currentPrice, msg.value);
        }

    
        _safeMint(msg.sender, _quantity);
        privateLimits[_index] -= _quantity;
        _currentUserInfo.joinedAlready = true;
    }

    function publicMintRagmon(uint16 _quantity) external payable {
        uint8 _currentRound = publicRound;
        if(_currentRound == 0 || _currentRound>= 3){
            revert SaleEnds();
        }
        uint8 _index = _currentRound-1;
        uint16 _userPublicMintLimit = userPublicMintLimit[_index];
        if(_quantity == 0 || _quantity > _userPublicMintLimit) {
            revert IncorrectQuantity();
        }

    
        uint32 _currentSaleTime = publicTimes[_index];
        if(_currentSaleTime > block.timestamp){
            revert SaleNotOpen(block.timestamp,_currentSaleTime);
        }

        UserInfo storage _currentUserInfo = users[msg.sender];

        uint16 _expectedUserMintedNFTs = _currentUserInfo.numOfPublicMint[_index] + _quantity;
        if( _expectedUserMintedNFTs > _userPublicMintLimit) {
            revert ExceededNFTsLimitPerUser(_expectedUserMintedNFTs, _userPublicMintLimit);
        }

        uint16 _currentMintAvailability = publicLimits[_index];
        uint256 _latestId = currentTokenId();
        uint256 _expectedNewNFTs = _latestId+_quantity;
        if (MAXIMUM_NFTS<_expectedNewNFTs) {
            revert OutOfNFTs(_expectedNewNFTs, MAXIMUM_NFTS); 
        }
       if(_currentMintAvailability<_quantity) { // 이부분 다시 한번 분석해서 봐야함 기준점 필요 // set current Limit 에서 지정하던지
            revert ExceededNFTsLimit(_quantity, _currentMintAvailability);
        }

        uint256 _currentPrice = publicPrice * _quantity;
        if (_currentPrice != msg.value) {
            revert InsufficientValue(_currentPrice, msg.value);
        }

   
        _safeMint(msg.sender, _quantity);
        _currentUserInfo.numOfPublicMint[_index] = _expectedUserMintedNFTs;
        publicLimits[_index] -= _quantity;
      
    }
 
    function airdropNfts(address[] calldata _users, uint256[] calldata _quantity) external onlyRole(MANAGER) {
        uint256 _size = _users.length;
        if(_size != _quantity.length) {
            revert MustBeSameSize(_size,_quantity.length);
        }
        uint256 _latestId = currentTokenId();
     
        uint256 _expectedNewNFTs = _latestId + _size;
        if (MAXIMUM_NFTS<_expectedNewNFTs) {
            revert OutOfNFTs(_expectedNewNFTs, MAXIMUM_NFTS); 
        }

        for (uint i = 0; i < _size; ++i) {
            _safeMint(_users[i], _quantity[i]);
          
        }
   
    }

    function mintForAirdropList(uint16 _quantity, bytes32[] calldata _merkleProof) external  {
        uint256 _latestId = currentTokenId();
        uint256 _expectedNewNFTs = _latestId + _quantity;
        if (MAXIMUM_NFTS<_expectedNewNFTs) {
            revert OutOfNFTs(_expectedNewNFTs, MAXIMUM_NFTS); 
        }
        
        UserInfo storage _currentUserInfo = users[msg.sender];
        if(!MerkleProof.verify(_merkleProof, merkleRootForAirdrop, keccak256(abi.encodePacked(msg.sender,_quantity)))||_currentUserInfo.joinedAirdrop) {
            revert NotInAirdropList(); 
        }
        _safeMint(msg.sender, _quantity);
        _currentUserInfo.joinedAirdrop = true;
    }   

    function setmerkleRootForAirdrop(bytes32 _merkleRootForAirdrop) external onlyRole(MANAGER) {
       merkleRootForAirdrop = _merkleRootForAirdrop;
    }
    
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(MANAGER) {
        merkleRoot = _merkleRoot;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        if (!_exists(tokenId)) revert NoRoyaltyInfo();
        return (royaltyAddress, salePrice * royaltyPercent / 100);
    }

    function setRoyaltiPercent(uint16 _royaltyPercent)external onlyRole(MANAGER) {
        royaltyPercent = _royaltyPercent;
    }

    function setRagmonURI(string memory _ragmonURI) external onlyRole(MANAGER) {
        if(ragmonURILock) revert NeverSetUpTwice();
        ragmonURI = _ragmonURI;
    }

    function lockRagmonURI() external onlyRole(MANAGER) {
        if(ragmonURILock) revert NeverSetUpTwice();
        ragmonURILock = true;
    }
    
    function setUserPrivateLimits(uint16 _userPrivateMintLimit) external onlyRole(MANAGER) {
        userPrivateMintLimit = _userPrivateMintLimit;
    }
    function setUserPublicLimits(uint16 _round1, uint16 _round2) external onlyRole(MANAGER) {
        uint16[2] storage _userPublicMintLimit = userPublicMintLimit;
        _userPublicMintLimit[0] = _round1;
        _userPublicMintLimit[1] = _round2;
    }
    function setPrivateLimits(uint16 _round1, uint16 _round2) external onlyRole(MANAGER) {
        uint16[2] storage _privateLimits = privateLimits;
        _privateLimits[0] = _round1;
        _privateLimits[1] = _round2;
    }
    
    function setPublicLimits(uint16 _round1, uint16 _round2) external onlyRole(MANAGER) {
        uint16[2] storage _publicLimits = publicLimits;
        _publicLimits[0] = _round1;
        _publicLimits[1] = _round2;
    }

    function setPrivateTimes(uint32 _round1, uint32 _round2) external onlyRole(MANAGER) {
        uint32[2] storage _privateTimes = privateTimes;
        _privateTimes[0] = _round1;
        _privateTimes[1] = _round2;
    }
    
    function setPublicTimes(uint32 _round1, uint32 _round2) external onlyRole(MANAGER) {
        uint32[2] storage _publicTimes = publicTimes;
        _publicTimes[0] = _round1;
        _publicTimes[1] = _round2;
    }

    function setPrivatePrice(uint256 _privatePrice) external onlyRole(MANAGER) {
        privatePrice = _privatePrice;
    }

    function setPublicPrice(uint256 _publicPrice) external onlyRole(MANAGER) {
        publicPrice = _publicPrice;
    }
    function setPrivateRound(uint8 _round) external onlyRole(MANAGER) {
        privateRound = _round;
    }

    function setPublicRound(uint8 _round) external onlyRole(MANAGER) {
        publicRound = _round;
    }

    function getUserInfo(address _user) external view returns(UserInfo memory){
        return users[_user];
    }
    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function withdraw(address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant()  {
        
        uint amount = address(this).balance;
        //slither-disable-next-line arbitrary-send per
      (bool _result, ) = _receiver.call{value:amount}("");   
      if(!_result) {
        revert WithdrawFailed();
      }
      emit Withdraw(_receiver,amount);
    } 


    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafkreieplqeq47cdrtnzhzkivqjk3fnnqwtqsndcikaxu3wfpfr7ke25ny";
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
          if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI(); 
        return bytes(ragmonURI).length == 0 ? baseURI  : string(abi.encodePacked(ragmonURI, tokenId.toString(), ".json"));
    }
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    function currentTokenId() public view returns (uint256) {
        return _nextTokenId() == 1 ? 0 :  _nextTokenId()-1;
    }
 

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721A, AccessControl, IERC721A, IERC165) 
        returns (bool) 
    {
        return  super.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId ;
    }




}