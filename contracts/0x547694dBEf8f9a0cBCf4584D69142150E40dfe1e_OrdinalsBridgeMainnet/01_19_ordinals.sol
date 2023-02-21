// SPDX-License-Identifier: MIT

/**
* Ordinals Bridge by https://rarity.garden
*/

pragma solidity ^0.8.17;

import "./filter/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OrdinalsBridgeMainnet is ERC721, IERC721Receiver, ERC2981, DefaultOperatorFilterer, Ownable 
{
    uint256 constant chainId = 1;
    string private constant domain = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)";
    bytes32 constant salt = 0xe711af9b32f97a0a2b1e9825e854aca8bfbe464ee6e84e74d9145b0080be80a6;
    bytes32 private constant domainTypeHash = keccak256(abi.encodePacked(domain));
    string private constant bridgeType = "Bridge(address signer,address receiver,uint256 expiration,uint256 tokenId,string inscription,uint8 bridgeType,uint256 jobNumber,string tokenUri)";
    bytes32 private constant bridgeTypeHash = keccak256(abi.encodePacked(bridgeType));
    string private constant bridgeOutType = "BridgeOut(address signer,address receiver,uint256 expiration,uint256 tokenId,string inscription,uint8 bridgeType,uint256 jobNumber)";
    bytes32 private constant bridgeOutTypeHash = keccak256(abi.encodePacked(bridgeOutType));
    bytes4 private constant EIP_1271_MAGIC_VALUE = 0x1626ba7e;
    bytes32 private domainSeparator;
    string internal _baseTokenURI;
    bool internal paused;
    uint256 public totalSupply;
    mapping(address => bool) public bridgeSigners;
    mapping(uint256 => string) public _tokenUri;

    struct Bridge 
    {
        uint8 v;
        uint8 bridgeType;
        uint256 expiration;
        uint256 tokenId;
        uint256 jobNumber;
        address signer;
        address receiver;
        bytes32 r;
        bytes32 s;
        string inscription;
        string tokenUri;
    }

    struct BridgeOut
    {
        uint8 v;
        uint8 bridgeType;
        uint256 expiration;
        uint256 tokenId;
        uint256 jobNumber;
        address signer;
        address receiver;
        bytes32 r;
        bytes32 s;
        string inscription;
    }

    event Bridged(address receiver, uint256 indexed tokenId, string indexed inscription, uint256 indexed jobNumber);
    event BridgedOut(address receiver, uint256 indexed tokenId, string indexed inscription, uint256 indexed jobNumber);

    constructor(
        string memory name,
        string memory symbol,
        address royaltyAddress,
        uint96 royaltyAmount
    ) ERC721(name, symbol) {

        domainSeparator = keccak256(abi.encode(
            domainTypeHash,
            keccak256("OrdinalsBridge"),
            keccak256("1"),
            chainId,
            this,
            salt
        ));

        bridgeSigners[0xa7900Cd245e94bE77447771043E1C6C85FC96475] = true;

        _setDefaultRoyalty(royaltyAddress, royaltyAmount);
    }

    function bridgeIn(Bridge memory bridge) external
    {
        bytes32 bridgeHash = hashBridge(bridge);

        require(!paused, "bridgeIn: bridging paused");
        require(bridgeSigners[bridge.signer], "bridgeIn: non-existent bridge signer");
        require(block.number < bridge.expiration, "bridgeIn: bridging expired");
        require(bridge.bridgeType == 1, "bridgeIn: not a valid bridge type");
        require(bridge.receiver == _msgSender(), "bridgeIn: you are not the receiver");
        require(validSignature(bridge.v, bridge.s), "bridgeIn: invalid bridge signature");
        require(validSigner(bridge.signer, bridgeHash, bridge.v, bridge.r, bridge.s), "bridgeIn: invalid bridge signer");

        if(bytes(bridge.tokenUri).length > 0)
        {
            _tokenUri[bridge.tokenId] = bridge.tokenUri;
        }

        if(_exists(bridge.tokenId))
        {
            ERC721(address(this)).safeTransferFrom(address(this), _msgSender(), bridge.tokenId);
        }
        else
        {
            totalSupply += 1;
            _safeMint(_msgSender(), bridge.tokenId);
        }

        emit Bridged(bridge.receiver, bridge.tokenId, bridge.inscription, bridge.jobNumber);
    }

    function bridgeOut(BridgeOut memory bridge) external
    {
        bytes32 bridgeHash = hashBridgeOut(bridge);

        require(!paused, "bridgeOut: bridging paused");
        require(bridgeSigners[bridge.signer], "bridgeOut: non-existent bridge signer");
        require(block.number < bridge.expiration, "bridgeOut: bridging expired");
        require(bridge.bridgeType == 2, "bridgeOut: not a valid bridge-in type");
        require(bridge.receiver == _msgSender(), "bridgeOut: you are not the receiver");
        require(validSignature(bridge.v, bridge.s), "bridgeOut: invalid bridge signature");
        require(validSigner(bridge.signer, bridgeHash, bridge.v, bridge.r, bridge.s), "bridgeOut: invalid bridge signer");

        ERC721(address(this)).safeTransferFrom(_msgSender(), address(this), bridge.tokenId);

        emit BridgedOut(bridge.receiver, bridge.tokenId, bridge.inscription, bridge.jobNumber);
    }

    function validSignature(uint8 v, bytes32 s) internal pure returns(bool){

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {

            return false;
        }

        if (v != 27 && v != 28) {

            return false;
        }

        return true;
    }

    function validSigner(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns(bool){

        address recSigner = ecrecover(hash, v, r, s);

        if(recSigner != signer){

            if(!isContract(signer, hash, v, r, s)){

                return false;
            }
        }

        return true;
    }

    function hashBridge(Bridge memory bridge) internal view returns (bytes32)
    {
        
      return keccak256(abi.encodePacked(
      "\x19\x01",
      domainSeparator,
      keccak256(abi.encode(
              bridgeTypeHash,
              bridge.signer,
              bridge.receiver,
              bridge.expiration,
              bridge.tokenId,
              keccak256(abi.encodePacked(bridge.inscription)),
              bridge.bridgeType,
              bridge.jobNumber,
              keccak256(abi.encodePacked(bridge.tokenUri))
          ))
      ));
    }

    function hashBridgeOut(BridgeOut memory bridge) internal view returns (bytes32)
    {
        
      return keccak256(abi.encodePacked(
      "\x19\x01",
      domainSeparator,
      keccak256(abi.encode(
              bridgeOutTypeHash,
              bridge.signer,
              bridge.receiver,
              bridge.expiration,
              bridge.tokenId,
              keccak256(abi.encodePacked(bridge.inscription)),
              bridge.bridgeType,
              bridge.jobNumber
          ))
      ));
    }

    function isContract(address seller, bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) 
    {

        bytes memory isValidSignatureData = abi.encodeWithSelector(
            EIP_1271_MAGIC_VALUE,
            hash,
            abi.encodePacked(r, s, v)
        );

        bytes4 result;

        assembly {
            let success := staticcall(           
                gas(),                             
                seller,                          
                add(isValidSignatureData, 0x20), 
                mload(isValidSignatureData),     
                0,                               
                0                                
            )

            if iszero(success) {                     
                returndatacopy(0, 0, returndatasize()) 
                revert(0, returndatasize())            
            }

            if eq(returndatasize(), 0x20) {  
                returndatacopy(0, 0, 0x20) 
                result := mload(0)        
            }
        }

        return result == EIP_1271_MAGIC_VALUE;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) 
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory tu = _tokenUri[tokenId];
        string memory ipfs = "ipfs://";
        require(bytes(tu).length > 0, "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(ipfs, tu));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {

        return
            ERC721.supportsInterface(type(IERC1155Receiver).interfaceId) ||
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setBridgeSigner(address signer, bool active) external onlyOwner{

        bridgeSigners[signer] = active;
    }

    function setPaused(bool pause) external onlyOwner{

        paused = pause;
    }

    function performErc721Recover(address collection, uint256 token_id) external onlyOwner {

        ERC721(collection).safeTransferFrom(address(this), _msgSender(), token_id);
    }

    function performErc20Recover(address token, uint256 amount) external onlyOwner {

        IERC20(token).transfer(_msgSender(), amount);
    }

    function performValueRecover(uint256 amount) external onlyOwner
    {
        
        (bool success,) = payable(_msgSender()).call{value: amount}("");
        require(success, "performValueRecover: could not recover");
    }

    function setDefaultRoyalty(address royaltyAddress, uint96 royaltyAmount) external onlyOwner {

        _setDefaultRoyalty(royaltyAddress, royaltyAmount);
    }

    function setInternallyAllowed(address requestor, bool allowed) external onlyOwner {

        internallyAllowed[requestor] = allowed;
    }

    function setOperatorFiltererAllowed(bool allowed) external onlyOwner {

        filterAllowed = allowed;
    }

    function isOperatorFiltererAllowed() view external returns(bool) {

        return filterAllowed;
    }

    function isInternallyAllowed(address requestor) view external returns(bool) {

        return internallyAllowed[requestor];
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721) onlyAllowedOperatorApproval(operator) {
        
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721) onlyAllowedOperatorApproval(operator) {

        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyAllowedOperator(from) {

        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyAllowedOperator(from) {

        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721)
        onlyAllowedOperator(from)
    {

        super.safeTransferFrom(from, to, tokenId, data);
    }

    function onERC721Received(address, address, uint256,bytes calldata) external pure returns (bytes4) {
        
        return IERC721Receiver.onERC721Received.selector;
    }
}