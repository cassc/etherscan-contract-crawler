// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract TheLongbowAllegiance is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    ERC2981,
    DefaultOperatorFilterer
{
    string public baseURI;
    string public notRevealedUri;
    uint256 public cost = 0.012 ether;
    uint256 public maxSupply = 1337;
    uint256 public MaxperWallet = 2;
    uint256 public MaxperWalletWl = 2;
    bool public paused = true;
    bool public revealed = true;
    bool public preSale = false;
    bytes32 public merkleRoot;
    uint96 internal royaltyFraction = 500; // 100 = 1% , 1000 = 10%
    address internal royaltiesReciever =
        0xa734EA7d5c0f325F6290E539ce7D5F048754FBF7;

    constructor() ERC721A("The Longbow Allegiance", "LBA") {
        setRoyaltyInfo(royaltiesReciever, royaltyFraction);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // public
    /// @dev Public mint
    function mint(uint256 tokens) public payable nonReentrant {
        require(!paused, "ETH: oops contract is paused");
        require(!preSale, "ETH: Sale Hasn't started yet");
        require(tokens <= MaxperWallet, "ETH: max mint amount per tx exceeded");
        require(totalSupply() + tokens <= maxSupply, "ETH: We Soldout");
        require(
            _numberMinted(_msgSenderERC721A()) + tokens <= MaxperWallet,
            "ETH: Max NFT Per Wallet exceeded"
        );
        require(msg.value >= cost * tokens, "ETH: insufficient funds");

        _safeMint(_msgSenderERC721A(), tokens);
    }

    /// @dev presale mint for whitelisted
    function presalemint(uint256 tokens, bytes32[] calldata merkleProof)
        public
        payable
        nonReentrant
    {
        require(!paused, "ETH: oops contract is paused");
        require(preSale, "ETH: Presale Hasn't started yet");
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "ETH: You are not Whitelisted"
        );
        require(
            _numberMinted(_msgSenderERC721A()) + tokens <= MaxperWalletWl,
            "ETH: Max NFT Per Wallet exceeded"
        );
        require(tokens <= MaxperWalletWl, "ETH: max mint per Tx exceeded");
        require(
            totalSupply() + tokens <= maxSupply,
            "ETH: Whitelist MaxSupply exceeded"
        );
        require(msg.value >= cost * tokens, "ETH: insufficient funds");

        _safeMint(_msgSenderERC721A(), tokens);
    }

    /// @dev use it for giveaway and team mint
    function airdrop(uint256 _mintAmount, address destination)
        public
        onlyOwner
        nonReentrant
    {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "max NFT limit exceeded"
        );

        _safeMint(destination, _mintAmount);
    }

    /// @notice returns metadata link of tokenid
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /// @notice return the number minted by an address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /// @notice return the tokens owned by an address
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    //only owner
    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    /// @dev change the merkle root for the whitelist phase
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @dev change the public max per wallet
    function setMaxPerWallet(uint256 _limit) public onlyOwner {
        MaxperWallet = _limit;
    }

    /// @dev change the whitelist max per wallet
    function setWlMaxPerWallet(uint256 _limit) public onlyOwner {
        MaxperWalletWl = _limit;
    }

    /// @dev change the public price(amount need to be in wei)
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    /// @dev cut the supply if we dont sold out
    function setMaxsupply(uint256 _newsupply) public onlyOwner {
        maxSupply = _newsupply;
    }

    /// @dev set your baseuri
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @dev set hidden uri
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    /// @dev to pause and unpause your contract(use booleans true or false)
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    /// @dev activate whitelist sale(use booleans true or false)
    function togglepreSale(bool _state) external onlyOwner {
        preSale = _state;
    }

    // set royalties info

    function setRoyaltyTokens(
        uint256 _tokenId,
        address _receiver,
        uint96 _royaltyFeesInBips
    ) public onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _royaltyFeesInBips);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    /// @dev withdraw funds from contract
    function withdraw() public payable onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(0xa734EA7d5c0f325F6290E539ce7D5F048754FBF7).transfer(balance);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}