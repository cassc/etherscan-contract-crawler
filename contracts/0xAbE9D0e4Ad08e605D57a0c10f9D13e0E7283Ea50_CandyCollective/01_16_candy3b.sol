// SPDX-License-Identifier: UNLICENSED

/// ============ Imports ============
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract CandyCollective is ERC721AUpgradeable, Ownable, DefaultOperatorFilterer {

    mapping(address => uint256[4]) public amountMinted;
    mapping (uint256 => string) private _tokenURIs;
    uint[] public MAX_PER_WALLET = [1,2,3,1];
    uint256 public MAX_SUPPLY;
    uint256 public PRICE;
    string public BASE_URI;
    string public _name;
    string public _symbol;
    uint[] public _startTimes;
    uint[] public _endTimes;
    bytes32[] _roots;
    address public fundsRecipient;
    event Minted(address sender, uint256 tokenId);
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor (
        uint256 maxSupply_,
        uint256 price_,
        bytes32[] memory roots_, 
        string memory baseUri,
        string memory name_,
        string memory symbol_,
        uint[] memory startTimes_,
        uint[] memory endTimes_,
        address payable _fundsRecipient
    ) {
        PRICE = price_;
        MAX_SUPPLY = maxSupply_;
        BASE_URI = baseUri;
        _name = name_;
        _symbol = symbol_;
        _startTimes = startTimes_;
        _endTimes = endTimes_;
        _roots = roots_;
        _tokenIdCounter.increment();
        fundsRecipient = _fundsRecipient;
    }
    
    function mint(address to, bytes32[] calldata _merkleProof, uint256 phase, uint256 quantity) public payable {
        if(phase != 3){
            require(msg.value >= PRICE*quantity, "Not enough ether sent.");
        }
        require(block.timestamp >= _startTimes[phase] && block.timestamp <= _endTimes[phase], "Minting not allowed outside of start and end time");
        require(amountMinted[msg.sender][phase] <= MAX_PER_WALLET[phase]-quantity, "Hit max per wallet.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Hit max supply.");
        
        if(_roots[phase] != 0x0000000000000000000000000000000000000000000000000000000000000000){
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, _roots[phase], leaf),"Invalid Merkle Proof.");
        }
        for (uint i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(to, 1);
            _setTokenURI(tokenId-1);
            _tokenIdCounter.increment();
            uint256 currentMinted = amountMinted[msg.sender][phase];
            currentMinted += 1;
            amountMinted[msg.sender][phase] = currentMinted;   
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

    function _setTokenURI(uint256 tokenId) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        string memory _tokenURI = string.concat(BASE_URI, Strings.toString(tokenId+1));
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        BASE_URI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setFundsRecipient(address payable newFundsRecipient) public onlyOwner {
        fundsRecipient = newFundsRecipient;
    }

    function setRoots(bytes32[] memory newRoots) public onlyOwner {
        _roots = newRoots;
    }

    function setStartTimes(uint[] memory startTimes_) public onlyOwner {
        _startTimes = startTimes_;
    }

    function setEndTimes(uint[] memory endTimes_) public onlyOwner {
        _endTimes = endTimes_;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(fundsRecipient).call{value: address(this).balance}("");
        require(success, "Could not withdraw");
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721AUpgradeable) onlyAllowedOperator(from) { }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable) payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable) payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721AUpgradeable)
        payable
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable)
        returns (bool)
    {
        return
        super.supportsInterface(interfaceId);
    }

}