// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract MetaZeusMintpassv2 is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;
    error InvalidPrice();
    error ContractPaused();
    error MaxSupplyReached();
    error AllowSaleInactive();
    error PublicSaleInactive();
    error MaxPerWallet();
    error InvalidAmount();
    error NotAllowedToMint();
    // set to immutable in prod !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    bytes32 private merkleRootAllowList;
    // set to 0,077 ETH in prod !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    uint256 private constant mintPrice=100;

    uint256 private constant maxSupTotal=5555;
    uint256 private constant teamAllocation=333;
    string private constant uriPrefix = '';
    string private constant uriSuffix = '.json';

    string public hiddenMetadataUri;
    //struct for state vars is 2nd best next to bitmap
    struct States {
        bool paused;
        bool allowlistMintEnabled;
        bool publicSaleEnabled;
        bool revealed;
    }
    //initialize structs
    States public state;
    constructor(
        States memory state,
        string memory _hiddenMetadataUri,
        bytes32 _merkleRootAllowList
    ) ERC721A("MetaZeusMintpassv2", "MetaZeusMintpassv2") {
        setHiddenMetadataUri(_hiddenMetadataUri);
        setPaused(state.paused);
        setPublicSaleActive(state.publicSaleEnabled);
        setWhitelistMintEnabled(state.allowlistMintEnabled);
        setRevealed(state.revealed);
        batchMint(msg.sender,teamAllocation);
        merkleRootAllowList = _merkleRootAllowList;

    }
    // checks for allow and public phases
    modifier mintComplianceAllow(uint256 _mintAmount, bytes32[] calldata _merkleProof) {
        if(state.paused) revert ContractPaused();
        if(_totalMinted()+_mintAmount > maxSupTotal) revert MaxSupplyReached();
        if(!state.allowlistMintEnabled) revert AllowSaleInactive();
        //if ((_getAux(_msgSender())+_mintAmount)>2) revert NotAllowedToMint();
        if(_mintAmount <= 0 || _mintAmount > 2) revert InvalidAmount();
        if(msg.value<mintPrice * _mintAmount) revert InvalidPrice();
        //bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        //if(!MerkleProof.verifyCalldata(_merkleProof, merkleRootAllowList, leaf)) revert NotAllowedToMint();
        _;
    }
    modifier mintCompliancePublic(uint256 _mintAmount) {
        if(state.paused) revert ContractPaused();
        if(_totalMinted()+_mintAmount > maxSupTotal) revert MaxSupplyReached();
        if(!state.publicSaleEnabled) revert PublicSaleInactive();
        //if ((_getAux(_msgSender())+_mintAmount*10)>12) revert NotAllowedToMint();
        if(_mintAmount <= 0 || _mintAmount > 1) revert InvalidAmount();
        if(msg.value<mintPrice * _mintAmount) revert InvalidPrice();
        _;
    }
    /**                                 ----MINT FUNCTIONS---- */
    //ALLOWLIST
    function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintComplianceAllow(_mintAmount,_merkleProof)   {
        _setAux(_msgSender(),(_getAux(_msgSender())+uint64(_mintAmount)));
        _mint(_msgSender(), _mintAmount);
    }
    // PUBLIC MINT
    function pubMint(uint256 _mintAmount) public payable mintCompliancePublic(_mintAmount) {
        _setAux(_msgSender(),(_getAux(_msgSender())+uint64(_mintAmount*10)));
        _mint(_msgSender(), _mintAmount);
    }
    // Batch Mint
    function batchMint(address to, uint256 quantity) public payable onlyOwner {

        _mintERC2309(to,quantity);
    }
    //               ------ HELPERS AND OTHER FUNCTIONS ------

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (state.revealed == false) {
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
    }
    function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
        return uriPrefix;
    }
    //                      -----GETTERS-----
    //              All contract states can be read from these 2 methods
    function getStates() public view returns (States memory) {
        return state;
    }
    //                          -----SETTERS-----
    function setRevealed(bool _state) public onlyOwner {
        state.revealed = _state;
    }
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setPaused(bool _state) public onlyOwner {
        state.paused = _state;
    }
    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        state.allowlistMintEnabled = _state;
    }
    function setPublicSaleActive(bool _state) public onlyOwner {
        state.publicSaleEnabled = _state;
    }
    // DELETE THIS FUNCTION FOR PROD!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    function setMerkleRoot(bytes32 _wlhash) public onlyOwner {

        merkleRootAllowList=_wlhash;
    }
    //                          -----TRANSFERS FUNCTIONS-----
    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }
}