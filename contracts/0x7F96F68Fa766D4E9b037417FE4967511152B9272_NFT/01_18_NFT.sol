// contracts/NFT.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/payment/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address payable;

    address payable public vault;
    address public uriSigner;
    address public timelock;

    bool public paused;
    bool public isInitialized = false;

    uint16 private _tokenCount = 0;
    uint16 public constant maxTokenCount = 20000; // 20,000 tokens is the max
    uint256 public constant baseSolosPerUri = 40 ether;

    IERC20 public solos;

    struct MINTER {
        address minter;
        uint256 timestamp;
    }

    mapping(uint16 => MINTER) public minterLog;
    mapping(uint16 => string) public permanentURIArweave;

    // Events
    event PermanentURIAdded(uint256 tokenId, string arweaveHash);

    constructor() ERC721("SOLOS", "SOLOS") Ownable() {}

    modifier paymentRequired() {
        require(msg.value >= getCurrentPrice(), "Error: Payment required, or value below price");
        vault.sendValue(msg.value);
        _;
    }

    modifier isMintable() {
        require(!paused, "Error: Token minting is paused");
        require(_tokenCount <= maxTokenCount, "Error: Maximum number of tokens have been minted");
        _;
    }

    modifier onlyInitializeOnce() {
        require(!isInitialized, "Error: contract is already initialized");
        isInitialized = true;
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == timelock, "Error: caller is not timelock");
        _;
    }

    function initialize(
        string memory baseURI,
        address payable _vault,
        address _uriSigner,
        IERC20 _solos,
        address _timelock
    ) public onlyOwner onlyInitializeOnce {
        // Vote Token
        solos = _solos;

        // Set the base uri
        _setBaseURI(baseURI);

        uriSigner = _uriSigner;

        // Set minting status
        paused = false;

        // Set the vault
        vault = _vault;

        // Address of the timelock
        timelock = _timelock;
    }

    /**
     * Mint Functions
     */
    function mint() public payable isMintable paymentRequired returns (uint256) {
        // Log who bought the token and when
        minterLog[_tokenCount].minter = msg.sender;
        minterLog[_tokenCount].timestamp = block.timestamp;

        // Mint user current tokenId
        _mint(msg.sender, _tokenCount);

        // Increment id
        _tokenCount++;

        return _tokenCount;
    }

    // Artist can mint, but they can't claim solos for 15 years.
    function artistMint() public payable isMintable onlyOwner returns (uint256) {
        // Log who bought the token and when
        minterLog[_tokenCount].minter = msg.sender;
        minterLog[_tokenCount].timestamp = block.timestamp + 500000000e18; // 500 million Seconds;

        // Mint user current tokenId
        _mint(msg.sender, _tokenCount);

        // Increment id
        _tokenCount++;

        return _tokenCount;
    }


    function getCurrentPrice() public view returns (uint256) {
        return _getCurrentPrice();
    }

    function _getCurrentPrice() internal view returns (uint256) {
        if (totalSupply() >= 19990) {
            return 100000000000000000000; // 16381 - 16383 100 ETH
        } else if (totalSupply() >= 18750) {
            return 5000000000000000000; // 16000 - 16380 5.0 ETH
        } else if (totalSupply() >= 17500) {
            return 3000000000000000000; // 15000  - 15999 3.0 ETH
        } else if (totalSupply() >= 15000) {
            return 1700000000000000000; // 11000 - 14999 1.7 ETH
        } else if (totalSupply() >= 12500) {
            return 900000000000000000; // 7000 - 10999 0.9 ETH
        } else if (totalSupply() >= 10000) {
            return 500000000000000000; // 3000 - 6999 0.5 ETH
        } else if (totalSupply() >= 5000) {
            return 300000000000000000; // 3000 - 6999 0.3 ETH
        } else if (totalSupply() >= 2500) {
            return 200000000000000000; // 2500 - 5000 0.2 ETH
        } else if (totalSupply() >= 1500) {
            return 150000000000000000; // 2500 - 5000 0.15 ETH
        } else if (totalSupply() >= 500) {
            return 100000000000000000; // 201 - 2500 0.1 ETH
        } else if (totalSupply() >= 250) {
            return 50000000000000000; // 201 - 2500 0.05 ETH
        } else if (totalSupply() >= 100) {
            return 10000000000000000; // 201 - 2500 0.01 ETH
        } else {
            return 0; // 0 - 100 free
        }
    }

    function createPermanentURI(
        bytes memory signature,
        string memory arweaveHash,
        uint16 tokenId
    ) public nonReentrant {
        // Note on Underlow for TokenID
        // This does not seem to be a danger, because we WANT tokens to be claimed. Only the onwer can claim in 24 hours, so it's fine if a underflow happens.
        // in any case that should not pass the signature check.

        // check to be sure this tokenID has not been claimed
        require(
            keccak256(abi.encodePacked(permanentURIArweave[tokenId])) == keccak256(abi.encodePacked("")),
            "Error: TokenId already claimed"
        );

        // Check to make sure this tokenID is inbounds:
        require(tokenId <= maxTokenCount, "Error: Maximum number of tokens have been minted");

        // Give the minter a 3 day lead time to claim these tokens
        if (msg.sender != minterLog[tokenId].minter) {
            require(
                block.timestamp > minterLog[tokenId].timestamp + 3 days,
                "Error: Minters 1 day delay not yet expired"
            );
        }

        // Check the signature
        require(_isValidData(tokenId, arweaveHash, signature), "Error: signature did not match");

        // Update the token URI
        permanentURIArweave[tokenId] = arweaveHash;

        // Give users community Solos for this
        solos.transfer(msg.sender, baseSolosPerUri);

        // Make the Data permanently availible
        emit PermanentURIAdded(tokenId, arweaveHash);
    }

    // Pause only the minting
    function pause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    // Release solos that might be held by this contract
    function releaseSolos(address recipient, uint256 amount) public onlyTimelock {
        solos.transfer(recipient, amount);
    } // only timelock

    // Update Base URI
    function updateBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    // Signature recovery
    function _isValidData(
        uint16 tokenid,
        string memory arweave,
        bytes memory sig
    ) internal view returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(tokenid, arweave));

        return (recoverSigner(message, sig) == uriSigner);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, "Error: Signature does not have proper length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}