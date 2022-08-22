// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract HalfHiding is ERC721AUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable  {
    using Strings for uint256;
    using ECDSA for bytes32;
    enum Status {
        Waiting,
        WhiteListStarted,
        Started,
        Finished
    }

    Status public status;
    string public baseURI;
    uint256 public MAX_MINT_PER_ADDR;
    uint256 public MAX_SUPPLY;
    uint256 public WHITELIST_PRICE;
    uint256 public PRICE;

    address public root; // for whitelist verification

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);

    function initialize(string memory initBaseURI) initializerERC721A initializer public {
        __ERC721A_init('HalfHiding', 'HalfHiding');
        __Ownable_init();
        __ReentrancyGuard_init();

        baseURI = initBaseURI;

        MAX_MINT_PER_ADDR = 2;
        MAX_SUPPLY = 7777;
        WHITELIST_PRICE = 0.06 * 10**18;
        PRICE = 0.07 * 10**18;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function whitelistMint(address user, bytes memory _signature, uint256 quantity) external payable nonReentrant {
        require(status == Status.WhiteListStarted, "It's not on sale yet.");
        // merkle tree list related
        require(root != address(0), "Whitelist Mint merkle tree not set");
        require(_isWhitelist(user, _signature), "Whitelist Mint validation failed");

        require(
            numberMinted(user) + quantity <= MAX_MINT_PER_ADDR,
            "The individual purchase limit is reached."
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "The maximum quantity is reached."
        );

        _refundIfOver(user, WHITELIST_PRICE * quantity);
        // start minting
        _safeMint(user, quantity);

    }

    function mint(address user, uint256 quantity) external payable nonReentrant {
        require(status == Status.Started, "It's not on sale yet.");
        require(
            numberMinted(user) + quantity <= MAX_MINT_PER_ADDR,
            "The individual purchase limit is reached."
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "The maximum quantity is reached."
        );

        _refundIfOver(user, PRICE * quantity);
        _safeMint(user, quantity);


        emit Minted(user, quantity);
    }

    function devMint(address user, uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "The maximum quantity is reached."
        );

        _safeMint(user, quantity);
        emit Minted(user, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function isWhitelist(address user, bytes memory signature)  public view returns (bool) {
        return _isWhitelist(user, signature);
    }

    function _refundIfOver(address user, uint256 price) private {
        require(msg.value >= price, "Value is not enough.");
        if (msg.value > price) {
            payable(user).transfer(msg.value - price);
        }
    }

    function _isWhitelist(address user, bytes memory signature) private view returns (bool) {
        bytes32 msgHash = keccak256(abi.encodePacked(user));
        return msgHash.recover(signature) == root;
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Withdraw success.");
    }

    function setRoot(address newRoot) external onlyOwner {
        root = newRoot;
    }
}