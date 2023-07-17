/*
Valiant Universe - Core Collection - Season 1 Character 1 - Punk Mambo Valiant Entertainment 2022
V
A      *                                                                 *
L       @                                                               (
I         @                             *                             @%
A          @@                           @                            @@
N           @@@                         @                           @@
T             @@@                       @@                        @@@
&              @@@@         #@@@@@@@@@  @@@@@@@@@@@@             @@@
E               %@@@@   @@@@@@          @@%       @@@@@@#       @@@
N                 @@@@@@@               @@@            @@@    @@@@
T                  @@@@@                @@@                  @@@@
E              *    *@@@@@              @@@@                @@@@@
R             @@@     @@@@@@            @@@@              @@@@@@@@
T           &@@@       @@@@@@@          @@@@@            @@@@@  @@@@
A          @@@@          @@@@@@@        @@@@@           @@@@@     @@@
I         ,@@@            @@@@@@@@      @@@@@         @@@@@@      *@@@
N         @@@              @@@@@@@@@    @@@@@        @@@@@@        @@@
M        ,@@&       &@       @@@@@@@@@  @@@        (@@@@@@@@        @@@
E     &@@@@@@@@@@@@@@@@       @@@@@@@@@(@         @@@@@@@@@@@@@@@@@@@@@@@@
N                              @@@@@@@@@         @@@@@@@
T         @@@                    @@@@@@@       &@@@@@@@            [email protected]@%
&         @@@                     @@@@@@      @@@@@@@@             @@@
S          @@@                     @@@@@     @@@@@@@@             @@@.
E           @@@                      @@@   @@@@@@@@@             @@@@
A            @@@                      @@  @@@@@@@@@             @@@.
S             @@@@                     & @@@@@@@@@            %@@@
O               @@@@                    @@@@@@@@@           @@@@
N                 @@@@.                 @@@@@@@@          @@@@
&                    @@@@@              @@@@@@@       @@@@@
1                       &@@@@@@#        @@@@@@   @@@@@@@
&                             @@@@@     @@@@@@@@@@%
©                                       @@@@
2                                       @@@
0                                       @@.
2                                       @.
2                                       %
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC721A, ERC721ABurnable, Pausable, AccessControl, Counters, EIP712, ECDSA, ValiantTokenInterface, ExchangeContractInterface, console} from './PMD.sol';


contract PunkMambo is ERC721A, ERC721ABurnable, Pausable, AccessControl, EIP712 {
    using Counters for Counters.Counter;


    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    Counters.Counter private _redeemedCounter;

    ValiantTokenInterface private _valiantToken;
    ExchangeContractInterface private _exchangeToken;

    mapping(address => bytes[]) private _mintSignatures;
    mapping(address => mapping(bytes32 => bytes[])) private _mintSignaturesByTier;
    mapping(bytes32 => address) private _hashes;
    mapping(address => uint256[]) private _mintedTokens;
    mapping(address => uint256[]) private _burnedTokens;
    mapping(address => uint256[]) private _exchangedTokens;

    bool private _allowBurn = false;
    uint256 private _maxItems;
    uint256 private _price = 0.077 ether;

    string private _contractURI = "";
    string private baseURI = "";

    event ExchangeToken(address, uint256);
    event BurnedToken(address, uint256);
    event RedeemedTokens(address, uint256[]);
    event MintedTokens(address, uint256[]);

    //This is the number of mint passes
    uint256 private _mintPasses = 500;

    constructor(string memory contractName, string memory symbol, address valiantTokenAddress, uint256 maxItems) ERC721A(contractName, symbol) EIP712(contractName, "1.0.0"){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _valiantToken = ValiantTokenInterface(valiantTokenAddress);
        _maxItems = maxItems;
    }

    function setContractURI(string memory newContractURI)
    external
    onlyRole(OPERATOR_ROLE)
    {
        _contractURI = newContractURI;
    }

    ///Returns the contract URI for OpenSea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    //BASE URI
    function setBaseURI(string memory _newBaseURI) public onlyRole(OPERATOR_ROLE) {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setValiantTokenInterface(address valiantTokenAddress)
    external
    onlyRole(OPERATOR_ROLE)
    {
        _valiantToken = ValiantTokenInterface(valiantTokenAddress);
    }


    function getValiantTokenInterface()
    external
    view
    returns (address)
    {
        return address(_valiantToken);
    }


    function setExchangeTokenInterface(address exchangeTokenAddress)
    external
    onlyRole(OPERATOR_ROLE)
    {
        _exchangeToken = ExchangeContractInterface(exchangeTokenAddress);
    }


    function getExchangeTokenInterface()
    external
    view
    returns (address)
    {
        return address(_exchangeToken);
    }



    function setMaxItems(uint256 maxItems)
    external
    onlyRole(OPERATOR_ROLE)
    {
        _maxItems = maxItems;
    }

    function getMaxItems()
    external
    view
    returns (uint256)
    {
        return _maxItems;
    }


    function getBurnedTokens(address account)
    external
    view
    returns (uint256[] memory)
    {
        return _burnedTokens[account];
    }

    function getExchangeTokens(address account)
    external
    view
    returns (uint256[] memory)
    {
        return _exchangedTokens[account];
    }


    function setPrice(uint256 price)
    external
    onlyRole(OPERATOR_ROLE)
    {
        _price = price;
    }

    function getPrice()
    external
    view
    returns (uint256)
    {
        return _price;
    }


    function setAllowBurn(bool allowBurn)
    external
    onlyRole(OPERATOR_ROLE)
    {
        _allowBurn = allowBurn;
    }

    function getAllowBurn()
    external
    view
    returns (bool)
    {
        return _allowBurn;
    }


    function setMintPasses(uint256 mintPasses)
    external
    onlyRole(OPERATOR_ROLE)
    {
        _mintPasses = mintPasses;
    }

    function getMintPasses()
    external
    view
    returns (uint256)
    {
        return _mintPasses;
    }

    function getMintedTokens(address account)
    external
    view
    returns (uint256[] memory)
    {
        return _mintedTokens[account];
    }

    function getRedeemedCounter()
    external
    view
    returns (uint256)
    {
        return _redeemedCounter.current();
    }


    function getTotalSupply()
    external
    view
    returns (uint256)
    {
        return totalSupply();
    }

    function pause() public onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    function getRedeemedSignatures(address account) external view returns (bytes[] memory){
        return _mintSignaturesByTier[account]['redeem'];
    }

    function getMintedSignatures(address account) external view returns (bytes[] memory){
        return _mintSignatures[account];
    }


    function getMintedSignaturesByTier(address account, bytes32 tier) external view returns (bytes[] memory){
        return _mintSignaturesByTier[account][tier];
    }


    function redeem(
        uint256 amount,
        uint256 nonce,
        uint256 balance,
        bytes calldata signature) external {

        require(!paused(), "CONTRACT_PAUSED");
        require(address(_valiantToken) != address(0), "INVALID_CONTRACT");
        require(amount > 0, "INVALID_AMOUNT");
        require(balance > 0, "INVALID_BALANCE");

        bytes32 hash = _hash(msg.sender, amount, balance, nonce);
        require(_verify(hash, signature), "INVALID_SIGNATURE");
        require(_hashes[hash] == address(0), "HASH_ALREADY_USED");

        require(_mintSignaturesByTier[msg.sender]['redeem'].length + amount <= balance, "EXCEED_QUOTA");
        require(amount + totalSupply() <= _maxItems, "EXCEED_MAX_ITEMS");

        uint256 startIndex = totalSupply();

        //MINT BATCH
        _safeMint(msg.sender, amount, "");

        //Fill the mappings with the indexes
        for (uint256 i = startIndex; i < startIndex + amount; i++) {
            _redeemedCounter.increment();
            _mintSignaturesByTier[msg.sender]['redeem'].push(signature);
            _mintedTokens[msg.sender].push(i);
        }

        emit RedeemedTokens(msg.sender, _mintedTokens[msg.sender]);

        _hashes[hash] = msg.sender;

    }

    function exists(uint256 tokenId) public view returns (bool) {
        return super._exists(tokenId);
    }

    function mint(
        uint256 amount,
        uint256 nonce,
        uint256 maxPerWallet,
        bytes32 tier,
        bytes calldata signature) external payable {

        require(!paused(), "CONTRACT_PAUSED");
        require(_price > 0, "INVALID_PRICE");
        require(amount > 0, "INVALID_AMOUNT");
        require(_mintPasses > 0, "PASSES_SETUP");
        require(_maxItems > 0, "MAX_ITEMS_SETUP");
        require(maxPerWallet > 0, "INVALID_MAX_PER_WALLET");

        bytes32 hash = _hashMint(msg.sender, amount, maxPerWallet, tier, nonce);
        require(_verify(hash, signature), "INVALID_SIGNATURE");
        require(_hashes[hash] == address(0), "HASH_ALREADY_USED");
        require((_mintSignaturesByTier[msg.sender][tier].length + amount) <= maxPerWallet, "EXCEED_QUOTA");

        require((amount + totalSupply()) <= _maxItems, "TOTAL_SUPPLY");
        require(msg.value >= (_price * amount), "VALUE_BELOW_PRICE");

        uint256 startIndex = totalSupply();

        //MINT BATCH
        _safeMint(msg.sender, amount, "");

        //Fill the mappings with the indexes
        for (uint256 i = startIndex; i < startIndex + amount; i++) {
            _mintSignatures[msg.sender].push(signature);
            _mintSignaturesByTier[msg.sender][tier].push(signature);
            _mintedTokens[msg.sender].push(i);
        }

        emit MintedTokens(msg.sender, _mintedTokens[msg.sender]);
        _hashes[hash] = msg.sender;

    }


    function safeMint(address to, uint256 amount) public onlyRole(OPERATOR_ROLE) {
        _safeMint(to, amount, "");
    }

    //------------------------------
    function _hash(
        address account,
        uint256 amount,
        uint256 balance,
        uint256 nonce
    ) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFT(address account,uint256 amount,uint256 balance,uint256 nonce)"
                    ),
                    account,
                    amount,
                    balance,
                    nonce
                )
            )
        );
    }

    function _hashMint(
        address account,
        uint256 amount,
        uint256 maxPerWallet,
        bytes32 tier,
        uint256 nonce
    ) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFT(address account,uint256 amount,uint256 maxPerWallet,bytes32 tier,uint256 nonce)"
                    ),
                    account,
                    amount,
                    maxPerWallet,
                    tier,
                    nonce
                )
            )
        );
    }


    function _verify(bytes32 digest, bytes memory signature)
    internal
    view
    returns (bool)
    {
        return hasRole(SIGNER_ROLE, ECDSA.recover(digest, signature));
    }


    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function withdraw()
    external
    onlyRole(WITHDRAWER_ROLE)
    {
        uint256 balance = address(this).balance;
        require(balance > 0, "BALANCE_ZERO");
        // solhint-disable-next-line
        (bool sent,) = payable(msg.sender).call{value : balance}("");
        require(sent, "WITHDRAW_FAILED");
    }

    function burn(uint256 tokenId) public override{
        require(_allowBurn, "BURN_NOT_ALLOWED");
        super.burn(tokenId);
        _burnedTokens[msg.sender].push(tokenId);
        emit BurnedToken(msg.sender, tokenId);
    }

    function exchangeToken(uint256 originalToKenId) external payable{
        require(address(_exchangeToken) != address(0), "INVALID_CONTRACT");
        _exchangeToken.mint(msg.sender, originalToKenId);
        super.burn(originalToKenId);
        _exchangedTokens[msg.sender].push(originalToKenId);
        emit ExchangeToken(msg.sender, originalToKenId);
    }


}

/*
╔════════════════════╗
║   Smart Contract   ║
║         by         ║
║     King Tide      ║
╚════════════════════╝
*/