/**
 *Submitted for verification at Etherscan.io on 2023-04-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @title ROARS
 * @author 0xSumo
 */

abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) { return ERC721TokenReceiver.onERC721Received.selector; }
}

abstract contract ERC721 {
    
    event Transfer(address indexed from_, address indexed to_, uint256 indexed tokenId_);
    event Approval(address indexed owner_, address indexed spender_, uint256 indexed id_);
    event ApprovalForAll(address indexed owner_, address indexed operator_, bool approved_);

    string public name; 
    string public symbol;
    string public baseTokenURI;
    string public baseTokenURI_EXT;

    uint256 public nextTokenId;
    uint256 public totalBurned;
    uint256 public constant maxBatchSize = 100;
    
    function startTokenId() public pure virtual returns (uint256) {
        return 0;
    }

    function totalSupply() public view virtual returns (uint256) {
        return nextTokenId - totalBurned - startTokenId();
    }

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        nextTokenId = startTokenId();
    }

    struct TokenData {
        address owner;
        uint40 lastTransfer;
        bool burned;
        bool nextInitialized;
    }
    struct BalanceData {
        uint32 balance;
        uint32 mintedAmount;
    }

    mapping(uint256 => TokenData) public _tokenData;
    mapping(address => BalanceData) public _balanceData;

    mapping(address => bool) public operatorList;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function _getTokenDataOf(uint256 tokenId_) public view virtual returns (TokenData memory) {
        uint256 _lookupId = tokenId_;
        require(_lookupId >= startTokenId(), "_getTokenDataOf _lookupId < startTokenId");
        TokenData memory _TokenData = _tokenData[_lookupId];
        if (_TokenData.owner != address(0) && !_TokenData.burned) return _TokenData;
        require(!_TokenData.burned, "_getTokenDataOf burned token!");
        require(_lookupId < nextTokenId, "_getTokenDataOf _lookupId > _nextTokenId");
        unchecked { while(_tokenData[--_lookupId].owner == address(0)) {} }
        return _tokenData[_lookupId];
    }

    function balanceOf(address owner_) public virtual view returns (uint256) {
        require(owner_ != address(0), "balanceOf to 0x0");
        return _balanceData[owner_].balance;
    }

    function ownerOf(uint256 tokenId_) public view returns (address) {
        return _getTokenDataOf(tokenId_).owner;
    }

    function _mintInternal(address to_, uint256 amount_) internal virtual { unchecked {
        require(to_ != address(0), "_mint to 0x0");
        uint256 _startId = nextTokenId;
        uint256 _endId = _startId + amount_;
        _tokenData[_startId].owner = to_;
        _tokenData[_startId].lastTransfer = uint40(block.timestamp);
        _balanceData[to_].balance += uint32(amount_);
        _balanceData[to_].mintedAmount += uint32(amount_);
        do { emit Transfer(address(0), to_, _startId); } while (++_startId < _endId);
        nextTokenId = _endId;
    }}

    function _mint(address to_, uint256 amount_) internal virtual {
        uint256 _amountToMint = amount_;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintInternal(to_, maxBatchSize);
        }
        _mintInternal(to_, _amountToMint);
    }

    function _burn(uint256 tokenId_, bool checkApproved_) internal virtual { unchecked {
        TokenData memory _TokenData = _getTokenDataOf(tokenId_);
        address _owner = _TokenData.owner;
        if (checkApproved_) require(_isApprovedOrOwner(_owner, msg.sender, tokenId_), "_burn not approved");
        delete getApproved[tokenId_];
        _tokenData[tokenId_].owner = _owner;
        _tokenData[tokenId_].lastTransfer = uint40(block.timestamp);
        _tokenData[tokenId_].burned = true;
        _tokenData[tokenId_].nextInitialized = true;

        if (!_TokenData.nextInitialized) {
            uint256 _tokenIdIncremented = tokenId_ + 1;
            if (_tokenData[_tokenIdIncremented].owner == address(0)) {
                if (tokenId_ < nextTokenId - 1) {
                    _tokenData[_tokenIdIncremented] = _TokenData;
                }
            }
        }
        
        _balanceData[_owner].balance--;
        emit Transfer(_owner, address(0), tokenId_);
        totalBurned++;
    }}

    function _transfer(address from_, address to_, uint256 tokenId_, bool checkApproved_) internal virtual { unchecked {
        require(to_ != address(0), "_transfer to 0x0");
        TokenData memory _TokenData = _getTokenDataOf(tokenId_);
        address _owner = _TokenData.owner;
        require(from_ == _owner, "_transfer not from owner");
        if (checkApproved_) require(_isApprovedOrOwner(_owner, msg.sender, tokenId_), "_transfer not approved");
        delete getApproved[tokenId_];
        _tokenData[tokenId_].owner = to_;
        _tokenData[tokenId_].lastTransfer = uint40(block.timestamp);
        _tokenData[tokenId_].nextInitialized = true;
        
        if (!_TokenData.nextInitialized) {
            uint256 _tokenIdIncremented = tokenId_ + 1;
            if (_tokenData[_tokenIdIncremented].owner == address(0)) {
                if (tokenId_ < nextTokenId - 1) {
                    _tokenData[_tokenIdIncremented] = _TokenData;
                }
            }
        }

        _balanceData[from_].balance--;
        _balanceData[to_].balance++;
        emit Transfer(from_, to_, tokenId_);
    }}

    function _setOperatorlist(address operator, bool status) internal virtual {
        operatorList[operator] = status;
    }

    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        _transfer(from_, to_, tokenId_, true);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        require(to_.code.length == 0 || ERC721TokenReceiver(to_).onERC721Received(msg.sender, from_, tokenId_, data_) ==
        ERC721TokenReceiver.onERC721Received.selector, "safeTransferFrom to unsafe address");
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function approve(address spender_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(operatorList[spender_], "operator is not on the list");
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender], "approve not authorized!");
        getApproved[tokenId_] = spender_;
        emit Approval(_owner, spender_, tokenId_);
    }

    function setApprovalForAll(address operator_, bool approved_) public virtual {
        require(operatorList[operator_], "operator is not on the list");
        isApprovedForAll[msg.sender][operator_] = approved_;
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }

    function _isApprovedOrOwner(address owner_, address spender_, uint256 tokenId_) internal virtual view returns (bool) {
        return (owner_ == spender_ || getApproved[tokenId_] == spender_ || isApprovedForAll[owner_][spender_]);
    }

    function supportsInterface(bytes4 id_) public virtual view returns (bool) {
        return  id_ == 0x01ffc9a7 || id_ == 0x80ac58cd || id_ == 0x5b5e139f;
    }

    function _setBaseTokenURI(string memory uri_) internal virtual { 
        baseTokenURI = uri_; 
    }

    function _setBaseTokenURIEXT(string memory uri_) internal virtual { 
        baseTokenURI_EXT = uri_; 
    }

    function _toString(uint256 value_) internal pure virtual returns (string memory _str) {
        assembly {
            let m := add(mload(0x40), 0xa0)
            mstore(0x40, m)
            _str := sub(m, 0x20)
            mstore(_str, 0)
            let end := _str
            for { let temp := value_ } 1 {} {
                _str := sub(_str, 1)
                mstore8(_str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            let length := sub(end, _str)
            _str := sub(_str, 0x20)
            mstore(_str, length)
        }
    }

    function _getURI(uint256 tokenId_) internal virtual view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, _toString(tokenId_), baseTokenURI_EXT));
    }

    function tokenURI(uint256 tokenId_) public virtual view returns (string memory);
}

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);
    IOperatorFilterRegistry constant operatorFilterRegistry = IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }
    modifier onlyAllowedOperator(address from) virtual {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (from == msg.sender) { _; return ; }
            if (!(operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender) && operatorFilterRegistry.isOperatorAllowed(address(this), from))) {
                revert OperatorNotAllowed(msg.sender);
        }}_;
    }
}

