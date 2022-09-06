// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheLastWalkOfLife is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MINT_PRICE = 0.01 ether;
    uint256 public MAX_SUPPLY = 444;
    uint256 public MAX_PER_TRANSACTION = 2;
    uint256 public MAX_PER_WALLET = 4;
    bool public paused = false;
    bool public reveal = false;

    mapping (address => uint8) public NFTPerAddress;

    string private baseUri = "";
    string private preRevealUri = "ipfs/QmQQmC8wm3aGXgS88rJ5FiBSzpyK1AcYidy4vUsbkuaQ1k";

    constructor() ERC721A("The Last Walk Of Life", "TheLastWalkOfLife") {}


  function mint(uint8 _mintAmount) external payable  {
     uint16 totalSupply = uint16(totalSupply());
     uint8 nft = NFTPerAddress[msg.sender];
     require(totalSupply + _mintAmount <= MAX_SUPPLY, "Exceeds max supply.");
     require(_mintAmount + nft <= MAX_PER_WALLET, "Exceeds max per wallet.");
     require(_mintAmount <= MAX_PER_TRANSACTION, "Exceeds max per transaction.");

     require(!paused, "The contract is paused!");
     require(msg.value >= MINT_PRICE * _mintAmount, "Insufficient Funds");
     NFTPerAddress[msg.sender] += _mintAmount;
     _safeMint(msg.sender, _mintAmount);
    
  }

    function setMaxMintAmountPerTx(uint8 _maxtx) external onlyOwner{
      MAX_PER_TRANSACTION = _maxtx;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setBaseURI(string calldata _newBaseUri) external onlyOwner {
        baseUri = _newBaseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function flipSale() external onlyOwner {
        paused = !paused;
    }

    function revealOn() external onlyOwner {
        reveal = true;
    }

    function reserves(uint256 numToReserve) external onlyOwner {
        require(
            totalSupply() + numToReserve <= MAX_SUPPLY,
            "Not enough to reserve"
        );
        _safeMint(msg.sender, numToReserve);
    }

    function withdraw() external onlyOwner {
        require(
            payable(owner()).send(address(this).balance),
            "Withdraw unsuccessful"
        );
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
        return
            bytes(baseUri).length != 0
                ? string(abi.encodePacked(baseUri, _toString(tokenId), ".json"))
                : preRevealUri;
    }
}