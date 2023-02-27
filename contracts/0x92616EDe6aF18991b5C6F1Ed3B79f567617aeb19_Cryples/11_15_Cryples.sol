//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

error Paused();
error SoldOut();
error SaleNotStarted();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error MintedOut();
error MaxMints();

contract Cryples is ERC721AQueryable, Ownable,    OperatorFilterer, ERC2981 {


    uint publicMintPrice = .0069 ether;
    uint public constant MAX_SUPPLY = 3333;
    uint public maxMintsPerWallet = 4;
    bool publicOn;
    bool public operatorFilteringEnabled;
    string public baseURI = "ipfs://QmaKnWZVPLAmGhZ1DWQZ2Tka93yaqEjmXQR4H17X6EcEn7/";
    string public baseExtension = ".json";
    constructor() ERC721A("Cryples", "PP") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 750);
        // _min
    }

    function _startTokenId() internal pure override returns (uint) {
        return 1;
    }
    function airdrop(address[] calldata to, uint[] calldata amount) external onlyOwner{
        uint _totalSupply = totalSupply();
        for(uint i = 0; i < to.length; i++) {
            if(_totalSupply + amount[i] > MAX_SUPPLY) revert SoldOut();
            _totalSupply += amount[i];
            _mint(to[i], amount[i]);
        }
    }

    function mint(uint amount) external payable {
        if(!publicOn) revert SaleNotStarted();
        uint numPublicMints = _numberMinted(_msgSender());
        if(numPublicMints + amount > maxMintsPerWallet) revert MintingTooMany();
        if(amount + totalSupply() > MAX_SUPPLY) revert SoldOut();
        if(msg.value < amount * publicMintPrice) revert Underpriced();
        _mint(_msgSender(), amount);
    }


    //SETTERS

    function setMaxMintsPerWallet(uint _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setPublicOn(bool _publicOn) external onlyOwner {
        publicOn = _publicOn;
    }

    function setPublicPrice (uint _publicMintPrice) external onlyOwner {
        publicMintPrice = _publicMintPrice;
    }

    function getNumPublicMints(address _address) external view returns (uint) {
        return _numberMinted(_address);
    }



    function setBaseURI(string calldata __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    function setBaseExtension(string calldata __baseExtension) external onlyOwner {
        baseExtension = __baseExtension;
    }



    function tokenURI(uint256 tokenId) public view  override(IERC721A,ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _toString(tokenId), baseExtension));
    }
    //-----------CLOSEDSEA----------------
    function setApprovalForAll(address operator, bool approved)
        public
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
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
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }



}