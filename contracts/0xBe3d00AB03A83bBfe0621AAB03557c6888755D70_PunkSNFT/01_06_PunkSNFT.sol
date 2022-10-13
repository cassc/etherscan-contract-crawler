pragma solidity ^0.8.9;

import "./PunkInterface.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PunkSNFT is Ownable {
    using ECDSA for bytes32;

    PunkInterface public nft;

    address public signer;

    mapping(uint256 => address) private _activatedBy;
    mapping(uint256 => bool) public isNonceUsed;
    mapping(uint256 => mapping(uint256 => string)) public handleOf; // tokenId => platformId => handle
    mapping(uint256 => string) public platforms; // platformId => platform

    uint256 totalPlatforms;

    event ActivatedStatusChanged(uint256 tokenId, address owner, bool status);
    event HandleUpdated(uint256 tokenId, uint256 platformId, string handle);
    event PlatformAdded(uint256 platformId, string platform);
    event PlatformUpdated(uint256 platformId, string platform);

    error OnlyNFTOwnerAllowed();
    error AlreadyActivated();
    error NotActivated();
    error InvalidSignature();
    error InvalidNonce();
    error ZeroAddressNotAllowed();
    error PlatformNotFound();
    error PlatformAlreadyAdded();

    constructor(PunkInterface _nft, address _signer) {
        nft = _nft;
        if (_signer == address(0)) revert ZeroAddressNotAllowed();
        signer = _signer;
        addPlatform("twitter");
    }

    function setSigner(address _signer) public onlyOwner {
        if (_signer == address(0)) revert ZeroAddressNotAllowed();
        signer = _signer;
    }

    function addPlatform(string memory _platform) public onlyOwner {
        // Generate platform Id
        uint256 platformId = totalPlatforms++;

        // Add the platform
        platforms[platformId] = _platform;
        emit PlatformAdded(platformId, _platform);
    }

    function updatePlatform(uint256 _platformId, string memory _platformName)
        public
        onlyOwner
    {
        if (_platformId >= totalPlatforms) revert PlatformNotFound();

        platforms[_platformId] = _platformName;
        emit PlatformUpdated(_platformId, _platformName);
    }

    function setProfile(
        uint256 _tokenId,
        uint256 _platformId,
        string memory _handle,
        bytes calldata _signature,
        uint256 _nonce
    ) public {
        // Check the nonce validity
        if (isNonceUsed[_nonce]) revert InvalidNonce();

        // Check if the sender is the owner of the token
        if (nft.punkIndexToAddress(_tokenId) != msg.sender)
            revert OnlyNFTOwnerAllowed();

        // Check if activated
        if (_activatedBy[_tokenId] != msg.sender) {
            _activatedBy[_tokenId] = msg.sender;
            emit ActivatedStatusChanged(_tokenId, msg.sender, true);
        }

        // Check signature from the assigned signer
        bytes32 msgHash = keccak256(
            abi.encodePacked(_tokenId, _platformId, _handle, _nonce)
        );
        bytes32 hash = msgHash.toEthSignedMessageHash();
        if (_platformId >= totalPlatforms) revert PlatformNotFound();
        if (hash.recover(_signature) != signer) revert InvalidSignature();

        // Update the nonce validity
        isNonceUsed[_nonce] = true;

        // Update the handle
        handleOf[_tokenId][_platformId] = _handle;
        emit HandleUpdated(_tokenId, _platformId, _handle);
    }

    function activate(
        uint256 _tokenId,
        bytes calldata _signature,
        uint256 _nonce
    ) public {
        // Check the nonce validity
        if (isNonceUsed[_nonce]) revert InvalidNonce();

        // Check if the sender is the owner of the token
        if (nft.punkIndexToAddress(_tokenId) != msg.sender)
            revert OnlyNFTOwnerAllowed();

        // Check if not already activated
        if (_activatedBy[_tokenId] == msg.sender) revert AlreadyActivated();

        // Check signature from the assigned signer
        bytes32 msgHash = keccak256(abi.encodePacked(_tokenId, _nonce));
        bytes32 hash = msgHash.toEthSignedMessageHash();
        if (hash.recover(_signature) != signer) revert InvalidSignature();

        // Update the nonce validity
        isNonceUsed[_nonce] = true;

        // Change the activation status
        _activatedBy[_tokenId] = msg.sender;
        emit ActivatedStatusChanged(_tokenId, msg.sender, true);
    }

    function deactivate(uint256 tokenId) public {
        // Check if the sender is the owner of the token
        if (nft.punkIndexToAddress(tokenId) != msg.sender)
            revert OnlyNFTOwnerAllowed();

        // Check if activated
        if (_activatedBy[tokenId] != msg.sender) revert NotActivated();

        // Change the activated status
        _activatedBy[tokenId] = address(0);
        emit ActivatedStatusChanged(tokenId, msg.sender, false);
    }

    function checkOwnershipAndActivatedStatus(address _owner, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return
            nft.punkIndexToAddress(_tokenId) == _owner &&
            _activatedBy[_tokenId] == _owner;
    }
}