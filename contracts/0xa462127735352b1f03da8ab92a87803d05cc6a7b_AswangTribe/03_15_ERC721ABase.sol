// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

error ERC721ABase_ExceedsMaxPerAddress();
error ERC721ABase_FunctionLocked();
error ERC721ABase_InvalidSignature();
error ERC721ABase_InsufficientSupply();
error ERC721ABase_InvalidValue();
error ERC721ABase_MetadataNotRevealed();
error ERC721ABase_ProvenanceHashNotSet();
error ERC721ABase_ProvenanceHashAlreadySet();
error ERC721ABase_TokenOffsetNotSet();
error ERC721ABase_TokenOffsetAlreadySet();

/**                                     ..',,;;;;:::;;;,,'..
                                 .';:ccccc:::;;,,,,,;;;:::ccccc:;'.
                            .,:ccc:;'..                      ..';:ccc:,.
                        .':cc:,.                                    .,ccc:'.
                     .,clc,.                                            .,clc,.
                   'clc'                                                    'clc'
                .;ll,.                                                        .;ll;.
              .:ol.                                                              'co:.
             ;oc.                                                                  .co;
           'oo'                                                                      'lo'
         .cd;                                                                          ;dc.
        .ol.                                                                 .,.        .lo.
       ,dc.                                                               'cxKWK;         cd,
      ;d;                                                             .;oONWMMMMXc         ;d;
     ;d;                                                           'cxKWMMMMMMMMMXl.        ;x;
    ,x:            ;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0NMMMMMMMMMMMMMMNd.        :x,
   .dc           .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.        cd.
   ld.          .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl'         .dl
  ,x;          .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:.             ;x,
  oo.         .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'.                .oo
 'x:          .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.                     :x'
 :x.           .xWMMMMMMMMMMM0occcccccccccccccccccccccccccccccccccccc:'                         .x:
 lo.            .oNMMMMMMMMMX;                                                                  .ol
.ol              .lXMMMMMMMWd.  ,dddddddddddddddo;.   .:dddddddddddddo,                          lo.
.dl                cXMMMMMM0,  'OMMMMMMMMMMMMMMNd.   .xWMMMMMMMMMMMMXo.                          ld.
.dl                 ;KMMMMNl   oWMMMMMMMMMMMMMXc.   ,OWMMMMMMMMMMMMK:                            ld.
 oo                  ,OWMMO.  ,KMMMMMMMMMMMMW0;   .cKMMMMMMMMMMMMWO,                             oo
 cd.                  'kWX:  .xWMMMMMMMMMMMWx.  .dKNMMMMMMMMMMMMNd.                             .dc
 ,x,                   .dd.  ;KMMMMMMMMMMMXo.  'kWMMMMMMMMMMMMMXl.                              ,x;
 .dc                     .   .,:loxOKNWMMK:   ;0WMMMMMMMMMMMMW0;                                cd.
  :d.                      ...      ..,:c'  .lXMMMMMMMMMMMMMWk'                                .d:
  .dl                      :OKOxoc:,..     .xNMMMMMMMMMMMMMNo.                                 cd.
   ;x,                      ;0MMMMWWXKOxoclOWMMMMMMMMMMMMMKc                                  ,x;
    cd.                      ,OWMMMMMMMMMMMMMMMMMMMMMMMMWO,                                  .dc
    .oo.                      .kWMMMMMMMMMMMMMMMMMMMMMMNx.                                  .oo.
     .oo.                      .xWMMMMMMMMMMMMMMMMMMMMXl.                                  .oo.
      .lo.                      .oNMMMMMMMMMMMMMMMMMW0;                                   .ol.
       .cd,                      .lXMMMMMMMMMMMMMMMWk'                                   ,dc.
         ;dc.                      :KMMMMMMMMMMMMNKo.                                  .cd;
          .lo,                      ;0WWWWWWWWWWKc.                                   'ol.
            ,ol.                     .,,,,,,,,,,.                                   .lo,
             .;oc.                                                                .co:.
               .;ol'                                                            'lo;.
                  ,ll:.                                                      .:ll,
                    .:ll;.                                                .;ll:.
                       .:ll:,.                                        .,:ll:.
                          .,:ccc;'.                              .';ccc:,.
                              .';cccc::;'...            ...';:ccccc;'.
                                    .',;::cc::cc::::::::::::;,..
                                              ........

 * @title Base contract for standard ERC721A token drops
 * @author Augminted Labs, LLC
 * @notice Contract has been optimized for fairness and security
 */