abstract contract OwnControll {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminSet(bytes32 indexed controllerType, bytes32 indexed controllerSlot, address indexed controller, bool status);
    address public owner;
    mapping(bytes32 => mapping(address => bool)) internal admin;
    constructor() { owner = msg.sender; }
    modifier onlyOwner() { require(owner == msg.sender, "only owner");_; }
    modifier onlyAdmin(string memory type_) { require(isAdmin(type_, msg.sender), "only admin");_; }
    function transferOwnership(address newOwner) external onlyOwner { emit OwnershipTransferred(owner, newOwner); owner = newOwner; }
    function setAdmin(string calldata type_, address controller, bool status) external onlyOwner { bytes32 typeHash = keccak256(abi.encodePacked(type_)); admin[typeHash][controller] = status; emit AdminSet(typeHash, typeHash, controller, status); }
    function isAdmin(string memory type_, address controller) public view returns (bool) { bytes32 typeHash = keccak256(abi.encodePacked(type_)); return admin[typeHash][controller]; }
}

abstract contract MerkleProof {
    mapping(uint256 => bytes32) internal _merkleRoot;
    function _setMerkleRoot(uint256 type_, bytes32 merkleRoot_) internal virtual { _merkleRoot[type_] = merkleRoot_; }
    function isWhitelisted(uint256 type_, address address_, bytes32[] memory proof_) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(address_));
        for (uint256 i = 0; i < proof_.length; i++) { 
            _leaf = _leaf < proof_[i] ? 
            keccak256(abi.encodePacked(_leaf, proof_[i])) : 
            keccak256(abi.encodePacked(proof_[i], _leaf)); 
        }
        return _leaf == _merkleRoot[type_];
    }
}

interface IMetadata {
    function tokenURI(uint256 tokenId_) external view returns (string memory);
}

interface INTP {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function balanceOf(address address_) external view returns (uint256);
}

