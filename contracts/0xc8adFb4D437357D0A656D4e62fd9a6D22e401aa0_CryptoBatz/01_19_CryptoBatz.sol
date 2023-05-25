// SPDX-License-Identifier: None
pragma solidity 0.8.8;

//.......................................;+++*%%%%%%%%%%?++++,............................................................
//..................................:????%%?**:,:,,,,,:,;**?S%+...........................................................
//.............................::;%%%?*+;:,,,::;++++;:::::[email protected]?...........................................................
//.........................,++*%%?:::,,,;;;;+********;::+%%*,,,...................................................;+++;...
//......................:?????+,,:;;++++*************+:;%@:.....................................................:??*?**?:.
//...................,:?%?*;,::+++******************;::[email protected]:....................................................,;@;,,,;@+,
//..................;*%+;:;;*+++;::::;+************+:::?%S,....................................................SS,::+++:%#
//................:??+,;+*+++::::::;+***;+********;::;[email protected]?......................................................S#,+?%%?:[email protected]
//.............,:??+:;+;;;:::::::;+***+;:;;*******;::;*@?....................................................:S+;;*?***%#@
//............;*%;:;+;::::::::::+***+::::::*++***?+::;*@?....................................................;@;:S*+****#@
//..........;*?+,;++:::::::::::;**+;::::::;*;:***%*:;+*@?...................................................+*?;;*?%%?**#@
//.......,:%*+:;+;;:::::::::::;*+;:::::::;+;::***S*:*%#+:.,,,,,...................................,,,......,SS,*%*?%?***#@
//.....,:*%;::+;;::::::::::::+*+;:::::::;++:::***%+:[email protected],.,S#SS?;................................:*S#?.....;@+:+*?*SS**?+#@
//.....,@?:;;+:::::::::::::::++::::::::;*;::::***%*:[email protected],.,#S++*?*;............................:*%[email protected]%....+*?;[email protected]?**S#*S#%#@
//....+%*+:*+::::::::::::::;+;;::::::::;*;::::***S*:[email protected],.,#S;::,+*%:,.......................,%?*:;[email protected]%.,;%*;,?%?*?S#S*S#?#@
//..,:?#:;+;:::::::::::::::;*;::::::::+*+;:::;*[email protected]?:[email protected],.,#%:;;:::;??:,...................:*S?+::+*@%:%?:;*[email protected]**?##S*S#*#@
//..,@?:;;::::::::::::::::;;+;::::::::+*::::::*?%#?;[email protected],.,@%,;;;::::;?*;....;*********+.:*S%*:::***@#?::*S##S%*?%##S*[email protected]#@@
//.+%?;:;;::::::::::::::::*+::::::::::++::::::*?%#%**[email protected],..+?%:,;+;:::,+*%%%????*******??#@*+;:;+***@%,[email protected]###?**S###S*?%#@@
//:%#:+?+++?*+?+::::::::::*+::::::::;*;;:::::;*?S#%**%#;,..+#+:,:;*;:::+#%*+:,,,,,,,,,,;;+#?::;**?#@S;[email protected]####*?#####S**?##S
//@%**?%%%%%%%%?*::::::::;+;::::::::;*;:::::::*?%###***@?...,#%.,:+;;::;+;::,,,,,,,,,,,,,,***;+**%@@@####@S*?%#####S*[email protected]@+,
//@#S*:........:*%*:::::;*;:::::::::;*;::::::;*?%###S?*%%?,..+*?:,:++:;;:::::,,,,,,,,,,,,:;;;****%@####S?%%%########%##*:.
//#*:............:*S+;::;+;::::::::++;::::::::+**?S#@S*+%@;,..;@+;:+*+**;***+;::::::::::+****+;;*[email protected]####%*S#@######%?#@#...
//,................,?%%%?*;;:::::::++::::::::::+*%S####***S%+,.,##*****[email protected]@@SS%***+++++**[email protected]@#S%*:[email protected]@###??###S%%###@?*#@#...
//...................:****S%+;:::::++::::::::::+*%S####S?**?S?+.##****++??*:::;;+%%%%SS+*??+:::;[email protected]@###*?##S*S####%%[email protected]%+...
//........................:*@+:::::++::::::::::+*?%####@S****?%%@#**+;:::::::::::[email protected]@%+::::::::;[email protected]@###?%#@S*S###[email protected]@;....
//.........................:S*+::;*;:::::::::::+**?%S#####%***[email protected]#*;:::::::::::::::::::::::::::;#@##S?###S%?###S%+##,.....
//...........................S#::;*;:::::::::::;+*?%%S#####S%*?%#S*;::::::;%%%%%%%%??%%%%%%+::::@@#######*[email protected]###?*S?+......
//.........................,,SS::;*;::::::::::::;*?S%S#######SS?##S*++;:::;****************+:;*S#########??####?%@;.......
//.........................;@+::+*+;:::::::::::;+**?%%%#############S?*+;;;;;;;;;;;;;;;;::+*?#@@#####S#S*S##%??##S;.......
//.........................;@*;:++:::::::::::::;+;+*%%%#########SS####S%%***************?SS#@######%%%#S*S##@@@%+.........
//.........................;@*;+*+::::::::::::++;++*?%S#########+;++?##@@SSSSSSSSSSSSSS*[email protected]@@#######*[email protected]%%S#@@*;;,..........
//........................:*#*+**+::::::::::::;++****?%S######%*+;::;*%SS#@#############%[email protected]@#@####S?%#@%:,,,..............
//........................#@SSSS?+::::::::::;;+;+****?%%S###%+;::::::::;+?S############@%*@@@@@##%*#@@%+..................
//........................;+++++%%;:::::::::;;++*****?S###%*;::::::::::::+*?S##########@%*@@@@@@@S*#%+,...................
//..............................,;%*+:::::::;+;+*****?%#S*;::::::::::::::+?S############%[email protected]@S:::SSS;,.....................
//................................,*??;:::::;;;+****%%%#%*::::::::::::::;+*%###########*[email protected]%;..............................
//..................................,+?%%%%%*++**++*%%S#%*;:::::::::::;+*%%%S########S%S?+................................
//....................................,:::::*%SSS%[email protected]#@@@S**+;::::::;;+*?S%%###SSSS%%%S%:,.................................
//...........................................,,.,+%S#@@@S****;;;;+%**%%%%S#SS%%%%%%%%;,...................................
//.............................................+%%%[email protected]@@@S*%SSSS#S#@##@#[email protected]@#SS%*++*:.......................................
//..........................................,;SS%#@@;;+#S*[email protected]@@@%%%#@@+:::::::............................................
//..........................................+%@@#%%%+?S%[email protected]@@@#S?#@@@#%:...................................................
//...........................................,+*+...*[email protected]@@@S*%#@@@@?;.....................................................
//...................................................,;::::,.:;::::........,..............................................
//.....................................................................,+?%#S*,...........................................
//..................................................................,;%#@@@@@@#*,,.....................,++................
//...........................................................*%%%%%[email protected]@@@#@@@@@@@@S%+................:[email protected]#*................
//...........................................................::[email protected]@@@@@S,*@@@@@@@S;,............:+?%@@@S,.................
//.,;++++;..,;+++++;,.,;+;...,++:,;++++++:..;+++++++;..:+++++:...*@@@@@S..;#@@@@@+..............;[email protected]@@@#:..................
//*[email protected]@@@@@?:;@@@@@@@%+;@@@;.,[email protected]@S:@@@@@@@@*;@@@@@@@@@:*#@@@@@@*:[email protected]@@@@S...%@@@@@+..,,......,,...,[email protected]@@#.;;.,,......,,.....
//@@@?::S#@+;@@@+:[email protected]@@:%@@@*[email protected]@S*:@@@+:;@@@*:;*@@@*;:;@@@+:;@@@*[email protected]@@@@S...%@@@@@+.,S#+....;S#;:;;[email protected]@@#;##:S#:...;%@#;....
//@@@+..,,,.;@@@##@@S+..*#@@@#S:.:@@@%?%@@#+..:@@@:..;@@@:.,@@@[email protected]@@@@S.:+#@@@@#+*[email protected]@@%*+?#@@@@@@@@@@@@@@@@@@%*%@@@@#+:..
//@@@*::S#@+:@@@[email protected]@S:..,#@@*...:@@@#SSS?,...:@@@:..;@@@;:;@@@*[email protected]@@@@@%@@@@@#*::%@@@@@%%@@@@@@%;[email protected]@@#+#@@@@#%@@@@@@#%?,.
//*[email protected]@@@@@?:;@@@:.,@@@;..,#@@*...:@@@;........:@@@;..,[email protected]@@@@@@?:[email protected]@@@@S:+%@@@@#%*[email protected]?;,:#@@@@?..%@@@#.?%[email protected]#,*@@@@@*,....
//.:+++++;..,+++,.,+++,...;++:...,+++,........,+++,....;+++++;[email protected]@@@@S..:#@@@@@@@++*%#[email protected]@@@@*..%@@@#,..;*:;@@@@@;*+....
//.[email protected]@@@@S...%@@@@@[email protected]@@@@:,#@@@@*..%@@@#.....;@@@@@*.#@:...
//.[email protected]@@@@S...%@@@@@+,[email protected]@@@,[email protected]@@@*.,[email protected]@@@;..:%@@@@@*.*@@?...
//.[email protected]@@@@#*;,%@@@@@?%@@@@@%%@@@@@#%#@@@@@@*%@@@@@@#%[email protected]@@@%;.
//..............................................................:*@@@@@@@@S#@@@@@%[email protected]@@S**%@@@@[email protected]@@#[email protected]@@@@?;?%@@@@%+.
//...........................................................,*[email protected]@@@@@@@S+,,,;+%@@+:%#*,...;##;...,[email protected]?,...:S#?:....;#S:...
//..........................................................+#@@##@@@@@+,.......,+:..,......,,......,,.....,,.......,,....
//..........................................................*@@+,,:*#S;...................................................
//[email protected]?,...::....................................................

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./SutterTreasury.sol";
import "./ERC2981.sol";

