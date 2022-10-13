// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Interfaces/IKingdomRaidsNFT.sol";
import "./Interfaces/IKingdomRaidsBlindBox.sol";

contract NFTFactory is Ownable, Pausable, ReentrancyGuard {
    using Address for address;
    using ECDSA for bytes32;

    // ERC20 token used for pay mint fee
    address public feeTokenAddress;
    // Price (in wei) for the new mint
    uint256 public nftMintFee;
    // Public signer to validate signature
    address public signerPublicKey;

    mapping(address => mapping(string => bool)) executed;

    // Events
    event OpenBlindbox(
        address blindboxAddress,
        uint256 boxId,
        address nftAddress,
        uint256 tokenId
    );
    event ChangeFeeToken(address newFeeTokenAddress);
    event ChangeSignerPublicKey(address newSignerPublicKey);
    event ChangeMintFee(uint256 newMintFee);
    event AssetCreated(
        address indexed nftAddres,
        address indexed creator,
        string ingameId,
        uint256 tokenId
    );

    constructor(
        uint256 _nftMintFee,
        address _feeTokenAddress,
        address _signer
    ) {
        setMintFee(_nftMintFee);
        setFeeTokenAddress(_feeTokenAddress);
        setSignerPublicKey(_signer);
    }

    function setSignerPublicKey(address newSignerPublicKey) public onlyOwner {
        require(
            newSignerPublicKey != address(0),
            "KingdomRaidsNFTFactory: invalid address"
        );
        require(
            newSignerPublicKey != signerPublicKey,
            "KingdomRaidsNFTFactory: new signer public key should be different with the current key"
        );
        signerPublicKey = newSignerPublicKey;
        emit ChangeSignerPublicKey(newSignerPublicKey);
    }

    function setFeeTokenAddress(address newFeeTokenAddress) public onlyOwner {
        require(
            newFeeTokenAddress.isContract(),
            "KingdomRaidsNFTFactory: fee token address must be a deployed contract"
        );
        feeTokenAddress = newFeeTokenAddress;
        emit ChangeFeeToken(newFeeTokenAddress);
    }

    function setMintFee(uint256 _nftMintFee) public onlyOwner {
        require(
            nftMintFee != _nftMintFee,
            "KingdomRaidsNFTFactory: must be different value"
        );
        nftMintFee = _nftMintFee;
        emit ChangeMintFee(_nftMintFee);
    }

    function openBox(
        address _blindboxAddress,
        uint256 _boxId,
        address _nftAddress,
        string memory _ingameId,
        bytes memory _signature
    ) external whenNotPaused nonReentrant returns (uint256) {
        address _sender = _msgSender();

        address signer = keccak256(
            abi.encode(
                _blindboxAddress,
                _boxId,
                _nftAddress,
                _ingameId,
                _sender
            )
        ).toEthSignedMessageHash().recover(_signature);
        require(
            signer == signerPublicKey,
            "KingdomRaidsNFTFactory: invalid signature"
        );
        IKingdomRaidsBlindBox(_blindboxAddress).burn(_sender, _boxId, 1);
        uint256 tokenId = _mint(_sender, _nftAddress, _ingameId);
        emit OpenBlindbox(_blindboxAddress, _boxId, _nftAddress, tokenId);
        return tokenId;
    }

    function mint(
        address _nftAddress,
        string memory _ingameId,
        bytes memory _signature
    ) external whenNotPaused nonReentrant returns (uint256) {
        address _sender = _msgSender();

        address signer = keccak256(abi.encode(_nftAddress, _ingameId, _sender))
            .toEthSignedMessageHash()
            .recover(_signature);

        require(
            signer == signerPublicKey,
            "KingdomRaidsNFTFactory: invalid signature"
        );
        uint256 tokenId = _mint(_sender, _nftAddress, _ingameId);
        return tokenId;
    }

    function _mint(
        address _sender,
        address _nftAddress,
        string memory _ingameId
    ) internal returns (uint256) {
        require(
            !executed[_nftAddress][_ingameId],
            "KingdomRaidsNFTFactory: ingameId is already used"
        );
        // Transfer mint fee to owner
        if (nftMintFee > 0) {
            IERC20(feeTokenAddress).transferFrom(_sender, owner(), nftMintFee);
        }

        uint256 tokenId = IKingdomRaidsNFT(_nftAddress).mint(_sender);
        executed[_nftAddress][_ingameId] = true;
        emit AssetCreated(_nftAddress, _sender, _ingameId, tokenId);
        return tokenId;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}