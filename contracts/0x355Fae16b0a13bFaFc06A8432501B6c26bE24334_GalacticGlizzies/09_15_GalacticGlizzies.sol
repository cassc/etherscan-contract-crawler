// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "closedsea/src/OperatorFilterer.sol";

//   _____       _            _   _         _____ _ _         _
//  / ____|     | |          | | (_)       / ____| (_)       (_)
// | |  __  __ _| | __ _  ___| |_ _  ___  | |  __| |_ _________  ___  ___
// | | |_ |/ _` | |/ _` |/ __| __| |/ __| | | |_ | | |_  /_  / |/ _ \/ __|
// | |__| | (_| | | (_| | (__| |_| | (__  | |__| | | |/ / / /| |  __/\__ \
//  \_____|\__,_|_|\__,_|\___|\__|_|\___|  \_____|_|_/___/___|_|\___||___/

contract GalacticGlizzies is
    ERC721AQueryable,
    ERC721ABurnable,
    OperatorFilterer,
    Ownable,
    ERC2981
{
    error IncorrectAmountError();
    error IncorrectSaleStageError();
    error ExceedsMaxSupplyError();
    error ExceedsWalletSupplyError();
    error InvalidProofError();

    uint256 public constant MAX_SUPPLY_OG = 1050;
    uint256 public constant MAX_SUPPLY_TOTAL = 6666;

    uint256 public constant MAX_MINTS_OG = 10;
    uint256 public constant MAX_MINTS_TOTAL = 20;

    uint256 public ogPrice = 0.005 ether;
    uint256 public price = 0.00666 ether;

    bytes32 public merkleRoot;

    string public hiddenURI;
    string public baseURI;

    bool public operatorFilteringEnabled;

    enum SaleStage {
        Closed,
        OG,
        Public
    }
    SaleStage public saleStage = SaleStage.Closed;

    constructor(
        bytes32 _merkleRoot,
        string memory _hiddenURI,
        address payable royaltiesReceiver)
        ERC721A("Galactic Glizzies", "GLIZZ")
    {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        merkleRoot = _merkleRoot;
        hiddenURI = _hiddenURI;

        _setDefaultRoyalty(royaltiesReceiver, 1000);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                      Modifiers                                      #
    // #                                                                                     #
    // #######################################################################################

    modifier verifyAmount(uint256 _amount, uint256 _price) {
        if (msg.value != _amount * _price) revert IncorrectAmountError();
        _;
    }

    modifier verifyAvailableSupply(uint256 amount, uint256 max) {
        if (totalSupply() + amount > max) revert ExceedsMaxSupplyError();
        _;
    }

    modifier verifyWalletSupply(uint256 amount, uint256 max) {
        if (_numberMinted(msg.sender) + amount > max)
            revert ExceedsWalletSupplyError();
        _;
    }

    modifier verifySaleStage(SaleStage requiredState) {
        if (saleStage != requiredState) revert IncorrectSaleStageError();
        _;
    }

    modifier verifyProof(bytes32[] calldata _merkleProof) {
        bytes32 leaf = keccak256(abi.encode(msg.sender));
        if (!MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf))
            revert InvalidProofError();
        _;
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                      Accessors                                      #
    // #                                                                                     #
    // #######################################################################################

    function setHiddenURI(string memory uri) external onlyOwner {
        hiddenURI = uri;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setOgPrice(uint256 _ogPrice) external onlyOwner {
        ogPrice = _ogPrice;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setSaleStage(SaleStage _SaleStage) external onlyOwner {
        saleStage = _SaleStage;
    }

    function withdraw(address payable _to, uint256 amount) external onlyOwner {
        if (address(this).balance < amount || amount == 0) revert IncorrectAmountError();

        _to.transfer(amount);
    }

    function withdrawAll(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       Minting                                       #
    // #                                                                                     #
    // #######################################################################################

    function getMints(address _minter) public view returns (uint256) {
        return _numberMinted(_minter);
    }

    function mintOG(bytes32[] calldata _merkleProof, uint256 _amount)
        external
        payable
        verifySaleStage(SaleStage.OG)
        verifyProof(_merkleProof)
        verifyAmount(_amount, ogPrice)
        verifyWalletSupply(_amount, MAX_MINTS_OG)
        verifyAvailableSupply(_amount, MAX_SUPPLY_OG)
    {
        _mint(msg.sender, _amount);
    }

    function mintPublic(uint256 _amount)
        external
        payable
        verifySaleStage(SaleStage.Public)
        verifyAmount(_amount, price)
        verifyWalletSupply(_amount, MAX_MINTS_TOTAL)
        verifyAvailableSupply(_amount, MAX_SUPPLY_TOTAL)
    {
        _mint(msg.sender, _amount);
    }

    function mintOwner(address _to, uint256 _amount)
        external
        onlyOwner
        verifyAvailableSupply(_amount, MAX_SUPPLY_TOTAL)
    {
        _mint(_to, _amount);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                  OperatorFilterer                                   #
    // #                                                                                     #
    // #######################################################################################

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       ERC2981                                       #
    // #                                                                                     #
    // #######################################################################################

    function setDefaultRoyalty(address payable receiver, uint96 numerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, numerator);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       ERC721A                                       #
    // #                                                                                     #
    // #######################################################################################

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory uri = _baseURI();
        return bytes(uri).length != 0 ? string(abi.encodePacked(uri, _toString(tokenId))) : hiddenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       ERC165                                        #
    // #                                                                                     #
    // #######################################################################################

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
}