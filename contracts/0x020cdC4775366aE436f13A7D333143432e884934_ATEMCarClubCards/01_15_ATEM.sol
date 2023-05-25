//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ATEMCarClubCards is ERC721A, ReentrancyGuard, Ownable {
  using ECDSA for bytes32;
  using Address for address;
  using SafeERC20 for IERC20;

  address private signer;
  string public _tokenUriBase;
  State public _state;

  IERC721 public asmBrainsContract;
  IERC20 public astoToken;

  uint256 public MAX_SUPPLY = 12455;
  /* @dev: 2384 ASTO tokens with 18 decimals */
  uint256 public MINT_PRICE = 2384 ether;

  mapping(bytes => bool) public usedToken;
  mapping(uint256 => bool) public asmHasMinted;
  mapping(address => mapping(uint256 => bool)) mintedInBlock;

  enum State {
    AsmMint,
    PublicMint,
    Closed
  }

  event Minted(address account, uint256 amount);
  event PreMinted(address account, uint256 amount);
  event MintAndAirdrop(uint256 quantity);
  event AstoTokenUpdated();
  event ASMBrainsUpdated();
  event OpenAsmMint();
  event OpenPublicMint();
  event MintClosed();
  event ASTOWithdrawn(address _to, uint256 _amount);
  event EtherWithdrawn(address _to, uint256 _amount);
  event TokenURIUpdated(string _uri);
  event SignerUpdated(address _signer);
  event MintPriceUpdated(uint256 _amount);

  /*
   * @param: _signer - Signer that is used for ECDSA
   * @param: _astoToken - contractAddress of ASTO
   * @param: _asmBrainsContract - contractAddress of ASM Brains
   */
  constructor(
    address _signer,
    IERC20 _astoToken,
    IERC721 _asmBrainsContract
  ) ERC721A("ATEM Car Club Cards", "ATEMCCC") {
    _state = State.Closed;
    astoToken = _astoToken;
    asmBrainsContract = _asmBrainsContract;
    signer = _signer;
  }

  /* @dev: Opens up the sale for ASM Brains */
  function setAsmMint() external onlyOwner {
    _state = State.AsmMint;
    emit OpenAsmMint();
  }

  /* @dev: Opens up the Public Mint */
  function setPublicMint() external onlyOwner {
    _state = State.PublicMint;
    emit OpenPublicMint();
  }

  /* @dev: Closes the sale entirely */
  function setClosed() external onlyOwner {
    _state = State.Closed;
    emit MintClosed();
  }

  /* @dev: Setter for ASM Brains ERC721
   * @param: contractAddress of ASM Brains
   */
  function updateBrainsContract(IERC721 _contractAddress) external onlyOwner {
    asmBrainsContract = _contractAddress;
    emit ASMBrainsUpdated();
  }

  /* @dev: Setter for ERC20 $ASTO token
   * @param: Contractaddress for asto parameter to be set to
   */
  function updateAstoToken(IERC20 _contractAddress) external onlyOwner {
    astoToken = _contractAddress;
    emit AstoTokenUpdated();
  }

  /* @dev: Setter for signer of SALT
   * @param: Walletaddress that signs
   */
  function updateSigner(address _signer) external onlyOwner {
    signer = _signer;
    emit SignerUpdated(_signer);
  }

  /* @dev: Setter for price of mint (18 decimals)
   */
  function updateMintPrice(uint256 _amount) external onlyOwner {
    MINT_PRICE = _amount;
    emit MintPriceUpdated(_amount);
  }

  /* @dev: Hash function for ECDSA
   * @param: salt and the address to hash it for
   * @returns: keccak256 hash based on salt, contractaddress and the msg.sender
   */
  function _hash(string calldata salt, address _address)
    public
    view
    returns (bytes32)
  {
    return keccak256(abi.encode(salt, address(this), _address));
  }

  /* @dev: Verify whether this hash was signed by the right signer
   * @param: Keccak256 hash, and the given token
   * @returns: Returns whether the signer was correct, boolean
   */
  function _verify(bytes32 hash, bytes memory token)
    public
    view
    returns (bool)
  {
    return (_recover(hash, token) == signer);
  }

  /* @dev: Recovers the hash for the token
   * @param: hash and token
   * @returns: A recovered hash
   */
  function _recover(bytes32 hash, bytes memory token)
    public
    pure
    returns (address)
  {
    return hash.toEthSignedMessageHash().recover(token);
  }

  /* @dev: Allows contractowner to premint with a maximum of 1000
   * @param: The amount to premint and _to is the recipient
   */
  function preMint(uint256 amount, address _to) external onlyOwner {
    require(totalSupply() + amount <= 1000, "you premint can only mint 1000");
    require(_state == State.Closed, "state must be closed");
    require(amount <= 100, "max amount is 100");
    _safeMint(_to, amount);
    emit PreMinted(_to, amount);
  }

  /* @dev: Mints straight to the owed wallet with a maximum of 1455 total after premint has happened
   * @param: array of walletaddresses and amounts, transfers are based on index
   */
  function mintAndAirdrop(
    address[] calldata walletAddresses,
    uint256[] calldata amounts
  ) external onlyOwner {
    require(totalSupply() + amounts.length <= 2454, "airdrop goes till 2454");
    require(
      amounts.length == walletAddresses.length,
      "arrays not equal in length"
    );
    require(
      walletAddresses.length <= 100,
      "you can only airdrop 100 tokens at once"
    );
    for (uint256 x = 0; x < walletAddresses.length; x++) {
      _safeMint(walletAddresses[x], amounts[x]);
    }
    emit MintAndAirdrop(walletAddresses.length);
  }

  /* @dev: Sale for ASM Brains, paid in ASTO tokens
   * @param: an array of ASM Brains tokenIds
   */
  function asmMint(uint256[] calldata _tokenIds) external nonReentrant {
    require(_state == State.AsmMint, "not open yet");
    require(msg.sender == tx.origin, "contracts not allowed");
    require(!Address.isContract(msg.sender), "contracts not allowed");
    require(
      astoToken.allowance(msg.sender, address(this)) >=
        _tokenIds.length * MINT_PRICE,
      "please first allow this contract to pay for your nfts in ASTO tokens"
    );
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      require(
        asmBrainsContract.ownerOf(_tokenIds[i]) == msg.sender,
        "not your brain"
      );
      require(
        asmHasMinted[_tokenIds[i]] == false,
        "this token has already minted"
      );
      asmHasMinted[_tokenIds[i]] = true;
    }
    astoToken.safeTransferFrom(
      msg.sender,
      address(this),
      _tokenIds.length * MINT_PRICE
    );
    _safeMint(msg.sender, _tokenIds.length);
    emit Minted(msg.sender, _tokenIds.length);
  }

  /* @dev: Public mint, paid in $ASTO tokens
   * @param: Salt and Token, and the amount that is wished to be minted
   */
  function publicMint(
    string calldata salt,
    bytes calldata token,
    uint16 amount
  ) external nonReentrant {
    require(_state == State.PublicMint, "not open yet");
    require(amount <= 5, "you cant mint more than 5");
    require(msg.sender == tx.origin, "contracts not allowed");
    require(totalSupply() + amount <= 12455, "cant go over max supply");
    require(!Address.isContract(msg.sender), "contracts not allowed");
    require(_verify(_hash(salt, msg.sender), token), "invalid token.");
    require(!usedToken[token], "The token has been used.");
    require(
      mintedInBlock[msg.sender][block.number] == false,
      "you already minted in this block"
    );
    require(
      astoToken.allowance(msg.sender, address(this)) >= amount * MINT_PRICE,
      "please first allow this contract to pay for your nfts in ASTO tokens"
    );
    astoToken.safeTransferFrom(msg.sender, address(this), amount * MINT_PRICE);
    usedToken[token] = true;
    mintedInBlock[msg.sender][block.number] = true;
    _safeMint(msg.sender, amount);
    emit Minted(msg.sender, amount);
  }

  /* @dev: Returns the metadata API and appends the tokenId
   * @param: tokenId integer
   * @returns: A string of tokenURI + tokenId
   */
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A)
    returns (string memory)
  {
    return string(abi.encodePacked(_tokenUriBase, Strings.toString(tokenId)));
  }

  /* @dev: Update the base URL of the metadata
   * @param: API URL as a string
   */
  function setTokenURI(string memory tokenUriBase_) public onlyOwner {
    _tokenUriBase = tokenUriBase_;
    emit TokenURIUpdated(tokenUriBase_);
  }

  /* @dev: View function to see if an ASM tokenId has already minted or not
   * @param: Array of tokenIds
   */
  function getASMBrainMintedStatus(uint256[] calldata tokenIds)
    public
    view
    returns (bool[] memory)
  {
    bool[] memory brainStatus = new bool[](tokenIds.length);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      brainStatus[i] = asmHasMinted[tokenIds[i]];
    }
    return brainStatus;
  }

  /* @dev: Withdraws the ASTO tokens to the recipient
   * @param: Walletaddress of the recipient
   */
  function withdrawAstoTokens(address recipient) external onlyOwner {
    uint256 amount = astoToken.balanceOf(address(this));
    astoToken.safeTransfer(recipient, amount);
    emit ASTOWithdrawn(recipient, amount);
  }

  /* @dev: Allows for withdrawal of Ether
   * @param: The recipient to withdraw to
   */
  function withdrawAll(address recipient) public onlyOwner {
    uint256 balance = address(this).balance;
    payable(recipient).transfer(balance);
    emit EtherWithdrawn(recipient, balance);
  }

  /* @dev: Allows for withdrawal of Ether
   * @param: The recipient to withdraw to
   */
  function withdrawAllViaCall(address payable _to) public onlyOwner {
    uint256 balance = address(this).balance;
    (bool sent, bytes memory data) = _to.call{value: balance}("");
    require(sent, "Failed to send Ether");
    emit EtherWithdrawn(_to, balance);
  }
}