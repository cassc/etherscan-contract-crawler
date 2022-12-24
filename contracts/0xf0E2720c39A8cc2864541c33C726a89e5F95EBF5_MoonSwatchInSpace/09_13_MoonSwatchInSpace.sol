// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "closedsea/src/OperatorFilterer.sol";

contract MoonSwatchInSpace is ERC721AQueryable, OperatorFilterer, ERC2981, Ownable {
    uint256 public immutable maxSupply;
    uint256 public price;
    uint256 public winnerId;
    uint256 public maxMintAmount;
    string public provenanceHash;
    bool public isMintActive;
    bool public operatorFilteringEnabled;
    mapping(address => uint256) public tokenMinted;

    string private baseTokenUri;

    // Token metadata initially stored on centralized server to allow more flexibility.
    // Once all tokens are revealed, metadata will be uploaded to IPFS storage for longevity.
    constructor(
        string memory _baseUri,
        uint256 _maxSupply,
        address _owner,
        address payable _royaltiesReceiver
    ) ERC721A("MoonSwatch in Space", "MSIS") {
        setRoyaltyInfo(_royaltiesReceiver, 600);
        _registerForOperatorFiltering();
        transferOwnership(_owner);
        baseTokenUri = _baseUri;
        maxSupply = _maxSupply;
        price = .03 ether;
        maxMintAmount = 5;
    }

    modifier mintActive() {
        require(isMintActive, "Mint not active");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setMintActive(bool _isMintActive) external onlyOwner {
        isMintActive = _isMintActive;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setProvenanceHash(string calldata _provenanceHash)
        external
        onlyOwner
    {
        provenanceHash = _provenanceHash;
    }

    function setRandomWinner(uint256 maxIndex, uint256 externalRandom)
        external
        onlyOwner
    {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender,
                    externalRandom
                )
            )
        );
        winnerId = (random % maxIndex) + 1;
    }

    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    function mint(uint256 _amount) external payable mintActive {
        require(msg.value == price * _amount, "Incorrect eth amount");
        require(
            tokenMinted[msg.sender] + _amount <= maxMintAmount,
            "Attempting to mint too many tokens"
        );
        require(totalSupply() + _amount <= maxSupply, "Max supply exceeded");

        tokenMinted[msg.sender] += _amount;
        _mint(msg.sender, _amount);
    }

    function adminMint(address _recipient, uint256 _quantity)
        external
        onlyOwner
    {
        require(totalSupply() + _quantity <= maxSupply, "Max supply exceeded");
        _mint(_recipient, _quantity);
    }

    function setRoyaltyInfo(address payable receiver, uint96 numerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, numerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function withdraw(address payable destination) external onlyOwner {
        destination.transfer(address(this).balance);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return operatorFilteringEnabled;
    }
}