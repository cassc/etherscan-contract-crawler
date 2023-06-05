// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/[email protected]/utils/Strings.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract EyeStar is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant NFT_MAX =  7210;
    uint256 public NORMAL_MINT = 5;
    uint256 public leftAmountMinted = 1;
    uint256 public rightAmountMinted = 7210;
    
    mapping(address => uint256) public purchases;

    bool public sellLive;
    bool public boxLive;

    bool public locked;
    string private _tokenBaseURI = "https://eyestars.io/metadata/";
    string private _tokenBoxURI = "https://gateway.pinata.cloud/ipfs/QmVmmbLya3cgUvvWywxnMJs1nJoEwvDzS6JfBb4eNEQ7JV";

    
    constructor() ERC721("eyeStar", "EYESTAR") {
           _mintToken(msg.sender);
    }

    modifier notLocked() {
        require(!locked, "Contract metadata methods are locked");
        _;
    }

    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function setTokenBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }

    function setTokenBoxURI(string calldata URI) external onlyOwner notLocked {
        _tokenBoxURI = URI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "NULL_ADDRESS");

        if(!boxLive){
            return _tokenBoxURI;
        }
      
        return
            string(
                abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json")
            );
    }


    function setMintNum(uint256 amount) external onlyOwner {
        NORMAL_MINT = amount;
    }


    function toggleSellLive() external onlyOwner {
        sellLive = !sellLive;
    }

    function toggleboxLive() external onlyOwner {
        boxLive = !boxLive;
    }

    function gmint(address[] calldata _recipients) external onlyOwner {
        uint256 recipients = _recipients.length;
        require(
            recipients + totalSupply() <= NFT_MAX,
            "EXCEED_ALLOC"
        );

        for (uint256 i = 0; i < recipients; i++) {
            _mintToken(_recipients[i]);
        }
    }

    function mint(
        uint256 quantity
    ) external payable  {

        uint256 newTotel  = totalSupply() + quantity;

        require(sellLive, "SALE_CLOSED");
        require(totalSupply() < NFT_MAX, "OUT_OF_STOCK");
        require(newTotel <= NFT_MAX,"OUT_OF_STOCK");
        require(purchases[msg.sender] + quantity <= NORMAL_MINT, "EXCEED_ALLOC");

        uint256 price;
        if(newTotel>721 && newTotel<=1500){
                price =  20000000000000000; //0.02
        }else if(newTotel>1500 && newTotel<=3000){
                price =  40000000000000000; //0.04
        }else if(newTotel>3000){
                price =  72100000000000000; //0.0721
        }
        require(quantity * price <= msg.value, "INSUFFICIENT_ETH");

        for (uint256 i = 0; i < quantity; i++) {
            _mintToken(msg.sender);
            purchases[msg.sender]++;
        }

    }

    function _mintToken(address sender) private  {
      if(totalSupply() % 2 == 0){
            _safeMint(sender,leftAmountMinted);
            leftAmountMinted = leftAmountMinted +1;
       } else {
            _safeMint(sender,rightAmountMinted);
            rightAmountMinted = rightAmountMinted-1;
      }
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}