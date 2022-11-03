//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';



contract Whitelist is Ownable {
    event WhitelistAdd(address indexed account);
    event WhitelistRemove(address indexed account);

    mapping(address => bool) private _whitelists;

    modifier onlyWhitelist() {
        require(isWhitelist(_msgSender()), "Caller is not whitelist");
        _;
    } 

    function isWhitelist(address account) public view returns (bool) {
        return _whitelists[account] || account == owner();
    }

    function addWhitelist(address account) external onlyOwner {
        _addWhitelist(account);
    }

    function removeWhitelist(address account) external onlyOwner {
        _removeWhitelist(account);
    }

    function renounceWhitelist() external {
        _removeWhitelist(_msgSender());
    }

    function _addWhitelist(address account) internal {
        _whitelists[account] = true;
        emit WhitelistAdd(account);
    }

    function _removeWhitelist(address account) internal {
        delete _whitelists[account];
        emit WhitelistRemove(account);
    }
}


contract MerkleWhitelist is Ownable {
  bytes32 public wl1WhitelistMerkleRoot = 0xdee9049aa98e91e67cdfdfd4eaf15cebb704e7934802ccc8b663d5be4dbba74a;
  bytes32 public wl2WhitelistMerkleRoot = 0xe469126153e62ed9e7b0fcd6aa43ec83827e2ac1c1f904a7d21eb9913b34a534;


  function _verifyWl1Sender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), wl1WhitelistMerkleRoot);
  }

  function _verifyWl2Sender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), wl2WhitelistMerkleRoot);
  }



  function _verify(bytes32[] memory proof, bytes32 addressHash, bytes32 whitelistMerkleRoot)
    internal
    pure
    returns (bool)
  {
    return MerkleProof.verify(proof, whitelistMerkleRoot, addressHash);
  }

  function _hash(address _address) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_address));
  }


  function setWl1WhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    wl1WhitelistMerkleRoot = merkleRoot;
  }

  function setWl2WhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    wl2WhitelistMerkleRoot = merkleRoot;
  }



  /*
  MODIFIER
  */
 modifier onlyWl1Whitelist(bytes32[] memory proof) {
    require(_verifyWl1Sender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }

  modifier onlyWl2Whitelist(bytes32[] memory proof) {
    require(_verifyWl2Sender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
  

}


contract bearfriends is Ownable, ERC721A, MerkleWhitelist, ReentrancyGuard,Whitelist {
    using SafeMath for uint256;


    uint256 public MAIN_PRICE = 0.066 ether;

    address private team1 = 0x9078190518A7f31EAeE5a6d815AF11955477D2fe;
    address private team2 = 0xC45533c7e009b679104c83ACBba6Bd3a2a7A0dEE;

    uint256 public TEAM1_AMOUNT = 277;
    uint256 public TEAM2_AMOUNT = 2200;
    uint256 public WL1_AMOUNT = 1000;
    uint256 public WL2_AMOUNT = 1500;
    uint256 public ALL_AMOUNT = 7777;



    uint256 public WL1_START_TIME = 1667401200;
    uint256 public WL1_END_TIME = 1667404800;

    uint256 public WL2_START_TIME = 1667404800;
    uint256 public WL2_END_TIME = 1667408400;

    uint256 public MAIN_START_TIME = 1667408400;
    uint256 public MAIN_END_TIME = 1667419200;


    uint256 public WL1_MINTED;
    uint256 public WL2_MINTED;
    uint256 public MAIN_MINTED;


    uint256 public WL1_LIMIT=1;
    uint256 public WL2_LIMIT=1;
    uint256 public MAIN_LIMIT=5;


    mapping(address => uint256) public WL1_WALLET_CAP;
    mapping(address => uint256) public WL2_WALLET_CAP;
    mapping(address => uint256) public MAIN_WALLET_CAP;


    bool _isWL1Active = true;
    bool _isWL2Active = true;
    bool _isMainActive = true;

    bool public REVEALED = false;

    bool isBlack = false;

    string public UNREVEALED_URI = "https://data.bearfriends.net/bear/bearbox/";
    string public BASE_URI;
    string public CONTRACT_URI ="https://data.bearfriends.net/api/contracturl.json";

    struct Info {
        uint256 amount;
        uint256 minted;
        uint256 price;
        uint256 start_wl1;
        uint256 end_wl1;
        uint256 start_wl2;
        uint256 end_wl2;
        uint256 start_main;
        uint256 end_main;
        uint256 wallet_cap;
    }


    constructor() ERC721A("BearFriends", "BearFriends") {
        _safeMint(team1, TEAM1_AMOUNT);
        _safeMint(team2, TEAM2_AMOUNT);
    }


    function approve(address to, uint256 tokenId) public payable override{
        if(isBlack){
            require(!isWhitelist(to), "Permission denied");
        }
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        if(isBlack){
            require(!isWhitelist(operator), "Permission denied");
        }
        super.setApprovalForAll(operator, approved);
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }


    function wl1Info(address user) public view returns (Info memory) {
       return  Info(WL1_AMOUNT,WL1_MINTED,0,WL1_START_TIME,WL1_END_TIME,WL2_START_TIME,WL2_END_TIME,MAIN_START_TIME,MAIN_END_TIME,WL1_WALLET_CAP[user]);
    }

    function wl2Info(address user) public view returns (Info memory) {
       return  Info(WL2_AMOUNT,WL2_MINTED,0,WL1_START_TIME,WL1_END_TIME,WL2_START_TIME,WL2_END_TIME,MAIN_START_TIME,MAIN_END_TIME,WL2_WALLET_CAP[user]);
    }

    function mainInfo(address user) public view returns (Info memory) {
       return  Info(mainAmount(),MAIN_MINTED,MAIN_PRICE,WL1_START_TIME,WL1_END_TIME,WL2_START_TIME,WL2_END_TIME,MAIN_START_TIME,MAIN_END_TIME,MAIN_WALLET_CAP[user]);
    }

    function mainAmount() public view returns (uint256) {
       return  ALL_AMOUNT - TEAM1_AMOUNT - TEAM2_AMOUNT - WL1_MINTED - WL2_MINTED;
    }



  
    function mintWL1(uint256 quantity,bytes32[] memory proof)
        public
        onlyWl1Whitelist(proof)
    {
        require(quantity > 0, "Must mint at least 1 token.");
        require(_isWL1Active, "WL1 must be active to mint tokens");
        require(block.timestamp >= WL1_START_TIME,"WL1 has not started yet!");
        require(block.timestamp < WL1_END_TIME, "WL1 is over");
        require(WL1_WALLET_CAP[msg.sender].add(quantity)<= WL1_LIMIT, "Purchase would exceed max number of metacards per wallet."); 
        require(WL1_MINTED.add(quantity) <= WL1_AMOUNT,"Max supply for WL1 reached!");
        require(totalSupply().add(quantity) <= ALL_AMOUNT,"reached max supply");

        WL1_MINTED = WL1_MINTED.add(quantity);

        WL1_WALLET_CAP[msg.sender] = WL1_WALLET_CAP[msg.sender].add(quantity);

        _safeMint(msg.sender, quantity);
    }

    function mintWL2(uint256 quantity,bytes32[] memory proof)
        public
       onlyWl2Whitelist(proof)
    {
        require(quantity > 0, "Must mint at least 1 token.");
        require(_isWL2Active, "WL2 must be active to mint tokens");
        require(block.timestamp >= WL2_START_TIME,"WL2 has not started yet!");
        require(block.timestamp < WL2_END_TIME, "WL2 is over");
        require(WL2_WALLET_CAP[msg.sender].add(quantity) <= WL2_LIMIT, "Purchase would exceed max number of metacards per wallet."); 
        require(WL2_MINTED.add(quantity) <= WL2_AMOUNT,"Max supply for WL2 reached!");
        require(totalSupply().add(quantity) <= ALL_AMOUNT,"reached max supply");

         if (WL2_MINTED.add(quantity) == WL2_AMOUNT){
            _isWL2Active = false;
            _isMainActive = true;
            MAIN_START_TIME = block.timestamp;
        }

        WL2_MINTED = WL2_MINTED.add(quantity);

        WL2_WALLET_CAP[msg.sender] =  WL2_WALLET_CAP[msg.sender].add(quantity);

        _safeMint(msg.sender, quantity);

    }

     function mintMain(uint256 quantity)
        public
        payable
    {
        require(quantity > 0, "Must mint at least 1 token.");
        require(block.timestamp >= MAIN_START_TIME || _isMainActive,"MAIN has not started yet!");
        require(block.timestamp < MAIN_END_TIME, "MAIN is over");
        require(MAIN_WALLET_CAP[msg.sender].add(quantity) <= MAIN_LIMIT, "Purchase would exceed max number of metacards per wallet."); 
        require(msg.value >= quantity.mul(MAIN_PRICE),"Did not send enough eth.");
        require(totalSupply().add(quantity) <= ALL_AMOUNT,"reached max supply");

        MAIN_MINTED = MAIN_MINTED.add(quantity);

        MAIN_WALLET_CAP[msg.sender] = MAIN_WALLET_CAP[msg.sender].add(quantity);

        _safeMint(msg.sender, quantity);

    }


   function withdraw() public onlyOwner nonReentrant {
        (bool succ, ) = payable(owner()).call{value: address(this).balance}('');
        require(succ, "transfer failed");
   }

    function setRevealData(bool _revealed,string memory _baseURI) public onlyOwner
    {
        REVEALED = _revealed;
        BASE_URI = _baseURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
    }

    function setRevealedURI(string memory _unrevealedURI) public onlyOwner {
        UNREVEALED_URI = _unrevealedURI;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (REVEALED) {
            return
                string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId), ".json"));
        } else {
            return
                string(abi.encodePacked(UNREVEALED_URI, Strings.toString(_tokenId), ".json"));
        }
    }


    function setAllStartTime(uint256 wl1Time,uint256 wl1EndTime,uint256 wl2Time,uint256 wl2EndTime,uint256 mainTime,uint256 mainEndTime) external onlyOwner {
        WL1_START_TIME = wl1Time;
        WL1_END_TIME = wl1EndTime;
        WL2_START_TIME = wl2Time;
        WL2_END_TIME = wl2EndTime;
        MAIN_START_TIME = mainTime;
        MAIN_END_TIME = mainEndTime;
    }



    function flipAllState(bool isWL1Active,bool isWL2Active,bool isMainActive) external onlyOwner {
        _isWL1Active = isWL1Active;
        _isWL2Active = isWL2Active;
        _isMainActive = isMainActive;
    }

    function setIsBlack(bool _isBlack) external onlyOwner {
        isBlack = _isBlack;
    }

    function setPrice(uint256 _price) external onlyOwner {
        MAIN_PRICE = _price;
    }

    function setMainLimit(uint256 _mainLimit) external onlyOwner {
        MAIN_LIMIT = _mainLimit;
    }


}