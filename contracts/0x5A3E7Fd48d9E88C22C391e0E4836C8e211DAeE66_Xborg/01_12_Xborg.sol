// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

// Import this file to use console.lAllowlist
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../libraries/ECDSALibrary.sol";
import "./ERC721A.sol";
import "./interfaces/IERC721A.sol";
import "hardhat/console.sol";

contract Xborg is ERC721A, Ownable, AccessControl {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant FREE_SIGNER_ROLE = keccak256("FREE_SIGNER_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    // base token URI
    string private _baseTokenURI;
    // Has the URI been frozen for ever
    bool public isUriFrozenForEver;

    // nonce used for free mints
    mapping(address => uint256) private nonces;

    // sale times
    uint256 private _whitelistSaleTime = 1663344000;
    uint256 private _allowlistSaleTime = 1663430400;
    uint256 private _publicSaleTime = 1663516800;

    // token prices
    uint256 private _tokenPriceWhitelist = 0.24 ether;
    uint256 private _tokenPriceAllowlist = 0.28 ether;
    uint256 private _tokenPricePublic = 0.28 ether;

    // collection's initial maximum supply
    uint256 private _maxSupply = 1111;

    // max mint quantity per transaction
    uint256 private _maxWhitelistMintPerTx = 2;
    uint256 private _maxAllowlistMintPerTx = 2;
    uint256 private _maxPublicMintPerTx = 2;

    // number of transactions per address
    mapping(address => uint256) internal _numbWhitelistTransactions;
    mapping(address => uint256) internal _numbAllowlistTransactions;

    // max number of transactions per address
    uint256 internal _maxWhitelistTransactions = 1;
    uint256 internal _maxAllowlistTransactions = 1;

    // payment splitter
    uint256 internal constant totalShares = 1000;
    uint256 internal totalReleased;
    mapping(address => uint256) internal released;
    mapping(address => uint256) internal shares;
    address internal constant project = 0xb98750782e30306d4cAa5f6139A44ec23CAb8385;
    address internal constant shareHolder2 = 0xe5d2c3eb042aD8C577F70832525656a37749A7F7;
    
    constructor() ERC721A("XBORG", "XBORG") {
        _grantRole(DEFAULT_ADMIN_ROLE, 0x70e4336d246664D97b8D2183A3281045B40F4867);

        shares[project] = 975;
        shares[shareHolder2] = 25;

        _safeMint(0xb98750782e30306d4cAa5f6139A44ec23CAb8385, 1);

        // set metadata
        _baseTokenURI = "https://nefture.mypinata.cloud/ipfs/QmNfLvhYf37q8qwvKbjEC7AJtXHR5N2f5fEi6Pm6ZQWdN4/";
    }

    /*
     * mint tokens as Whitelisted
     *
     * @param _quantity: quantity to mint
     * @param _signature: whitelist signature
     *
     * Error messages:
     *  - A1: "Wrong price"
     *  - A2: "Trying to mint too many tokens"
     *  - A3: "Max supply has been reached"
     *  - A4: "Mint has not started yet"
     *  - A5: "Wrong signature"
     *  - A13: "Already made the maximum of whitelist transactions allowed"
     */
    function whitelistMint(uint256 _quantity, bytes calldata _signature) external payable {
      require(msg.value == _tokenPriceWhitelist * _quantity, "A1");
      require(_quantity <= _maxWhitelistMintPerTx, "A2");
      require(totalSupply() + _quantity <= _maxSupply, "A3");
      require(block.timestamp > _whitelistSaleTime, "A4");
      require(_numbWhitelistTransactions[msg.sender] < _maxWhitelistTransactions, "A13");
      _numbWhitelistTransactions[msg.sender] += 1;

      require(hasRole(SIGNER_ROLE, ECDSALibrary.recover(abi.encodePacked(msg.sender, "WL"), _signature)), "A5");

      _safeMint(msg.sender, _quantity);
    }

    /*
     * mint tokens as an Allowlist
     *
     * @param _quantity: quantity to mint
     * @param _signature: Allowlist signature
     *
     * Error messages:
     *  - A1: "Wrong price"
     *  - A2: "Trying to mint too many tokens"
     *  - A3: "Max supply has been reached"
     *  - A4: "Mint has not started yet"
     *  - A5: "Wrong signature"
     *  - A14: "Already made the maximum of allowlist transactions allowed"
     */
    function AllowlistMint(uint256 _quantity, bytes calldata _signature) external payable {
      require(msg.value == _tokenPriceAllowlist * _quantity, "A1");
      require(_quantity <= _maxAllowlistMintPerTx, "A2");
      require(totalSupply() + _quantity <= _maxSupply, "A3");
      require(block.timestamp > _allowlistSaleTime, "A4");
      require(_numbAllowlistTransactions[msg.sender] < _maxAllowlistTransactions, "A14");
      _numbAllowlistTransactions[msg.sender] += 1;

      require(hasRole(SIGNER_ROLE, ECDSALibrary.recover(abi.encodePacked(msg.sender, "AL"), _signature)), "A5");

      _safeMint(msg.sender, _quantity);
    }

    /*
     * mint tokens in public
     *
     * @param _quantity: quantity to mint
     *
     * Error messages:
     *  - A1: "Wrong price"
     *  - A2: "Trying to mint too many tokens"
     *  - A3: "Max supply has been reached"
     *  - A4: "Mint has not started yet"
     */
    function publicMint(uint256 _quantity) external payable {
      require(msg.value == _tokenPricePublic * _quantity, "A1");
      require(_quantity <= _maxPublicMintPerTx, "A2");
      require(totalSupply() + _quantity <= _maxSupply, "A3");
      require(block.timestamp > _publicSaleTime, "A4");

      _safeMint(msg.sender, _quantity);
    }

    /*
     * mint tokens as free claims
     *
     * @param _quantity: quantity to mint
     * @param _signature: free claim signature
     *
     * Error messages:
     *  - A2: "Trying to mint too many tokens"
     *  - A3: "Max supply has been reached"
     *  - A5: "Wrong signature"
     */
    function freeClaim(uint256 _quantity, bytes calldata _signature) external {
      require(_quantity <= _maxPublicMintPerTx, "A2");
      require(totalSupply() + _quantity <= _maxSupply, "A3");

      uint256 nonce = nonces[msg.sender] + 1;
      require(hasRole(FREE_SIGNER_ROLE, ECDSALibrary.recover(abi.encodePacked(msg.sender, _quantity, nonce), _signature)), "A5");
      nonces[msg.sender] += 1;

      _safeMint(msg.sender, _quantity);
    }

    /*
     * airdrop tokens to address
     *
     * @param _quantity: quantity to airdrop
     * @param _to: receiver of the tokens
     *
     * Error messages:
     *  - A3: "Max supply has been reached"
     */
    function airdrop(uint256 _quantity, address _to) external onlyRole(AIRDROP_ROLE) {
      require(totalSupply() + _quantity <= _maxSupply, "A3");

      _safeMint(_to, _quantity);
    }

    /*
     * set maximum mint quantity per transactions
     *
     * @param _newMaxAllowlistMint: new value for maximum Allowlist mint per transaction
     * @param _newMaxWhitelistMint: new value for maximum whitelist mint per transaction
     * @param _newMaxPublicMint: new value for maximum public mint per transaction
     */
    function setMaxMintsPerTx(
      uint256 _newMaxWhitelistMint, 
      uint256 _newMaxAllowlistMint,
      uint256 _newMaxPublicMint
    ) external onlyOwner {
      _maxWhitelistMintPerTx = _newMaxWhitelistMint;
      _maxAllowlistMintPerTx = _newMaxAllowlistMint;
      _maxPublicMintPerTx = _newMaxPublicMint;
    }

    /*
     * set maximum number of transactions in whitelist and allowlist
     *
     * @param _newWhitelistMaxTransactions: new value for maximum transactions for the whitelist
     * @param _newAllowlistMaxTransactions: new value for maximum transactions for the allowlist
     */
    function setMaxTransactions(
      uint256 _newWhitelistMaxTransactions,
      uint256 _newAllowlistMaxTransactions
    ) external onlyOwner {
      _maxWhitelistTransactions = _newWhitelistMaxTransactions;
      _maxAllowlistTransactions = _newAllowlistMaxTransactions;
    }

    /*
     * change price of tokens
     *
     * @param _newTokenPriceAllowlist: new value for Allowlist mint price
     * @param _newTokenPriceWhitelist: new value for whitelist mint price
     * @param _newTokenPricePublic: new value for public mint price
     */
    function setSalePrices(
      uint256 _newTokenPriceWhitelist, 
      uint256 _newTokenPriceAllowlist, 
      uint256 _newTokenPricePublic
    ) external onlyOwner {
      _tokenPriceWhitelist = _newTokenPriceWhitelist;
      _tokenPriceAllowlist = _newTokenPriceAllowlist;
      _tokenPricePublic = _newTokenPricePublic;
    }

    /*
     * change sale times
     *
     * @param _newAllowlistTime: new allowlist sale time
     * @param _newWhitelisteTime: new whiteliste sale time
     * @param _newPublicTime: new public sale time
     */
    function setSalesTimes(uint256 _newWhitelistTime, uint256 _newAllowlistTime, uint256 _newPublicTime) external onlyOwner {
      _whitelistSaleTime = _newWhitelistTime;
      _allowlistSaleTime = _newAllowlistTime;
      _publicSaleTime = _newPublicTime;
    }

    /*
     * permanently reduce maximum supply of the collection
     *
     * @param _newMaxSupply: new maximum supply
     *
     * Error messages:
     *  - A6: "Can not increase the maximum supply"
     *  - A7: "Can not set the new maximum supply under the current supply"
     */
    function reduceMaxSupply(uint256 _newMaxSupply) external onlyOwner {
      require(_newMaxSupply < _maxSupply, "A6");
      require(_newMaxSupply >= totalSupply(), "A7");

      _maxSupply = _newMaxSupply;
    }

    /*
     * get prices of tokens
     *
     * @return _tokenPriceAllowlist: price of the tokens when Allowlist
     * @return _tokenPriceWhitelist: price of the tokens when whitelist
     * @return _tokenPricePublic: price of the tokens when public
     */
    function getPrices() external view returns(uint256, uint256, uint256) {
      return (_tokenPriceWhitelist, _tokenPriceAllowlist, _tokenPricePublic);
    }

    /*
     * get maximum supply of the collection
     *
     * @return _maxSupply: maximum supply of the collection
     */
    function getMaxSupply() external view returns(uint256) {
      return _maxSupply;
    }

    /*
     * get time of the sales
     *
     * @return _allowlistSaleTime: time of the sale
     * @return _whitelistSaleTime: time of the sale
     * @return _publicSaleTime: time of the sale
     */
    function getSalesTimes() external view returns(uint256, uint256, uint256) {
      return (_whitelistSaleTime, _allowlistSaleTime, _publicSaleTime);
    }

    /*
     * get maximum mints per transaction for each sale type
     *
     * @return _maxAllowlistMintPerTx: maximum Allowlist mint per transaction
     * @return _maxWhitelistMintPerTx: maximum whitelist mint per transaction
     * @return _maxPublicMintPerTx: maximum public mint per transaction
     */
    function getMaxMintsPerTx() external view returns(uint256, uint256, uint256) {
      return (_maxWhitelistMintPerTx, _maxAllowlistMintPerTx, _maxPublicMintPerTx);
    }

    /*
     * get the nonce of an account
     *
     * @param _account: account for which to recover the nonce
     *
     * @return nonces[_account]: nonce of _account
     */
    function getNonce(address _account) external view returns(uint256) {
      return nonces[_account];
    }

    /*
     * get current number of transactions of an account for whitelist and allowlist
     *
     * @param _account: account for which to recover number of transactions
     *
     * @return _numbWhitelistTransactions[_account]: number of whitelist transactions
     * @return _numbAllowlistTransactions[_account]: number of allowlist transactions
     */
    function getNumberOfTransactions(address _account) external view returns (uint256, uint256) {
      return (_numbWhitelistTransactions[_account], _numbAllowlistTransactions[_account]);
    }

    /*
     * get the maximum number of transactions allowed for the whitelist and allowlist
     *
     * @return _maxWhitelistTransactions: maximum Allowlist transactions allowed
     * @return _maxAllowlistTransactions: maximum whitelist transactions allowed
     */
    function getMaxNumberOfTransactions() external view returns(uint256, uint256) {
      return (_maxWhitelistTransactions, _maxAllowlistTransactions);
    }

    /*
     * burn a token
     *
     * @param _tokenId: tokenId of the token to burn
     *
     * Error messages:
     *  - A8: "You don't own this token"
     */
    function burn(uint256 _tokenId) external {
      require(ownerOf(_tokenId) == msg.sender, "A8");
      
      _burn(_tokenId);
    }

    /*
     * freezes uri of tokens
     *
     * Error messages:
     * - A9 : "URI already frozen"
     */
    function freezeMetadata() external onlyOwner {
        require(!isUriFrozenForEver, "A9");
        isUriFrozenForEver = true;
    }

    /*
     * override of the baseURI to use private variable _baseTokenURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /*
     * change base URI of tokens
     *
     * Error messages:
     * - A10 : "URI has been frozen"
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        require(!isUriFrozenForEver, "A10");
        _baseTokenURI = baseURI;
    }

    /**
     * overrides start tokenId
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * Withdraw contract's funds
     *
     * Error messages:
     * - A11 : "No shares for this account"
     * - A12 : "No remaining payment"
     */
    function withdraw(address account) external {
        require(shares[account] > 0, "A11");

        uint256 totalReceived = address(this).balance + totalReleased;
        uint256 payment = (totalReceived * shares[account]) /
            totalShares -
            released[account];

        released[account] = released[account] + payment;
        totalReleased = totalReleased + payment;

        require(payment > 0, "A12");

        payable(account).transfer(payment);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
      return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
      interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
      interfaceId == type(IAccessControl).interfaceId;
    }
}