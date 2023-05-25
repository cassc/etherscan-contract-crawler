// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

contract Burrows is ERC721A, ReentrancyGuard, Ownable {
  using ECDSA for bytes32;
  using Address for address;

  enum State {
    Setup,
    WindowOne,
    WindowTwo,
    WindowThree,
    PublicSale,
    Finished
  }

  State private _state;
  address private _signer;
  address public _beneficiaryWallet;
  string private _tokenUriBase;
  uint256 public constant MAX_BURROWS = 10500;
  uint256 public constant MAX_MINT = 5;
  uint256 private BURROWS_PRICE = 0.22 ether;
  mapping(bytes => bool) public usedToken;
  mapping(address => mapping(uint256 => bool)) public tokenMinted;
  mapping(uint256 => mapping(address => bool)) public allowedContractsInWindow;
  event Minted(
    address minter,
    address[] contractAddresses,
    uint256[] tokenIdsToMint,
    uint256 fromTokenId,
    uint256 toTokenId,
    uint256 amount
  );
  event PublicMinted(address minter, uint256 amount);
  event StateChanged(State _state);
  event SignerChanged(address signer);
  event BalanceWithdrawn(address recipient, uint256 value);

  constructor(address signer)
    ERC721A("FLUF World: Burrows", "BURROWS", MAX_MINT)
  {
    _signer = signer;
    _state = State.Setup;
    _beneficiaryWallet = address(0xabc1f4Db8D6cc2b4Df9296A1852Ba1Ff8D190a7F);
    // Window 1;
    allowedContractsInWindow[1][
      0xCcc441ac31f02cD96C153DB6fd5Fe0a2F4e6A68d
    ] = true; // FLUF
    // Window 2;
    allowedContractsInWindow[2][
      0xCcc441ac31f02cD96C153DB6fd5Fe0a2F4e6A68d
    ] = true; // FLUF
    allowedContractsInWindow[2][
      0x35471f47c3C0BC5FC75025b97A19ECDDe00F78f8
    ] = true; // Partybears
    allowedContractsInWindow[2][
      0x1AFEF6b252cc35Ec061eFe6a9676C90915a73F18
    ] = true; // THINGIES
    // Window 3;
    allowedContractsInWindow[3][
      0xCcc441ac31f02cD96C153DB6fd5Fe0a2F4e6A68d
    ] = true; // FLUF
    allowedContractsInWindow[3][
      0x35471f47c3C0BC5FC75025b97A19ECDDe00F78f8
    ] = true; // Partybears
    allowedContractsInWindow[3][
      0x1AFEF6b252cc35Ec061eFe6a9676C90915a73F18
    ] = true; // THINGIES
    allowedContractsInWindow[3][
      0x96bE46c50E882dbd373081d08E0CDE2B055Adf6c
    ] = true; // ASM Characters
    allowedContractsInWindow[3][
      0xD0318da435DbcE0B347cc6faA330B5A9889e3585
    ] = true; // ASM Brains
    allowedContractsInWindow[3][
      0xd0F0C40FCD1598721567F140eBf8aF436e7b97cF
    ] = true; // JADU Jetpacks
    allowedContractsInWindow[3][
      0xeDa3b617646B5fc8C9c696e0356390128cE900F8
    ] = true; // JADU Hoverboards
  }

  function updateBeneficiaryWallet(address _wallet) public onlyOwner {
    _beneficiaryWallet = _wallet;
  }

  function updateSigner(address __signer) public onlyOwner {
    _signer = __signer;
  }

  function _hash(string calldata salt, address _address)
    public
    view
    returns (bytes32)
  {
    return keccak256(abi.encode(salt, address(this), _address));
  }

  function _verify(bytes32 hash, bytes memory token)
    public
    view
    returns (bool)
  {
    return (_recover(hash, token) == _signer);
  }

  function _recover(bytes32 hash, bytes memory token)
    public
    pure
    returns (address)
  {
    return hash.toEthSignedMessageHash().recover(token);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A)
    returns (string memory)
  {
    return string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
  }

  function baseTokenURI() public view virtual returns (string memory) {
    return _tokenUriBase;
  }

  function setTokenURI(string memory tokenUriBase_) public onlyOwner {
    _tokenUriBase = tokenUriBase_;
  }

  function setStateToSetup() public onlyOwner {
    _state = State.Setup;
  }

  function startWindowOne() public onlyOwner {
    _state = State.WindowOne;
  }

  function startWindowTwo() public onlyOwner {
    _state = State.WindowTwo;
  }

  function startWindowThree() public onlyOwner {
    _state = State.WindowThree;
  }

  function startPublicSale() public onlyOwner {
    _state = State.PublicSale;
  }

  function setStateToFinished() public onlyOwner {
    _state = State.Finished;
  }

  function updateAllowedContractsInWindow(
    uint256 window,
    address contractAddress,
    bool allowed
  ) public onlyOwner {
    allowedContractsInWindow[window][contractAddress] = allowed;
  }

  function currentContractIsAllowedToMint(address contractAddress)
    public
    view
    returns (bool)
  {
    uint256 key = 0;
    if (_state == State.Setup || _state == State.Finished) {
      return false;
    }
    if (_state == State.WindowOne) {
      key = 1;
    } else if (_state == State.WindowTwo) {
      key = 2;
    } else if (_state == State.WindowThree) {
      key = 3;
    }
    return allowedContractsInWindow[key][contractAddress];
  }

  function isTokenOwner(
    address _contractAddress,
    uint256 tokenId,
    address _address
  ) public view returns (bool) {
    address owner_ = IERC721(_contractAddress).ownerOf(tokenId);
    if (owner_ == _address) {
      return true;
    } else {
      return false;
    }
  }

  function hasTokenMintedBatch(
    address[] calldata _contractAddresses,
    uint256[] calldata _tokens
  ) public view returns (bool[] memory) {
    require(
      _contractAddresses.length == _tokens.length,
      "Arrays are not identical in length"
    );
    uint256 amount = _contractAddresses.length;
    bool[] memory results = new bool[](amount);
    for (uint256 i = 0; i < amount; i++) {
      results[i] = tokenMinted[_contractAddresses[i]][_tokens[i]];
    }
    return results;
  }

  function mint(
    address[] memory contractAddresses,
    uint256[] memory tokenIdsToMint
  ) external payable nonReentrant {
    require(_state != State.Setup, "Sale is not active.");
    require(_state != State.Finished, "Sale has already finished.");
    require(_state != State.PublicSale, "Sale has should not be publicsale.");
    uint256 amount = tokenIdsToMint.length;
    require(amount > 0, "You can't mint 0 Burrows");
    require(
      amount == contractAddresses.length,
      "Both arrays have to be identical in length"
    );
    require(
      totalSupply() + amount <= MAX_BURROWS,
      "Amount should not exceed max supply of Burrows."
    );
    require(
      msg.value >= BURROWS_PRICE * amount,
      "Ether value sent is incorrect."
    );

    for (uint256 i = 0; i < amount; i++) {
      require(isTokenOwner(contractAddresses[i], tokenIdsToMint[i],
       msg.sender) == true, "You can't mint someone else's Burrow");
      require(
        currentContractIsAllowedToMint(contractAddresses[i]) == true,
        "The given contract is not allowed to mint, maybe later?"
      );
      require(
        tokenMinted[contractAddresses[i]][tokenIdsToMint[i]] == false,
        "This token has already minted"
      );
      tokenMinted[contractAddresses[i]][tokenIdsToMint[i]] = true;
    }

    _safeMint(msg.sender, amount);
    uint256 fromTokenId = totalSupply() - amount;
    forwardEther(_beneficiaryWallet);
    emit Minted(
      msg.sender,
      contractAddresses,
      tokenIdsToMint,
      fromTokenId,
      (totalSupply() - 1),
      amount
    );
  }

  function publicMint(
    string calldata salt,
    bytes calldata token,
    uint256 amount
  ) external payable nonReentrant {
    require(_state == State.PublicSale, "Public sale is not active.");
    require(
      !Address.isContract(msg.sender),
      "Contracts are not allowed to mint burrows."
    );
    require(amount <= MAX_MINT, "You can only mint 5 Burrows at a time.");
    require(
      totalSupply() + amount <= MAX_BURROWS,
      "Amount should not exceed max supply of Burrows."
    );
    require(
      msg.value >= BURROWS_PRICE * amount,
      "Ether value sent is incorrect."
    );
    require(!usedToken[token], "The token has been used.");
    require(_verify(_hash(salt, msg.sender), token), "Invalid token.");
    usedToken[token] = true;
    _safeMint(msg.sender, amount);
    forwardEther(_beneficiaryWallet);
    emit PublicMinted(msg.sender, amount);
  }

  function forwardEther(address _to) public payable {
    (bool sent, bytes memory data) = _to.call{value: msg.value}("");
    require(sent, "Failed to send Ether");
  }

  function withdrawAll(address recipient) public onlyOwner {
    uint256 balance = address(this).balance;
    payable(recipient).transfer(balance);
    emit BalanceWithdrawn(recipient, balance);
  }

  function withdrawAllViaCall(address payable _to) public onlyOwner {
    uint256 balance = address(this).balance;
    (bool sent, bytes memory data) = _to.call{value: balance}("");
    require(sent, "Failed to send Ether");
  }
}