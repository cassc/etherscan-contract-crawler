//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity  0.8.9;

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

library LibRoyaltiesV2 {
    /*
     * bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}

abstract contract AbstractRoyalties {
    mapping (uint256 => LibPart.Part[]) internal royalties;

    function _saveRoyalties(uint256 id, LibPart.Part[] memory _royalties) internal {
        uint256 totalValue;
        for (uint i = 0; i < _royalties.length; i++) {
            require(_royalties[i].account != address(0x0), "Recipient should be present");
            require(_royalties[i].value != 0, "Royalty value should be positive");
            totalValue += _royalties[i].value;
            royalties[id].push(_royalties[i]);
        }
        require(totalValue < 10000, "Royalty total value should be < 10000");
        _onRoyaltiesSet(id, _royalties);
    }

    function _updateAccount(uint256 _id, address _from, address _to) internal {
        uint length = royalties[_id].length;
        for(uint i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                royalties[_id][i].account = payable(address(uint160(_to)));
            }
        }
        
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) virtual internal;
}

contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2 {
    function getRaribleV2Royalties(uint256 id) override external view returns (LibPart.Part[] memory) {
        return royalties[id];
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) override internal {
        emit RoyaltiesSet(id, _royalties);
    }
    
}

contract BSG is ERC721, ERC721Enumerable, Ownable, RoyaltiesV2Impl {

    address payable royaltiesRecipientAddress = payable(0x81C13d0b718711CBb8816f3f6f610f340b6D86FB);
    address public feeWallet = 0x81C13d0b718711CBb8816f3f6f610f340b6D86FB;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 public mintFee = 1e17; //0.1 Ethereum
    uint256 public tokenId = 0;
    uint256 constant public maxMint = 1001;

    bool public mintStatus = false;

    string public baseURI = "https://ipfs.io/";
    string public COLLECTOIN_INFO = "ipfs/QmdbpEvimv1htLZpBMr9aTadfgPcg4pw8qfx21XRxo2KTJ";

    string[] public URIs = [
    "ipfs/QmTJxM4kUgTQNH9gJyww4pUBVC4GbHrzDysbdgLMZxXJDe/Common2.json",
    "ipfs/QmTJxM4kUgTQNH9gJyww4pUBVC4GbHrzDysbdgLMZxXJDe/Rare2.json",
    "ipfs/QmTJxM4kUgTQNH9gJyww4pUBVC4GbHrzDysbdgLMZxXJDe/Epic2.json",
    "ipfs/QmTJxM4kUgTQNH9gJyww4pUBVC4GbHrzDysbdgLMZxXJDe/Legendary2.json",
    "ipfs/QmTJxM4kUgTQNH9gJyww4pUBVC4GbHrzDysbdgLMZxXJDe/God2.json"];
    uint256[] public chances = [400, 320, 150, 88, 42];
    uint256 public totalNFTs = 1000;

    mapping(uint256=>uint256) public tokenURIs;

    constructor() ERC721("Black Shibaverse Genesis", "BSG"){
    }

    event MintEnabled(bool indexed status);

    function setCommonURI(string memory data) external onlyOwner{
        URIs[0] = data;
    }
    function setRareURI(string memory data) external onlyOwner{
        URIs[1] = data;
    }

    function setEpicURI(string memory data) external onlyOwner{
        URIs[2] = data;
    }

    function setLegendaryURI(string memory data) external onlyOwner{
        URIs[3] = data;
    }
    
    function setGodURI(string memory data) external onlyOwner{
        URIs[4] = data;
    }

    function mintNft() public payable {
        require(msg.sender == owner() || mintStatus, "minting is not enabled yet!");
        require(tokenId < maxMint, "reached max mint!");
        require(msg.value >= mintFee, "BSG: mint fee is 0.1 ETH!");
        payable(feeWallet).transfer(msg.value);
        uint256 result = pickARandomNumber();
        tokenId += 1;
        setRoyalties(tokenId, royaltiesRecipientAddress, 500);
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, result);
        chances[result] = chances[result] - 1;
        totalNFTs -= 1;
    }

    function multiMint(uint256 number) public payable {
        require(msg.sender == owner() || mintStatus, "minting is not enabled yet!");
        require(tokenId + number < maxMint, "reached max mint!");
        require(msg.value >= mintFee * number, "BSG: mint fee is 0.1 ETH!");
        payable(feeWallet).transfer(msg.value);
        for(uint256 i = 0; i < number; i++){
            uint256 result = pickARandomNumber();
            tokenId += 1;
            setRoyalties(tokenId, royaltiesRecipientAddress, 500);
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, result);
            chances[result] = chances[result] - 1;
            totalNFTs -= 1;
        }
    }
    
    function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress,uint96 _percentageBasisPoints) internal{
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function setRoyaltyRecipientAddress(address payable _royaltiesRecipientAddress) public onlyOwner{
        royaltiesRecipientAddress = _royaltiesRecipientAddress;
    }

    function pickARandomNumber() internal view returns(uint256 result){
        uint256 randomNumber = uint256(keccak256(abi.encode(block.timestamp, block.difficulty, block.number, msg.sender, tokenId)));
        randomNumber = randomNumber % totalNFTs;
        uint256 acc = 0;
        for(uint256 i = 0; i < chances.length; i++){
            if(randomNumber >= acc && randomNumber <= acc + chances[i] && chances[i] != 0){
                result = i;
            }
            acc += chances[i];
        }
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory ownerTokens) {
         uint256 tokenCount = balanceOf(_owner);
         
          if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all Rats have IDs starting at 1 and increasing
            // sequentially up to the totalCat count.
            uint256 tokensId;

            for (tokensId = 1; tokensId <= totalTokens; tokensId++) {
                if (ownerOf(tokensId) == _owner) {
                    result[resultIndex] = tokensId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function setFeeWallet(address newFee) public onlyOwner{
        feeWallet = newFee;
    }

    function getRoyaltyRecipientAddress() public view returns(address payable){
        return royaltiesRecipientAddress;
    }

    function setMintStatus(bool status) external onlyOwner{
        mintStatus = status;
        emit MintEnabled(status);
    }

    function setMintFee(uint256 _mintFee) external onlyOwner{
        mintFee = _mintFee;
    }

    function _setTokenURI(uint256 _tokenId, uint256 index) internal{
        tokenURIs[_tokenId] = index;
    }

    function tokenURI(uint256 _tokenId) public override view returns(string memory){
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), URIs[tokenURIs[_tokenId]]));
    }

    function contractURI() public view returns (string memory) { //Collection details
        return string(abi.encodePacked(_baseURI(), COLLECTOIN_INFO));
    }

    function updateContractURI(string memory data) public onlyOwner{
        COLLECTOIN_INFO = data;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBASE) external onlyOwner {
        baseURI = newBASE;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES){
            return true;
        }

        if(interfaceId == _INTERFACE_ID_ERC2981){
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

}