//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

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
  bytes32 public wl1WhitelistMerkleRoot = 0x087b1fd0605db38ea0878d611ed9881fe4a90338c38663ace96ed3333ca28889;

  function _verifyWl1Sender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), wl1WhitelistMerkleRoot);
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


  /*
  MODIFIER
  */
 modifier onlyWl1Whitelist(bytes32[] memory proof) {
    require(_verifyWl1Sender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
 

}


contract justchill is Ownable, ERC721A, ReentrancyGuard,MerkleWhitelist,Whitelist {
     using SafeMath for uint256;

    address private team1 = 0x828c3FFCC3F87889d2989c2a91f19584dE8C2784;
    address private team2 = 0xB1A1AC3AA59539A519280cB8F6f7a977FbA1Bf8F;
    address private team3 = 0x8DF3A38Fa43a38721b92e05E24123f24D95C9ccd;
   
    uint256 public maxSupply = 888;
    uint256 public AMOUNT = 888;
    uint256 public TEAM_AMOUNT = 100;

    uint256 public PRICE = 1.2 ether;
    uint256 public WL_PRICE = 0.89 ether;
    uint256 public LIMIT = 5;


    bool _isActive = true;
    bool _isBlack = false;

    string public BASE_URI="https://data.justchill.io/metadata/";
    string public CONTRACT_URI ="https://data.justchill.io/api/contracturl.json";

    struct Info {
        uint256 all_amount;
        uint256 minted;
        uint256 price;
        uint256 wl_price;
        uint256 start_time;
        uint256 numberMinted;
        uint256 limit;
        uint256 amount;
        bool isActive;
    }


    constructor() ERC721A("JustChill", "justchill") {
        _safeMint(team1, TEAM_AMOUNT);
        _safeMint(team2, TEAM_AMOUNT);
        _safeMint(team3, TEAM_AMOUNT);
    }  

     function approve(address to, uint256 tokenId) public payable override{
        if(_isBlack){
            require(!isWhitelist(to), "Permission denied");
        }
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        if(_isBlack){
            require(!isWhitelist(operator), "Permission denied");
        }
        super.setApprovalForAll(operator, approved);
    }

    
    function info(address user) public view returns (Info memory) {
        return  Info(maxSupply,totalSupply(),PRICE,WL_PRICE,0,_numberMinted(user),LIMIT,AMOUNT,_isActive);
    }


    function mint(uint256 amount,bytes32[] memory proof) external payable{
        require(msg.sender == tx.origin, "Cannot mint from contract");
        require(_isActive, "must be active to mint tokens");
        require(amount > 0, "amount must be greater than 0");
        require(totalSupply().add(amount) <= AMOUNT, "Max supply for mint reached!");
        require(totalSupply().add(amount) <= maxSupply, "max supply would be exceeded");
        uint minted = _numberMinted(msg.sender);
        require(minted.add(amount) <= LIMIT, "max mint per wallet would be exceeded");
        
        if(_verifyWl1Sender(proof)){
             require(msg.value >= WL_PRICE * amount, "value not met");
        }else{
             require(msg.value >= PRICE * amount, "value not met");
        }
       
        _safeMint(msg.sender, amount);
    }

   function withdraw() public onlyOwner nonReentrant {
        (bool succ, ) = payable(owner()).call{value: address(this).balance}('');
        require(succ, "transfer failed");
   }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
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
        return string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId), ".json"));
    }

    function flipState(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    function setPrice(uint256 price) public onlyOwner
    {
        PRICE = price;
    }

    function setWlPrice(uint256 wl_price) public onlyOwner
    {
        WL_PRICE = wl_price;
    }

    function setAmount(uint256 amount) public onlyOwner
    {
        AMOUNT = amount;
    }

    function setLimit(uint256 limit) public onlyOwner
    {
        LIMIT = limit;
    }

     function setIsBlack(bool isBlack) external onlyOwner {
        _isBlack = isBlack;
    }


}