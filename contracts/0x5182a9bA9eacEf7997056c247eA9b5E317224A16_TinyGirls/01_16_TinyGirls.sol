pragma solidity 0.8.4;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./NonBlockingReceiver.sol";
import "./interfaces/ILayerZeroUserApplicationConfig.sol";

/* 
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░██████████████░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░██▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░██▒██▒▒▒██▒░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░██░░▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░██▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░███▒█▒███░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░▒▒█▒█▒█▒▒░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░▒▒█▒█▒█▒▒░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░███████░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░███████░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░▒▒▒░▒▒▒░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░███░███░░░░░░░░░░░░░░░░░░░░░
░░░░═══░░░║░║░║░║░░░░░░░░░░░░░░░░░░░░░░░
░░░░░║░░║░║░░║░╚╦╝░░░░░░░░░░░░░░░░░░░░░░
░░░░░║░░║░║░─║░░║░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░══░░░░░░║░░══░░░░░░░░░░░░░░░░░░░░░░
░░░░║░░░░░░░░║░║░░░░░░░░░░░░░░░░░░░░░░░░
░░░░║░═░║░╔═░║░░═░░░░░░░░░░░░░░░░░░░░░░░
░░░░░══░║░║░░║░══║░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ */

/// @title A LayerZero OmnichainNonFungibleToken Contract
/// @author Tiny Girls
/// @notice You can use this to mint ONFT and transfer across chain
/// @dev All function calls are currently implemented without side effects
contract TinyGirls is ERC721, NonblockingReceiver, ILayerZeroUserApplicationConfig {

    using Strings for uint256;
    string public baseTokenURI;
    string public baseTokenNotRevealedURI;

    address _owner;

    uint256 public nextTokenId;
    uint256 public immutable maxSupply;
    uint256 public immutable maxMintPerTx = 2;
    uint256 public immutable maxPerWallet = 3;

    bool public revealed = false;

    /// @notice Constructor for the OmnichainNonFungibleToken
    /// @param _baseTokenURI the Uniform Resource Identifier (URI) for tokenId token
    /// @param _layerZeroEndpoint handles message transmission across chains
    /// @param _startToken the starting mint number on this chain
    /// @param _maxSupply the max number of mints on this chain
    constructor(
        string memory _baseTokenURI,
        string memory _baseTokenNotRevealedURI,
        address _layerZeroEndpoint,
        uint256 _startToken,
        uint256 _maxSupply
    )
    ERC721("TinyGirls", "TG"){
        setBaseURI(_baseTokenURI);
        setBaseNotRevealedURI(_baseTokenNotRevealedURI);
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        nextTokenId = _startToken;
        maxSupply = _maxSupply;
        _owner = msg.sender;

        for(uint8 i = 0; i < 100; i++){
            _safeMint(msg.sender, nextTokenId++);
        }
    }

    function mint(uint8 _amountMint) external {
        require(_amountMint > 0 && _amountMint <= maxMintPerTx, "Tiny Girls: Only 3 mint per TX");
        require(nextTokenId + _amountMint <= maxSupply, "Tiny Girls: Max supply for this chain");
        require(_amountMint <= maxMintPerTx && balanceOf(msg.sender) <= maxPerWallet, "Tiny Girls: Only max 3 for address");
        
        _safeMint(msg.sender, ++nextTokenId);
        if (_amountMint == 2) {
            _safeMint(msg.sender, ++nextTokenId);
        }
    }

    function totalSupply() public view returns (uint) {
        return maxSupply;
    }
    
    function reveal() public onlyOwner {
        revealed = true;
    }

    /// @notice Burn OmniChainNFT_tokenId on source chain and mint on destination chain
    /// @param _chainId the destination chain id you want to transfer too
    /// @param omniChainNFT_tokenId the id of the ONFT you want to transfer
    function traverseNFT(
        uint16 _chainId,
        uint256 omniChainNFT_tokenId
    ) public payable {
        require(trustedSourceLookup[_chainId].length != 0, "This chain is not a trusted source source.");

        // burn ONFT on source chain
         _burn(omniChainNFT_tokenId);

        // encode payload w/ sender address and ONFT token id
        bytes memory payload = abi.encode(msg.sender, omniChainNFT_tokenId);

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

    /// @notice Set the baseTokenURI
    /// @param _baseTokenURI to set
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
    
    function setBaseNotRevealedURI(string memory _baseTokenNotRevealedURI) public onlyOwner {
        baseTokenNotRevealedURI = _baseTokenNotRevealedURI;
    }

    /// @notice Get the base URI
    function _baseURI() override internal view returns (string memory) {
        return baseTokenURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns(string memory){
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");

        if(!revealed) {
            return baseTokenNotRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),".json")) : "";
    }

    /// @notice Override the _LzReceive internal function of the NonblockingReceiver
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    /// @dev safe mints the ONFT on your destination chain
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