// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*[email protected]%###%%@==*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*.   +      +   .*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@- .+   .-:::::-   =. [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@#*+++++++++++%@@@@@@@@@#@@@@@@@@@@%%%%%%%%%@@@@@@@@@@@@@.   .=            -:   [email protected]@@@@@%%@%%%%%%%%@@@@@@@@@@@@@@%%%%@@@@@@@@@%%%@%%%%%%%%%%%%%@@@%*+++++++++++#@@
//@%-           :*@@@@@@@@@@= .%@@@@@@@@--.       [email protected]@@@@@@#*   :-.--::.  ..:--:-:   *%@@@@. +.        :*@@@@@@%+-.      .==#@@@@   :=:::+      .%@*.           =#@@@
//@-:: -#######%@@@@@@@@@@@-    #@@@@@@@ =: -===-.    [email protected]@@@@-+ .-.      .::..     .-: [email protected]@@@. +.:=====.   [email protected]@@@-    .-===-+.-=:*@@+=====  *.:====%@#::: *#######@@@@@@
//@- .+=+*******%@@@@@@@@%:      *@@@@@@ =: *@@@@@%.   [email protected]@@@.*+:   =##-       +%#:  [email protected]@@@. :--%%%%-    [email protected]@@.   -%@@@@@@@*  =-*@@@@@@@. *:*@@@@@@#  ==+*******#@@@@@
//@@+. .:::::::[email protected]@@@@#.   :    [email protected]@@@@ =: *@@@@@@*    @@@@.+=    %@@%      [email protected]@@*   =:[email protected]@@@.             [email protected]@#    @@@@@@@@@@=   [email protected]@@@@@@. ..*@@@@@@@%-  .::::::--==#@@
//@@@@@%######*. :*[email protected]@@#-:::*@#.   [email protected]@@@ :-:#@@@@@%:   [email protected]@@@.+=    %@@%  ..  [email protected]@@*   [email protected]@@@.   =%%%%%%-   :@@-=. -%@@@@@@@*.   [email protected]@@@@@@.   [email protected]@@@@@@@@@%#######+  +-%@
//@@*+++++++++=    [email protected]@+    ==---::::=%@@    *+++=:    [email protected]@@@@:+=    *@@+.*-:=+ #@@-   +:[email protected]@@@.   +*++++=.   [email protected]@%-==.==-=+=-    .*@@@@@@@@.   [email protected]@@@@@@@++++++++++:    %@
//@@:            -#@@-   .-------:  [email protected]@    *.     :+%@@@@@@=+ :=                  :-.=*@@@@.   :-:*.    -#@@@@@%+=:       .=*@@@@@@@@@@.   [email protected]@@@@@@%            .=%@@
//@@%##########%@@@@@####@@@@@@@@@%@@@@@%###@%#%%@@@@@@@@@@@%*  :-      ::::.     .=  #@@@@@%######@%#%%@@@@@@@@@@@@@%%#%%@@@@@@@@@@@@@@%###@@@@@@@@@##########%@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=  .:::::=    -:::::: .*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+:.              :=*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#*******#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@[email protected]@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@

