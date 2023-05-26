//SPDX-License-Identifier: MIT

/******************************************************************************************* /
*   ███████████                   ██████████                                               *
* ░░███░░░░░░█                  ░░███░░░░███                                               *
*  ░███   █ ░   ██████   ███████ ░███   ░░███ ████████   ██████  ████████   █████          *
*  ░███████    ███░░███ ███░░███ ░███    ░███░░███░░███ ███░░███░░███░░███ ███░░           *
*  ░███░░░█   ░███ ░███░███ ░███ ░███    ░███ ░███ ░░░ ░███ ░███ ░███ ░███░░█████          *
*  ░███  ░    ░███ ░███░███ ░███ ░███    ███  ░███     ░███ ░███ ░███ ░███ ░░░░███         *
*  █████      ░░██████ ░░███████ ██████████   █████    ░░██████  ░███████  ██████          *
* ░░░░░        ░░░░░░   ░░░░░███░░░░░░░░░░   ░░░░░      ░░░░░░   ░███░░░  ░░░░░░           *
*                       ███ ░███                                 ░███                      *
*                      ░░██████                                  █████                     *
*                       ░░░░░░                                  ░░░░░                      *
******************************************************************************************** /                                                        *
*/

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Foggie is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    string public baseURI = "";

    string public uriSuffix = "";

    uint256 public cost;

    uint256 public maxSupply = 10000;

    uint256 public maxPerTx;

    uint256 public maxPerWallet;

    bool public publicEnable = false;

    bool public exchangeEnable = true;

    mapping(address => bool) public exchanger;
    mapping(string => address) public usedNonces;
    address private _reserveAddress;

    uint256 private _reservedAmount = 3000;
    uint256 public reservedAmountExchanged = 0;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxMintPerTx,
        uint256 _maxPerWallet,
        uint256 _cost
    ) ERC721A(_name, _symbol) {
        maxPerTx = _maxMintPerTx;
        maxPerWallet = _maxPerWallet;
        cost = _cost;
        _reserveAddress = 0x526d505086a5B5217f87A27287377FF00186B0Eb;
        exchanger[_reserveAddress] = true;
        exchanger[0x36De1637bD475392b8aF968ee5cA631e82db0a79] = true;
    }

    /**
     * @dev check the conditions are valid
     */
    modifier _check_mint_compliance(uint256 _mintAmount) {
        require(
            _msgSender().code.length == 0,
            "The caller is another contract"
        );
        require(
            _mintAmount > 0 && _mintAmount <= maxPerTx,
            "Invalid mint amount"
        );
        require(
            numberMinted(_msgSender()) + _mintAmount <= maxPerWallet,
            "Mint amount to limited"
        );
        _;
    }

    /**
     * @dev check mint balance
     */
    modifier _check_mint_balance(uint256 _mintAmount) {
        require(msg.value >= ownerToPay(_mintAmount), "Insufficient funds!");
        _;
    }

    /**
     * @dev return how much someone need to pay ether for mint Tx
     */
    function ownerToPay(uint256 _mintAmount) public view returns (uint256) {
        return cost * _mintAmount;
    }

    /**
     * @dev public mint for everyone
     */
    function mint(uint256 _mintAmount)
        public
        payable
        _check_mint_compliance(_mintAmount)
        _check_mint_balance(_mintAmount)
    {
        require(publicEnable, "The public mint is paused!");
        require(
            (totalSupply() + _mintAmount - reservedAmountExchanged) <= (maxSupply - _reservedAmount),
            "Max public supply exceeded"
        );
        _safeMint(_msgSender(), _mintAmount);
    }

    /**
     * @dev exchange mint，
     */
    function exchangeMint(
        uint256 _mintAmount,
        string memory nonce,
        bytes32 _hash,
        bytes memory signature
    )
        public
        _check_mint_compliance(_mintAmount)
        nonReentrant
    {
        require(exchangeEnable, "The exchange mint is not enabled!");
        require(usedNonces[nonce] == address(0), "Hash reused");
        require(
            hashTransaction(_msgSender(),_mintAmount, nonce) == _hash,
            "Hash failed"
        );
        require(matchSigner(_hash, _mintAmount, signature),"sign failed");

        usedNonces[nonce] = _msgSender();

        // start minting
        _safeMint(_msgSender(), _mintAmount);
        _setAux(_msgSender(), _getAux(_msgSender()) + uint64(_mintAmount));
    }

    /**
     * @dev signature realted,if the systemAddress not eq the public key that server trusted,revert tx
     */
    function matchSigner(
        bytes32 _hash,
        uint256 _mintAmount,
        bytes memory signature
    ) internal returns (bool) {
        address signaddress = _hash.toEthSignedMessageHash().recover(signature);
        if(exchanger[signaddress] == true){
            if(signaddress == _reserveAddress){
                reservedAmountExchanged = reservedAmountExchanged + 1;
                return reservedAmountExchanged <= _reservedAmount && (totalSupply() + _mintAmount) <= maxSupply;
            } else {
                return (totalSupply() + _mintAmount - reservedAmountExchanged) <= (maxSupply - _reservedAmount);
            }
        } else {
            return false;
        }
    }

    function hashTransaction(address _reciever,uint256 amount, string memory nonce)
        internal
        pure
        returns (bytes32)
    {
        bytes32 hash = keccak256(abi.encodePacked(_reciever,amount, nonce));

        return hash;
    }

    /**
     * @dev set sys address
     */

    function setExchanger(address _sysAddress, bool _enable)
        public
        onlyOwner
    {
        require(
            _sysAddress != address(0),
            "Invalid address"
        );
        require(
            _sysAddress.code.length == 0,
            "The address is another contract"
        );
        exchanger[_sysAddress] = _enable;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function numberExchangeMinted(address owner) public view returns (uint256) {
        return _getAux(owner);
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxPerTx(uint256 _maxPerTx) public onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPublicEnable(bool _enable) public onlyOwner {
        publicEnable = _enable;
    }

    function setExchangeEnabled(bool _enable) public onlyOwner {
        exchangeEnable = _enable;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory _baseUri = _baseURI();
        return
            bytes(_baseUri).length != 0
                ? string(
                    abi.encodePacked(_baseUri, _toString(tokenId), uriSuffix)
                )
                : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}