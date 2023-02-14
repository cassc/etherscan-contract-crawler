//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Checkuints is Ownable, ERC721A, ReentrancyGuard {
    using SafeMath for uint256;
   
    uint256 public maxSupply = 9999;

    uint256 public PRICE1 = 0 ether;
    uint256 public PRICE2 = 0.002 ether;
    uint256 public PRICE3 = 0.003 ether;
    uint256 public PRICE4 = 0.003 ether;

    uint256 public MINTED1;
    uint256 public MINTED2;
    uint256 public MINTED3;
    uint256 public MINTED4;
    uint256 public AMOUNT1 = 999;
    uint256 public AMOUNT2 = 1999;
    uint256 public AMOUNT3 = 2999;
    uint256 public AMOUNT4 = 9999;


    uint256 public LIMIT = 20;

    uint256 _step = 0;

    mapping(address => uint256) public WALLET1_CAP;
    mapping(address => uint256) public WALLET2_CAP;
    mapping(address => uint256) public WALLET3_CAP;
    mapping(address => uint256) public WALLET4_CAP;

    address public _burner;
    
    string public BASE_URI="https://data.checkuints.net/metadata/";
    string public CONTRACT_URI ="https://data.checkuints.net/api/contracturl.json";

   struct Info {
        uint256 all_amount;
        uint256 minted;
        uint256 price;
        uint256 start_time;
        uint256 numberMinted;
        uint256 step;
        uint256 limit;
        uint256 step_minted;
        uint256 step_amount;
    }


    constructor() ERC721A("CHECKUINTS", "Checkuints") {
        _safeMint(msg.sender, 1);
    }  
    
    function info(address user) public view returns (Info memory) {
        if(_step == 1){
             return  Info(maxSupply,totalSupply(),PRICE1,0,WALLET1_CAP[user],_step,LIMIT,MINTED1,AMOUNT1);
        }else if(_step == 2){
             return  Info(maxSupply,totalSupply(),PRICE2,0,WALLET2_CAP[user],_step,LIMIT,MINTED2,(AMOUNT2-MINTED1));
        }else if(_step == 3){
             return  Info(maxSupply,totalSupply(),PRICE3,0,WALLET3_CAP[user],_step,LIMIT,MINTED3,(AMOUNT3-MINTED1-MINTED2));
        }else if(_step == 4){
             return  Info(maxSupply,totalSupply(),PRICE4,0,WALLET4_CAP[user],_step,LIMIT,MINTED4,(maxSupply-MINTED1-MINTED2-MINTED3));
        }
    }



    function mint1(uint256 amount) external {
        require(msg.sender == tx.origin, "Cannot mint from contract");
        require(_step == 1, "must be active to mint tokens");
        require(amount > 0, "amount must be greater than 0");

        require(WALLET1_CAP[msg.sender].add(amount) <= LIMIT, "max mint per wallet would be exceeded");
        require(totalSupply().add(amount) <= maxSupply, "max supply would be exceeded");

        MINTED1 = MINTED1.add(amount);

        WALLET1_CAP[msg.sender] = WALLET1_CAP[msg.sender].add(amount);
        
        _safeMint(msg.sender, amount);
    }

    function mint2(uint256 amount) external payable {
        require(msg.sender == tx.origin, "Cannot mint from contract");
        require(_step == 2, "must be active to mint tokens");
        require(amount > 0, "amount must be greater than 0");

        require(WALLET2_CAP[msg.sender].add(amount) <= LIMIT, "max mint per wallet would be exceeded");
        require(totalSupply().add(amount) <= maxSupply, "max supply would be exceeded");

        require(msg.value >= PRICE2 * amount, "value not met");

        MINTED2 = MINTED2.add(amount);

        WALLET2_CAP[msg.sender] = WALLET2_CAP[msg.sender].add(amount);
        
        _safeMint(msg.sender, amount);
    }

    function mint3(uint256 amount) external payable {
        require(msg.sender == tx.origin, "Cannot mint from contract");
        require(_step == 3, "must be active to mint tokens");
        require(amount > 0, "amount must be greater than 0");

        require(WALLET3_CAP[msg.sender].add(amount) <= LIMIT, "max mint per wallet would be exceeded");
        require(totalSupply().add(amount) <= maxSupply, "max supply would be exceeded");

        require(msg.value >= PRICE3 * amount, "value not met");

        MINTED3 = MINTED3.add(amount);

        WALLET3_CAP[msg.sender] = WALLET3_CAP[msg.sender].add(amount);
        
        _safeMint(msg.sender, amount);
    }


    function mint4(uint256 amount) external payable {
        require(msg.sender == tx.origin, "Cannot mint from contract");
        require(_step == 4, "must be active to mint tokens");
        require(amount > 0, "amount must be greater than 0");

        require(WALLET4_CAP[msg.sender].add(amount) <= LIMIT, "max mint per wallet would be exceeded");
        require(totalSupply().add(amount) <= maxSupply, "max supply would be exceeded");

        require(msg.value >= PRICE4 * amount, "value not met");

        MINTED4 = MINTED4.add(amount);

        WALLET4_CAP[msg.sender] = WALLET4_CAP[msg.sender].add(amount);
        
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

     function flipStep(uint256 step) external onlyOwner {
        _step = step;
    }


     function setPrice2(uint256 price) public onlyOwner
    {
        PRICE2 = price;
    }

     function setPrice3(uint256 price) public onlyOwner
    {
        PRICE3 = price;
    }

     function setPrice4(uint256 price) public onlyOwner
    {
        PRICE4 = price;
    }

    function burn(uint256 tokenId) public {
        require(msg.sender == _burner, "Permission denied for burn");
        _burn(tokenId);
    }

    function setBurner(address burner) external onlyOwner {
        _burner = burner;
    }


}