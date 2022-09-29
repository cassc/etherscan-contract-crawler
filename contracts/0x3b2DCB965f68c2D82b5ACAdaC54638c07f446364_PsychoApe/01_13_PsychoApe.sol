// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721A.sol";

/*

██████╗ ███████╗██╗   ██╗ ██████╗██╗  ██╗ ██████╗  █████╗ ██████╗ ███████╗
██╔══██╗██╔════╝╚██╗ ██╔╝██╔════╝██║  ██║██╔═══██╗██╔══██╗██╔══██╗██╔════╝
██████╔╝███████╗ ╚████╔╝ ██║     ███████║██║   ██║███████║██████╔╝█████╗  
██╔═══╝ ╚════██║  ╚██╔╝  ██║     ██╔══██║██║   ██║██╔══██║██╔═══╝ ██╔══╝  
██║     ███████║   ██║   ╚██████╗██║  ██║╚██████╔╝██║  ██║██║     ███████╗
╚═╝     ╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚══════╝
                                                                          
*/
contract PsychoApe is ERC2981, ERC721A, Ownable {
    using Strings for uint256;

    uint32 public constant MAX_SUPPLY = 5000;
    uint32 public constant FREE_SUPPLY = 500;
    uint32 public constant TEAM_SUPPLY = 300;

    uint32 public _publicLimitPerWallet = 5;
    uint32 public _freeLimitPerWallet = 1;
    uint32 public _freeMintTotal;
    uint32 public _teamMintTotal;
    bool public _publicMintActive;
    bool public _freeMintActive;
    uint256 public _price = 0.005 ether;

    string public _prerevealURI;
    string public _matadataURI;

    constructor() ERC721A("PsychoApe", "PAPE") {
        _setDefaultRoyalty(msg.sender, 500);
    }

    // Modifiers

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Contract caller forbidden");
        _;
    }

    modifier supplyCompliance(uint32 amount) {
        require(_totalMinted() + amount <= MAX_SUPPLY, "Exceed max supply");
        _;
    }

    modifier publicCompliance(uint32 amount) {
        require(_publicMintActive, "Public mint is inactive");
        require(msg.value == _price * amount, "Value error");
        require(
            _numberMinted(msg.sender) + amount - _getAux(msg.sender) <=
                _publicLimitPerWallet,
            "Exceed public mint limit per wallet"
        );
        _;
    }

    modifier freeCompliance(uint32 amount) {
        require(_freeMintActive, "Free mint is inactive");
        require(_freeMintTotal < FREE_SUPPLY, "Exceed free supply");
        require(
            _getAux(msg.sender) + amount <= _freeLimitPerWallet,
            "Exceed free mint limit per wallet"
        );
        _;
    }

    modifier teamCompliance(uint32 amount) {
        require(_teamMintTotal + amount <= TEAM_SUPPLY, "Exceed team supply");
        _;
    }

    // Public Read

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _matadataURI;
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : _prerevealURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function numberFreeMinted(address owner) public view returns (uint256) {
        return _getAux(owner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Public Write

    function mint(uint32 amount)
        external
        payable
        supplyCompliance(amount)
        publicCompliance(amount)
        callerIsUser
    {
        _mint(msg.sender, amount, "", false);
    }

    function freeMint(uint32 amount)
        external
        supplyCompliance(amount)
        freeCompliance(amount)
        callerIsUser
    {
        _setAux(msg.sender, _getAux(msg.sender) + amount);
        _freeMintTotal += amount;

        _mint(msg.sender, amount, "", false);
    }

    // Only Owner

    function devMint(uint32 amount, address to)
        external
        supplyCompliance(amount)
        teamCompliance(amount)
        onlyOwner
    {
        _teamMintTotal += amount;

        _mint(to, amount, "", false);
    }

    function setPublicLimitPerWallet(uint32 publicLimitPerWallet) external onlyOwner {
        _publicLimitPerWallet = publicLimitPerWallet;
    }

    function setFreeLimitPerWallet(uint32 freeLimitPerWallet) external onlyOwner {
        _freeLimitPerWallet = freeLimitPerWallet;
    }

    function flipPublicMintActive() external onlyOwner {
        _publicMintActive = !_publicMintActive;
    }

    function flipFreeMintActive() external onlyOwner {
        _freeMintActive = !_freeMintActive;
    }

    function setPrerevealURI(string calldata prerevealURI) external onlyOwner {
        _prerevealURI = prerevealURI;
    }

    function setMetadataURI(string calldata metadataURI) external onlyOwner {
        _matadataURI = metadataURI;
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    function setFeeNumerator(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdraw(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}