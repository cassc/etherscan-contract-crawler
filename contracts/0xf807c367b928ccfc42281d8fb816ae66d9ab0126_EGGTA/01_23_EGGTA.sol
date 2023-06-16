// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Auth.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract EGGTA is
    DefaultOperatorFilterer,
    Context,
    Auth,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;
    using MerkleProof for bytes32[];
    // Events
    event mintedEvent(address indexed to, uint tokenId, string uri);
    // bool public revealed = true;
    bool public onlyWhitelisted = false;
    string public contractURILocation = "";
    // string public notRevealedUri;
    string private _baseTokenURI;
    uint256 public mintFee = 0.25 ether;
    uint256 public developerRate = 45;
    uint256 public lotteryRate = 55;
    uint256 public maxSupply = 300;
    address public developer = 0x026D0c6aAed9859f500b441F44C8E3cE35Dc3353;
    bytes32 private _merkleRoot;
    mapping(uint256 => string) private _tokenURIs;
    Counters.Counter private _tokenIdTracker;

    constructor() ERC721("EGGTA", "EGTA") Auth(msg.sender) {
        _baseTokenURI = "";
        // setNotRevealedURI("QmaxBLFX4fKtG3wUyxGC1U5abBPUww5z1GH55yzHy5bMfv");
    }
    // make this contract globally payable
    receive() external payable {}
    fallback() external payable {}
    // Public or external functions
    function mint(string memory uri, bytes32[] memory proof) external virtual payable{
        if(!isAuthorized(msg.sender) || !isOwner(msg.sender)){
            if(onlyWhitelisted == true) {
                require(_merkleRoot != "", "merkleRoot not set");
                require(proof.verify(_merkleRoot, keccak256(abi.encodePacked(msg.sender))),"user is not whitelisted");
            }
            uint256 supply = totalSupply();
            require(supply.add(1) <= maxSupply, "NFT supply exceeded");
            require(msg.value >= mintFee, "mint fee is not enough");
        }
        uint currentId = _tokenIdTracker.current();
        _mint(msg.sender, currentId);
        _tokenIdTracker.increment();
        _setTokenURI(currentId, uri);
        emit mintedEvent(msg.sender, currentId, uri);
    }

    function mintTo(string memory uri, address receiver) external virtual payable{
        if(!isAuthorized(msg.sender) || !isOwner(msg.sender)){

            uint256 supply = totalSupply();
            require(supply.add(1) <= maxSupply, "NFT supply exceeded");
            require(msg.value >= mintFee, "mint fee is not enough");
        }
        uint currentId = _tokenIdTracker.current();
        _mint(receiver, currentId);
        _tokenIdTracker.increment();
        _setTokenURI(currentId, uri);
        emit mintedEvent(receiver, currentId, uri);
    }

    function contractURI() public view returns (string memory) {
        return contractURILocation;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        // if(revealed == false) {
        //     return notRevealedUri;
        // }
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return super.tokenURI(tokenId);
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setDeveloperRate(uint256 value) external onlyOwner{
        uint256 base = 100;
        developerRate = value;
        lotteryRate = base.sub(value);
    }

    // function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner{
    //     notRevealedUri = _notRevealedURI;
    // }

    function setContractURILocation(string memory uri) external onlyOwner{
        contractURILocation = uri;
    }

    function setDeveloper(address developerAddress) external onlyOwner{
        developer = developerAddress;
    }

    function setMintFee(uint256 value) external onlyOwner{
        mintFee = value;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner{
        onlyWhitelisted = _state;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        _merkleRoot = root;
    }

    // function toggleReveal() external virtual onlyOwner {
    //     revealed = !revealed;
    // }

    function pause() external virtual onlyOwner{
        _pause();
    }

    function unpause() external virtual onlyOwner{
        _unpause();
    }

    function withdraw() external onlyOwner{
        (bool sent, ) = developer.call{value: address(this).balance}("");
        require(sent, "failed to pay developer");
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Internal functions
    function _baseURI() internal view virtual override returns (string memory){
        return _baseTokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual{
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    // function _pay(uint256 value) internal{
    //     uint256 base = 100;
    //     uint256 paymentValue = value.mul(developerRate).div(base);
    //     (bool sent, ) = developer.call{value: paymentValue}("");
    //     require(sent, "failed to pay developer");
    // }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable){
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}