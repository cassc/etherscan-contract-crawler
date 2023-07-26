// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";



contract PleoSynthGen1 is ERC721,ERC2981,Ownable, ReentrancyGuard {
    uint256 private _mintPrice;
    uint96  private _royaltyFraction = 500;
    bytes32 public _merkleRoot;
    uint256 private _whiteListSupply;
    uint256 private _whiteListTotal = 0;
    uint256 private _wlMaxPerAddr = 3;
    uint256 private _maxPerAddr = 10;
    string private _baseUri = "";
    string private _baseUriPost = ".json";
    address private _signer;
    address private _withdrawAddr = 0x53Ac8100c590FC378DB86041044A06f95a273599;
    mapping(uint256 => address) private _whiteSpecifyWL;
    mapping(address=>uint256) private _whitelistClaimed;

    // for batch users
    mapping(uint256 => address) private _transfered;
    mapping(address => uint256) private _transferedBalance;
    uint256 private _transNum = 0;
    // for batch user begin
    uint256 private _beginToken = 0;
    // for batch user end
    uint256 private _endToken = 0;
    // batch address
    address private _batchAddress;


    modifier mintWhiteCompliance(uint256 quantity) {
        require(_whiteListTotal + quantity <= _whiteListSupply, 'Max supply for WL exceeded!');
        _;
    }

    modifier mintPriceCompliance(uint256 quantity) {
        require(msg.value >= _mintPrice * quantity, 'Insufficient funds!');
        _;
    }

    modifier checkSignature(uint256 tokenid, bytes calldata signature) {
        bytes32 message = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(tokenid)));
        require(SignatureChecker.isValidSignatureNow(_signer, message, signature),"Invalid signature");
        _;
    }

    constructor(address withdrawAddr,uint256 mintPrice,uint256 whiteListSupply,string memory baseUri,address signer)
     ERC721("pleosynth", "pleosynth")
      {
        _withdrawAddr = withdrawAddr;
        _mintPrice = mintPrice;
        _whiteListSupply = whiteListSupply;
        _baseUri = baseUri;
        _signer = signer;        
    }

    function _mintOne(uint256 tokenId) internal virtual {
        require(!_exists(tokenId), "invalid token ID");
        _safeMint(_msgSender(),tokenId,"");
        _setTokenRoyalty(tokenId,address(this),_royaltyFraction);
    }

    function mint(uint256 tokenId, bytes calldata signature) external payable mintPriceCompliance(1) checkSignature(tokenId,signature) {
        require(balanceOf(_msgSender()) + 1 <= _maxPerAddr,'Max supply for this address exceeded!');
        require(_whiteSpecifyWL[tokenId] == address(0),"no specify nft for this address");
        _mintOne(tokenId);
    }

    function whitelistMint(uint256 tokenId, bytes32[] calldata merkleProof) external mintWhiteCompliance(1) {
        // Verify whitelist requirements
        require(_whitelistClaimed[_msgSender()]+1 <= _wlMaxPerAddr, 'Max supply for this address exceeded!');
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_msgSender()))));
        require(MerkleProof.verify(merkleProof, _merkleRoot, leaf), 'not in whitelist!');
        if(_whiteSpecifyWL[tokenId] != address(0) && _whiteSpecifyWL[tokenId] != _msgSender()) {
            revert("no specify nft for this address");
        }
        _mintOne(tokenId);
        _whiteListTotal += 1;
        _whitelistClaimed[_msgSender()] += 1;
    }

    function batchMintToAddr(uint256 beginId,uint256 batchSize, address to) external onlyOwner {
        _batchMint(to,beginId,batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721,ERC2981) returns (bool) {
        return 
            ERC721.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    function setSpecifyWhiteList(address[] memory addrs,uint256[] memory uriids) public onlyOwner {
        for(uint256 i=0;i<addrs.length;i++){
            _whiteSpecifyWL[uriids[i]] = addrs[i];
        }
    }

    function setMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setMintPrice(uint256 mintPrice) public onlyOwner {
        _mintPrice = mintPrice;
    }

    function setMaxPerAddr(uint256 maxPerAddr) public onlyOwner {
        _maxPerAddr = maxPerAddr;
    }

    function setWhiteListSupply(uint256 whiteListSupply) public onlyOwner {
        _whiteListSupply = whiteListSupply;
    }

    function setBaseUri(string memory baseUri) public onlyOwner {
        _baseUri = baseUri;
    }

    function setPostFix(string memory postfix) public onlyOwner {
        _baseUriPost = postfix;
    }

    function setwlMaxPerAddr(uint256 wlMaxPerAddr) public onlyOwner {
        _wlMaxPerAddr = wlMaxPerAddr;
    }

    function setRoyaltyFraction(uint96 royaltyFraction) public onlyOwner {
        _royaltyFraction = royaltyFraction;
    }

    function setSigner(address signer) public onlyOwner {
        require(signer != address(0),"Invalid signer");
        _signer = signer;
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 ownerBalance = address(this).balance;
        (bool withdrawSuccess, ) = payable(_withdrawAddr).call{value: ownerBalance}('');
        require(withdrawSuccess);
    }

    function getWithdrawAddress() public view returns(address) {
        return _withdrawAddr;
    }

    function getSigner()  public view returns(address) {
        return _signer;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        // super.transferVotingUnits(from, to, batchSize);
        if(_isBatch(firstTokenId) && from != address(0)) {
            for(uint256 i=0;i<batchSize;i++){
                uint256 tokenId = firstTokenId + i;
                if(tokenId >= _endToken) {
                    break;
                }
                if(_transfered[tokenId] == address(0)) {
                    if(to == address(0)) {
                        // for burn
                        _transfered[tokenId] = address(1);
                    }else{
                        _transfered[tokenId] = to;
                        _transferedBalance[to] += 1;
                    }
                    _transNum++;
                }
            }
        }
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view override returns (address) {
        if(_isBatchAndOwner(tokenId)){
            return _batchAddress;
        }else if(_isBatch(tokenId)){
            return _transfered[tokenId];
        }
        return super._ownerOf(tokenId);
    }


    function _isBatch(uint256 tokenId) private view returns(bool) {
        return _batchAddress != address(0) && tokenId >= _beginToken && tokenId < _endToken;
    }

    function _isBatchAndOwner(uint256 tokenId) private view returns(bool) {
        return _isBatch(tokenId) && _transfered[tokenId] == address(0);
    }

    function _exists(uint256 tokenId) internal view override returns (bool) {
        if(_isBatch(tokenId)){
            return true;
        }
        return _ownerOf(tokenId) != address(0);
    }

    function balanceOf(address account) public view override returns(uint256) {
        uint256 batchNum = _transferedBalance[account];
        if(account == _batchAddress){
            batchNum = _endToken - _beginToken - _transNum;
        }
        return super.balanceOf(account) + batchNum;
    }

    function burn(uint256 tokenId) public {
        _resetTokenRoyalty(tokenId);
        if(_isBatchAndOwner(tokenId)) {
            _beforeTokenTransfer(_batchAddress, address(0), tokenId, 1);
            emit Transfer(_batchAddress, address(0), tokenId);
            _afterTokenTransfer(_batchAddress, address(0), tokenId, 1);
            return;
        }
        _burn(tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if(_isBatchAndOwner(tokenId)){
            require(to != address(0), "ERC721: transfer to the zero address");
            _beforeTokenTransfer(from, to, tokenId, 1);
            _approve(address(0),tokenId);
            emit Transfer(from, to, tokenId);
            _afterTokenTransfer(from, to, tokenId, 1);
        }else if(_transfered[tokenId] != address(0) && from == _transfered[tokenId]){
            require(to != address(0), "ERC721: transfer to the zero address");
            _beforeTokenTransfer(from, to, tokenId, 1);
            _approve(address(0),tokenId);
            _transfered[tokenId] = to;
            _transferedBalance[from]--;
            _transferedBalance[to]++;
            emit Transfer(from, to, tokenId);
            _afterTokenTransfer(from, to, tokenId, 1);
        }else{
            super._transfer(from,to,tokenId);
        }
    }

    function _batchMint(address to, uint256 tokenId, uint256 quantity) internal virtual {
        require(_batchAddress == address(0), "batchAddress has been setted");
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        // _beforeTokenTransfer(address(0), to, tokenId, quantity);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        _beginToken = tokenId;
        _endToken = tokenId + quantity;
        _batchAddress = to;

        for(uint256 i=0;i<quantity;i++) {
            emit Transfer(address(0), to, tokenId+i);
        }

        _afterTokenTransfer(address(0), to, tokenId, quantity);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(_baseUri, Strings.toString(tokenId),_baseUriPost));
    }
}