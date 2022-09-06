// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./lzApp/NonblockingLzApp.sol";
/*
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU      UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU            UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU               UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU                UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU                UU  UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU                        UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU                         UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU                         UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU                       UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU                   UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU               UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU          UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU      UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU    UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU               UUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU  UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU          UUUUUUUUU                   UUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUU UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU              UUUUU                       UUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU              UUU                          UUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU             UUU                          UUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUU    UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU             UU                            UUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUU    UU  UUUUUUUUUUUUUUUUUUUUUUUUU    UUUUUU           UU                              UUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUU          UUUUUUUUUUUUUUUUUUUU          UUUUU          U                               UUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUU           UUUUUUUUUUUUUUUUUUU           UUUUU        UU                                 UUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUU          UUUUUUUUUUUUUUUUUUUU            UUUUU                                          UUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUU          UUUUUUUUUUUUUUUUUUU             UUUUU                                          UUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUU          UUUUUUUUUUUUUUUUUUUU             UUUUU                                          UUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUU          UUUUUUUUUUUUUUUUUUU              UUUUU                                         UUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUU          UUUUUUUUUUUUUUUUUUU             UUUUUU                                         UUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUU            UUUUUUUUUUUUUUUU               UUUUU                                          UUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUU             UUUUUUUUUUUUUU               UUUUUU                                          UUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUU              UUUUUUUUU                  UUUUU                                          UUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUU                                        UUUUU                                           UUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUU                                       UUUUUU                  UUUUUUUU                 UUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUU                                     UUUUUU                 UUUUUUUUUUU               UUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUU                                   UUUUUU                 UUUUUUUUUUUU              UUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUU                                 UUUUUU                 UUUUUUUUUUUUU              UUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUU                               UUUUUU                  UUUUUUUUUUUU               UUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUU                           UUUUUUU                  UUUUUUUUUUUU               UUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUU                     UUUUUUUUUU                  UUUUUUUUUUU                UUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU           UUUUUUUUUUUUUUUUUUU          UUUUUUUUUUUUUUUU              UUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
*/
contract UninvitedElephant is ERC721, Ownable, ReentrancyGuard, NonblockingLzApp {
    using Strings for uint256;

    string public baseTokenURI;
    string public hiddenMetadataUri;

    uint256 public lastMintId;
    uint256 public gasForDestinationLzReceive = 350000;
    uint256 public immutable startMintId;
    uint256 public immutable maxMintId;
    // all chain total supply
    uint256 public totalSupply;
    uint256 public universalMaxTokenId = 1033;
    // WARNING:
    // If maxMIntAmountPerTx is changed to any number other than 2, all the
    // code blocks surrounded by the marker
    // **maxMintAmountPerTx DEPENDENT GAS OPTIMIZATION**
    // should be re-written.
    uint256 public constant maxMintAmountPerTx = 2;

    bool public paused = true;

    bytes32 public merkleRoot;

    /// @notice Constructor for the Omnichain NFT
    /// @param _preMintCount need pre mint NFTs on this chain
    /// @param _startMintId the starting mint tokenId on this chain
    /// @param _endMintId the max number of mints on this chain
    /// @param _layerZeroEndpoint handles message transmission across chains
    /// @param _hiddenMetadataUri the hidden Uniform Resource Identifier (URI)
    constructor(
        uint256 _preMintCount,
        uint256 _startMintId,
        uint256 _endMintId,
        address _layerZeroEndpoint,
        string memory _hiddenMetadataUri
    ) ERC721("UninvitedElephant", "UE") NonblockingLzApp(_layerZeroEndpoint) {
        lastMintId = _startMintId - 1;
        startMintId = _startMintId;
        maxMintId = _endMintId;

        setHiddenMetadataUri(_hiddenMetadataUri);
        // preMint when _preMintCount > 0
        for (uint8 i = 0; i < _preMintCount; ++i) {
            _safeMint(_msgSender(), ++lastMintId);
        }
    }

    modifier mintCompliance(uint8 _mintAmount) {
        require(

            // **maxMintAmountPerTx DEPENDENT GAS OPTIMIZATION**
            // _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 
            _mintAmount == 1 || _mintAmount == 2,
            // **maxMintAmountPerTx DEPENDENT GAS OPTIMIZATION**
            "UninvitedElephant: Invalid mint amount"
        );
        require(
            lastMintId + _mintAmount <= maxMintId, 
            "UninvitedElephant: Max supply exceeded"
        );
        require(
            _msgSender() == tx.origin, 
            "UninvitedElephant: User wallet required"
        );
        require(
            (balanceOf(_msgSender()) + _mintAmount) <= maxMintAmountPerTx, 
            "UninvitedElephant: Only max 2 for address"
        );
        _;
    }

    function whitelistMint(uint8 _mintAmount, bytes32[] calldata _merkleProof)
     external 
     payable
     mintCompliance(_mintAmount) {
        require(
            proofWhitelist(_merkleProof),
            "UninvitedElephant: Address not in the whitelist"
        );

        // **maxMintAmountPerTx DEPENDENT GAS OPTIMIZATION**
        /*
            for(uint8 i = 0; i < _mintAmount; i++){
                _safeMint(_msgSender(), nextMintId++);
            }
        */
        _safeMint(_msgSender(), ++lastMintId);
	    if (_mintAmount == 2) {
            _safeMint(_msgSender(), ++lastMintId);
        }
        // **maxMintAmountPerTx DEPENDENT GAS OPTIMIZATION**
     }

    function mint(uint8 _mintAmount) external payable mintCompliance(_mintAmount) {
        require(!paused, "UninvitedElephant: The contract is paused");

        // **maxMintAmountPerTx DEPENDENT GAS OPTIMIZATION**
        /*
            for(uint8 i = 0; i < _mintAmount; i++){
                _safeMint(_msgSender(), nextMintId++);
            }
        */
        _safeMint(_msgSender(), ++lastMintId);
	    if (_mintAmount == 2) {
            _safeMint(_msgSender(), ++lastMintId);
	    }
        // **maxMintAmountPerTx DEPENDENT GAS OPTIMIZATION**
    }

    function proofWhitelist(bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "UninvitedElephant: URI query for nonexistent token");
        return _getTokenURI(_tokenId);
    }

    function _getTokenURI(uint256 _tokenId) internal view returns (string memory) {
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json")) : hiddenMetadataUri;
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function totalMinted() external view returns(uint256){
        unchecked {
            return lastMintId + 1 - startMintId;
        }
    }

    // only this chain supply, different from @totalSupply
    function maxSupply() external view returns (uint256){
         unchecked {
            return maxMintId - startMintId + 1;
         }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setGasForDestinationLzReceive(uint256 newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }

    function setUniversalMaxTokenId(uint256 newVal) external onlyOwner {
        universalMaxTokenId = newVal;
    }

    /// @notice if roothash not empty means whitelist minting enable
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool os,) = payable(owner()).call{value : address(this).balance}("");
        require(os);
    }

    /// @notice Block transfers when whitelist mint enable.
     function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        // tranfser
        if(from != address(0) && to != address(0)){
            require(!paused, "UninvitedElephant: Can't transfer before public minting");
        }
        // mint
       else if (from == address(0) && to != address(0)) {
            unchecked {
                ++totalSupply;
            }
        } 
        // burn
        else if (from != address(0) && to == address(0)) {
            unchecked {
                --totalSupply;
            }
        }
    }

    /// @notice Burn UE on source chain and mint on destination chain
    /// @param _dstChainId  - the destination chain id you want to transfer too
    /// @param _tokenId     - the id of the NFT you want to transfer
    function traverseChains(uint16 _dstChainId, uint _tokenId) external payable {
        require(!paused, "UninvitedElephant: Can't transfer when contract paused");
        require(ownerOf(_tokenId) == _msgSender(), "UninvitedElephant: Send from incorrect owner");
        require(trustedRemoteLookup[_dstChainId].length != 0, "UninvitedElephant: Destination chain is not a trusted source");

        _burn(_tokenId);

        bytes memory payload = abi.encode(_msgSender(), _tokenId);

        // encode adapterParams w/ extra gas for destination chain
        uint16 version = 1;
        uint gas = gasForDestinationLzReceive;
        bytes memory adapterParams = abi.encodePacked(version, gas);

        // use LayerZero estimateFees for cross chain delivery
        (uint quotedLayerZeroFee, ) = endpoint.estimateFees(_dstChainId, address(this), payload, false, adapterParams);

        require(msg.value >= quotedLayerZeroFee, "UninvitedElephant: Not enough gas to cover cross chain transfer.");

        _lzSend(_dstChainId, payload, payable(_msgSender()), address(0x0), adapterParams);
    }


    /// @notice Override the _LzReceive internal function of the NonblockingLzApp
    // @param _payload      - the signed payload is the UA bytes has encoded to be sent
    function _LzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal virtual override {
        (address dstAddress, uint256 tokenId) = abi.decode(_payload, (address, uint256));
        require(tokenId <= universalMaxTokenId, "UninvitedElephant: Impossible token ID! L0 endpoint been hacked?");
        _safeMint(dstAddress, tokenId);
    }
}