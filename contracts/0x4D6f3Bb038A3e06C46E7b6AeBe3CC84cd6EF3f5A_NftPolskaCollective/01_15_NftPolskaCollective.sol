// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "closedsea/src/OperatorFilterer.sol";

/////////////////////////////////////////////////////////
//   _  _ ___ _____   ___  ___  _    ___ _  __   _     //
//  | \| | __|_   _| | _ \/ _ \| |  / __| |/ /  /_\    //
//  | .` | _|  | |   |  _/ (_) | |__\__ \ ' <  / _ \   //
//  |_|\_|_|_  |_|  _|_| _\___/|____|___/_|\_\/_/_\_\  //
//   / __/ _ \| |  | |  | __/ __|_   _|_ _\ \ / / __|  //
//  | (_| (_) | |__| |__| _| (__  | |  | | \ V /| _|   //
//   \___\___/|____|____|___\___| |_| |___| \_/ |___|  //
//                                                     //
/////////////////////////////////////////////////////////

contract NftPolskaCollective is
    ERC721AQueryable,
    OperatorFilterer,
    ERC2981,
    Ownable
{
    uint256 public immutable maxSupply;
    uint256 public mintSupply;
    uint256 public price;
    uint256 public maxMintAmount;
    uint256 public mintStart;
    uint256 public mintEnd;
    bool public isWhiteListActive;
    bool public operatorFilteringEnabled;
    bytes32 public merkleRoot;
    mapping(address => uint256) public tokenMinted;

    string private baseTokenUri;

    constructor(
        string memory _baseUri,
        uint256 _maxSupply,
        uint256 _mintSupply,
        address _owner,
        address payable _royaltiesReceiver,
        uint256 _mintStart,
        uint256 _mintEnd
    ) ERC721A("NFT Polska Collective", "NPC") {
        transferOwnership(_owner);
        setRoyaltyInfo(_royaltiesReceiver, 750);
        _registerForOperatorFiltering();
        baseTokenUri = _baseUri;
        maxSupply = _maxSupply;
        mintSupply = _mintSupply;
        mintStart = _mintStart;
        mintEnd = _mintEnd;
        maxMintAmount = 1;
        price = .286 ether;
        isWhiteListActive = true;
        operatorFilteringEnabled = true;
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

    function setWhiteListActive(bool _isWhiteListActive) external onlyOwner {
        isWhiteListActive = _isWhiteListActive;
    }

    function setMintStart(uint256 _mintStart) external onlyOwner {
        mintStart = _mintStart;
    }

    function setMintEnd(uint256 _mintEnd) external onlyOwner {
        mintEnd = _mintEnd;
    }

    function setMintSupply(uint256 _mintSupply) external onlyOwner {
        require(_mintSupply <= maxSupply, "Max supply exceeded");
        mintSupply = _mintSupply;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    function mint(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(block.timestamp >= mintStart, "Mint not started");
        require(block.timestamp <= mintEnd, "Mint is over");
        require(msg.value == price * _amount, "Incorrect eth amount");
        require(
            tokenMinted[msg.sender] + _amount <= maxMintAmount,
            "Attempting to mint too many tokens"
        );
        require(totalSupply() + _amount <= mintSupply, "Mint supply exceeded");

        if (isWhiteListActive) {
            bytes32 node = keccak256(abi.encodePacked(msg.sender, _amount));
            require(
                MerkleProof.verify(_merkleProof, merkleRoot, node),
                "You are not whitelisted"
            );
        }

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