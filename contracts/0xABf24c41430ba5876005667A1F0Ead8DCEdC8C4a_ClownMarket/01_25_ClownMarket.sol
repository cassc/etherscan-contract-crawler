// SPDX-License-Identifier: UNLICENSED

/*
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠿⠿⠿⠿⠿⠿⠿⠿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣠⣤⣄⡀⠀⠰⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⡖⠀⢀⣠⣤⣄⠀⠀⠀⠀
⠀⠀⠀⠀⠙⣿⣿⡟⢀⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⡀⢻⣿⣿⠋⠀⠀⠀⠀
⠀⠀⠀⠀⣠⣿⠏⢠⣾⣿⡟⠙⣿⣿⣿⣿⣿⣿⠋⢻⣿⣷⡄⠹⣿⣄⠀⠀⠀⠀
⠀⢰⣾⣿⣿⡏⢠⣿⣿⠏⢠⣦⠈⢿⣿⣿⡿⠁⣴⡄⠹⣿⣿⡄⢹⣿⣿⣷⡆⠀
⠀⠀⠙⢿⣿⠁⣼⣿⡟⢀⣿⣿⣇⠘⣿⣿⠃⣸⣿⣿⡀⢻⣿⣧⠈⣿⡿⠋⠀⠀
⠀⠀⠀⠸⠿⠀⣿⣿⠁⣸⡇⠀⣿⡀⢹⡏⢀⣿⠀⢸⣇⠈⣿⣿⠀⠿⠇⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢿⣿⣤⡤⣤⣤⡄⢀⡤⠀⠀⢠⣤⣤⢤⣤⣿⡿⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠘⢁⣤⣤⣤⣄⡀⠏⠀⠀⠀⢀⣠⣤⣤⣤⡈⠃⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢻⣿⡍⠹⣿⣷⣤⣀⣀⣤⣾⣿⠏⢩⣿⡟⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣦⣈⠙⠿⠿⠿⠿⠋⣁⣴⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠿⣿⣶⣶⣶⣶⣿⠿⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
*/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { DefaultOperatorFilterer, OperatorFilterer } from "./opensea/DefaultOperatorFilterer.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";

contract ClownMarket is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable, ERC2981, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 constant maxSupply = 5000;
    uint256 constant mintPrice = 0 ether;
    uint256 public maxPerAddress = 1;
    uint256 public maxPerTx = 1;
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    bool public revealed = false;
    bool public pieinyourface = false;

    constructor() ERC721A("Clown Market", "CM") {
    }

    function pie(bool _pie) external onlyOwner {
        pieinyourface = _pie;
    }

    function mint(uint256 _quantity) external payable {
        require(pieinyourface, "Clown Market: Mint Not Active");
        require(_quantity <= maxPerTx, "Clown Market: Max Per Transaction Exceeded");
        require(totalSupply() + _quantity <= maxSupply, "Clown Market: Mint Supply Exceeded");
        require(_numberMinted(msg.sender) + _quantity <= maxPerAddress, "Clown Market: Exceeds Max Per Wallet");
        _safeMint(msg.sender, _quantity);
    }

    function reserve(address _address, uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Clown Market: Mint Supply Exceeded");
        _safeMint(_address, _quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

      function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721A, ERC2981, IERC721A)
        returns (bool) 
    {
        return
            ERC2981.supportsInterface(interfaceId)
            || ERC721A.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

      function setDefaultRoyalty(
    address _receiver,
    uint96 _feeNumerator
  )
    external
    onlyOwner
  {
    _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  function deleteDefaultRoyalty()
    external
    onlyOwner
  {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(
    uint256 _tokenId,
    address _receiver,
    uint96 _feeNumerator
  )
    external
    onlyOwner
  {
    _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
  }

  function resetTokenRoyalty(
    uint256 tokenId
  )
    external
    onlyOwner
  {
    _resetTokenRoyalty(tokenId);
  }

  /* ------------ OpenSea Overrides --------------*/
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    payable
    override(ERC721A, IERC721A)  
    onlyAllowedOperator(_from)
  {
      super.transferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) 
    public
    payable
    override(ERC721A, IERC721A) 
    onlyAllowedOperator(_from)
  {
    super.safeTransferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    public
    payable
    override(ERC721A, IERC721A) 
    onlyAllowedOperator(_from)
  {
    super.safeTransferFrom(_from, _to, _tokenId, _data);
  }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }
}