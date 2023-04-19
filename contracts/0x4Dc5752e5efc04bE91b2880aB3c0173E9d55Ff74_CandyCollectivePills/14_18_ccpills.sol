// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CandyCollectivePills is ERC721, Ownable, DefaultOperatorFilterer {
    mapping(address => uint256) public amountMintedWL;
    mapping(address => uint256) public amountMinted;
    mapping(uint256 => uint256) private _tokenVersions;

    uint256 public _price;
    string public BASE_URI;
    string public _name;
    string public _symbol;
    uint[] public _times;
    bytes32[] _roots;
    uint256[] _maxPerWalletWL;
    uint256 _maxPerWallet;
    address public _fundsRecipient;
    event Minted(address sender, uint256 tokenId);
    bool private _mintingClosed = false;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor (
        uint256 price_,
        bytes32[] memory roots_, 
        uint256[] memory maxPerWalletWL_,
        uint256 maxPerWallet_,
        string memory baseUri,
        string memory name_,
        string memory symbol_,
        uint[] memory times_,
        address payable fundsRecipient_
    ) ERC721(name_, symbol_) {
        _price = price_;
        BASE_URI = baseUri;
        _name = name_;
        _symbol = symbol_;
        _times = times_;
        _roots = roots_;
        _maxPerWalletWL = maxPerWalletWL_;
        _maxPerWallet = maxPerWallet_;
        _fundsRecipient = fundsRecipient_;
        _tokenIdCounter.increment();
    }
    
    function mint(address to, uint256 version, uint256 quantity) public payable {
        require(msg.value >= _price * quantity, "Not enough ether sent.");
        require(block.timestamp >= _times[0] && block.timestamp <= _times[1], "Minting not allowed outside of start and end time");
        require(!_mintingClosed, "Minting has been closed forever.");
        require(version >= 1 && version <= 9, "Version should be between 1 and 9");
        require(amountMinted[msg.sender]+quantity <= _maxPerWallet, "You have already minted the maximum number of tokens");

        for (uint i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _mint(to, tokenId);
            _setTokenVersion(tokenId, version);
            _tokenIdCounter.increment();
            uint256 currentMinted = amountMinted[msg.sender];
            currentMinted += 1;
            amountMinted[msg.sender] = currentMinted;
        }
    }


    function mintWL(address to, uint256 version, bytes32[] calldata _merkleProof, uint256 tier, uint256 quantity) public payable {
        require(block.timestamp >= _times[0] && block.timestamp <= _times[1], "Minting not allowed outside of start and end time");
        require(amountMintedWL[msg.sender]+quantity <= _maxPerWalletWL[tier], "You have already minted the maximum number of tokens");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, _roots[tier], leaf),"Invalid Merkle Proof.");
        require(!_mintingClosed, "Minting has been closed forever.");
        require(version >= 1 && version <= 9, "Version should be between 1 and 9");

        for (uint i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _mint(to, tokenId);
            _setTokenVersion(tokenId, version);
            _tokenIdCounter.increment();
            uint256 currentMinted = amountMintedWL[msg.sender];
            currentMinted += 1;
            amountMintedWL[msg.sender] = currentMinted;
        }     
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function contractURI()
        public
        view
        virtual
        returns (string memory)
    {
        return string.concat(BASE_URI,"metadata.json");
    }

    function getAmountMintedWL(address account) public view returns (uint256) {
        return amountMintedWL[account];
    }

    function getMaxPerWalletWL(uint256 tier) public view returns (uint256) {
        return _maxPerWalletWL[tier];
    }

    function getAmountMinted(address account) public view returns (uint256) {
        return amountMinted[account];
    }

    function getMaxPerWallet() public view returns (uint256) {
        return _maxPerWallet;
    }


    function _setTokenVersion(uint256 tokenId, uint256 version) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: Version set of nonexistent token");
        _tokenVersions[tokenId] = version;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 version = _tokenVersions[tokenId];
        string memory _tokenURI = string.concat(BASE_URI, Strings.toString(version), ".json");
        return _tokenURI;
    }

    function totalSupply() public view returns (uint256) {
        uint256 supply = _tokenIdCounter.current() - 1;
        return supply;
    }

    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        _burn(tokenId);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        BASE_URI = uri;
    }

    function setFundsRecipient(address payable newFundsRecipient) public onlyOwner {
        _fundsRecipient = newFundsRecipient;
    }

    function setRoots(bytes32[] memory newRoots) public onlyOwner {
        _roots = newRoots;
    }

    function setmaxPerWalletWL(uint256[] memory newMax) public onlyOwner {
        _maxPerWalletWL = newMax;
    }


    function setTimes(uint[] memory times_) public onlyOwner {
        _times = times_;
    }

    function closeMinting() external onlyOwner {
        _mintingClosed = true;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(_fundsRecipient).call{value: address(this).balance}("");
        require(success, "Could not withdraw");
    }


    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual onlyAllowedOperator(from) { }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return
        super.supportsInterface(interfaceId);
    }

}