import "./ERC721A.sol"; // Azuki ERC721 contract @ https://www.azuki.com/erc721a
import "./DutchAuctionSC.sol"; //SignorCyrpto Dutch Action contract (https://signorcrypto.com)
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SadBots is ERC721A, Ownable, ReentrancyGuard, DutchAuctionSC {
  // Smart contract status
  enum MintStatus {
    CLOSED,
    PRESALE,
    DUTCH_AUCTION
  }
  MintStatus public status = MintStatus.CLOSED;

  // ERC721 params
  string private _name = "Sad Bots";
  string private _symbol = "SAD";
  string private _baseTokenURI = "https://mint.sadbots.io/api/metadata/";

  // Collection params
  uint256 public TOTAL_SUPPLY = 8888;
  uint256 public RESERVED_SUPPLY = 500;

  uint256 public reserved_supply = RESERVED_SUPPLY;
  uint256 public public_supply = TOTAL_SUPPLY - reserved_supply;
  uint256 public presale_minted = 0;

  uint256 private PRESALE_PRICE = 0.15 ether;
  uint256 private DUTCH_START_PRICE = 0.5 ether;
  uint256 private DUTCH_END_PRICE = 0.2 ether;
  uint256 private STEP_TIME = 15 * 60; //seconds
  uint256 public STEP_PRICE = 0.05 ether;

  uint256 private MAX_MINT = 50;
  uint256[3] private MAX_PER_STATUS = [0, 1, 5];

  // Amount minted
  mapping(address => uint256[3]) private _amountMinted;

  // Merkle tree
  bytes32 public merkleRoot =
    0xc55bcf18f33672992dc75baf50baaf03ae6ad9431853a4ed4415d65687b62597; // TODO: Update it

  // Event declaration
  event ChangedStatusEvent(uint256 newStatus);
  event ChangedBaseURIEvent(string newURI);
  event ChangedMerkleRoot(bytes32 newMerkleRoot);

  // Modifier to check claiming requirements
  modifier qtyValidation(uint256 _qty) {
    require(status != MintStatus.CLOSED, "Minting is closed");
    require(public_supply > 0, "Collection is sold out");
    require(_qty <= public_supply, "Not enough NFTs available");
    require(_qty > 0, "NFTs amount must be greater than zero");
    require(
      _qty + _amountMinted[msg.sender][uint256(status)] <=
        MAX_PER_STATUS[uint256(status)],
      "Exceeded the max amount of mintable NFT"
    );
    uint256 price = getPrice() * _qty;
    require(msg.value >= price, "Ether sent is not correct");
    _;
  }

  // Constructor
  constructor()
    ERC721A(_name, _symbol, MAX_MINT, TOTAL_SUPPLY)
    DutchAuctionSC(DUTCH_START_PRICE, DUTCH_END_PRICE, STEP_TIME, STEP_PRICE)
  {
    _safeMint(msg.sender, 1);
  }

  function getPrice() public view returns (uint256) {
    if (status == MintStatus.PRESALE || status == MintStatus.CLOSED) {
      return PRESALE_PRICE;
    } else if (status == MintStatus.DUTCH_AUCTION) {
      return currentPrice();
    }
  }

  // Owner mint function
  function ownerMint(
    address[] calldata _address_list,
    uint256[] calldata _qty_list
  ) external nonReentrant onlyOwner {
    require(reserved_supply > 0, "Collection is sold out");
    require(
      _address_list.length == _qty_list.length,
      "The two list must contains the same amount of elements"
    );
    uint256 qty_tot = 0;
    for (uint256 i; i < _qty_list.length; i++) {
      require(_qty_list[i] > 0, "Qty must be positive");
      require(_qty_list[i] <= MAX_MINT, "Qty exceed the max");
      qty_tot += _qty_list[i];
    }
    require(qty_tot <= reserved_supply, "Not enough NFTs available");

    // Update reserved_supply
    reserved_supply -= qty_tot;
    for (uint256 i; i < _address_list.length; i++) {
      _safeMint(_address_list[i], _qty_list[i]);
    }
  }

  // Pre-sale mint
  function presaleMint(uint256 _qty, bytes32[] calldata _proof)
    external
    payable
    nonReentrant
    qtyValidation(_qty)
  {
    require(status == MintStatus.PRESALE, "Status is not presale");

    require(
      MerkleProof.verify(
        _proof,
        merkleRoot,
        keccak256(abi.encodePacked(msg.sender))
      ),
      "You are not in presale"
    );
    presale_minted += _qty;
    _privateMint(_qty);
  }

  //Dutch auction mint
  function mint(uint256 _qty)
    external
    payable
    nonReentrant
    qtyValidation(_qty)
  {
    require(status == MintStatus.DUTCH_AUCTION, "Status is not dutch auction");
    require(isDutchAuctionStarted(), "Dutch action not started yet");

    _privateMint(_qty);
  }

  function _privateMint(uint256 _qty) private {
    _amountMinted[msg.sender][uint256(status)] += _qty;
    public_supply -= _qty;
    _safeMint(msg.sender, _qty);
  }

  // Getters
  function tokenExists(uint256 _id) public view returns (bool) {
    return _exists(_id);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function getStatus()
    external
    view
    returns (
      string memory status_,
      uint256 qty_,
      uint256 price_,
      uint256 counter_
    )
  {
    uint256 mintedInStatus = _amountMinted[msg.sender][uint256(status)];
    uint256 maxStatus = MAX_PER_STATUS[uint256(status)];
    uint256 _remainingToMint = maxStatus - mintedInStatus;
    uint256 _price = getPrice();

    if (public_supply == 0) {
      return ("SOLD_OUT", 0, _price, 0);
    }
    if (status == MintStatus.DUTCH_AUCTION) {
      return ("DUTCH_AUCTION", _remainingToMint, _price, public_supply);
    } else if (status == MintStatus.PRESALE) {
      return ("PRESALE", _remainingToMint, _price, presale_minted);
    } else {
      return ("CLOSED", _remainingToMint, _price, public_supply);
    }
  }

  function _baseURI()
    internal
    view
    virtual
    override(ERC721A)
    returns (string memory)
  {
    return _baseTokenURI;
  }

  // Setters
  function setStatus(uint8 _status) external onlyOwner {
    // _status -> 0: CLOSED, 1: PRESALE, 2: DUTCH_AUCTION
    require(
      _status >= 0 && _status <= 2,
      "Mint status must be between 0 and 2"
    );
    status = MintStatus(_status);
    if (status == MintStatus.DUTCH_AUCTION) {
      _setStartTime(block.timestamp);
    }
    emit ChangedStatusEvent(_status);
  }

  function setBaseURI(string memory _URI) external onlyOwner {
    _baseTokenURI = _URI;
    emit ChangedBaseURIEvent(_URI);
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
    emit ChangedMerkleRoot(_merkleRoot);
  }

  function setDutchAcutionParams(
    uint256 _startPrice,
    uint256 _endPrice,
    uint256 _stepTime,
    uint256 _stepPrice
  ) external onlyOwner {
    _setDutchAcutionParams(_startPrice, _endPrice, _stepTime, _stepPrice);
  }

  // Withdraw function
  function withdrawAll(address payable withdraw_address)
    external
    payable
    nonReentrant
    onlyOwner
  {
    require(withdraw_address != address(0), "Withdraw address cannot be zero");
    require(address(this).balance != 0, "Balance is zero");
    payable(withdraw_address).transfer(address(this).balance);
  }
}