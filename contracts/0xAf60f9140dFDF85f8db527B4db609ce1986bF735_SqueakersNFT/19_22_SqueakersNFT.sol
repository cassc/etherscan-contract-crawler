// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface WhitelistNFTContract {
    function balanceOf(address owner) external view returns (uint256);
}

contract SqueakersNFT is DefaultOperatorFilterer, ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl, ERC721Burnable{
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIdCounter;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    string public baseURI;
    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public constant TEAM_ALLOCATION = 100;
    uint256 public mintStatus = 0;
    WhitelistNFTContract public whitelistNFTContract;

    constructor() ERC721("Squeakers", "SQUEAK") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPDATER_ROLE, msg.sender);
        baseURI = "ipfs://bafybeid2vfpiazvtenwihnk7ka4nrbttgo2tiqsa34u7idrwtqhmrr6ile/";
        whitelistNFTContract = WhitelistNFTContract(0x340700450f0303791529789793909C703730926f);
    }

    function mintTeamAllocation(uint256 amount) public onlyRole(UPDATER_ROLE) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply reached");
        for(uint256 i = 0; i < amount; i++){
            mint();
        }
    }

    function setBaseURI(string memory uri) public onlyRole(UPDATER_ROLE) {
        baseURI = uri;
    }

    function getWhitelistNFTBalanceOfUser(address userAddress) internal view returns (uint256) {
        return whitelistNFTContract.balanceOf(userAddress);
    }

    function updateWhitelistNFTContract(address contractAddress) public onlyRole(UPDATER_ROLE) {
        whitelistNFTContract = WhitelistNFTContract(contractAddress);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyRole(UPDATER_ROLE) {
        _setTokenURI(tokenId, uri);
    }

    function setMintStatus(uint256 status) public onlyRole(UPDATER_ROLE) {
        mintStatus = status;
    }
    
    function mint() public payable{
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");

        if(mintStatus == 1){
            require(getWhitelistNFTBalanceOfUser(msg.sender) > 0, "You must own a Whitelist NFT to mint a Squeakers NFT");
        }

        if(hasRole (UPDATER_ROLE, msg.sender) == false){
            require(balanceOf(msg.sender) < 3, "You can only mint 3 NFTs");
        }

        uint256 tokenId = _tokenIdCounter.current();
        safeMint(msg.sender, baseURI, tokenId);
        _tokenIdCounter.increment();
    }

    function safeMint(address to, string memory uri, uint256 tokenId) private{
        _safeMint(to, tokenId);
        string memory tokenIdString = Strings.toString(tokenId);
        string memory newUri = string(abi.encodePacked(uri, tokenIdString));
        _setTokenURI(tokenId, newUri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //Overrides for opensea royalties
        function setApprovalForAll(address operator, bool approved) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
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