pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";


contract CryptoHunters is ERC721AQueryable, Ownable {
    using ECDSA for bytes32;

    address public messageSigner;

    bool public isMintEnabled;

    uint256 public mintEnableTime;

    string public baseUri = "https://storage.googleapis.com/crypto-hunters-test/";

    uint256 public constant whitelistPrice = 0.2 ether;

    uint256 public constant publicPrice = 0.25 ether;

    uint256 public constant supply = 6000;

    mapping(address => uint) public whitelist;

    mapping(address => uint) public publicMint;

    uint public constant whitelistMintLimit = 6;
    uint public constant publicMintLimit = 10;


    event SetBaseURI(string baseURI_);


    constructor() ERC721A("Crypto Hunters", "CH") {
        messageSigner = msg.sender;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
        emit SetBaseURI(_baseUri);
    }

    function setMessageSigner(address _messageSigner) external onlyOwner {
        messageSigner = _messageSigner;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function publicMintEnabled() public view returns(bool) {
        return (isMintEnabled && (block.timestamp - mintEnableTime) >= 6 hours);
    }

    function setMintEnabled(bool _enabled) external onlyOwner {
        if(_enabled && mintEnableTime == 0) {
            mintEnableTime = block.timestamp;
        }
        isMintEnabled = _enabled;
    }

    function ownerMint(uint256 quantity) external onlyOwner {
        require((_totalMinted() + quantity) <= supply, "CryptoHunters: supply limit exceeded");
        _mint(msg.sender, quantity);
    }

    function mint(uint256 quantity, bytes memory whitelistSignature) external payable {
        require(isMintEnabled, "CryptoHunters: mint is not enabled");
        require(quantity > 0, "CryptoHunters: quantity should be greater then 0");
        bool isPublicMintEnabled = publicMintEnabled();
        if (!isPublicMintEnabled) {
            bytes32 message = bytes32(uint256(uint160(msg.sender)));
            bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
            address signatureAddress = hash.recover(whitelistSignature);
            require(signatureAddress == messageSigner, "CryptoHunters: invalid whitelist signature");

            require((whitelist[msg.sender] += quantity) <= whitelistMintLimit, "CryptoHunters: mint limit exceeded");
        } else {
            require(publicMint[msg.sender] + quantity <= publicMintLimit, "CryptoHunters: mint limit exceeded");
            publicMint[msg.sender] += quantity;
        }
        uint256 price = (isPublicMintEnabled ? publicPrice : whitelistPrice) * quantity;
        require(msg.value == price, "CryptoHunters: incorrect amount");
        require((_totalMinted() + quantity) <= supply, "CryptoHunters: supply limit exceeded");
        _mint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        (bool success,) = payable(owner()).call{value : address(this).balance}("");
        require(success, "CryptoHunters: unsuccessful withdraw");
    }
}