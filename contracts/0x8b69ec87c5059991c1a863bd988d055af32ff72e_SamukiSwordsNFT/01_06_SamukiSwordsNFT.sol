//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract SamukiSwordsNFT is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.01 ether;
    uint256 public presaleCost = 0.001 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 25;
    uint256 public nftPerAddressLimit = 50;
    address public YetiContract = 0x752FdacB71E76a68eC949FE25ccfCCd10Eee2F9F;
    address public SamukiContract = 0xe24C9e84115819aF35A1F3142932996e0216cd44;
    bool public paused = false;

    mapping(address => uint256) public addressMintedBalance;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) payable {
        setBaseURI(_initBaseURI);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address _to, uint256 _mintAmount) external payable {
        uint256 supply = totalSupply();
        uint256 white = 0;
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);

        if (msg.sender != owner()) {
            require(supply + _mintAmount <= maxSupply);
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
            if (ICheckContract(SamukiContract).balanceOf(msg.sender) > 0) {
                white++; 
            }

            if (ICheckContract(YetiContract).balanceOf(msg.sender) > 0) {
                white++; 
            }              
            if (white > 0)
            {
                require(msg.value >= presaleCost * _mintAmount);
            }
            else {
                require(msg.value >= cost * _mintAmount); 
            }
        }


    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
    }
        _safeMint(_to, _mintAmount);
    }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

    //only owner
    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setPresaleCost(uint256 _newCost) public onlyOwner {
        presaleCost = _newCost;
    }

    function setSamukiContract(address _addSamukiContract) public onlyOwner {
        SamukiContract = _addSamukiContract;
    }

    function setYetiContract(address _addYetiContract) public onlyOwner {
        YetiContract = _addYetiContract;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}

interface ICheckContract {
 function balanceOf(address owner) external view returns (uint256 balance);
}