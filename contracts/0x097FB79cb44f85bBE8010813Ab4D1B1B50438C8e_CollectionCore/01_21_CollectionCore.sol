// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ApprovedCreatorRegistryInterface.sol";
import "./RoyaltyRegistryInterface.sol";
import "./OBOControl.sol";
import "./VaultCoreInterface.sol";

contract CollectionCore is ERC721Enumerable, OBOControl, Pausable {
    using ECDSA for bytes32;
    uint8 public constant VERSION = 1;
    uint16 public immutable royaltyPercentage;
    address public immutable creator;
    address public signerAddress;
    bool public enableExternalMinting;
    // by default bool's are false, save gas by not initializing
    bool public isImmutable;
    uint256 public immutable totalMediaSupply;
    string public baseURI;
    ApprovedCreatorRegistryInterface public creatorRegistryStore;

    struct ExternalCreateRequest {
        address owner;
        bytes signature;
        uint256 tokenId;
    }

    struct OBOCreateRequest {
        address owner;
        uint256 tokenId;
    }

    struct ChainSignatureRequest {
        uint256 onchainId;
        address owner;
        address thisContract;
    }

    event NewSignerEvent(address signer);

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _crsAddress,
        uint256 _totalSupply,
        address _creator,
        uint16 _royaltyPercentage,
        string memory _initialBaseURI
    ) ERC721(_tokenName, _tokenSymbol) {
        require(
            _royaltyPercentage > 0 && _royaltyPercentage <= 10000,
            "invalid royalty"
        );
        require(_creator != address(0), "creator = 0x0");
        setCreatorRegistryStore(_crsAddress);
        require(_totalSupply > 0, "supply > 0");
        totalMediaSupply = _totalSupply;
        creator = _creator;
        royaltyPercentage = _royaltyPercentage;
        baseURI = _initialBaseURI;
    }

    /*
     * Set signer address on the token contract. Setting signer means we are opening
     * the token contract for external accounts to create tokens. Call this to change
     * the signer immediately.
     */
    function setSignerAddress(
        address _signerAddress,
        bool _enableExternalMinting
    ) external whenNotPaused isApprovedOBO {
        require(_signerAddress != address(0), "cant be zero");
        signerAddress = _signerAddress;
        enableExternalMinting = _enableExternalMinting;
        emit NewSignerEvent(signerAddress);
    }

    // Set the creator registry address upon construction. Immutable.
    function setCreatorRegistryStore(address _crsAddress) internal {
        require(_crsAddress != address(0), "registry = 0x0");
        ApprovedCreatorRegistryInterface candidateCreatorRegistryStore = ApprovedCreatorRegistryInterface(
                _crsAddress
            );
        // require(candidateCreatorRegistryStore.getVersion() == 1, "registry store is not version 1");
        // Simple check to make sure we are adding the registry contract indeed
        // https://fravoll.github.io/solidity-patterns/string_equality_comparison.html
        bytes32 contractType = keccak256(
            abi.encodePacked(candidateCreatorRegistryStore.typeOfContract())
        );
        // keccak256(abi.encodePacked("approvedCreatorRegistryReadOnly")) = 0x9732b26dfb8751e6f1f71e8f21b28a237cfe383953dce7db3dfa1777abdb2791
        require(
            contractType ==
                0x9732b26dfb8751e6f1f71e8f21b28a237cfe383953dce7db3dfa1777abdb2791,
            "not crtrReadOnlyRegistry"
        );
        creatorRegistryStore = candidateCreatorRegistryStore;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /*
     * Set BaseURI for the entire collectible project. Only owner can set it to hide / reveal
     * baseURI.
     */
    function setBaseURI(string memory _newBaseURI)
        external
        onlyOwner
        whenNotPaused
    {
        require(isImmutable == false, "cant change");
        baseURI = _newBaseURI;
    }

    function makeImmutable() external onlyOwner {
        isImmutable = true;
    }

    /* External users who have been given a signature can mint token using this function
     * This Fn works only when unpaused.
     */
    function mintTokens(ExternalCreateRequest[] calldata requests)
        external
        whenNotPaused
    {
        require(enableExternalMinting == true, "minting disabled");
        for (uint32 i = 0; i < requests.length; i++) {
            ExternalCreateRequest memory request = requests[i];
            // If a token is burnt _exists will return 0.
            require(_exists(request.tokenId) == false, "token exists");
            require(request.owner == msg.sender, "owner error");
            require(totalSupply() + 1 <= totalMediaSupply, "exceeded supply");
            ChainSignatureRequest
                memory signatureRequest = ChainSignatureRequest(
                    request.tokenId,
                    request.owner,
                    address(this)
                );
            bytes32 encodedRequest = keccak256(abi.encode(signatureRequest));
            address addressWhoSigned = encodedRequest.recover(
                request.signature
            );
            require(addressWhoSigned == signerAddress, "sig error");
            _safeMint(msg.sender, request.tokenId);
        }
    }

    function oboMintTokens(OBOCreateRequest[] calldata requests)
        external
        isApprovedOBO
    {
        for (uint32 i = 0; i < requests.length; i++) {
            OBOCreateRequest memory request = requests[i];
            require(_exists(request.tokenId) == false, "token exists");
            require(totalSupply() + 1 <= totalMediaSupply, "exceeded supply");
            _safeMint(request.owner, request.tokenId);
        }
    }

    /**
     * Override the isApprovalForAll to check for a special oboApproval list.  Reason for this
     * is that we can can easily remove obo operators if they every become compromised.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(IERC721, ERC721)
        registryInitialized
        returns (bool)
    {
        if (
            creatorRegistryStore.isOperatorApprovedForCustodialAccount(
                _operator,
                _owner
            ) == true
        ) {
            return true;
        } else {
            return super.isApprovedForAll(_owner, _operator);
        }
    }

    /**
     * Validates that the Registered store is initialized.
     */
    modifier registryInitialized() {
        require(address(creatorRegistryStore) != address(0), "registry = 0x0");
        _;
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address _creator, uint256 _payout)
    {
        return (creator, ((_salePrice * royaltyPercentage) / 10000));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // TODO: Other collectible project dont expose burn.
    // function burn(uint256 _tokenId) external {
    //     require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: burn caller is not owner nor approved");
    //     _burn(_tokenId);
    // }
}