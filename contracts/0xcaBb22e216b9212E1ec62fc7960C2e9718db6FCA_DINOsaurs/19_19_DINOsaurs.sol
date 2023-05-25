// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./DinoEgg.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract DINOsaurs is ERC721, ERC721Burnable, ERC2981, Ownable {

    using Strings for uint256;
    using Counters for Counters.Counter;

    uint private nonce;

    Counters.Counter[5] private _base;

    DinoEgg public eggNFT;

    string baseURI;
    string baseExtension = ".json";
    address dinoWallet;
    address royaltyWallet;
    uint public cost = .0333 ether;

    constructor(
        address _dinoWallet,
        address _royaltyWallet,
        address _eggNFT
    )
    ERC721("The DINOSaurs LFG","Dinos")
    {
        dinoWallet = _dinoWallet;
        royaltyWallet = _royaltyWallet;
        _setDefaultRoyalty(royaltyWallet, 500);
        eggNFT = DinoEgg(_eggNFT);
        
    }
    //need token approval for eggNFT
    function hatchEgg(uint eggID) public payable{
        require(msg.value >= cost, "not enough ether sent");
        eggNFT.burn(eggID);
        randomHatch(msg.sender);
    }
    
    function randomHatch(address _hatchee) internal {
        uint word = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), block.coinbase, msg.sender, nonce++)));
        uint range = (word % 5) + 1;
        emit numberResolved(range, msg.sender);

        uint totalWeight = 0;
        uint[] memory weights = new uint[](5);
        uint[] memory currentCounts = new uint[](5);

        for (uint i = 0; i < 5; i++) {
            currentCounts[i] = _base[i].current();
            uint weight = 2000 - currentCounts[i]; // Inverse of the current count
            weights[i] = weight;
            totalWeight += weight;
        }

        uint randomNumber = (word % totalWeight) + 1;
        uint cumulativeWeight = 0;

        for (uint i = 0; i < 5; i++) {
            cumulativeWeight += weights[i];
            if (randomNumber <= cumulativeWeight) {
                uint startingIndex = i * 2000 + 1;
                uint tokenId = currentCounts[i] + startingIndex;
                _base[i].increment();
                _safeMint(_hatchee, tokenId);
                emit TokenIssued(tokenId, _hatchee);
                break;
            }
        }
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
  
  function _baseURI() internal view virtual override returns (string memory)
  {
    return baseURI;
  }

  function setNewCost(uint _newCost) public onlyOwner{
      cost = _newCost;    
  }
  function setBaseURI(string memory _newbaseURI) public onlyOwner
  {
    baseURI = _newbaseURI;
  }
  function withdrawEther() public onlyOwner
  {
    uint256 contractEthBal = address(this).balance;
    payable(dinoWallet).transfer(contractEthBal); 
  }
event numberResolved
(
    uint indexed number,
    address indexed caller
);
event TokenIssued(
      uint256 tokenID,
      address hatcher
  );
//override to make royalties and 721 get along
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
    

    function metaMint() public onlyOwner
  {
    _safeMint(msg.sender, 10001);
  }
}