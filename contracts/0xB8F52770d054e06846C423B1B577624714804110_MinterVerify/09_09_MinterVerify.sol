// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract IERC721 {
    function mint(address to, uint quantity) external virtual;

    function ownerOf(uint tokenId) external view virtual returns (address);
}

contract MinterVerify is Ownable, EIP712 {
    using SafeERC20 for IERC20;
    IERC721 public erc721;
    IERC20 public stableToken;
    bytes32 public constant MINTER_TYPEHASH = keccak256("Mint(address to,uint256 quantity,uint256 nonce)");

    address public signerAddress;
    address public feeCollectorAddress;
    uint public price;
    bool public publicMint;
    mapping(bytes32 => bool) public signatureUsed;
    modifier requiresSignature(
        bytes calldata signature,
        uint quantity,
        uint nonce
    ) {
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 structHash = keccak256(abi.encode(MINTER_TYPEHASH, msg.sender, quantity, nonce));
        bytes32 digest = _hashTypedDataV4(structHash); /*Calculate EIP712 digest*/
        require(!signatureUsed[digest], "signature used");
        signatureUsed[digest] = true;
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = ECDSA.recover(digest, signature);
        require(signerAddress == recoveredAddress, "Invalid Signature");
        _;
    }

    constructor(IERC721 _erc721, IERC20 _stableToken, address _signer, uint _price, address _feeCollector) EIP712("UFC277Minter", "1") {
        erc721 = _erc721;
        stableToken = _stableToken;
        signerAddress = _signer;
        price = _price;
        feeCollectorAddress = _feeCollector;
    }

    function setNFT(IERC721 erc721_) public onlyOwner {
        erc721 = erc721_;
    }

    function setPublicMint(bool onOrOff) public onlyOwner {
        publicMint = onOrOff;
    }

    function setSignerAddress(address _newSigner) public onlyOwner {
        signerAddress = _newSigner;
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function mintPublic(uint _quantity) public {
        require(publicMint, "Public mint is not active");
        stableToken.safeTransferFrom(msg.sender, feeCollectorAddress, price * _quantity);
        erc721.mint(msg.sender, _quantity);
    }

    function mint(uint _quantity, uint _nonce, bytes calldata _signature) public requiresSignature(_signature, _quantity, _nonce) {
        stableToken.safeTransferFrom(msg.sender, feeCollectorAddress, price * _quantity);
        erc721.mint(msg.sender, _quantity);
    }
}