struct PresaleConfig {
  uint32 startTime;
  uint32 endTime;
  uint32 supplyLimit;
  uint256 mintPrice;
}

struct DutchAuctionConfig {
  uint32 txLimit;
  uint32 startTime;
  uint32 bottomTime;
  uint32 stepInterval;
  uint256 startPrice;
  uint256 bottomPrice;
  uint256 priceStep;
}

contract CryptoBatz is Ownable, ERC721, ERC2981, SutterTreasury {
  using Address for address;
  using SafeCast for uint256;
  using ECDSA for bytes32;

  // EVENTS *****************************************************
  event StartingIndexSet(uint256 _value);
  event ProvenanceHashUpdated(uint256 _hash);
  event WhitelistSignerUpdated(address _signer);
  event BaseUriUpdated(string _uri);
  event AncientBatzMinterUpdated(address _address);
  event AncientBatzMinted(address indexed _to, uint256 indexed _id);
  event PresaleConfigUpdated();
  event DutchAuctionConfigUpdated();

  // MEMBERS ****************************************************

  uint256 public constant MAX_OWNER_RESERVE = 100;
  uint256 public constant ANCIENT_BATZ_SUPPLY = 99;
  uint256 public constant CRYPTO_BATZ_SUPPLY = 9666;

  uint256 public totalSupply = 0;

  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  PresaleConfig public presaleConfig;
  DutchAuctionConfig public dutchAuctionConfig;

  string public baseURI;
  address public whitelistSigner;
  address public ancientBatzMinter;

  uint256 public PROVENANCE_HASH;
  uint256 public randomizedStartIndex;

  mapping(address => uint256) private presaleMinted;

  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private constant TYPEHASH =
    keccak256("presale(address buyer,uint256 limit)");

  address[] private mintPayees = [
    0xaDC6A7985036531c394B6dF054666C51dE29b9a9, //Ozzy
    0x76bf7b1e22C773754EBC608d92f71cc0B5D99d4B, //Sutter
    0x8b8AbE9CEC13CF5050517816B2E95722E711818e //Dev
  ];

  uint256[] private mintShares = [50, 45, 5];

  SutterTreasury public royaltyRecipient;

  // CONSTRUCTOR **************************************************

  constructor(string memory initialBaseUri)
    ERC721("CryptoBatz by Ozzy Osbourne", "BATZ")
    SutterTreasury(mintPayees, mintShares)
  {
    baseURI = initialBaseUri;

    ancientBatzMinter = msg.sender;

    presaleConfig = PresaleConfig({
      startTime: 1642633200, // Wed Jan 19 2022 23:00:00 GMT+0000
      endTime: 1642719600, //	Thu Jan 20 2022 23:00:00 GMT+0000
      supplyLimit: 8000,
      mintPrice: 0.088 ether
    });

    dutchAuctionConfig = DutchAuctionConfig({
      txLimit: 3,
      startTime: 1642721400, // Thu Jan 20 2022 23:30:00 GMT+0000
      bottomTime: 1642735800, // Fri Jan 21 2022 03:30:00 GMT+0000
      stepInterval: 60, // 1 minute
      startPrice: 1.666 ether,
      bottomPrice: 0.1 ether,
      priceStep: 0.006525 ether
    });

    address[] memory royaltyPayees = new address[](2);
    royaltyPayees[0] = 0xaDC6A7985036531c394B6dF054666C51dE29b9a9; //Ozzy
    royaltyPayees[1] = 0x76bf7b1e22C773754EBC608d92f71cc0B5D99d4B; //Sutter

    uint256[] memory royaltyShares = new uint256[](2);
    royaltyShares[0] = 70;
    royaltyShares[1] = 30;

    royaltyRecipient = new SutterTreasury(royaltyPayees, royaltyShares);

    _setRoyalties(address(royaltyRecipient), 750); // 7.5% royalties

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("CryptoBatz")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  // PUBLIC METHODS ****************************************************

  /// @notice Allows users to buy during presale, only whitelisted addresses may call this function.
  ///         Whitelisting is enforced by requiring a signature from the whitelistSigner address
  /// @dev Whitelist signing is performed off chain, via the cryptobatz website backend
  /// @param signature signed data authenticating the validity of this transaction
  /// @param numberOfTokens number of NFTs to buy
  /// @param approvedLimit the total number of NFTs this address is permitted to buy during presale, this number is also encoded in the signature
  function buyPresale(
    bytes calldata signature,
    uint256 numberOfTokens,
    uint256 approvedLimit
  ) external payable {
    PresaleConfig memory _config = presaleConfig;

    require(
      block.timestamp >= _config.startTime && block.timestamp < _config.endTime,
      "Presale is not active"
    );
    require(whitelistSigner != address(0), "Whitelist signer has not been set");
    require(
      msg.value == (_config.mintPrice * numberOfTokens),
      "Incorrect payment"
    );
    require(
      (presaleMinted[msg.sender] + numberOfTokens) <= approvedLimit,
      "Mint limit exceeded"
    );
    require(
      (totalSupply + numberOfTokens) <= _config.supplyLimit,
      "Not enough BATZ remaining"
    );

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(TYPEHASH, msg.sender, approvedLimit))
      )
    );
    address signer = digest.recover(signature);
    require(
      signer != address(0) && signer == whitelistSigner,
      "Invalid signature"
    );

    presaleMinted[msg.sender] = presaleMinted[msg.sender] + numberOfTokens;

    mint(msg.sender, numberOfTokens);
  }

  /// @notice Allows users to buy during public sale, pricing follows a dutch auction format
  /// @dev Preventing contract buys has some downsides, but it seems to be what the NFT market generally wants as a bot mitigation measure
  /// @param numberOfTokens the number of NFTs to buy
  function buyPublic(uint256 numberOfTokens) external payable {
    // disallow contracts from buying
    require(
      (!msg.sender.isContract() && msg.sender == tx.origin),
      "Contract buys not allowed"
    );

    DutchAuctionConfig memory _config = dutchAuctionConfig;

    require(
      (totalSupply + numberOfTokens) <= CRYPTO_BATZ_SUPPLY,
      "Not enough BATZ remaining"
    );
    require(block.timestamp >= _config.startTime, "Sale is not active");
    require(numberOfTokens <= _config.txLimit, "Transaction limit exceeded");

    uint256 mintPrice = getCurrentAuctionPrice() * numberOfTokens;
    require(msg.value >= mintPrice, "Insufficient payment");

    // refund if customer paid more than the cost to mint
    if (msg.value > mintPrice) {
      Address.sendValue(payable(msg.sender), msg.value - mintPrice);
    }

    mint(msg.sender, numberOfTokens);
  }

  /// @notice Gets the current price for the duction auction, based on current block timestamp
  /// @dev Dutch auction parameters configured via dutchAuctionConfig
  /// @return currentPrice Current mint price per NFT
  function getCurrentAuctionPrice() public view returns (uint256 currentPrice) {
    DutchAuctionConfig memory _config = dutchAuctionConfig;

    uint256 timestamp = block.timestamp;

    if (timestamp < _config.startTime) {
      currentPrice = _config.startPrice;
    } else if (timestamp >= _config.bottomTime) {
      currentPrice = _config.bottomPrice;
    } else {
      uint256 elapsedIntervals = (timestamp - _config.startTime) /
        _config.stepInterval;
      currentPrice =
        _config.startPrice -
        (elapsedIntervals * _config.priceStep);
    }

    return currentPrice;
  }

  /// @notice Gets an array of tokenIds owned by a wallet
  /// @param wallet wallet address to query contents for
  /// @return an array of tokenIds owned by wallet
  function tokensOwnedBy(address wallet)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      ownedTokenIds[i] = _ownedTokens[wallet][i];
    }

    return ownedTokenIds;
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  // OWNER METHODS ********************************************************

  /// @notice Allows the contract owner to reserve NFTs for team members or promotional purposes
  /// @dev This should be called before presale or public sales start, as only the first MAX_OWNER_RESERVE tokens can be reserved
  /// @param to address for the reserved NFTs to be minted to
  /// @param numberOfTokens number of NFTs to reserve
  function reserve(address to, uint256 numberOfTokens) external onlyOwner {
    require(
      (totalSupply + numberOfTokens) <= MAX_OWNER_RESERVE,
      "Exceeds owner reserve limit"
    );

    mint(to, numberOfTokens);
  }

  /// @notice Allows the owner to roll a pseudo-random number once, which will be used as the starting index for the token metadata.
  ///         This is used to prove randomness and fairness in the metadata distribution, in conjunction with the PROVENANCE_HASH
  /// @dev The starting index can only be set once, only after the start of the public sale, and only if the PROVENANCE_HASH has been set
  function rollStartIndex() external onlyOwner {
    require(PROVENANCE_HASH != 0, "Provenance hash not set");
    require(randomizedStartIndex == 0, "Index already set");
    require(
      block.timestamp >= dutchAuctionConfig.startTime,
      "Too early to roll start index"
    );

    uint256 number = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(block.number - 1),
          block.coinbase,
          block.difficulty,
          block.timestamp
        )
      )
    );

    randomizedStartIndex = (number % CRYPTO_BATZ_SUPPLY) + 1;

    emit StartingIndexSet(randomizedStartIndex);
  }

  /// @notice Allows the ancientBatzMinter to mint an AncientBatz to the specified address
  /// The Hanging Judge
  /// @param to the address for the AncientBatz to be minted to
  /// @param ancientBatzId the AncientBatz id, from 1 to ANCIENT_BATZ_SUPPLY inclusive
  function mintAncientBatz(address to, uint256 ancientBatzId) external {
    require(ancientBatzMinter != address(0), "AncientBatz minter not set");
    require(
      msg.sender == ancientBatzMinter,
      "Must be authorized AncientBatz minter"
    );
    require(
      ancientBatzId > 0 && ancientBatzId <= ANCIENT_BATZ_SUPPLY,
      "Invalid AncientBatz Id"
    );

    uint256 tokenId = CRYPTO_BATZ_SUPPLY + ancientBatzId;

    emit AncientBatzMinted(to, ancientBatzId);
    _safeMint(to, tokenId);

    totalSupply++;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    emit BaseUriUpdated(newBaseUri);
    baseURI = newBaseUri;
  }

  function setWhitelistSigner(address newWhitelistSigner) external onlyOwner {
    emit WhitelistSignerUpdated(newWhitelistSigner);
    whitelistSigner = newWhitelistSigner;
  }

  function setAncientBatzMinter(address newMinter) external onlyOwner {
    emit AncientBatzMinterUpdated(newMinter);
    ancientBatzMinter = newMinter;
  }

  function setProvenance(uint256 provenanceHash) external onlyOwner {
    require(randomizedStartIndex == 0, "Starting index already set");

    emit ProvenanceHashUpdated(provenanceHash);
    PROVENANCE_HASH = provenanceHash;
  }

  /// @notice Allows the contract owner to update start and end time for the presale
  function configurePresale(uint256 startTime, uint256 endTime)
    external
    onlyOwner
  {
    uint32 _startTime = startTime.toUint32();
    uint32 _endTime = endTime.toUint32();

    require(0 < _startTime, "Invalid time");
    require(_startTime < _endTime, "Invalid time");
    require(_endTime <= dutchAuctionConfig.startTime, "Invalid time");

    presaleConfig.startTime = _startTime;
    presaleConfig.endTime = _endTime;

    emit PresaleConfigUpdated();
  }

  /// @notice Allows the contract owner to update config for the public dutch auction
  function configureDutchAuction(
    uint256 startTime,
    uint256 bottomTime,
    uint256 stepInterval,
    uint256 startPrice,
    uint256 bottomPrice,
    uint256 priceStep
  ) external onlyOwner {
    uint32 _startTime = startTime.toUint32();
    uint32 _bottomTime = bottomTime.toUint32();
    uint32 _stepInterval = stepInterval.toUint32();

    require(presaleConfig.endTime <= _startTime, "Invalid time");
    require(_startTime < _bottomTime, "Invalid time");
    require(0 < stepInterval, "0 step interval");
    require(bottomPrice < startPrice, "Invalid start price");
    require(0 < bottomPrice, "Invalid bottom price");
    require(0 < priceStep && priceStep < startPrice, "Invalid price step");

    dutchAuctionConfig.startTime = _startTime;
    dutchAuctionConfig.bottomTime = _bottomTime;
    dutchAuctionConfig.stepInterval = _stepInterval;
    dutchAuctionConfig.startPrice = startPrice;
    dutchAuctionConfig.bottomPrice = bottomPrice;
    dutchAuctionConfig.priceStep = priceStep;

    emit DutchAuctionConfigUpdated();
  }

  // PRIVATE/INTERNAL METHODS ****************************************************

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function mint(address to, uint256 numberOfTokens) private {
    uint256 newId = totalSupply;

    for (uint256 i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(to, newId);
    }

    totalSupply = newId;
  }

  // ************************************************************************************************************************
  // The following methods are borrowed from OpenZeppelin's ERC721Enumerable contract, to make it easier to query a wallet's
  // contents without incurring the extra storage gas costs of the full ERC721Enumerable extension
  // ************************************************************************************************************************

  /**
   * @dev Private function to add a token to ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
    private
  {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from != address(0)) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to != address(0)) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }
}