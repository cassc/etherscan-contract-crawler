// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC721AUpgradeable, ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {ERC721AQueryableUpgradeable} from
    "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC2981Upgradeable, ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "closedsea/src/OperatorFilterer.sol";

/// @title NastyNFT
/// @author aceplxx (https://twitter.com/aceplxx)

enum SaleState {
    Paused,
    Presale,
    Public
}

contract NastyNFT is
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable,
    OperatorFilterer,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    UUPSUpgradeable
{
    
    SaleState public saleState;

    string public baseURI;

    uint256 public maxPerTx;
    uint256 public constant MAX_SUPPLY = 3838;
    uint256 public constant TEAM_RESERVES = 138;

    uint256 public price;

    bool public notRevealed;
    bool public operatorFilteringEnabled;

    bytes32 public presaleRoot;

    error SaleNotActive();

    function initialize(
        string memory _name,
        string memory _ticker
    ) public initializerERC721A initializer {
        __ERC721A_init(_name,_ticker);
        __Ownable_init();
        __ERC2981_init();

        notRevealed = true;
        maxPerTx = 5;
        price = 0.03 ether;

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setPresaleRoot(bytes32 _root) public onlyOwner {
        presaleRoot = _root;
    }

    function setSaleState(SaleState state) public onlyOwner {
        saleState = state;
    }

    function setMintConfig(uint256 _price, uint256 _maxPerTx) public onlyOwner {
        price = _price;
        maxPerTx = _maxPerTx;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function _isWhitelisted(bytes32[] calldata _merkleProof, address _address) internal view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        bool whitelisted;
        whitelisted = MerkleProofUpgradeable.verify(
            _merkleProof,
            presaleRoot,
            leaf
        );
        return whitelisted;
    }

    function numberMinted(address user) external view returns (uint256){
        return _numberMinted(user);
    }

    function presaleMint(uint256 quantity, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(quantity <= maxPerTx, "NN: Too much");
        require(totalSupply() + quantity <= MAX_SUPPLY, "NN: Insufficient supply");
        require(msg.value == price * quantity, "NN: Price incorrect");

        bool eligible = true;
        if (saleState == SaleState.Presale) {
            eligible = _isWhitelisted(_merkleProof, _msgSender());
        } else {
            revert SaleNotActive();
        }

        require(eligible, "NN: Cannot mint");

        _mint(_msgSender(), quantity);
    }

    function publicMint(uint256 quantity) external payable {
        require(saleState == SaleState.Public, "NN: Public inactive");
        require(_numberMinted(_msgSender()) + quantity <= maxPerTx, "NN: Mint too much");
        require(totalSupply() + quantity <= MAX_SUPPLY, "NN: Insufficient supply");
        require(msg.value >= price * quantity, "NN: Price incorrect");

        _mint(_msgSender(), quantity);
    }

    function airdrop(address[] calldata users, uint256[] calldata qty) external onlyOwner {
        require(users.length == qty.length, "missmatch input");
        for(uint256 i = 0; i < users.length; i++){
            require(totalSupply() + qty[i] <= MAX_SUPPLY, "NN: Insufficient supply");
            _mint(users[i], qty[i]);
        }
    }

    function airdropFromContract(address user, uint256[] calldata tokenIds) external onlyOwner {
        for(uint256 i = 0; i < tokenIds.length; i++){
            IERC721AUpgradeable(address(this)).transferFrom(
                address(this),
                user,
                tokenIds[i]
            );
        }
    }

    function fpxMint(address receiver, uint256 quantity) public onlyOwner {
        require(quantity <= maxPerTx, "NN: Too much");
        require(totalSupply() + quantity <= MAX_SUPPLY, "NN: Insufficient supply");
        _mint(receiver, quantity);
    }

    function mintReserve() public onlyOwner {
        _mint(_msgSender(), 275);
    }

    //ERC721A function overrides for operator filtering to enable OpenSea creator royalities.

    function setApprovalForAll(address operator, bool approved)
        public
        override (IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC721AUpgradeable, ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721AUpgradeable.supportsInterface(interfaceId)
            || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function withdraw() public onlyOwner {
        bool success;
        (success, ) = payable(_msgSender()).call{
            value: address(this).balance
        }("");
        require(success, "failed");
    }
}