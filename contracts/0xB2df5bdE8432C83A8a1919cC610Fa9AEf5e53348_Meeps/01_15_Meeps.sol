// SPDX-License-Identifier: MIT
/*
███╗   ███╗███████╗███████╗██████╗ ███████╗
████╗ ████║██╔════╝██╔════╝██╔══██╗██╔════╝
██╔████╔██║█████╗  █████╗  ██████╔╝███████╗
██║╚██╔╝██║██╔══╝  ██╔══╝  ██╔═══╝ ╚════██║
██║ ╚═╝ ██║███████╗███████╗██║     ███████║
╚═╝     ╚═╝╚══════╝╚══════╝╚═╝     ╚══════╝
Contract by Novem - https://novem.dev
*/
pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Meeps is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRootWl1;
  bytes32 public merkleRootWl2;
  mapping(address => uint256) public whitelistClaimed;

  string public uriPrefix = "";
  string public uriSuffix = ".json";

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public publicSaleEnabled = false;
  bool public whitelistMintEnabled = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
    address[] memory _teamWallets,
    address _devTeamWallet
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setUriPrefix(_hiddenMetadataUri);
    _safeMint(msg.sender, 132);
    for (uint256 i=0; i< _teamWallets.length; i++) {
      _safeMint(_teamWallets[i], 15);
    }
    _safeMint(_devTeamWallet, 10);
  }

  // Makes sure the mint amount is valid and not greater than the max supply.
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount <= maxMintAmountPerTx, "That amount is too high my fren.");
    require(totalSupply() + _mintAmount <= maxSupply, "Wow, think we sold out already.");
    _;
  }


  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Meep Meep, you don't have enough money.");
    _;
  }

  /*
              _       __ 
   ____ ___  (_)___  / /_
  / __ `__ \/ / __ \/ __/
 / / / / / / / / / / /_  
/_/ /_/ /_/_/_/ /_/\__/  
  */

  // Guaranteed list for 1 or 2 allowed mints
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "Meep! You've got to wait for the whitelist sale to be open!");

    // Make sure that the merkle proof is valid and that we first verify that a wallet is in the wl2 list before wl1.
    // If a wallet is in both lists, it will only be considered as wl2.
    uint256 mintLimit;
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    if(MerkleProof.verify(_merkleProof, merkleRootWl2, leaf)) mintLimit = 2;
    else if(MerkleProof.verify(_merkleProof, merkleRootWl1, leaf)) mintLimit = 1;
    else revert("Wait!? You are not in the whitelist! You can't mint!");

    // Make sure the user does not mint more than what he is allowed to
    require((whitelistClaimed[msg.sender]+_mintAmount)<=mintLimit, "Uh oh! You have already claimed what you are allowed to!");

    // Update the number of claimed tokens for the whitelist sale
    whitelistClaimed[msg.sender] = whitelistClaimed[msg.sender] + _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }

  // Public sale - Max 2 per transaction and NOT per wallet
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(publicSaleEnabled, "Sale currently closed.");
    _safeMint(msg.sender, _mintAmount);
  }

  // Internal function to airdrop multiple tokens to multiple wallets.
  // This function is used to airdrop all the Meeps Genesis Pass holders their 5 allowed mints.
  function mintForAddresses(uint256 _mintAmount, address[] memory _receivers) public onlyOwner {
    require(_mintAmount > 0, "You've got to mint at least 1 Meep...");
    for(uint256 i = 0; i<_receivers.length; i++){
      _safeMint(_receivers[i], _mintAmount);
    }
  }

  /*
                __  __                
   ________  / /_/ /____  __________
  / ___/ _ \/ __/ __/ _ \/ ___/ ___/
 (__  )  __/ /_/ /_/  __/ /  (__  ) 
/____/\___/\__/\__/\___/_/  /____/        
  */

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPublicSaleEnabled(bool _state) public onlyOwner {
    publicSaleEnabled = _state;
  }

  function setMerkleRootWl1(bytes32 _merkleRoot) public onlyOwner {
    merkleRootWl1 = _merkleRoot;
  }

  function setMerkleRootWl2(bytes32 _merkleRoot) public onlyOwner {
    merkleRootWl2 = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  /*
           _ __  __        __                   
 _      __(_) /_/ /_  ____/ /________ __      __
| | /| / / / __/ __ \/ __  / ___/ __ `/ | /| / /
| |/ |/ / / /_/ / / / /_/ / /  / /_/ /| |/ |/ / 
|__/|__/_/\__/_/ /_/\__,_/_/   \__,_/ |__/|__/  
  */

  // Used in case the contract receives funds.
  function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

  /*
                               _     __         
  ____ _   _____  __________(_)___/ /__  _____
 / __ \ | / / _ \/ ___/ ___/ / __  / _ \/ ___/
/ /_/ / |/ /  __/ /  / /  / / /_/ /  __(__  ) 
\____/|___/\___/_/  /_/  /_/\__,_/\___/____/  
  */

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
    ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
    : "";
  }

  // ERC721A baseURI override
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}