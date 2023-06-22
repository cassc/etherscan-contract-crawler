// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.4;

// @author: PISCES DEV
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Pisces is ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;
    using Math for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    /*
	* Public Variables
	*/
    // max supply
    uint public constant MAX_SUPPLY = 3000;
    // max free mint supply
    uint public constant MAX_FREE_MINT_SUPPLY = 1000;
    // sale price 0.01 ETH
    uint256 public constant MINT_PRICE = 0.01 ether;
    // base token uri ipfs://xxxxxxxxxx/
    string public baseTokenURI;
    // blind box token uri
    string public blindBoxTokenURI;

    /*
    * Private Variables
    */
    // record the used whitelist signature
    mapping(bytes => bool) private _signatureUsed;
    // token index counter
    Counters.Counter private _tokenIndex;
    // free mint counter
    Counters.Counter private _freeMintedCounter;
    // address used to sign
    address private _signerAddress;
    bool private _isBlindBox = true;

    /*
    * Constructor
    */
    /// Initial Smart Contract
    /// @param name contract name
    /// @param symbol contract symbol
    /// @param baseTokenURI_ base URI of all tokens
    /// @param signerAddress the admin address to verify signature
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI_,
        string memory blindBoxTokenURI_,
        address signerAddress
    )
    ERC721(name, symbol)
    {
        baseTokenURI = baseTokenURI_;
        blindBoxTokenURI = blindBoxTokenURI_;
        _signerAddress = signerAddress;
        _pause();
    }


    // ======================================================== Owner Functions
    /// Set the base URI of tokens
    /// @param baseTokenURI_ new base URI
    function setBaseURI(string memory baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    /// Set the pause status
    /// @param isPaused pause or not
    function setPaused(bool isPaused) external onlyOwner {
        isPaused ? _pause() : _unpause();
    }

    /// Open blind box
    function openBlindBox() external onlyOwner {
        _isBlindBox = false;
    }

    /// Airdrop NFTs to Receiver
    /// @param receiver the receiver address
    /// @param count tokens count
    function airdrop(address receiver, uint count) external onlyOwner {
        require(_hasEnoughSupply(count), "Not enough NFTs left!");
        for (uint i = 0; i < count; i++) {
            _airdrop(receiver);
        }
    }

    /// @notice Withdraw eth
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw.");

        payable(msg.sender).transfer(balance);
    }


    // ======================================================== External Functions
    /// Free Mint Token
    /// @dev free mint token using verified signature signed by an admin address
    /// @param signature signed by an admin address
    function freeMint(bytes memory signature) external payable whenNotPaused {
        require(_hasEnoughSupply(1), "Not enough NFTs left!");
        require(_isValidSignature(signature), "Address is not in whitelist.");
        require(!_signatureUsed[signature], "Signature has already been used.");
        // if has enough free mint supply, free mint
        if (_hasEnoughFreeMintSupply()) {
            _freeMint();
        } else {
            // has not enough free mint supply, pay for mint
            require(_hasEnoughBalance(1), "Not enough balance left!");
            _mint();
        }
        _signatureUsed[signature] = true;
    }

    /// Mint Token
    /// @dev mints token
    function mint(uint256 count) external payable whenNotPaused {
        require(_hasEnoughSupply(count), "Not enough NFTs left!");
        require(_hasEnoughBalance(count), "Not enough balance left!");

        for (uint256 i = 0; i < count; i++) {
            _mint();
        }
    }

    /// @dev has enough free mint supply
    function canFreeMint() public view virtual returns (bool) {
        return _hasEnoughFreeMintSupply();
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        if (_isBlindBox) {
            return blindBoxTokenURI;
        }

        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }

    /// Get Token Ids
    /// @dev Get the token ids owned by owner
    /// @param _owner owner address of tokens
    /// @return token Ids array
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        return _tokensOfOwner(_owner);
    }


    // ======================================================== Internal Functions
    /// Verify Signature
    /// @param signature signed by an admin address
    /// @return if the signature is valid
    function _isValidSignature(bytes memory signature) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(name(), msg.sender));
        return _isValidHash(hash, signature);
    }

    /// Verify Hash And Signature
    /// @param signature signed by an admin address
    /// @return if the signature is valid
    function _isValidHash(bytes32 hash, bytes memory signature) internal view returns (bool) {
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address recoveredAddress = ECDSA.recover(message, signature);
        return recoveredAddress != address(0) && recoveredAddress == _signerAddress;
    }

    /// Verify Supply
    /// @dev check the supply is enough or not
    /// @param count mint count
    /// @return is enough
    function _hasEnoughSupply(uint count) internal view returns (bool) {
        return totalSupply() + count <= MAX_SUPPLY;
    }

    /// Verify Free Mint Supply
    /// @dev check the supply of free mint is enough or not
    /// @return is enough
    function _hasEnoughFreeMintSupply() internal view returns (bool) {
        return _freeMintedCounter.current() + 1 <= MAX_FREE_MINT_SUPPLY;
    }

    /// Verify Balance
    /// @dev check the balance is enough or not
    /// @return is enough
    function _hasEnoughBalance(uint numberOfTokens) internal view returns (bool) {
        return msg.value >= MINT_PRICE.mul(numberOfTokens);
    }

    /// Get Token Ids
    /// @dev Get the token ids owned by owner
    /// @param _owner owner address of tokens
    /// @return token Ids array
    function _tokensOfOwner(address _owner) private view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /// @notice Get Next Token Id
    /// @dev if a token id has exists, then the token index ++ and recursive get nextTokenId
    function _nextTokenId() private returns (uint) {
        uint newTokenID = _tokenIndex.current();
        // if a token id exists, then the token index ++
        if (_exists(newTokenID)) {
            _tokenIndex.increment();
            // recursive get
            return _nextTokenId();
        }
        return newTokenID;
    }

    /// Free Mint
    /// @dev free mint NFT to the sender address
    function _freeMint() private {
        _mint();
        _freeMintedCounter.increment();
    }

    /// Mint
    /// @dev mint NFT to the sender address
    function _mint() private {
        uint newTokenID = _nextTokenId();
        _safeMint(msg.sender, newTokenID);
        _tokenIndex.increment();
    }

    /// Airdrop
    /// @dev airdrop NFT to the sender address
    function _airdrop(address receiver) private {
        uint newTokenID = _nextTokenId();
        _safeMint(receiver, newTokenID);
        _tokenIndex.increment();
    }
} // End of Contract