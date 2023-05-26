// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IShogunToken.sol";

/*  _____ _                             _____                                 _     
  / ____| |                            / ____|                               (_)    
 | (___ | |__   ___   __ _ _   _ _ __ | (___   __ _ _ __ ___  _   _ _ __ __ _ _ ___ 
  \___ \| '_ \ / _ \ / _` | | | | '_ \ \___ \ / _` | '_ ` _ \| | | | '__/ _` | / __|
  ____) | | | | (_) | (_| | |_| | | | |____) | (_| | | | | | | |_| | | | (_| | \__ \
 |_____/|_| |_|\___/ \__, |\__,_|_| |_|_____/ \__,_|_| |_| |_|\__,_|_|  \__,_|_|___/
                      __/ |                                                         
                     |___/    
*/
contract ShogunNFT is ERC721Enumerable, Ownable {
  using SafeMath for uint256;
  using Strings for uint256;
  using ECDSA for bytes32;

  IShogunToken public SHOGUN_TOKEN;

  address payable public treasury;
  address public stakingContractAddress;
  address private signerAddressPublic;
  address private signerAddressPresale;

  string public baseURI;
  string public notRevealedUri;

  uint256 public cost = 0.08 ether;
  uint256 public maxSupply = 8888;
  uint256 public maxMintPerTxn = 4; // maximum number of mint per transaction
  uint256 public nftPerAddressLimitPublic = 8; // maximum number of mint per wallet for public sale
  uint256 public nftPerAddressLimitPresale = 2; // maximum number of mint per wallet for presale
  uint256 public nameChangePrice = 300 ether;

  uint256 public presaleWindow = 24 hours; // 24 hours presale period
  uint256 public presaleStartTime = 1634342400; // 16th October 0800 SGT
  uint256 public publicSaleStartTime = 1634443200; // 17thth October 1200 SGT

  bool public paused = false;
  bool public revealed = false;
  mapping(uint256 => string) public shogunName;

  // manual toggle for presale and public sale //
  bool public presaleOpen = false;
  bool public publicSaleOpen = false;

  // private variables //
  mapping(uint256 => bool) private _isLocked;
  mapping(address => bool) public whitelistedAddresses; // all address of whitelisted OGs
  mapping(address => uint256) private presaleAddressMintedAmount; // number of NFT minted for each wallet during presale
  mapping(address => uint256) private publicAddressMintedAmount; // number of NFT minted for each wallet during public sale
  mapping(bytes => bool) private _nonceUsed; // nonce was used to mint already

  // allows transactiones from only externally owned account (cannot be from smart contract)
  modifier onlyEOA() {
    require(msg.sender == tx.origin, "SHOGUN: Only EOA");
    _;
  }

  // allow transactions only from staking Contract address
  modifier onlyStakingContract() {
    require(
      msg.sender == stakingContractAddress,
      "SHOGUN: Only callable from staking contract"
    );
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI, // ""
    string memory _notRevealedUri, // default unrevealed IPFS
    address _signerAddressPresale,
    address _signerAddressPublic,
    address _treasury
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    notRevealedUri = _notRevealedUri;
    setSignerAddressPresale(_signerAddressPresale);
    setSignerAddressPublic(_signerAddressPublic);
    treasury = payable(_treasury);
  }

  // dev team mint
  function devMint(uint256 _mintAmount) public onlyEOA onlyOwner {
    require(!paused); // contract is not paused
    uint256 supply = totalSupply(); // get current mintedAmount
    require(
      supply + _mintAmount <= maxSupply,
      "SHOGUN: total mint amount exceeded supply, try lowering amount"
    );
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  // public sale
  function publicMint(
    bytes memory nonce,
    bytes memory signature,
    uint256 _mintAmount
  ) public payable onlyEOA {
    require(!paused);
    require(
      (isPublicSaleOpen() || publicSaleOpen),
      "SHOGUN: public sale has not started"
    );
    require(!_nonceUsed[nonce], "SHOGUN: nonce was used");
    require(
      isSignedBySigner(msg.sender, nonce, signature, signerAddressPublic),
      "invalid signature"
    );
    uint256 supply = totalSupply();
    require(
      publicAddressMintedAmount[msg.sender] + _mintAmount <=
        nftPerAddressLimitPublic,
      "SHOGUN: You have exceeded max amount of mints"
    );
    require(
      _mintAmount <= maxMintPerTxn,
      "SHOGUN: exceeded max mint amount per transaction"
    );
    require(
      supply + _mintAmount <= maxSupply,
      "SHOGUN: total mint amount exceeded supply, try lowering amount"
    );

    (bool success, ) = treasury.call{ value: msg.value }(""); // forward amount to treasury wallet
    require(success, "SHOGUN: not able to forward msg value to treasury");

    require(
      msg.value == cost * _mintAmount,
      "SHOGUN: not enough ether sent for mint amount"
    );

    for (uint256 i = 1; i <= _mintAmount; i++) {
      publicAddressMintedAmount[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
    _nonceUsed[nonce] = true;
  }

  // presale mint
  function presaleMint(
    bytes memory nonce,
    bytes memory signature,
    uint256 _mintAmount
  ) public payable onlyEOA {
    require(!paused, "SHOGUN: contract is paused");
    require(
      (isPresaleOpen() || presaleOpen),
      "SHOGUN: presale has not started or it has ended"
    );
    require(
      whitelistedAddresses[msg.sender],
      "SHOGUN: you are not in the whitelist"
    );
    require(!_nonceUsed[nonce], "SHOGUN: nonce was used");
    require(
      isSignedBySigner(msg.sender, nonce, signature, signerAddressPresale),
      "SHOGUN: invalid signature"
    );
    uint256 supply = totalSupply();
    require(
      presaleAddressMintedAmount[msg.sender] + _mintAmount <=
        nftPerAddressLimitPresale,
      "SHOGUN: you can only mint a maximum of two nft during presale"
    );
    require(
      msg.value >= cost * _mintAmount,
      "SHOGUN: not enought ethere sent for mint amount"
    );

    (bool success, ) = treasury.call{ value: msg.value }(""); // forward amount to treasury wallet
    require(success, "SHOGUN: not able to forward msg value to treasury");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      presaleAddressMintedAmount[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
    _nonceUsed[nonce] = true;
  }

  function airdrop(address[] memory giveawayList) public onlyEOA onlyOwner {
    require(!paused, "SHOGUN: contract is paused");
    require(
      balanceOf(msg.sender) >= giveawayList.length,
      "SHOGUN: not enough in wallet for airdrop amount"
    );
    uint256[] memory ownerWallet = walletOfOwner(msg.sender);

    for (uint256 i = 0; i < giveawayList.length; i++) {
      _safeTransfer(msg.sender, giveawayList[i], ownerWallet[i], "0x00");
    }
  }

  //*************** PUBLIC FUNCTIONS ******************//
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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

    if (!revealed) {
      return notRevealedUri;
    } else {
      return
        bytes(currentBaseURI).length > 0
          ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
          : "";
    }
  }

  //*************** INTERNAL FUNCTIONS ******************//
  function isSignedBySigner(
    address sender,
    bytes memory nonce,
    bytes memory signature,
    address signerAddress
  ) private pure returns (bool) {
    bytes32 hash = keccak256(abi.encodePacked(sender, nonce));
    return signerAddress == hash.recover(signature);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function isPresaleOpen() public view returns (bool) {
    return
      block.timestamp >= presaleStartTime &&
      block.timestamp < (presaleStartTime + presaleWindow);
  }

  function isPublicSaleOpen() public view returns (bool) {
    return block.timestamp >= publicSaleStartTime;
  }

  function isWhitelisted(address _user) public view returns (bool) {
    return whitelistedAddresses[_user];
  }

  //*************** OWNER FUNCTIONS ******************//
  // No possible way to unreveal once it is toggled
  function reveal() public onlyOwner {
    revealed = true;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setShogunToken(address _shogunToken) external onlyOwner {
    SHOGUN_TOKEN = IShogunToken(_shogunToken);
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function whitelistUsers(address[] calldata _users) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      whitelistedAddresses[_users[i]] = true;
    }
  }

  function withdrawToTreasury() public payable onlyOwner {
    (bool success, ) = treasury.call{ value: address(this).balance }(""); // returns boolean and data
    require(success);
  }

  function setPresaleOpen(bool _presaleOpen) public onlyOwner {
    presaleOpen = _presaleOpen;
  }

  function setPublicSaleOpen(bool _publicSaleOpen) public onlyOwner {
    publicSaleOpen = _publicSaleOpen;
  }

  function setSignerAddressPresale(address presaleSignerAddresss)
    public
    onlyOwner
  {
    signerAddressPresale = presaleSignerAddresss;
  }

  function setSignerAddressPublic(address publicSignerAddress)
    public
    onlyOwner
  {
    signerAddressPublic = publicSignerAddress;
  }

  function setNotRevealedUri(string memory _notRevealedUri)
    public
    onlyOwner
  {
    notRevealedUri = _notRevealedUri;
  }

  //*************** Future Utility Functions ******************//
  function setStakingContractAddress(address _stakingContract)
    public
    onlyOwner
  {
    stakingContractAddress = _stakingContract;
  }

  // sacrifice/burn ERC721
  function seppuku(uint256 _tokenId) public {
    require(
      _isApprovedOrOwner(_msgSender(), _tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _burn(_tokenId);
  }

  function setNameChangePrice(uint256 _newNameChangePrice) public onlyOwner {
    nameChangePrice = _newNameChangePrice;
  }

  function changeName(uint256 tokenId, string memory newName) public virtual {
    address owner = ownerOf(tokenId);
    require(_msgSender() == owner, "ERC721: caller is not the owner");
    require(validateName(newName) == true, "SHOGUN: Not a valid new name");
    require(
      sha256(bytes(newName)) != sha256(bytes(shogunName[tokenId])),
      "SHOGUN: New name is same as the current one"
    );

    SHOGUN_TOKEN.burn(_msgSender(), nameChangePrice);
    shogunName[tokenId] = newName;
  }

  function tokenNameByIndex(uint256 index) public view returns (string memory) {
    return shogunName[index];
  }

  function validateName(string memory str) public pure returns (bool) {
    bytes memory b = bytes(str);
    if (b.length < 1) return false;
    if (b.length > 25) return false; // Cannot be longer than 25 characters
    if (b[0] == 0x20) return false; // Leading space
    if (b[b.length - 1] == 0x20) return false; // Trailing space

    bytes1 lastChar = b[0];

    for (uint256 i; i < b.length; i++) {
      bytes1 char = b[i];

      if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

      if (
        !(char >= 0x30 && char <= 0x39) && //9-0
        !(char >= 0x41 && char <= 0x5A) && //A-Z
        !(char >= 0x61 && char <= 0x7A) && //a-z
        !(char == 0x20) //space
      ) return false;

      lastChar = char;
    }

    return true;
  }

  function lockToken(uint256[] memory _tokenIds) external onlyStakingContract {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _isLocked[_tokenIds[i]] = true;
    }
  }

  function unlockToken(uint256[] memory _tokenIds)
    external
    onlyStakingContract
  {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _isLocked[_tokenIds[i]] = false;
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721Enumerable) {
    require(_isLocked[tokenId] == false, "SHOGUN: Token is Locked");
    super._beforeTokenTransfer(from, to, tokenId);
  }
}