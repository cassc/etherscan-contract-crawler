// SPDX-License-Identifier: MIT
// Author: Pagzi Tech Inc. | 2022
// Kitbash  -  Toy Boogers | 2022
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract KitbashBoogers is Context, ERC165, IERC721, IERC721Metadata, Ownable {
    using Address for address;
    using Strings for uint256;

    // Token name and symbol
    string private _name = "Kitbash Boogers";
    string private _symbol = "KIT";
    
    mapping(uint => uint) private _availableTokens;
    uint256 private _numAvailableTokens = 1112;
    uint256 private _maxSupply = 1112;
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    //allowlist settings    
    bytes32 public merkleRoot = 0xde78a4c070eb27d3c355d3faff588c310950396f9e98b89dbaaf4a52e6687089;
    mapping(address => bool) public claimed;

    //sale settings
    uint256 public cost = 0.25 ether;

    //backend settings
    string public baseURI;
    address internal founder = 0x6ed5a435495480774Dfc44cc5BC85333f1b0646A;
    address internal immutable pagzidev = 0xeBaBB8C951F5c3b17b416A3D840C52CcaB728c19;
    address internal immutable partner1 = 0xc8B8B0C3f5Fc995B0E6a05ff89bDf8c820221C4F;
    address internal immutable partner2 = 0xe9D30EdDD11DeA8433cf6D2B2c22E9CCE94113dC;

    //proxy access and freezing
    mapping(address => bool) public projectProxy;
    bool public frozen;

    //date variables
    uint256 public publicDate = 1651341600;

    //mint passes/claims
    address public proxyAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    //royalty settings
    uint256 public royaltyFee = 5000;

    modifier checkDate() {
        require((publicDate < block.timestamp),"Allowlist sale is not yet!");
        _;
    }
    modifier checkPrice() {
        require(msg.value == cost , "Check sent funds!");
        _;
    }
    /**
     * @dev Initializes the contract by minting the #0 to Doug and setting the baseURI ;)
     */
    constructor() {
        _mintAtIndex(founder,0);
        baseURI = "https://kitbash.nftapi.art/meta/";
    }
    
    // external
    function mint(bytes32[] calldata _merkleProof) external payable checkPrice checkDate {
        // Verify allowlist requirements
        require(claimed[msg.sender] != true, "Address has no allowance!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid merkle proof!");
        require(_numAvailableTokens > 1, "No tokens left!");
        _mintRandom(msg.sender);
        claimed[msg.sender] = true;
    }

    /**
     * @dev See {ERC-2981-royaltyInfo}.
     */
    function royaltyInfo(uint256, uint256 value) external view 
    returns (address receiver, uint256 royaltyAmount){
    require(royaltyFee > 0, "ERC-2981: Royalty not set!");
    return (founder, (value * royaltyFee) / 10000);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == 0x2a55205a /* ERC-2981 royaltyInfo() */ ||
            super.supportsInterface(interfaceId);
    }
    function totalSupply() public view virtual returns (uint256) {
        return _maxSupply - _numAvailableTokens;
    }
    
    function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = KitbashBoogers.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = KitbashBoogers.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mintIdWithoutBalanceUpdate(address to, uint256 tokenId) private {
        _beforeTokenTransfer(address(0), to, tokenId);
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _mintRandom(address to) internal virtual {
        uint updatedNumAvailableTokens = _numAvailableTokens;
        uint256 tokenId = getRandomAvailableTokenId(to, updatedNumAvailableTokens);
        _mintIdWithoutBalanceUpdate(to, tokenId);
        --updatedNumAvailableTokens;
        _numAvailableTokens = updatedNumAvailableTokens;
        _balances[to] += 1;
    }
        
    function getRandomAvailableTokenId(address to, uint updatedNumAvailableTokens) internal returns (uint256) {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this),
                    updatedNumAvailableTokens
                )
            )
        );
        uint256 randomIndex = randomNum % updatedNumAvailableTokens;
        return getAvailableTokenAtIndex(randomIndex, updatedNumAvailableTokens);
    }

    function getAvailableTokenAtIndex(uint256 indexToUse, uint updatedNumAvailableTokens) internal returns (uint256) {
        uint256 valAtIndex = _availableTokens[indexToUse];
        uint256 result;
        if (valAtIndex == 0) {
            // This means the index itself is still an available token
            result = indexToUse;
        } else {
            // This means the index itself is not an available token, but the val at that index is.
            result = valAtIndex;
        }

        uint256 lastIndex = updatedNumAvailableTokens - 1;
        if (indexToUse != lastIndex) {
            uint256 lastValInArray = _availableTokens[lastIndex];
            if (lastValInArray == 0) {
                _availableTokens[indexToUse] = lastIndex;
            } else {
                _availableTokens[indexToUse] = lastValInArray;
                delete _availableTokens[lastIndex];
            }
        }
        
        return result;
    }
    
    function _mintAtIndex(address to, uint index) internal virtual {        
        uint tokenId = getAvailableTokenAtIndex(index, _numAvailableTokens);
        --_numAvailableTokens;        
        _mintIdWithoutBalanceUpdate(to, tokenId);        
        _balances[to] += 1;
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(KitbashBoogers.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(KitbashBoogers.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    //only owner
    function gift(uint256[] calldata quantity, address[] calldata recipient) external onlyOwner{
    require(quantity.length == recipient.length, "Invalid data" );
    uint256 totalQuantity;
    for(uint256 i = 0; i < quantity.length; ++i){
        totalQuantity += quantity[i];
    }
        require(_numAvailableTokens >= totalQuantity, "ERC721: minting more tokens than available");
        for(uint256 i = 0; i < recipient.length; ++i){
        for(uint256 j = 1; j <= quantity[i]; ++j){
            _mintRandom(recipient[i]);
        }
        }
        delete totalQuantity;
    }

    function setSupply(uint256 _supply) external onlyOwner {
        _maxSupply = _supply;
    }
    function setAvailibility(uint256 _supply) external onlyOwner {
        _numAvailableTokens = _supply;
    }
    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }
    function setPublicDate(uint256 _publicDate) external onlyOwner {
        publicDate = _publicDate;
    }
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
    function switchProxy(address _proxyAddress) public onlyOwner {
        projectProxy[_proxyAddress] = !projectProxy[_proxyAddress];
    }
    function setProxy(address _proxyAddress) external onlyOwner {
        proxyAddress = _proxyAddress;
    }
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }
    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);
        uint256[] memory allTokens = new uint256[](tokenCount);
        uint256 j = 0;
        for(uint256 i; i < _maxSupply; i++ ){
          address owner = _owners[i];
          if(_owner == owner){
            allTokens[j] = (i);
            j++;
            if(j == tokenCount) return allTokens;
            }
        }
        return allTokens;
    }
    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }
    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }
    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }
        return true;
    }
    function isApprovedForAll(address _owner, address operator) public view override(IERC721) returns (bool) {
        //Free listing on OpenSea by granting access to their proxy wallet. This can be removed in case of a breach on OS.
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return isApprovedForAll(_owner, operator);
    }
    //ERC-2981 Royalty Implementation
    function setRoyalty(address _royaltyAddr, uint256 _royaltyFee) public onlyOwner {
        require(_royaltyFee < 10001, "ERC-2981: Royalty too high!");
        founder = _royaltyAddr;
        royaltyFee = _royaltyFee;
    }    
    function freeze() external onlyOwner {
        frozen = !frozen;
    }
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(founder).transfer((balance * 400) / 1000);
        payable(partner1).transfer((balance * 200) / 1000);
        payable(partner2).transfer((balance * 200) / 1000);
        payable(pagzidev).transfer((balance * 200) / 1000);
    }
}
contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}