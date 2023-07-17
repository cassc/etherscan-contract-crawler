// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;


import "ERC1155.sol";
import "ERC1155Supply.sol";
import "Ownable.sol";
import "Counters.sol";
import "MerkleProof.sol";
import "ERC1155Burnable.sol";


// @dev @0xDevZombie
contract TheAscendantsPass is ERC1155, ERC1155Supply, ERC1155Burnable, Ownable {

    string public name = "The Ascendants - Gifts of The Gods";
    string public symbol = "GOTG";

    uint256 public constant GIFT_OF_ZEUS = 1;
    uint256 public constant GIFT_OF_POSEIDON = 2;
    uint256 public constant GIFT_OF_HADES = 3;

    using Counters for Counters.Counter;
    mapping(uint256 => string) private _tokenIdToUri;
    mapping(uint256 => Counters.Counter) private _tokenIdToCounter;
    mapping(uint256 => bool) public tokenIdToPrivateSaleOpen;
    mapping(uint256 => bool) public tokenIdToPublicSaleOpen;
    mapping(uint256 => uint) private _tokenIdToTokenLimit;
    mapping(uint256 => uint) private _tokenIdToMintPrice;
    mapping(uint256 => bytes32) private _tokenIdToMerkleRoot;
    mapping(uint256 => bool) private _tokenIdToCuratorAwardClaimed;
    bool burnMintEnabled;
    address payable internal curatorTeamAddress;
    address payable internal payoutTeamAddress;

    mapping(address => User) addressToUser;
    struct User {
        bool hasWhitelistMinted;
        mapping(uint => bool) tokenIdToWhitelistMinted;
        mapping(uint => bool) tokenIdToPublicMinted;
    }

    constructor(address curatorsAddress) ERC1155("") {
        setTokenIdToMintPrice(GIFT_OF_POSEIDON, 0.2 ether);
        curatorTeamAddress = payable(curatorsAddress);
    }

    /// The token id does not exist.
    error TokenIdDoesNotExist();
    /// This function has not been enabled yet.
    error FunctionNotEnabled();
    /// This token id cannot be used for this function.
    error TokenIdNotAllowed();
    /// Max tokens have been minted.
    error MaxTokensMinted();
    /// You are not on the whitelist
    error NotOnWhitelist();
    /// You have minted your allowance
    error MintedAllowance();
    /// msg.value too low
    error MintPayableTooLow();
    /// You dont own enough tokens for a burn mint.
    error NotEnoughOwnedTokens();
    /// Curator team award limit reached.
    error CuratorTeamAwardLimit();

    modifier isValidTokenId(uint256 tokenId) {
        if (tokenId != GIFT_OF_ZEUS && tokenId != GIFT_OF_POSEIDON && tokenId != GIFT_OF_HADES)
            revert TokenIdDoesNotExist(); // dev: tokenId unknown
        _;
    }

    modifier isBelowMaxSupply(uint256 tokenId) {
        uint256 tokenCount = _tokenIdToCounter[tokenId].current();
        if (tokenCount >= _tokenIdToTokenLimit[tokenId])
            revert MaxTokensMinted(); // dev: max token supply minted
        _;
    }

    modifier isNotBelowMintPrice(uint256 tokenId) {
        if (msg.value < _tokenIdToMintPrice[tokenId])
            revert MintPayableTooLow(); // dev: msg.value too low
        _;
    }


    function privateMint(uint256 tokenId, bytes32[] calldata _merkleProof) external
    isValidTokenId(tokenId)
    isBelowMaxSupply(tokenId)
    isNotBelowMintPrice(tokenId)
    payable {
        if (tokenIdToPrivateSaleOpen[tokenId] == false)
            revert FunctionNotEnabled(); // dev: sale is not open currently

        User storage user = addressToUser[msg.sender];
        if (user.hasWhitelistMinted == true)
            revert MintedAllowance(); // dev: whitelist allowance minted

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_merkleProof, _tokenIdToMerkleRoot[tokenId], leaf) == false)
            revert NotOnWhitelist(); // dev: not on the whitelist

        user.hasWhitelistMinted = true;
        _tokenIdToCounter[tokenId].increment();
        _mint(msg.sender, tokenId, 1, "");
    }

    function publicMint(uint256 tokenId) external
    isValidTokenId(tokenId)
    isBelowMaxSupply(tokenId)
    isNotBelowMintPrice(tokenId)
    payable {
        if (tokenIdToPublicSaleOpen[tokenId] == false)
            revert FunctionNotEnabled(); // dev: public sale is not open
        
        User storage user = addressToUser[msg.sender];

        if (user.tokenIdToPublicMinted[tokenId] == true)
            revert MintedAllowance(); // dev: public allowance minted

        user.tokenIdToPublicMinted[tokenId] = true;
        _tokenIdToCounter[tokenId].increment();
        _mint(msg.sender, tokenId, 1, "");
    }

    function burnMint() external
        isBelowMaxSupply(GIFT_OF_ZEUS)
    {
        if (burnMintEnabled == false)
            revert FunctionNotEnabled(); // dev: burn mint not enabled

        if (balanceOf(msg.sender, GIFT_OF_POSEIDON) < 4)
            revert NotEnoughOwnedTokens(); // dev: not enough tokens
        burn(msg.sender, GIFT_OF_POSEIDON, 4);
        _mint(msg.sender, GIFT_OF_ZEUS, 1, "");
    }

    function curatorAward(uint256 tokenId, uint256 quantity) external
    isValidTokenId(tokenId)
    isBelowMaxSupply(tokenId)
    onlyOwner {
        if (_tokenIdToCuratorAwardClaimed[tokenId])
            revert CuratorTeamAwardLimit(); // dev: cannot claim curator award again
        _tokenIdToCuratorAwardClaimed[tokenId] = true;
        _mint(curatorTeamAddress, tokenId, quantity, "");
    }

    function withdrawFunds() external virtual onlyOwner {
        curatorTeamAddress.transfer(address(this).balance);
    }

    /**
    * Settings
    */

    function togglePrivateSaleOpen(uint256 tokenId) external virtual onlyOwner {
        tokenIdToPrivateSaleOpen[tokenId] = !tokenIdToPrivateSaleOpen[tokenId];
    }

    function togglePublicSaleOpen(uint256 tokenId) external virtual onlyOwner {
        if (tokenId == GIFT_OF_ZEUS)
            revert TokenIdNotAllowed(); // dev: public mint not allowed for this token
        tokenIdToPublicSaleOpen[tokenId] = !tokenIdToPublicSaleOpen[tokenId];
    }

    function toggleBurnMint() external virtual onlyOwner {
        burnMintEnabled = !burnMintEnabled;
    }

    function setMaxTokenSupply(uint256 tokenId, uint256 maxSupply) external onlyOwner isValidTokenId(tokenId) {
        _tokenIdToTokenLimit[tokenId] = maxSupply;
    }

    function setTokenIdToMintPrice(uint256 tokenId, uint256 mintPrice) public onlyOwner isValidTokenId(tokenId) {
        if (tokenId == GIFT_OF_ZEUS)
            revert TokenIdNotAllowed(); // dev: cannot set price for this token
        _tokenIdToMintPrice[tokenId] = mintPrice;
    }

    function setTokenIdToMerkleRoot(uint256 tokenId, bytes32 merkleRoot) external onlyOwner isValidTokenId(tokenId) {
        _tokenIdToMerkleRoot[tokenId] = merkleRoot;
    }

    function setTokenIdToUri(uint256 tokenId, string memory uri) external onlyOwner {
        _tokenIdToUri[tokenId] = uri;
    }

    /**
    * views
    */

    function getTokenIdToRemainingMints(uint256 tokenId) external view returns (uint256) {
        return _tokenIdToTokenLimit[tokenId] - _tokenIdToCounter[tokenId].current();
    }

    function getTokenIdToMaxSupply(uint256 tokenId) external view returns (uint256) {
        return _tokenIdToTokenLimit[tokenId];
    }


    /**
    * @dev override default uri method to return separate uri for each token id
    */
    function uri(uint256 tokenId) override public view returns (string memory) {
        return (_tokenIdToUri[tokenId]);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

}