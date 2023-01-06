//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Millionaireasia1155Contract is ERC2981, ERC1155Supply, Ownable {
    using Strings for uint256;
    struct ApprovedAddress {
        mapping(address => bool) addresses;
    }
    struct OwnedTokens {
        mapping(uint256 => ApprovedAddress) tokens;
    }
    struct BuyRequest {
        address seller;
        uint256 tokenId;
        uint256 quantity;
        uint256 amount;
        uint256 fee;
    }
    struct BuyBatchRequest {
        address seller;
        uint256[] tokenIds;
        uint256[] quantities;
        uint256[] amounts;
        uint256[] fees;
    }
    // Optional base URI
    string private _baseURI = "";
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => address[]) private _tokenOwners;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    mapping(uint256 => uint256) private _allTokensIndex;
    mapping(uint256 => address) private creators;
    mapping(address => OwnedTokens) private _tokenApprovals;
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    string public name;
    string public symbol;
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function mint(address to, uint256 id, uint256 amount, string memory uri, address royaltyRecipient, uint96 royaltyValue) external payable {
        address owner = owner();
        if(owner != msg.sender) {
            require(msg.value > 0, "Must pay minting service fee");
            uint256 ethBalance = msg.sender.balance;
            require(ethBalance > msg.value, "Insufficient balance");
            (bool success, ) = owner.call{ value: msg.value }("");
            require(success, "Transaction failed");           
        }
        _mint(to, id, amount, '');
        creators[id] = to;
        if (royaltyValue > 0) {
            _setTokenRoyalty(id, royaltyRecipient, royaltyValue);
        }
        if (bytes(uri).length > 0) {
            _setTokenURI(id, uri);
        }
    }
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, string[] memory uris, address[] memory royaltyRecipients, uint96[] memory royaltyValues ) external payable {
        require(ids.length == amounts.length &&ids.length == royaltyValues.length, 'ERC1155: Arrays length mismatch');
        address owner = owner();
        if(owner != msg.sender) {
            require(msg.value > 0, "Must pay minting service fee");
            uint256 ethBalance = msg.sender.balance;
            require(ethBalance > msg.value, "Insufficient balance");
            (bool success, ) = owner.call{ value: msg.value }("");
            require(success, "Transaction failed");           
        }

        for (uint256 i; i < ids.length; i++) {
            _mint(to, ids[i], amounts[i], '');
            creators[ids[i]] = to;
            if (royaltyValues[i] > 0) {
                _setTokenRoyalty(
                    ids[i],
                    royaltyRecipients[i],
                    royaltyValues[i]
                );
            }
            if (bytes(uris[i]).length > 0) {
                _setTokenURI(ids[i], uris[i]);
            }
        }
    }
    function creator(uint256 tokenId) public view returns (address) {
        require(exists(tokenId), 'ERC1155: token does not exist');
        return creators[tokenId];
    }
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory uri = _tokenURIs[tokenId];
        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return bytes(uri).length > 0 ? string(abi.encodePacked(_baseURI, uri)) : super.uri(tokenId);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < _ownedTokens[owner].length, "ERC1155: Owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function ownersOfTokens(uint256 tokenId) public view returns (address[] memory) {
        require(exists(tokenId), 'ERC1155: token does not exist');
        return _tokenOwners[tokenId];
    }
    function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        _tokenURIs[tokenId] = uri;
        emit URI(tokenURI(tokenId), tokenId);
    }
    function _setBaseURI(string memory baseURI) external virtual onlyOwner {
        _baseURI = baseURI;
    }
    function approve(address to, uint256 tokenId, uint256 quantity) public virtual {
        uint256 balance = balanceOf(msg.sender, tokenId);
        require(to != msg.sender, "ERC1155: approval to current owner");
        require(balance >= quantity, "ERC1155: Insufficient token supply");
        _tokenApprovals[_msgSender()].tokens[tokenId].addresses[to] = true;
        emit Approval(_msgSender(), to, tokenId);
    }
    function approveBatch(address to, uint256[] memory tokenIds, uint256[] memory quantities) public virtual {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 balance = balanceOf(msg.sender, tokenId);
            require(to != msg.sender, "ERC1155: approval to current owner");
            require(balance >= quantities[i], "ERC1155: Insufficient token supply");
            _tokenApprovals[_msgSender()].tokens[tokenId].addresses[to] = true;
            emit Approval(_msgSender(), to, tokenId);
        }
    }
    function getApproved(uint256 tokenId, address owner, address operator) public view returns(bool) {
        require(exists(tokenId), "ERC1155: approved query for nonexistent token");
        return _tokenApprovals[owner].tokens[tokenId].addresses[operator];
    }
    modifier onlyApproved(uint256 tokenId, address owner, address operator) {
        require(exists(tokenId), "ERC1155: approved query for nonexistent token");
        require(_tokenApprovals[owner].tokens[tokenId].addresses[operator]);
        _;
    }
    modifier onlyApprovers(uint256[] memory tokenIds, address owner, address operator) {
        for (uint256 i; i < tokenIds.length; i++) {
            require(exists(tokenIds[i]), "ERC1155: approved query for nonexistent token");
            require(_tokenApprovals[owner].tokens[tokenIds[i]].addresses[operator]);
        }
        _;
    }
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()) || getApproved(id, from, to), "ERC1155: caller is not owner nor approved");
        super._safeTransferFrom(from, to, id, amount, data);
    }
    function safeTransferFromWithFee(address from, address to, uint256 id, uint256 amount, bytes memory data) public payable {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()) || getApproved(id, from, to), "ERC1155: caller is not owner nor approved");
        if(msg.value > 0) {
            address contractOwner = owner();
            (bool success, ) = contractOwner.call{ value: msg.value }("");
            require(success, "ERC721: Transfer failed");
        }
        super._safeTransferFrom(from, to, id, amount, data);
    }
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
        require(ids.length == amounts.length, 'ERC1155: Arrays length mismatch');
        for (uint256 i; i < ids.length; i++) {
            require(from == _msgSender() || isApprovedForAll(from, _msgSender()) || getApproved(ids[i], from, to), "ERC1155: caller is not owner nor approved");
            super._safeTransferFrom(from, to, ids[i], amounts[i], data);
        }
    }
    function safeBatchTransferFrom(address from, address[] memory tos, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public payable {
        require(ids.length == amounts.length, 'ERC1155: Arrays length mismatch');
        if(msg.value > 0) {
            address contractOwner = owner();
            (bool success, ) = contractOwner.call{ value: msg.value }("");
            require(success, "ERC721: Transfer failed");
        }
        for (uint256 i; i < ids.length; i++) {
            require(from == _msgSender() || isApprovedForAll(from, _msgSender()) || getApproved(ids[i], from, tos[i]), "ERC1155: caller is not owner nor approved");
            super._safeTransferFrom(from, tos[i], ids[i], amounts[i], data);
        }
    }
    function buy(BuyRequest memory request) external payable onlyApproved(request.tokenId, request.seller, msg.sender) {
        require(msg.value == request.amount, "Amount is invalid");
        uint256 ethBalance = msg.sender.balance;
        (address recipient, uint256 royalty) = royaltyInfo(request.tokenId, request.amount);
        require(ethBalance > msg.value, "Insufficient balance");
        uint256 balance = balanceOf(request.seller, request.tokenId);
        require(balance >= request.quantity, "Insufficient token supply");
        address contractOwner = owner();
        (bool success, ) = request.seller.call{value: (msg.value - request.fee - royalty)}("");
        if(success && royalty > 0) {
            (success, ) = recipient.call{value: royalty}("");          
        }
        if(success)
            (success, ) = contractOwner.call{value: request.fee}("");
        require(success, "Transaction failed");
        safeTransferFrom(request.seller, _msgSender(), request.tokenId, request.quantity, "");
    }
    function buyBatch(BuyBatchRequest memory request) external payable onlyApprovers(request.tokenIds, request.seller, msg.sender) {
        require(request.tokenIds.length == request.amounts.length && request.tokenIds.length == request.quantities.length, 'ERC1155: Arrays length mismatch');
        uint256 ethBalance = msg.sender.balance;
        require(ethBalance > msg.value, "Insufficient balance");
        for (uint256 i; i < request.tokenIds.length; i++) {
            (address recipient, uint256 royalty) = royaltyInfo(request.tokenIds[i], request.amounts[i]);
            
            uint256 balance = balanceOf(request.seller, request.tokenIds[i]);
            require(balance >= request.quantities[i], "Insufficient token supply");
            address contractOwner = owner();
            (bool success, ) = request.seller.call{value: (msg.value - request.fees[i] - royalty)}("");
            if(success && royalty > 0) {
                (success, ) = recipient.call{value: royalty}("");          
            }
            if(success && request.fees[i] > 0)
                (success, ) = contractOwner.call{value: request.fees[i]}("");
            require(success, "Transaction failed");
            safeTransferFrom(request.seller, _msgSender(), request.tokenIds[i], request.quantities[i], "");
        }
    }
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            _addTokenToOwnerEnumeration(to, ids[i]);
            _addOwnerToTokenEnumeration(to, ids[i]);
            if(from != address(0) && balanceOf(from, ids[i]) == 0){
                _removeTokenFromOwnerEnumeration(from, ids[i]);
                _removeOwnerFromTokenEnumeration(from, ids[i]);
            }
            delete _tokenApprovals[from].tokens[ids[i]].addresses[to];
        }
    }
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        bool isExist = false;
        for (uint256 i = 0; i < _ownedTokens[to].length; ++i) {
            if(_ownedTokens[to][i] == tokenId){
                isExist = true;
                break;
            }
        }
        if(!isExist)
            _ownedTokens[to].push(tokenId);
    }
    function _addOwnerToTokenEnumeration(address to, uint256 tokenId) private {
        bool isExist = false;
        for (uint256 i = 0; i < _tokenOwners[tokenId].length; ++i) {
            if(_tokenOwners[tokenId][i] == to){
                isExist = true;
                break;
            }
        }
        if(!isExist)
            _tokenOwners[tokenId].push(to);
    }
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        address owner = creators[tokenId];
        if(owner != from){
            for (uint256 i = 0; i < _ownedTokens[from].length; ++i) {
                if(_ownedTokens[from][i] == tokenId){
                    delete _ownedTokens[from][i];
                    break;
                }
            }
        }
    }
    function _removeOwnerFromTokenEnumeration(address from, uint256 tokenId) private {
        address owner = creators[tokenId];
        if(owner != from){
            for (uint256 i = 0; i < _tokenOwners[tokenId].length; ++i) {
                if(_tokenOwners[tokenId][i] == from){
                    delete _tokenOwners[tokenId][i];
                    break;
                }
            }
        }
    }
}