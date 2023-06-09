// SPDX-License-Identifier: MIT

/*
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.   @@@@@@     #@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%   *     *#    @@@.  @   ,@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*          &@*  &@@@@@   @@(  @@@.   @@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.,        %   @@@@@@@@*  &@*    &@@&           @@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @.&@   @@@@@         @@*    .%   &@@  /@@@@@@/  ,@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@        @@@@@@@   @@@@   @@@@@   @@@@@@@@,  &@@@@      ,@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@*      %@@@   @@@@@@@   @@@@   @@@@@   @@@@*   *  &@@@@@@@@/        *@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@*  #@@@@@@@   @@@@@@@   @@@@   @@@@@        *@@@@&      @*  [email protected]@@@@.   @@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@*  .     &@   @@@@@@   &@@@@   @@@@@@@@@(   @.     %@@@@@*  #@@@@@@&  [email protected]@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@*   #@@@@@@&          @@@@@@@@@@(        *@@@.  &@@@@*%@@*  #@@@@@@   @@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@*  #@@@@@@@@@@/..&@@@@@@   @.  &@@@@@   @@@@@.        @@@*  #@@@@,   @@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@*  #@@@@@@@@.  ,  @@@@@@   @.  &@@@@@   @@@@@.  &@@@@@@@@*        (@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@%@@@@@@@   @      #@@@   @.  &@@@@@   @@@@@.  &(      %*  #@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@   @@@@@@@   @   @.   [email protected]   @.  &@@@@@   @@@@@.    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@   @@@@@@@   @   @@@*      @.  &@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@   @@@@@@@   @   @@@@@#    @.  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@   %@@@@@   @@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    Futera United in partnership with Top Dog Studios (https://topdogstudios.io) ⚽🐶🚀
*/

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract FuteraUnited is IERC2981, EIP712, ERC721, PaymentSplitter, Ownable {
    enum SaleState { CLOSED, PRESALE, PUBLIC }
    struct MintKey { uint16 amount; address wallet; }

    struct SaleConfig {
        SaleState SALE_STATUS;
        uint8 RESERVED;
        uint8 PUBLIC_SALE_MAX_PURCHASE;
        uint8 PRE_SALE_MAX_PURCHASE;
        uint16 MAX_SUPPLY;
        uint16 ROYALTY_BPS;
        uint128 MINT_PRICE;
    }

    bytes32 private constant MINTKEY_TYPE_HASH = keccak256("MintKey(uint16 amount,address wallet)");
    uint16 private _totalSupply;
    SaleConfig private _config;
    address private _signer;
    address private _treasury;
    string private _baseTokenURI;
    mapping(address => bool) private _claimedMintKeys;
    address private _openSeaProxyRegistryAddress;
    bool private _isOpenSeaProxyActive = true;

    string public FUTERA_UNITED_PROVENANCE;

    constructor (
        string memory name,
        string memory symbol,
        address[] memory payees,
        uint256[] memory shares,
        SaleConfig memory saleConfig,
        address signer,
        address treasury,
        address openSeaProxyRegistryAddress,
        string memory baseTokenURI
    )
        ERC721(name, symbol)
        EIP712(name, "1")
        PaymentSplitter(payees, shares)
    {
        _config = saleConfig;
        _signer = signer;
        _treasury = treasury;
        _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress;
        _baseTokenURI = baseTokenURI;
    }
    
    function setProvenanceHash(string calldata provenanceHash) external onlyOwner {
        FUTERA_UNITED_PROVENANCE = provenanceHash;
    }

    function setBaseTokenURI(string calldata baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

     function setIsOpenSeaProxyActive(bool isOpenSeaProxyActive) external onlyOwner {
        _isOpenSeaProxyActive = isOpenSeaProxyActive;
    }

    function setSaleConfig(SaleConfig calldata config) external onlyOwner {
        _config = config;
    }

    function saleStatus() external view returns (SaleState) {
        return _config.SALE_STATUS;
    }

    function maxMintable() external view returns (uint8) {
        if (_config.SALE_STATUS == SaleState.CLOSED) return 0;

        return _config.SALE_STATUS == SaleState.PRESALE ? _config.PRE_SALE_MAX_PURCHASE : _config.PUBLIC_SALE_MAX_PURCHASE;
    }

    function isMintKeyClaimed(address mintKey) external view returns (bool) {
        return _claimedMintKeys[mintKey];
    }
    
    function mint(bytes calldata signature, MintKey calldata mintKey) external payable {
        require(_config.SALE_STATUS != SaleState.CLOSED, "SALE_CLOSED");
        require(msg.value == mintKey.amount * _config.MINT_PRICE, "INCORRECT_FUNDS");
        
        if (_config.SALE_STATUS == SaleState.PRESALE) {
            require(mintKey.amount > 0 && mintKey.amount <= _config.PRE_SALE_MAX_PURCHASE, "INCORRECT_QUANTITY");
            require(_claimedMintKeys[mintKey.wallet] == false, "ALREADY_MINTED");
            require(verify(signature, mintKey), "INVALID_SIGNATURE");

            _claimedMintKeys[mintKey.wallet] = true;
        }
        else if (_config.SALE_STATUS == SaleState.PUBLIC) {
            require(mintKey.amount > 0 && mintKey.amount <= _config.PUBLIC_SALE_MAX_PURCHASE, "INCORRECT_QUANTITY");
        }

        _mintMultiple(mintKey.wallet, mintKey.amount);
    }

    function reserve(address to, uint256 amount) external onlyOwner {
        require(amount > 0 && amount <= _config.RESERVED, "RESERVE_EXCEEDED");

        _mintMultiple(to, amount);
        _config.RESERVED -= uint8(amount);
    }

    function _mintMultiple(address to, uint256 amount) private {
        require(_totalSupply + amount <= _config.MAX_SUPPLY, "SUPPLY_EXCEEDED");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _totalSupply + 1;
            _safeMint(to, tokenId);
            _totalSupply++;
        }
    }

    function totalSupply() public view returns (uint16) {
        return _totalSupply;
    }

    function verify(bytes calldata signature, MintKey calldata mintKey) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    MINTKEY_TYPE_HASH,
                    mintKey.amount,
                    mintKey.wallet
                )
            )
        );

        return ECDSA.recover(digest, signature) == _signer;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), ".json"));
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(_openSeaProxyRegistryAddress);
        if (_isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) return true;

        return super.isApprovedForAll(owner, operator);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function royaltyInfo(uint256 /* _tokenId */, uint256 _salePrice) external view override returns (address, uint256) {
        return (_treasury, (_salePrice * _config.ROYALTY_BPS / 10000));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}