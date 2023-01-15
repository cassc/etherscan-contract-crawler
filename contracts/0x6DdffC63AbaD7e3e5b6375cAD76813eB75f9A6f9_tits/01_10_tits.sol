//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



contract MerkleWhitelist is Ownable {
  bytes32 public wl1WhitelistMerkleRoot = 0x1b9f9dbc907c20adf0e8d319f697eff0e4f55adfb9633c425185819b350a93b5;


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


contract tits is Ownable, ERC721A, ReentrancyGuard,MerkleWhitelist {
    using SafeMath for uint256;
   
    uint256 public ALL_AMOUNT = 555;

    uint256 public PRICE = 0.002 ether;

    uint256 public LIMIT = 5;
    uint256 public WL1_LIMIT = 1;

    uint256 _step = 0;

    mapping(address => uint256) public WL1_WALLET_CAP;
    mapping(address => uint256) public WALLET_CAP;

    bool public REVEALED = false;
    string public UNREVEALED_URI = "https://tits.dontslapme.net/box/box.json";
    string public BASE_URI;
    string public CONTRACT_URI ="https://tits.dontslapme.net/api/contracturl.json";

    struct Info {
        uint256 all_amount;
        uint256 minted;
        uint256 price;
        uint256 start_time;
        uint256 numberMinted;
        uint256 step;
        uint256 limit;
    }


    constructor() ERC721A("Tits", "tits") {
        _safeMint(msg.sender, 1);
    }  
    
    function info(address user) public view returns (Info memory) {
        if(_step == 1){
             return  Info(ALL_AMOUNT,totalSupply(),0,0,WL1_WALLET_CAP[user],_step,WL1_LIMIT);
        }else if(_step == 2){
             return  Info(ALL_AMOUNT,totalSupply(),PRICE,0,WALLET_CAP[user],_step,LIMIT);
        }
    }


    function mintWL1(uint256 amount,bytes32[] memory proof)
        public
        onlyWl1Whitelist(proof)
    {
        require(msg.sender == tx.origin, "Cannot mint from contract");
        require(_step == 1, "must be active to mint tokens");
        require(amount > 0, "amount must be greater than 0");

        require(WL1_WALLET_CAP[msg.sender].add(amount)<= WL1_LIMIT, "max mint per wallet would be exceeded"); 
        require(totalSupply().add(amount) <= ALL_AMOUNT,"max supply would be exceeded");

        WL1_WALLET_CAP[msg.sender] = WL1_WALLET_CAP[msg.sender].add(amount);

        _safeMint(msg.sender, amount);
    }


    function mint(uint256 amount) external payable {
        require(msg.sender == tx.origin, "Cannot mint from contract");
        require(_step == 2, "must be active to mint tokens");
        require(amount > 0, "amount must be greater than 0");

        require(WALLET_CAP[msg.sender].add(amount) <= LIMIT, "max mint per wallet would be exceeded");
        require(totalSupply().add(amount) <= ALL_AMOUNT, "max supply would be exceeded");

        require(msg.value >= PRICE * amount, "value not met");

        WALLET_CAP[msg.sender] = WALLET_CAP[msg.sender].add(amount);
        
        _safeMint(msg.sender, amount);
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
            return UNREVEALED_URI;
        }
    }

    function flipStep(uint256 step) external onlyOwner {
        _step = step;
    }


    function setPrice(uint256 price) public onlyOwner
    {
        PRICE = price;
    }

}