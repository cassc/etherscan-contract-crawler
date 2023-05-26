pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./NonBlockingReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";


contract LayerZeroPunksMainnet is ERC721Enumerable, NonblockingReceiver, ILayerZeroUserApplicationConfig {
    using Strings for uint256;

    string public baseTokenURI;
    uint256 nextTokenId;
    uint256 public immutable maxMint;
    uint256 public immutable maxPerTx = 2;
    uint256 public immutable startTimestamp;

    constructor(
        string memory _baseTokenURI,
        address _layerZeroEndpoint,
        uint256 _startToken,
        uint256 _maxMint,
        uint256 _startTimestamp
    )
    ERC721("Layer Zero Punks", "LZP") {
        setBaseURI(_baseTokenURI);
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        nextTokenId = _startToken;
        maxMint = _maxMint;
        startTimestamp = _startTimestamp;
    }

    /// @notice Mint your OmnichainNonFungibleToken
    function mint(uint256 quantity) external {
        require(block.timestamp >= startTimestamp, "NOT_LIVE");
        require(quantity <= maxPerTx && balanceOf(msg.sender) < maxPerTx, "ONLY_2_PER_WALLET");
        require(nextTokenId + quantity <= maxMint, "MAX_SUPPLY_FOR_CHAIN");
        unchecked {
            for(uint256 i = 0; i < quantity; i++) {
                _safeMint(msg.sender, ++nextTokenId);
            }
        }
    }

    function reservePunks() public onlyOwner {
        for(uint256 i = 0; i < 20; i++) {
            _safeMint(msg.sender, i+1);
        }     
    }

    function traverseChains(
        uint16 _chainId,
        uint256 tokenId
    ) public payable {
        require(msg.sender == ownerOf(tokenId), "Message sender must own the OmnichainNFT.");
        require(trustedSourceLookup[_chainId].length != 0, "This chain is not a trusted source source.");

        // burn ONFT on source chain
         _burn(tokenId);

        // encode payload w/ sender address and ONFT token id
        bytes memory payload = abi.encode(msg.sender, tokenId);

        // encode adapterParams w/ extra gas for destination chain
        // This example uses 500,000 gas. Your implementation may need more.
        uint16 version = 1;
        uint gas = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gas);

        // use LayerZero estimateFees for cross chain delivery
        (uint quotedLayerZeroFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);

        require(msg.value >= quotedLayerZeroFee, "Not enough gas to cover cross chain transfer.");

        endpoint.send{value:msg.value}(
            _chainId,                      // destination chainId
            trustedSourceLookup[_chainId], // destination address of OmnichainNFT
            payload,                       // abi.encode()'ed bytes
            payable(msg.sender),           // refund address
            address(0x0),                  // future parameter
            adapterParams                  // adapterParams
        );
    }

    function getEstimatedFees(uint16 _chainId, uint256 tokenId) public view returns (uint) {
        bytes memory payload = abi.encode(msg.sender, tokenId);
        uint16 version = 1;
        uint gas = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gas);
        (uint quotedLayerZeroFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);
        return quotedLayerZeroFee;
    }

    /// @notice Set the baseTokenURI
    /// @param _baseTokenURI to set
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Get the base URI
    function _baseURI() override internal view returns (string memory) {
        return baseTokenURI;
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"));
    }

    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal override  {
        (address _dstAddress, uint256 tokenId) = abi.decode(_payload, (address, uint256));
        _safeMint(_dstAddress, tokenId);
    }

    //---------------------------DAO CALL----------------------------------------
    // generic config for user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        endpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        endpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        endpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    function renounceOwnership() public override onlyOwner {}
}