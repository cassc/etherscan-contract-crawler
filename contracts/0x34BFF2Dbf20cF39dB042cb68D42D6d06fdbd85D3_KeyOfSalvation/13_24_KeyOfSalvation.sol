// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// import '../nft-base/NFTExtendedA.sol';

import '../nft-base/ERC721AExtended.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @dev Key of Salvation (aka Genesis Pass) contract.
 */
contract KeyOfSalvation is ERC721AExtended, AccessControl, ERC2981, DefaultOperatorFilterer {
    using Strings for uint256;

    /**
     * @dev modifiers for error checking
     */
    // checks if current supply + _amount is greater than max supply
    modifier isBelowMaxSupply(uint256 _amount) {
        require(totalSupply() + _amount <= maxSupply, 'KOS1');
        _;
    }

     // checks if the address is whitelisted for guaranteed.
    modifier whitelistedForGuaranteed(bytes32[] calldata _proof) {
        require(_isWhitelisted(1, _msgSender(), _proof), 'KOS2');
        _;
    }

    // checks if the address is whitelisted for overallocated.
    modifier whitelistedForOverallocated(bytes32[] calldata _proof) {
        require(_isWhitelisted(2, _msgSender(), _proof), 'KOS3');
        _;
    }

    // checks if the address has not minted.
    modifier hasNotMinted() {
        require(_getAux(_msgSender()) == 0, 'KOS4');
        _;
    }

    // checks if guaranteed mint is on
    modifier isGuaranteedMint() {
        require(block.timestamp >= guaranteedMintTimestamp, 'KOS5');
        _;
    }

    // checks if overallocated mint is on
    modifier isOverallocatedMint() {
        require(block.timestamp >= overallocatedMintTimestamp, 'KOS6');
        _;
    }

    // checks if mint is not over
    modifier isNotEndOfMint() {
        require(block.timestamp < endMintTimestamp, 'KOS7');
        _;
    }

    // only owner modifier
    modifier onlyOwner() {
        require(_msgSender() == _owner, 'KOS8');
        _;
    }

    // checks if _to is to an address that is not zero.
    modifier transferToNonZeroAddress(address _to) {
        require(_to != address(0), 'KOS9');
        _;
    }

    // checks if the merkle type is valid
    modifier isValidMerkleType(uint8 _type) {
        require(_type == 1 || _type == 2, 'KOS10');
        _;
    }

    // ensures that _tokenId exists
    modifier uriQueryExists(uint256 _tokenId) {
        require(_exists(_tokenId), 'KOS11');
        _;
    }

        // ensures that reveal stage is valid
    modifier validRevealStage(uint8 _type) {
        require(_type == 1 || _type == 2 || _type == 3, 'KOS12');
        _;
    }

    /**
     * @dev Key variables for the Key.
     */
    // max supply of the key
    uint16 public maxSupply = 5000;
    // max supply a dev can mint
    uint16 public devMintLimit = 500;
    // // check if an address has already minted (guaranteed or overallocated)
    // mapping (address => uint256) public whitelistMinted;
    // guaranteed mint timestamp
    uint256 public guaranteedMintTimestamp;
    // overallocated mint timestamp
    uint256 public overallocatedMintTimestamp;
    // timestamp for when mint ends
    uint256 public endMintTimestamp;

    // owner of the contract
    address private _owner;

    // starts at STAGE_1.
    RevealStage public revealStage;
    // reveal stages
    enum RevealStage {
        // not revealed
        STAGE_1,
        // revealed the second stage
        STAGE_2,
        // revealed the final stage
        STAGE_3
    }

    constructor() ERC721A('Key Of Salvation', 'KOS') {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // sets the default royalty to 10%
        _setDefaultRoyalty(_msgSender(), 1000);
        revealStage = RevealStage.STAGE_1;
        // 7 April 2023 09:00 EST
        guaranteedMintTimestamp = 1680872400;
        // 7 April 2023 18:30 EST
        overallocatedMintTimestamp = 1680906600;
        // 7 April 2023 23:59 EST
        endMintTimestamp = 1680926340;
        // sets the owner to the deployer
        _owner = _msgSender();
    }

    // gets the owner of the contract.
    function owner() public view returns (address) {
        return _owner;
    }

    // changes the owner of the contract. only callable by the current owner.
    function changeOwner(address _newOwner) external onlyOwner() transferToNonZeroAddress(_newOwner) {
        _owner = _newOwner;
    }

    // changes the max supply of the contract.
    function changeMaxSupply(uint16 _maxSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = _maxSupply;
    }

    // changes the dev mint limit of the contract.
    function changeDevMintLimit(uint16 _devMintLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        devMintLimit = _devMintLimit;
    }

    // changes the guaranteed mint timestamp.
    function changeGuaranteedMintTimestamp(uint256 _timestamp) external onlyRole(DEFAULT_ADMIN_ROLE) {
        guaranteedMintTimestamp = _timestamp;
    }

    // changes the overallocated mint timestamp.
    function changeOverallocatedMintTimestamp(uint256 _timestamp) external onlyRole(DEFAULT_ADMIN_ROLE) {
        overallocatedMintTimestamp = _timestamp;
    }

    // changes the end mint timestamp.
    function changeEndMintTimestamp(uint256 _timestamp) external onlyRole(DEFAULT_ADMIN_ROLE) {
        endMintTimestamp = _timestamp;
    }

    // changes start token from 0 to 1.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // sets the reveal stage of the key.
    function setRevealStage(RevealStage _stage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revealStage = _stage;
    }

    // mints a key to a guaranteed WL holder.
    function guaranteedMint(bytes32[] calldata _proof) external whitelistedForGuaranteed(_proof) hasNotMinted() isGuaranteedMint() isNotEndOfMint() {
        // sets the whitelist minted to 1
        _setAux(_msgSender(), 1);
        // mints the key
        _safeMint(_msgSender(), 1);
    }

    // mints a key to an overallocated WL holder or a guaranteed WL holder if the guaranteed mint is over and they didn't get a chance to mint.
    function overallocatedMint(bytes32[] calldata _proof) external whitelistedForOverallocated(_proof) hasNotMinted() isOverallocatedMint() isNotEndOfMint() {
        // sets the whitelist minted to 1
        _setAux(_msgSender(), 1);
        // mints the key
        _safeMint(_msgSender(), 1);
    }

    // mints _amount of keys to the dev (i.e. DEFAULT_ADMIN_ROLE).
    function devMint(uint16 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _safeMint(_msgSender(), _amount);
    }

    function _safeMint(address _to, uint256 _amount) internal virtual override isBelowMaxSupply(_amount) {
        ERC721A._safeMint(_to, _amount);
    }

    /// root hashes of the merkle tree. used for whitelisting
    // merkle root for guaranteed whitelist
    bytes32 public guaranteedMerkleRoot;
    // merkle root for overallocated whitelist
    bytes32 public overallocatedMerkleRoot;

    // sets the root of the tree
    function setMerkleRoot(uint8 _type, bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) isValidMerkleType(_type) {
        if (_type == 1) {
            guaranteedMerkleRoot = _merkleRoot;
        } else if (_type == 2) {
            overallocatedMerkleRoot = _merkleRoot;
        }
    }

    // checks if an address is whitelisted for either guaranteed or overallocated
    function _isWhitelisted(uint8 _type, address _addr, bytes32[] calldata _proof) internal view returns (bool) {
        return _verify(_type, _getLeaf(_addr), _proof);
    }

    // gets the leaf (i.e. the hashed output of the address)
    function _getLeaf(address _addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addr));
    }

    // verifies the provided _proof to check if they are guaranteed/overallocated/not whitelisted.
    function _verify(uint8 _type, bytes32 _leaf, bytes32[] memory _proof) internal view isValidMerkleType(_type) returns (bool) {
        if (_type == 1) {
            return MerkleProof.verify(_proof, guaranteedMerkleRoot, _leaf);
        }
        
        // assumes type is 2, otherwise `isValidMerkleType` reverts it automatically.
        return MerkleProof.verify(_proof, overallocatedMerkleRoot, _leaf);
    }

    /// TOKEN URI FUNCTIONS
    string private _contractURI;
    string private _stage1RevealURI;
    string private _stage2RevealURI;
    string private _stage3RevealURI;

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) uriQueryExists(_tokenId) returns (string memory) {
        string memory baseURI_ = _baseURI();

        if (revealStage == RevealStage.STAGE_1) {
            return baseURI_;
        } else {
            return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, _tokenId.toString(), '.json')) : '';
        }
    }

    function _baseURI() internal view override returns (string memory) {
        if (revealStage == RevealStage.STAGE_1) {
            return _stage1RevealURI;
        } else if (revealStage == RevealStage.STAGE_2) {
            return _stage2RevealURI;
        } else {
            return _stage3RevealURI;
        }
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(uint8 _type, string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) validRevealStage(_type) {
        if (_type == 1) {
            _stage1RevealURI = _uri;
        } else if (_type == 2) {
            _stage2RevealURI = _uri;
        } else if (_type == 3) {
            _stage3RevealURI = _uri;
        }
    }

    // contract URI for opensea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string calldata contractURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractURI = contractURI_;
    }
    /// End of TOKEN URI FUNCTIONS

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setApprovalForAll(address _operator, bool _approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(_operator) {
        super.setApprovalForAll(_operator, _approved);
    }

    function approve(address _operator, uint256 _tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(_operator) {
        super.approve(_operator, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(_from) {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

     /********* WITHDRAWALS*************** */
    /// withdraws balance from this contract to admin.
    /// Note: Please do NOT send unnecessary funds to this contract.
    /// This is used as a mechanism to transfer any balance that this contract has to admin.
    /// we will NOT be responsible for any funds transferred accidentally.
    function withdrawFunds() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(_msgSender()).transfer(address(this).balance);
    }

    /// withdraws tokens from this contract to admin.
    /// Note: Please do NOT send unnecessary tokens to this contract.
    /// This is used as a mechanism to transfer any tokens that this contract has to admin.
    /// we will NOT be responsible for any tokens transferred accidentally.
    function withdrawTokens(address _tokenAddr, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 _token = IERC20(_tokenAddr);
        _token.transfer(_msgSender(), _amount);
    }
    /**************************************** */

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, AccessControl, ERC2981) returns (bool) {
        return 
            interfaceId == type(IAccessControl).interfaceId ||
            ERC721A.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}