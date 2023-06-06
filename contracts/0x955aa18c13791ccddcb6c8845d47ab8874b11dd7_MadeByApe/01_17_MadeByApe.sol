// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';

contract MadeByApe is ERC721A, Ownable, PaymentSplitter {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    enum Status {
        Pending,
        PreSale,
        PublicSale,
        Finished
    }

    Status public status;

    string public baseURI;
    address private _signer;
    uint256 public constant PRESALE_PRICE = 0.045 ether;
    uint256 public constant PUBLIC_PRICE = 0.055 ether;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public presaleMaxPerWallet = 2;
    uint256 public maxPerWallet = 5;

    address public immutable spcAddress;
    address public immutable maycAddress;
    address public immutable baycAddress;
    uint256 public immutable partnerAllowance;
    mapping(address => bool) private _partnerMints;
    mapping(address => bool) private _presaleMints;
    Counters.Counter private _spcMinted;
    Counters.Counter private _baycMaycMinted;

    address[] private _wallets = [
        0x5e5Ad992A5Be70c13E971224671a6CDefCf8BE6E,
        0x3515001548Cb3f93Dc5E3F3880D1f5ab2b0E07DB,
        0xf15d6d83F49302C9666A8d41B3096D7C6384dd8a
    ];

    uint256[] private _walletShares = [10, 10, 80];

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event SignerChanged(address signer);
    event BaseURIChanged(string newBaseURI);

    error InvalidPartnerHolder();
    error PartnerAllowanceExceeded();

    constructor(
        string memory initBaseURI,
        address signer,
        address _spcAddress,
        address _baycAddress,
        address _maycAddress,
        uint256 _partnerAllowance
    ) ERC721A('Made By Ape', 'BYAPE') PaymentSplitter(_wallets, _walletShares) {
        baseURI = initBaseURI;
        _signer = signer;
        spcAddress = _spcAddress;
        baycAddress = _baycAddress;
        maycAddress = _maycAddress;
        partnerAllowance = _partnerAllowance;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract');
        _;
    }

    modifier eligibleToMint(uint256 amount) {
        require(totalSupply() + amount <= MAX_SUPPLY, 'Exceeds max supply');
        _;
    }

    function spcMint() external payable callerIsUser eligibleToMint(1) {
        require(status == Status.PreSale, 'Presale is not active');
        require(!_partnerMints[msg.sender], 'Already minted as partner');

        uint256 spcBalance = IERC721(spcAddress).balanceOf(msg.sender);

        if (spcBalance > 0) {
            if (_spcMinted.current() + 1 <= partnerAllowance) {
                _spcMinted.increment();
                _partnerMints[msg.sender] = true;
                _safeMint(msg.sender, 1);
                refundIfOver(PRESALE_PRICE);

                emit Minted(msg.sender, 1);
            } else {
                revert PartnerAllowanceExceeded();
            }
        } else {
            revert InvalidPartnerHolder();
        }
    }

    function baycMint() external payable callerIsUser eligibleToMint(1) {
        require(status == Status.PreSale, 'Presale is not active');
        require(!_partnerMints[msg.sender], 'Already minted as partner');

        uint256 baycBalance = IERC721(baycAddress).balanceOf(msg.sender);
        uint256 maycBalance = IERC721(maycAddress).balanceOf(msg.sender);

        if (baycBalance > 0 || maycBalance > 0) {
            if (_baycMaycMinted.current() + 1 <= partnerAllowance) {
                _baycMaycMinted.increment();
                _partnerMints[msg.sender] = true;
                _safeMint(msg.sender, 1);
                refundIfOver(PRESALE_PRICE);

                emit Minted(msg.sender, 1);
            } else {
                revert PartnerAllowanceExceeded();
            }
        } else {
            revert InvalidPartnerHolder();
        }
    }

    function presaleMint(
        uint256 amount,
        string calldata salt,
        bytes calldata token
    ) external payable callerIsUser eligibleToMint(amount) {
        require(status == Status.PreSale, 'Presale is not active');
        require(_verify(_hash(salt, msg.sender), token), 'Invalid token');
        require(_numberMintedWithoutPartner(msg.sender) + amount <= presaleMaxPerWallet, 'Cannot mint that many');

        _presaleMints[msg.sender] = true;
        _safeMint(msg.sender, amount);
        refundIfOver(PRESALE_PRICE * amount);

        emit Minted(msg.sender, amount);
    }

    function mint(uint256 amount) external payable callerIsUser eligibleToMint(amount) {
        require(status == Status.PublicSale, 'Public sale is not active');
        require(_numberMintedAfterPresale(msg.sender) + amount <= maxPerWallet, 'Cannot mint that many');

        _safeMint(msg.sender, amount);
        refundIfOver(PUBLIC_PRICE * amount);

        emit Minted(msg.sender, amount);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, 'Not enough ETH');
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _hash(string calldata salt, address _address) internal view returns (bytes32) {
        return keccak256(abi.encode(salt, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory token) internal view returns (bool) {
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setMaxPerWallet(uint256 newMaxPerWallet) external onlyOwner {
        maxPerWallet = newMaxPerWallet;
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(_status);
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
        emit SignerChanged(signer);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function ownershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownerships[index];
    }

    function _numberMintedAfterPresale(address _owner) internal view returns (uint256) {
        uint256 reducedBy = 0;

        if (_presaleMints[_owner]) {
            reducedBy += 2;
        }

        if (_partnerMints[_owner]) {
            reducedBy += 1;
        }

        return _numberMinted(_owner) - reducedBy;
    }

    function _numberMintedWithoutPartner(address owner) internal view returns (uint256) {
        if (_partnerMints[owner]) {
            return _numberMinted(owner) - 1;
        } else {
            return _numberMinted(owner);
        }
    }
}