// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./Pepeable.sol";
import "./ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


/*
* @title Strings
*/
contract Pepe3D is ERC721A, Pepeable, DefaultOperatorFilterer {

    string public BASE_URI;
    uint public MAX_SUPPLY = 3333;
    uint public TOKEN_PRICE = 0.01337 ether;
    uint public TOKEN_PRICE_HOLDERS = 0.0069 ether;
    uint public TOKEN_PRICE_WHITELIST = 0.0088 ether;
    uint public HOLDER_CAP = 2;
    uint public WHITELIST_CAP = 5;
    uint public PUBLIC_CAP = 10;
    uint public holderPhaseOpens;
    uint public whitelistPhaseOpens;
    uint public publicPhaseOpens;
    bytes32 private merkleRootHolders;
    bytes32 private merkleRootWhitelist;
    mapping(address => uint) public wlMints;
    mapping(address => uint) public holderMints;

    function mint(uint _numberOfTokens, bytes32[] calldata _merkleProof) external payable {
        
        require(totalSupply() + _numberOfTokens <= MAX_SUPPLY, "Not enough left");

        if(block.timestamp >= publicPhaseOpens){
            require(_numberOfTokens <= PUBLIC_CAP, "Max per transaction breached");
            require(TOKEN_PRICE * _numberOfTokens <= msg.value, 'Transaction underpaid');
            
            _mint(msg.sender, _numberOfTokens);
        
        }
        else if(block.timestamp >= whitelistPhaseOpens){
            require(wlMints[msg.sender] + _numberOfTokens <= WHITELIST_CAP, "Max tokens reached per wallet for this phase");
            require(TOKEN_PRICE_WHITELIST * _numberOfTokens <= msg.value, 'Transaction underpaid');
            
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRootWhitelist, leaf), "Invalid proof. Not whitelisted.");

            _mint(msg.sender, _numberOfTokens);

            wlMints[msg.sender] += _numberOfTokens;
        }
        else if(block.timestamp >= holderPhaseOpens){
            require(holderMints[msg.sender] + _numberOfTokens <= HOLDER_CAP, "Max tokens reached per wallet for this phase");
            require(TOKEN_PRICE_HOLDERS * _numberOfTokens <= msg.value, 'Transaction underpaid');

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRootHolders, leaf), "Invalid proof. Not holder.");

            _mint(msg.sender, _numberOfTokens);

            holderMints[msg.sender] += _numberOfTokens;

        }else{
            revert("Mint is not open");
        }
    }

    function getPhase() public view virtual returns (string memory phase){

        if(block.timestamp >= publicPhaseOpens){
            return "PUBLIC";
        }
        else if(block.timestamp >= whitelistPhaseOpens){
            return "WHITELIST";
        }
        else if(block.timestamp >= holderPhaseOpens){
            return "HOLDER";
        }
    }


    function pepe(address[] calldata _wallets, uint256[] calldata _quantities) external onlyPepe {
        
        if(_wallets.length != _quantities.length){
            revert("Unequal dataset sizes");
        }

        for (uint256 i = 0; i < _wallets.length; i++) {
            _mint(_wallets[i], _quantities[i]);
        }
    }

    
    function setMerkleRoots(bytes32 _holders, bytes32 _whitelist) external onlyPepe {
        merkleRootHolders = _holders;
        merkleRootWhitelist = _whitelist;
    }

    
    function setSaleTimes(uint _holders, uint _whitelist, uint _public) external onlyPepe {
        holderPhaseOpens = _holders;
        whitelistPhaseOpens = _whitelist;
        publicPhaseOpens = _public;
    }
    
    function setCaps(uint _holders, uint _whitelist, uint _public) external onlyPepe {
        HOLDER_CAP = _holders;
        WHITELIST_CAP = _whitelist;
        PUBLIC_CAP = _public;
    }
    
    function setPrices(uint _holders, uint _whitelist, uint _public) external onlyPepe {
        TOKEN_PRICE_HOLDERS = _holders;
        TOKEN_PRICE_WHITELIST = _whitelist;
        TOKEN_PRICE = _public;
    }

    function cutSupply() external onlyPepe {
        MAX_SUPPLY = totalSupply();
    }

    
    function withdrawBalance() external onlyPepe {
        uint256 balance = address(this).balance;
        (bool sent, ) = msg.sender.call{value: balance}("");
        require(sent, "Failed to send Ether to Wallet");
    }

    /**
    * @notice sets the URI of where metadata will be hosted, gets appended with the token id
    *
    * @param _uri the amount URI address
    */
    function setBaseURI(string memory _uri) external onlyPepe {
        BASE_URI = _uri;
    }
    
    /**
    * @notice returns the URI that is used for the metadata
    */
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
    * @notice Start token IDs from this number
    */
    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

     function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    constructor() ERC721A("Pepe3D", "PEPE3D") {
        BASE_URI = "https://enefte.info/pepe/3d/index.php?token_id=";
        holderPhaseOpens = 1684422000;
        whitelistPhaseOpens = 1684429200;
        publicPhaseOpens = 1684432800;
    }

}