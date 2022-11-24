// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import './extensions/ERC721AQueryable_opensea.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
  

contract vitoshi_721A_opensea_v2 is ERC721AQueryable, Ownable,ERC2981, ReentrancyGuard {  

  bytes32 public constant merkleRoot = 0x61cb7d0b6537f0bb8d59c9749976290b171575119ca652ed984934f8cc281d68;
  uint256 public constant TOTAL_SUPPLY_LIMIT = 6302;
  uint256 public constant WHITELIST_LIMIT_PER_WALLET = 12;
  uint256 public constant TOTAL_LIMIT_PER_WALLET = 30;
  string public baseTokenURI ="";
  bool public publicMintingOpen;
  bool public whitelistMintingOpen;
  address public royaltyAddress;
  uint96 public royaltyFee = 1000;
   
	constructor() ERC721A("Vitoshis Castle OutTakes", "VCOT") {
      royaltyAddress = msg.sender;
      _setDefaultRoyalty(msg.sender, royaltyFee);
  }

     function airdrop(address[] memory airdrops, uint256 tokensForEach) external onlyOwner {
  
    require(tokensForEach <= 30,"<30/batch");
    for(uint i = 0; i < airdrops.length; i++) {
	    _mint(airdrops[i], tokensForEach);
        require(i + totalSupply() <= TOTAL_SUPPLY_LIMIT, "Exceeds Max Supply");
    }
  }

    function mintFromWhitelist(bytes32[] calldata _merkleProof,uint64 contestantsToMint) public {
    require(whitelistMintingOpen == true, "Whitelist Sale Off");
    require(contestantsToMint + totalSupply() <= TOTAL_SUPPLY_LIMIT, "Exceeds Max Supply");
    require(MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not whitelisted");
    require( (_getAux(msg.sender) + contestantsToMint) <= WHITELIST_LIMIT_PER_WALLET , "Exceeds Whitelist Limit / Wallet");
    require(balanceOf(msg.sender) + contestantsToMint <= TOTAL_LIMIT_PER_WALLET,"Exceeds limit - 30/wallet");

    _setAux(msg.sender, _getAux(msg.sender) + contestantsToMint);

    _mint(msg.sender,contestantsToMint);

  }

  function mintFromSale(uint contestantsToMint) public  {
    require(contestantsToMint + totalSupply() <= TOTAL_SUPPLY_LIMIT, "Exceeds Max Supply");
    require(publicMintingOpen == true, "Public Sale Off");
  require(balanceOf(msg.sender) + contestantsToMint <= TOTAL_LIMIT_PER_WALLET,"Exceeds limit - 30/wallet");
    require(contestantsToMint <= 30,"<30/batch");

    _mint(msg.sender,contestantsToMint);
  }

  function togglePublicSale() external onlyOwner {
	  publicMintingOpen = !publicMintingOpen;
  }

  function toggleWhitelistSale() external onlyOwner {
	  whitelistMintingOpen = !whitelistMintingOpen;
  }

  function retrieveFunds() external onlyOwner nonReentrant {
    payable(owner()).transfer(address(this).balance);
  }

  /// @dev Returns an URI for a given token ID
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /// @dev Sets the base token URI prefix.
  function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

      function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    //Change the royalty address where royalty payouts are sent
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

        function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }  
}