contract ROARS is ERC721, OwnControll, MerkleProof, OperatorFilterer {

    address public metadata;
    bool public useMetadata;

    mapping(uint256 => uint256) private claim;
    mapping(address => uint256) private mintedP1;
    mapping(address => uint256) private mintedP2;
    modifier onlySender() { require(msg.sender == tx.origin, "No smart contract");_; }

    uint8 public saleState;
    uint256 public phase1Price = 0.01 ether;
    uint256 public phase2Price = 0.02 ether;
    uint256 public constant maxToken = 12345;

    INTP public NTP = INTP(0xA65bA71d653f62c64d97099b58D25a955Eb374a0);

    constructor() ERC721("ROARS", "ROARS") OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true) {}

    function ownerMint(address[] calldata addresses_, uint256[] calldata amounts_) external onlyOwner {
        uint256 l = addresses_.length;
        uint256 i; unchecked { do { 
            _mint(addresses_[i], amounts_[i]);
        } while (++i < l); }
    }

    /// Phase1 sale
    function phase1SaleAL1(uint256[] calldata tokenIds_, uint256 amount_) external payable onlySender {
        require(saleState == 1, "Sale not active");
        uint256 l = tokenIds_.length;
        uint256 i; unchecked { do {
            require(NTP.ownerOf(tokenIds_[i]) == msg.sender, "Not Owner of token");
            require(claim[tokenIds_[i]] == 0, "claimed");
            claim[tokenIds_[i]]++;
        } while (++i < l); }
        require(l * 3 >= amount_, "Exceed max claim per NFT");
        require(amount_ + totalSupply() <= maxToken, "No more NFTs");
        require(msg.value == phase1Price * amount_, "Value sent is not correct");
        _mint(msg.sender, amount_);
    }

    function phase1SaleAL3(bytes32[] memory proof_) external payable onlySender {
        require(saleState == 1, "Sale not active");
        require(1 + totalSupply() <= maxToken, "No more NFTs");
        require(isWhitelisted(1, msg.sender, proof_), "You are not whitelisted!");
        require(msg.value == phase2Price, "Value sent is not correct");
        require(mintedP1[msg.sender] == 0, "1 max per address");
        mintedP1[msg.sender]++;
        _mint(msg.sender, 1);
    }

    /// Phase2 sale
    function phase2Sale(uint256 amount_, bytes32[] memory proof_) external payable onlySender {
        require(saleState == 2, "Sale not active");
        require(amount_ + totalSupply() <= maxToken, "No more NFTs");
        require(isWhitelisted(2, msg.sender, proof_), "You are not whitelisted!");
        require(msg.value == phase2Price * amount_, "Value sent is not correct");
        require(4 > mintedP2[msg.sender] + amount_, "3 max per address");
        require(4 > amount_, "3 max per tx");
        mintedP2[msg.sender] += amount_;
        _mint(msg.sender, amount_);
    }

    /// Phase3 sale
    function phase3Sale(uint256 amount_, bytes32[] memory proof_) external payable onlySender {
        require(saleState == 3, "Sale not active");
        require(isWhitelisted(3, msg.sender, proof_), "You are not whitelisted!");
        require(msg.value == phase2Price * amount_, "Value sent is not correct");
        require(amount_ + totalSupply() <= maxToken, "No more NFTs");
        require(6 > amount_, "5 max per tx");
        _mint(msg.sender, amount_);
    }

    function mint(address address_, uint256 amount_) external onlyAdmin("MINTER") {
        _mint(address_, amount_);
    }

    function burn(uint256 tokenId_, bool checkApproved_) external onlyAdmin("BURNER") {
        _burn(tokenId_, checkApproved_);
    }

    function setMerkleRoot(uint256 type_, bytes32 merkleRoot_) external onlyAdmin("ADMIN") {
        _setMerkleRoot(type_, merkleRoot_);
    }

    function setSaleState(uint8 state_) external onlyAdmin("ADMIN") {
        saleState = state_;
    }

    function setSalePrice1(uint256 price_) external onlyAdmin("ADMIN") {
        phase1Price = price_;
    }

    function setSalePrice2(uint256 price_) external onlyAdmin("ADMIN") {
        phase2Price = price_;
    }

    function setOperatorlist(address address_, bool status) external onlyAdmin("ADMIN") {
        _setOperatorlist(address_, status);
    }

    function setBaseTokenURI(string calldata uri_) external onlyAdmin("ADMIN") {
        _setBaseTokenURI(uri_);
    }

    function setBaseTokenURIEXT(string calldata uri_) external onlyAdmin("ADMIN") {
        _setBaseTokenURIEXT(uri_);
    }

    function setMetadata(address address_) external onlyAdmin("ADMIN") {
        metadata = address_;
    }

    function setUseMetadata(bool bool_) external onlyAdmin("ADMIN") {
        useMetadata = bool_;
    }

    function seeClaim(uint256 tokenId_) public view returns (uint256) {
        return claim[tokenId_];
    }

    function startTokenId() public pure virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        if (!useMetadata) {
            return _getURI(tokenId_);
        } else {
            return IMetadata(metadata).tokenURI(tokenId_);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}