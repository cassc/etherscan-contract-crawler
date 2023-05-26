// SPDX-License-Identifier: MIT

/*    ____     __  __   ____     ______   ____                 
    /\  _`\  /\ \/\ \ /\  _`\  /\__  _\ /\  _`\    /'\_/`\    
    \ \ \/\_\\ \ \ \ \\ \ \L\ \\/_/\ \/ \ \,\L\_\ /\      \   
     \ \ \/_/_\ \ \ \ \\ \  _ <'  \ \ \  \/_\__ \ \ \ \__\ \  
      \ \ \L\ \\ \ \_\ \\ \ \L\ \  \_\ \__ /\ \L\ \\ \ \_/\ \ 
       \ \____/ \ \_____\\ \____/  /\_____\\ `\____\\ \_\\ \_\
        \/___/   \/_____/ \/___/   \/_____/ \/_____/ \/_/ \/_/
*/

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol"; 
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "contracts/OperatorFilterer.sol";

contract Cubism is ERC721, ERC2981, OperatorFilterer, Ownable {

    using Counters for Counters.Counter;
    using Strings for uint256;

    error SaleStateClosedError();
    error InsufficientMints();
    error IncorrectPayableAmount();
    error ExceedsMaxSupply();
    error IncorrectProof();

    string public ProvenanceHash;
    string public baseURI;
    string private _contractURI;
    uint64 constant maxSupply = 100; 
    uint64 constant price = 0.1 ether;
    bool public operatorFilteringEnabled;
    bytes32 public merkleRoot;
    address public beneficiary;

    Counters.Counter private _tokenIdCounter;

    mapping(address => bool) private _alreadyMinted;   

    enum SaleState {
        Closed,
        CubeList,
        Public
    }

    SaleState public saleState = SaleState.Closed;

    constructor(
        address payable royalityReceiver, 
        string memory _initialBaseURI,
        string memory _initialContractURI,
        address _beneficiary
    )   ERC721("Cubism", "CUBE") 
    {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        beneficiary = _beneficiary;
        baseURI = _initialBaseURI;
        _contractURI = _initialContractURI;
        _setDefaultRoyalty( royalityReceiver, 500);
    }

    function setRoyaltyInfo(address payable _royalityReceiver, uint96 _royaltiesBIPs) public onlyOwner {
        _setDefaultRoyalty(_royalityReceiver, _royaltiesBIPs);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setProvenanceHash(string calldata hash) external onlyOwner {
        ProvenanceHash = hash;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }
    
    function setSaleState(SaleState _saleState) external onlyOwner {
        saleState = _saleState;
    }

    function _internalMint(address sender) internal {
        _tokenIdCounter.increment();
        _mint(sender, _tokenIdCounter.current());
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function alreadyMinted(address addr) public view returns (bool) {
        return _alreadyMinted[addr];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    modifier verifySaleState(SaleState requiredState) {
        if (saleState != requiredState) revert SaleStateClosedError();
        _;
    }

    modifier verifyAmount() {
        if (msg.value != price) revert IncorrectPayableAmount();
        _;
    }

    modifier verifyAvailableSupply(uint256 amount) {
        if (_tokenIdCounter.current() + amount > maxSupply) revert ExceedsMaxSupply();
        _;
    }

    modifier verifyAlreadyMinted() {
        if (_alreadyMinted[_msgSender()] == true) revert InsufficientMints();
        _;
    }

//CubeMint
    function cubeMint(bytes32[] calldata merkleProof) 
        external 
        payable 
        verifySaleState(SaleState.CubeList) 
        verifyAvailableSupply(1) 
        verifyAlreadyMinted() 
        verifyAmount() 
    {
        address sender = _msgSender();
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        if (!MerkleProof.verify(merkleProof, merkleRoot, leaf)) revert IncorrectProof();
        _alreadyMinted[sender] = true;
        _internalMint(sender);
    }

//OwnerMint
    function ownerMint(uint256 amount) 
        external 
        onlyOwner 
        verifyAvailableSupply(amount) 
    {
        for (uint256 i = 0; i < amount; i++) 
        {
            address sender = _msgSender();
            _internalMint(sender);
        }
    }

//PublicMint
    function mintPublic() 
        external 
        payable 
        verifySaleState(SaleState.Public) 
        verifyAvailableSupply(1) 
        verifyAlreadyMinted() 
        verifyAmount() 
    {
        address sender = _msgSender();
        _alreadyMinted[sender] = true;
        _internalMint(sender);
    }

    function withdraw(address payable destination) 
        external 
        onlyOwner 
    {
        destination.transfer(address(this).balance);
    }

// OperatorFilterer

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721, ERC2981)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}