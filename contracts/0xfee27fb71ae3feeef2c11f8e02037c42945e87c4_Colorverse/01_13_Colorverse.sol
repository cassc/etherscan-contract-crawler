// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface AggregatorV3Interface {
  function latestAnswer() external view returns (int256);
}

interface ERC20 {
  function balanceOf(address tokenOwner) external view returns (uint balance);
  function transfer(address to, uint tokens) external returns (bool success);
}

interface Founder {
   function register(uint256[16] calldata _tokenIds, address founderAddr) external;
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract Colorverse is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor () public {
        _name = "Colorverse";  //// Change for MAINNET
        _symbol = "RGB";   //// Change for MAINNET
        _owner = msg.sender;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
    //Upper bound of possbile "True Color" 24-bit color depth, 3-channel RGB colors. (2^8)^3==256^3==2^24==16,777,216 total color tokens possible: 0-16777215 as tokenIds.
    uint256 public constant TOTAL_MAX_SUPPLY = 16777216;

    uint256 public PRICE = 5e26;

    //Rinkeby Price 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    //Mainnet Price 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    address public priceFeedAddress;
    AggregatorV3Interface internal priceFeed;

    //Rinkeby Safe 0x1A572d0Eab9AB9eD715F4066295cBAc0C4b2b344
    //Mainnet Safe 0xea1652B9247f341EDc67c0fa844486F024Df570a
    address payable private safe;

    address public founderContract;

    address private _owner;

    string datajson = "data:application/json;utf8,";
    string datasvg = "data:image/svg+xml;utf8,";
    string svg1 = "<svg xmlns='http://www.w3.org/2000/svg'><rect width='350' height='350' style='fill: ";
    string svg2 = "'><title>";
    string svg3 = "</title></rect></svg>";
    string svga = "<svg%20xmlns='http://www.w3.org/2000/svg'><rect%20width='350'%20height='350'%20style='fill:%20";

    // Mapping from token ID to name (from Hashmasks)
    mapping (uint256 => string) private _tokenName;

    // Mapping if certain name string has already been reserved (from Hashmasks)
    mapping (string => bool) private _nameReserved;

    event NameChange (uint256 indexed tokenId, string newName);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlySafe() {
        require(msg.sender == safe, "Only safe"); //Change to MAINNET
        //require(msg.sender == safe, "Only safe can call this.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner"); //Change to MAINNET
        //require(owner() == _msgSender(), "Ownable: caller is not the owner");  //From OZ, Context, GSN
        _;
    }

    function contractOwner() public view returns (address) {
        return _owner;
    }

    function setOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    function setFounder(address founderAddress) public onlyOwner {
        founderContract = founderAddress;
    }

    function setPriceSource(address priceAddress) public onlyOwner {
        priceFeedAddress = priceAddress;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function getPriceSource() public view returns (address) {
        return priceFeedAddress;
    }

    function setSafe(address payable safeAddress) public onlyOwner {
      safe = safeAddress;
    }

    function withdraw() public onlySafe{
        uint256 balance = address(this).balance;
        safe.transfer(balance);
    }

    function getLatestPrice() public view returns (int) {
          return priceFeed.latestAnswer();
    }

    function getPrice() public view returns (uint256 price) {
        return PRICE/uint256(getLatestPrice());
    }

    /**
     * @dev Returns name of the NFT at index.(from Hashmasks)
     */
    function tokenNameById(uint256 tokenId) public view returns (string memory) {
        return _tokenName[tokenId];
    }

    /**
     * @dev Returns if the name has been reserved. (from Hashmasks)
     */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }

    /**
    * @dev Changes the name for Hashmask tokenId (from Hashmasks)
    */
    function changeName(uint256 tokenId, string memory newName) public payable {
        address colorOwner = ownerOf(tokenId);
        require(_msgSender() == colorOwner, "ERC721: caller is not the owner"); //GSN Network????
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");
        uint256 currentPrice = getPrice();
        require(msg.value >= (currentPrice-((currentPrice*2)/100)), "Insufficient ETH amount");
        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        emit NameChange(tokenId, newName);
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false (from Hashmasks)
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    /**
    * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space) (from Hashmasks)
    */
   function validateName(string memory str) public pure returns (bool) {
       bytes memory b = bytes(str);
       if(b.length < 1) return false;
       if(b.length > 25) return false; // Cannot be longer than 25 characters
       if(b[0] == 0x20) return false; // Leading space
       if (b[b.length - 1] == 0x20) return false; // Trailing space

       bytes1 lastChar = b[0];

       for(uint i; i<b.length; i++){
           bytes1 char = b[i];

           if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

           if(
               !(char >= 0x30 && char <= 0x39) && //9-0
               !(char >= 0x41 && char <= 0x5A) && //A-Z
               !(char >= 0x61 && char <= 0x7A) && //a-z
               !(char == 0x20) //space
           )
               return false;
           lastChar = char;
       }
       return true;
   }

   /**
   * @dev Converts the string to lowercase (from Hashmasks)
   */
   function toLower(string memory str) public pure returns (string memory) {
       bytes memory bStr = bytes(str);
       bytes memory bLower = new bytes(bStr.length);
       for (uint i = 0; i < bStr.length; i++) {
           // Uppercase character
           if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
               bLower[i] = bytes1(uint8(bStr[i]) + 32);
           } else {
               bLower[i] = bStr[i];
           }
       }
       return string(bLower);
   }

   function renderSVG(uint256 tokenId) public view returns (string memory) {
     require(_exists(tokenId), "SVG query for nonexistent token");
     string memory hx = tokenIdToColorHex(tokenId);
     return string(abi.encodePacked(svg1, hx, svg2, hx, svg3));
     /*
     string memory svg = render(tokenId, false);
     svg = string(abi.encodePacked(svgBegin, svg, svg16, tokenId.toString(), svgSpaces, "|", svgSpaces, CVAddressString));
     svg = string(abi.encodePacked(svg, svgSpaces, "|", svgSpaces, "1/1", svgSpaces, "|", svgSpaces, "Block ", _founderNFTs[tokenId].blockNum.toString(), svgEnd));
     return svg;
     */
   }

   function svgURI(uint256 tokenId) public view returns (string memory) {
     require(_exists(tokenId), "URI query for nonexistent token");
     string memory color = tokenIdToColor(tokenId);
     return string(abi.encodePacked(datasvg, svg1, "%23", color, svg2, "%23", color, svg3));
   }

   function esvgURI(uint256 tokenId) public view returns (string memory) {
     require(_exists(tokenId), "URI query for nonexistent token");
     string memory color = tokenIdToColor(tokenId);
     return string(abi.encodePacked(datasvg, svga, "%2523", color, svg2, "%2523", color, svg3));
   }

   function tokenIdToColor(uint256 tokenId) public pure returns (string memory) {
     require(tokenId < TOTAL_MAX_SUPPLY, "24-bit color exceeded");
     bytes32 val = bytes32(tokenId);
     bytes memory hx = "0123456789ABCDEF";
     bytes memory str = new bytes(51);

     for (uint i = 17; i < 20; i++) {
       str[i*2] = hx[uint(uint8(val[i + 12] >> 4))];
       str[1+i*2] = hx[uint(uint8(val[i + 12] & 0x0f))];
     }

     return string(str);
   }

   function tokenIdToColorHex(uint256 tokenId) public pure returns (string memory) {
     return string(abi.encodePacked("#", tokenIdToColor(tokenId)));
   }

   function rgb(uint256 tokenId) public pure returns (uint256 r, uint256 g, uint256 b) {
     require (tokenId < TOTAL_MAX_SUPPLY, "24-bit color exceeded");
     r = tokenId/(256**2);
     g = (tokenId/256)%256;
     b = tokenId%256;
     return (r, g, b);
   }

   function mint(uint256 _tokenId) internal {
     require(_tokenId<TOTAL_MAX_SUPPLY, "TokenID exceeds possible");
     _safeMint(msg.sender, _tokenId);
   }

   function mintAll(uint256[] memory _tokenIds) public payable {
     require(_tokenIds.length>0, "No colors specified");
     require(_tokenIds.length<17, "Color minting exceeded");
     uint256 currentAmount = getPrice()*uint256(_tokenIds.length);
     require(msg.value >= (currentAmount-((currentAmount*2)/100)), "Insufficient ETH amount");
     for (uint i=0; i<_tokenIds.length; i++) {
       mint(_tokenIds[i]);
     }
     //register founders token if 16 tokens
     if (_tokenIds.length==16) {
       uint256[16] memory tmpArr;
         for (uint i=0; i<_tokenIds.length; i++) {
            tmpArr[i] = _tokenIds[i];
         }
         Founder(founderContract).register(tmpArr, msg.sender);
       }
   }

   function getCollectionHexString(address _address) public view returns (string memory) {
     uint256 addressBalance = balanceOf(_address);
     string memory list;

     if (addressBalance == 0) {
       return list;
     }

     for (uint256 i=0; i < addressBalance; i++) {
       string memory tokenIdString = tokenIdToColorHex(tokenOfOwnerByIndex(_address, i));
       if (i==0){
           list = string(abi.encodePacked(tokenIdString));
       } else {
       list = string(abi.encodePacked(list, ",", tokenIdString));
       }
     }
     return list;
   }

   function getCollectionArray(address _address) public view returns (uint256[] memory) {
     uint256 addressBalance = balanceOf(_address);
     uint256[] memory intArray = new uint256[](addressBalance);

     if (addressBalance == 0) {
       return intArray;
     }

     for (uint256 i=0; i < addressBalance; i++) {
       intArray[i] = tokenOfOwnerByIndex(_address, i);
     }
     return intArray;
   }

   function exists(uint256 tokenId) public view returns (bool) {
     return _exists(tokenId);
   }

   function batchTransfer(uint256[] memory tokenIds, address to) public {
     for (uint256 i=0; i < tokenIds.length; i++) {
         safeTransferFrom(_msgSender(), to, tokenIds[i], "");
     }
   }

   function colorOfOwnerByIndex(address owner, uint256 index) public view returns (string memory) {
      return tokenIdToColorHex(tokenOfOwnerByIndex(owner, index));
   }

   function transfer_targetToken(address target) public onlySafe {
      ERC20(target).transfer(safe, ERC20(target).balanceOf(address(this)));
   }

    function transfer_targetNFT(address target, uint256 tokenId) public onlySafe {
      IERC721(target).transferFrom(address(this), safe, tokenId);
    }
/////////////////////
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function contractURI() public view returns (string memory) {
      string memory uri1 = "{\"name\":%20\"Colorverse%20Tokens%20(RGB)\",%20\"description\":%20\"All%20Colors.%20Tokensized.%20Find%20your%20colors.%20Own%20your%20colors.%20The%20first%20meta-NFT%20for%20generative,%20on-chain%20art%20-%201/1.\",";
      string memory uri2 = "\"image\":%20\"https://www.colorverse.io/colorverse.png\",%20\"external_url\":%20\"https://www.colorverse.io\"}";
      string memory uri = string(abi.encodePacked(datajson, uri1, uri2));
      return uri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory rname = tokenNameById(tokenId);
        string memory uriname;
        if (bytes(rname).length == 0) {
            uriname = string(abi.encodePacked("%23", tokenIdToColor(tokenId)));
        } else {
            uriname = string(abi.encodePacked("%23", tokenIdToColor(tokenId), "%20-%20", rname));
        }

        string memory uri1 = "{\"name\": \"";

        string memory uri2 = "\", \"description\":%20\"All%20Colors.%20Tokensized.%20Find%20your%20colors.%20Own%20your%20colors.%20The%20first%20meta-NFT%20for%20generative,%20on-chain%20art%20-%201/1.\",";
        string memory uri3 = "\"external_url\":%20\"https://www.colorverse.io/";
        string memory uri4 = "\", \"image\":%20\"";
        string memory uri = string(abi.encodePacked(datajson, uri1, uriname, uri2, uri3));
        uri = string(abi.encodePacked(uri, tokenIdToColor(tokenId), uri4, esvgURI(tokenId), "\"}"));
        return uri;
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // internal owner
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}