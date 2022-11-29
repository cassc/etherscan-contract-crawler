// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//  
//  ░██████╗██╗██╗░░░░░██╗░░░░░██╗░░░██╗██╗░░██╗███████╗██████╗░░██████╗░███████╗██╗░░██╗░█████╗░░██████╗░░██████╗
//  ██╔════╝██║██║░░░░░██║░░░░░╚██╗░██╔╝██║░░██║██╔════╝██╔══██╗██╔════╝░██╔════╝██║░░██║██╔══██╗██╔════╝░██╔════╝
//  ╚█████╗░██║██║░░░░░██║░░░░░░╚████╔╝░███████║█████╗░░██║░░██║██║░░██╗░█████╗░░███████║██║░░██║██║░░██╗░╚█████╗░
//  ░╚═══██╗██║██║░░░░░██║░░░░░░░╚██╔╝░░██╔══██║██╔══╝░░██║░░██║██║░░╚██╗██╔══╝░░██╔══██║██║░░██║██║░░╚██╗░╚═══██╗
//  ██████╔╝██║███████╗███████╗░░░██║░░░██║░░██║███████╗██████╔╝╚██████╔╝███████╗██║░░██║╚█████╔╝╚██████╔╝██████╔╝
//  ╚═════╝░╚═╝╚══════╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═════╝░░╚═════╝░╚══════╝╚═╝░░╚═╝░╚════╝░░╚═════╝░╚═════╝░

// 
// created by SillyHedgehogs

import "erc721a/contracts/ERC721A.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract SillyHedgehogs is ERC721A, ERC721AQueryable, Owned, DefaultOperatorFilterer {

  uint256 constant MINT_PRICE = 0.019 ether;
  uint256 public TOTAL_SUPPLY = 7777;
  uint256 public TOTAL_RESERVES = 4000;
  uint256 constant PUBLIC_SUPPLY_PLUS_ONE = 3778;
  uint256 constant MAX_PER_TRANSACTION_PLUS_ONE = 11;

  string tokenBaseUri = "ipfs://QmQgZjjFxHwN9nWejty3bN4YWZB5DJZBFgymWVHr97ikp1/";

  bool public paused = true;

  mapping(address => uint256) private _freeMintedCount;

  constructor() ERC721A("SillyHedgehogs", "SHG") Owned(msg.sender) {}

  // Rename mint function to optimize gas
  function mint(uint256 _quantity) external payable {
    unchecked {
      require(!paused, "MINTING PAUSED");

      uint256 _totalSupply = totalSupply();

      require(_totalSupply + _quantity < PUBLIC_SUPPLY_PLUS_ONE, "PUBLIC SUPPLY REACHED");
      require(_quantity < MAX_PER_TRANSACTION_PLUS_ONE, "MAX PER TRANSACTION IS 10");

      uint256 payForCount = _quantity;

      require(
        msg.value == payForCount * MINT_PRICE,
        "INCORRECT ETH AMOUNT"
      );

      _mint(msg.sender, _quantity);
    }
  }


  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function setBaseURI(string calldata _newBaseUri) external onlyOwner {
    tokenBaseUri = _newBaseUri;
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function collectReserves(uint _reserve) external onlyOwner {
    uint256 _totalSupply = totalSupply();  
          require(_totalSupply + _reserve < TOTAL_RESERVES, "ALL RESERVES TAKEN");
    _mint(msg.sender, 200);
  }
  
  function withdraw() external onlyOwner {
    require(
      payable(owner).send(address(this).balance),
      "UNSUCCESSFUL"
    );
  }

       // OPERATOR FILTERER 
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}