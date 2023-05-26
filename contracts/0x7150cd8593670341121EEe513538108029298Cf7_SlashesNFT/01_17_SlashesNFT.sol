// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "./ISlashesSVG.sol";
import {Base64} from "./Base64.sol";
import {Utils} from "./Utils.sol";

contract SlashesNFT is ERC721, ERC721Enumerable, Ownable {

  // contructor arg
  uint public constant MAX_SUPPLY = 1024;
  uint public constant PRICE = 0.2 ether;

  address public SlashesSVGAddress;

  // auto increment token ids
  using Counters for Counters.Counter;
  Counters.Counter private _nextTokenId;

  // timestamp in sec
  // default to 31 Jan 2022 00:00:00 GMT
  uint public saleStart = 1643587200;

  constructor(
    address _SlashesSVGAddress
  ) ERC721("SLASHES", "SLASHES") {

    setSlashesSVGAddress(_SlashesSVGAddress);
    
    // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
    _nextTokenId.increment();
  }

  function setSlashesSVGAddress(address _SlashesSVGAddress) public onlyOwner {
    require(_SlashesSVGAddress != address(0), 'SlashesSVGAddress can not be address zero');
    SlashesSVGAddress = _SlashesSVGAddress;
  }

  function mint(address recipient) payable public salesIsOpen returns (uint256) {
    uint256 currentTokenId = _nextTokenId.current();

    require(msg.value >= PRICE, "Not enough ETH to purchase: check price.");
    
    // mint the token
    _safeMint(recipient, currentTokenId);
    _nextTokenId.increment();
    return currentTokenId;
  }

  function batchMint(address recipient, uint256 numberOfNfts) public payable salesIsOpen {
    require(numberOfNfts > 0, "Number of NFTs cannot be 0");
    require(totalSupply() + numberOfNfts <= MAX_SUPPLY, "Exceeds MAX_SUPPLY");
    require(msg.value >= PRICE * numberOfNfts, "Ether value sent is not correct");
    for (uint i = 0; i < numberOfNfts; i++) {
        uint256 tokenId = _nextTokenId.current();
        _safeMint(recipient, tokenId);
        _nextTokenId.increment();
    }
  }

  function totalSupply() public view override returns (uint256) {
    return _nextTokenId.current() - 1;
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
    ) internal
    override(ERC721, ERC721Enumerable) 
    {
      super._beforeTokenTransfer(from, to, tokenId);
    }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, ERC721Enumerable)
      returns (bool)
    {
      return super.supportsInterface(interfaceId);
    }

  function contractURI() 
    public 
    view 
    returns (string memory) 
    {
      ISlashesSVG svg = ISlashesSVG(SlashesSVGAddress);
      string memory svgString;
      string memory attributes;
      (svgString, attributes) = svg.generateSVG(block.timestamp % _nextTokenId.current());

      return string(
          abi.encodePacked(
              "data:application/json;base64,",
              Base64.encode(
                  bytes(
                      abi.encodePacked(
                        '{"name": "Slashes","description": "The Slashes piece proposes a vision of the paths we take and of the people that we encounter throughout our lives. This is the first 100% on-chain generative art series using Solidity smart-contracts on the Ethereum blockchain as a medium to output SVGs by makio135.eth & clemsos.eth.","image":"',
                        svgString,
                        '", "external_link": "https://makio135.io/slashes", "seller_fee_basis_points": 1500, "fee_recipient":"0x',
                        Utils.addressToString(address(this)),
                        '"}'
                        )
                  )
              )
          )
      );
    }
  
  function tokenURI(uint256 tokenId) 
    public 
    view 
    virtual 
    override (ERC721)
    returns (string memory) 
    {
        ISlashesSVG svg = ISlashesSVG(SlashesSVGAddress);
        string memory svgString;
        string memory attributes;
        (svgString, attributes) = tokenId > totalSupply() ? ('', '') : svg.generateSVG(tokenId);
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                          '{"description":"The Slashes piece proposes a vision of the paths we take and of the people that we encounter throughout our lives. This is the first 100% on-chain generative art series using Solidity smart-contracts on the Ethereum blockchain as a medium to output SVGs by makio135.eth & clemsos.eth.","name":"Slashes #',
                          Utils.uint2str(tokenId),
                          '","image":"',
                          svgString,
                          '","attributes":[',
                          attributes,
                          ']}'
                        )
                    )
                )
            )
        );
    }
  
  function withdraw(address payable recipient, uint256 amount) public onlyOwner {
      require(recipient != address(0), 'SlashesSVGAddress can not be address zero');

      uint balance = address(this).balance;
      require(balance > 0, "No ether left to withdraw");
      
      (bool succeed, ) = recipient.call{value: amount}("");
      require(succeed, "Failed to withdraw Ether");
  }

  function setSaleStart(uint _dateInSec) public onlyOwner {
    saleStart = _dateInSec;
  }

  modifier salesIsOpen() {
    require(block.timestamp > saleStart, "Sale is not currently open");
    require(totalSupply() < MAX_SUPPLY, "Sale has already ended");
    _;
  }

}