contract ERC721ABase is ERC721AQueryable, Ownable, VRFConsumerBaseV2 {
    using Address for address;
    using ECDSA for bytes32;

    struct VrfRequestConfig {
        bytes32 keyHash;
        uint64 subId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }

    struct MintConfig {
        uint256 price;
        uint256 maxPerAddress;
        address signer;
    }

    struct Metadata {
        string baseURI;
        string collectionURI;
        string placeholderURI;
    }

    VRFCoordinatorV2Interface internal immutable COORDINATOR;
    uint256 public immutable MAX_MINTABLE;

    VrfRequestConfig public vrfRequestConfig;
    MintConfig public mintConfig;
    Metadata public metadata;
    bool public revealed;
    mapping(bytes4 => bool) public functionLocked;
    string internal _provenanceHash;
    uint256 internal _tokenOffset;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxMintable,
        address vrfCoordinator
    )
        ERC721A(name, symbol)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        MAX_MINTABLE = maxMintable;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert ERC721ABase_FunctionLocked();
        _;
    }

    /**
     * @notice Return token metadata
     * @param tokenId To return metadata for
     * @return Token URI for the specified token
     */
    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        return revealed ? ERC721A.tokenURI(tokenId) : metadata.placeholderURI;
    }

    /**
     * @notice Override ERC721 _baseURI function to use base URI pattern
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return metadata.baseURI;
    }

    /**
     * @notice Token offset is added to the token ID (wrapped on overflow) to get metadata asset index
     */
    function tokenOffset() public view returns (uint256) {
        if (_tokenOffset == 0) revert ERC721ABase_TokenOffsetNotSet();

        return _tokenOffset;
    }

    /**
     * @notice Provenance hash is used as proof that token metadata has not been modified
     */
    function provenanceHash() public view returns (string memory) {
        if (bytes(_provenanceHash).length == 0) revert ERC721ABase_ProvenanceHashNotSet();

        return _provenanceHash;
    }

    /**
     * @notice Lock individual functions that are no longer needed. WARNING: THIS CANNOT BE UNDONE
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) public onlyOwner {
        functionLocked[id] = true;
    }

    /**
     * @notice Set token offset using Chainlink VRF
     * @dev Provenance hash must already be set
     */
    function setTokenOffset() public onlyOwner {
        if (bytes(_provenanceHash).length == 0) revert ERC721ABase_ProvenanceHashNotSet();
        if (_tokenOffset != 0) revert ERC721ABase_TokenOffsetAlreadySet();

        COORDINATOR.requestRandomWords(
            vrfRequestConfig.keyHash,
            vrfRequestConfig.subId,
            vrfRequestConfig.requestConfirmations,
            vrfRequestConfig.callbackGasLimit,
            1 // number of random words
        );
    }

    /**
     * @notice Callback function for Chainlink VRF request randomness call
     * @dev Maximum offset value is the maximum token ID (MAX_MINTABLE - 1)
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _tokenOffset = randomWords[0] % MAX_MINTABLE;
    }

    /**
     * @notice Set provenance hash
     * @dev Can only be set before the token offset is generated
     * @param __provenanceHash Metadata proof string
     */
    function setProvenanceHash(string memory __provenanceHash) public onlyOwner {
        if (_tokenOffset != 0) revert ERC721ABase_TokenOffsetAlreadySet();

        _provenanceHash = __provenanceHash;
    }

    /**
     * @notice Set configuration for mint
     * @param _mintConfig Struct with updated configuration values
     */
    function setMintConfig(MintConfig memory _mintConfig) public onlyOwner {
        mintConfig = _mintConfig;
    }

    /**
     * @notice Set configuration for Chainlink VRF
     * @param _vrfRequestConfig Struct with updated configuration values
     */
    function setVrfRequestConfig(VrfRequestConfig memory _vrfRequestConfig) public onlyOwner {
        vrfRequestConfig = _vrfRequestConfig;
    }

    /**
     * @notice Set metadata information
     * @param _metadata Struct with updated metadata values
     */
    function setMetadata(Metadata calldata _metadata) public lockable onlyOwner {
        metadata = _metadata;
    }

    /**
     * @notice Flip token metadata to revealed
     * @dev Can only be revealed after token offset has been set
     */
    function flipRevealed() public virtual lockable onlyOwner {
        if (_tokenOffset == 0) revert ERC721ABase_TokenOffsetNotSet();

        revealed = !revealed;
    }

    /**
     * @notice Mint a specified amount of tokens using a signature
     * @param amount Amount of tokens to mint
     * @param signature Ethereum signed message, created by `signer`
     */
    function mint(uint256 amount, bytes memory signature) public virtual payable {
        if (msg.value != mintConfig.price * amount) revert ERC721ABase_InvalidValue();
        if (_numberMinted(_msgSender()) + amount > mintConfig.maxPerAddress)
            revert ERC721ABase_ExceedsMaxPerAddress();
        if (mintConfig.signer != ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_msgSender()))),
            signature
        )) revert ERC721ABase_InvalidSignature();

        _mint(amount);
    }

    /**
     * @notice Internal function to mint a specified amount of tokens
     * @param amount Amount of tokens to mint
     */
    function _mint(uint256 amount) internal virtual {
        if (_totalMinted() + amount > MAX_MINTABLE) revert ERC721ABase_InsufficientSupply();

        _mint(_msgSender(), amount);
    }

    /**
     * @notice Permanently commit the state of the metadata information. WARNING: THIS CANNOT BE UNDONE
     * @dev Metadata should be migrated to a decentralized and, ideally, permanent storage solution
     */
    function commitMetadata() external {
        if (!revealed) revert ERC721ABase_MetadataNotRevealed();

        lockFunction(this.setMetadata.selector);
        lockFunction(this.flipRevealed.selector);
    }

    /**
     * @notice Withdraw all ETH transferred to the contract
     */
    function withdraw() external onlyOwner {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }
}