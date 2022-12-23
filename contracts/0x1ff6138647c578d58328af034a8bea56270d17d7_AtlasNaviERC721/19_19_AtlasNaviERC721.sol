// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract AtlasNaviERC721 is Initializable, OwnableUpgradeable, ERC721Upgradeable {
    using SafeERC20Upgradeable for IERC20;
    using ECDSA for bytes32;

    struct Type {
        uint256 lastId;
    }

    address public signerAddress;
    address public developerAddress;
    uint256 public tokensCount;
    string public baseURI;

    uint256[] public typeList;
    mapping(uint256 => Type) public types;
    mapping(bytes => bool) private signatures;

    mapping(address => bool) public paymentTokens;

    event SignerUpdated(address oldSignerAddress, address newSignerAddress);
    event DeveloperUpdated(address oldDeveloperAddress, address newDeveloperAddress);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);

    /**
     * @dev Throws if called by any account other than the owner or developer.
     */
    modifier onlyOwnerOrDeveloper() {
        require(owner() == _msgSender() || developerAddress == _msgSender(), "Caller is not the owner or developer");
        _;
    }

    function initialize(
        address _ownerAddress,
        address _signerAddress,
        address _developerAddress
    ) external initializer {
        __ERC721_init("AtlasNavi", "ATN");
        __Ownable_init();

        signerAddress = _signerAddress;
        developerAddress = _developerAddress;

        paymentTokens[address(0)] = true;

        transferOwnership(_ownerAddress);
    }

    function typeListLength() external view returns (uint256) {
        return typeList.length;
    }

    function updateSignerAddress(address _signerAddress) external onlyOwner {
        emit SignerUpdated(signerAddress, _signerAddress);
        signerAddress = _signerAddress;
    }

    function updateDeveloperAddress(address _developerAddress) external onlyOwner {
        emit DeveloperUpdated(developerAddress, _developerAddress);
        developerAddress = _developerAddress;
    }

    function setPaymentToken(address _tokenAddress, bool _isPaymentToken) external onlyOwner {
        require(paymentTokens[_tokenAddress] != _isPaymentToken, 'Already set');

        paymentTokens[_tokenAddress] = _isPaymentToken;
    }

    function mint(
        uint256 _typeId,
        uint256 _typeLimit,
        address _paymentToken,
        uint256 _price,
        uint256 _expiration,
        bytes calldata _signature
    ) external payable {
        require(_typeId < 100000000, "typeId must be less than 100000000");
        require(_typeId > 10000000, "typeId must be greater than 10000000");
        require(_typeLimit < 1000000, "typeLimit must be less than 1000000");
        require(paymentTokens[_paymentToken], 'Invalid payment token');
        require(_expiration > block.timestamp, "Signature expired");
        require(signatures[_signature] == false, "Signature used");

        if (_paymentToken == address(0)) {
            require(msg.value >= _price, "Not enough bsc");
        } else {
            IERC20(_paymentToken).safeTransferFrom(msg.sender, address(this), _price);
        }

        Type storage _type = types[_typeId];
        require(_typeId * 1000000 + _typeLimit > _type.lastId, "typeLimit reached");

        bytes32 _messageHash = keccak256(abi.encodePacked(msg.sender, _typeId, _typeLimit, _paymentToken, _price, _expiration));
        require(
            signerAddress == _messageHash.toEthSignedMessageHash().recover(_signature),
            "Signer address mismatch"
        );

        tokensCount++;
        signatures[_signature] = true;

        if (_type.lastId == 0) {
            typeList.push(_typeId);
            _type.lastId = _typeId * 1000000 + 1;
        } else {
            _type.lastId++;
        }

        _safeMint(msg.sender, _type.lastId);
    }

    function withdraw(address _receiver, uint256 _amount) public payable onlyOwner {
        uint _balance = address(this).balance;
        require(_balance >= _amount, "Not enough funds");

        (bool _success,) = _receiver.call{value : _amount}("");
        require(_success, "Transfer failed.");
    }

    function withdrawERC20(address _token, address _receiver, uint256 _amount) public onlyOwner {
        IERC20(_token).safeTransfer(_receiver, _amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public virtual onlyOwnerOrDeveloper {
        baseURI = newBaseURI;
    }
}