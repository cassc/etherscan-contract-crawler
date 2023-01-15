// SPDX-License-Identifier: MIT

/*
 (                                 _
   )                               /=>
  (  +____________________/\/\___ / /|
   .''._____________'._____      / /|/\
  : () :              :\ ----\|    \ )
   '..'______________.'0|----|      \
                    0_0/____/        \
                        |----    /----\
                       || -\\ --|      \
                       ||   || ||\      \
                        \\____// '|      \
Bang! Bang!                     .'/       |
                               .:/        |
                               :/_________|
             __  __  __            __                     
           /  |/  |/  |          /  |                    
 __     __ $$/ $$ |$$ |  ______  $$/  _______   ________ 
/  \   /  |/  |$$ |$$ | /      \ /  |/       \ /        |
$$  \ /$$/ $$ |$$ |$$ | $$$$$$  |$$ |$$$$$$$  |$$$$$$$$/ 
 $$  /$$/  $$ |$$ |$$ | /    $$ |$$ |$$ |  $$ |  /  $$/  
  $$ $$/   $$ |$$ |$$ |/$$$$$$$ |$$ |$$ |  $$ | /$$$$/__ 
   $$$/    $$ |$$ |$$ |$$    $$ |$$ |$$ |  $$ |/$$      |
    $/     $$/ $$/ $$/  $$$$$$$/ $$/ $$/   $$/ $$$$$$$$/  

@title Villainz Optimized Minting Contract.
You either die a hero... or you live long enough to see yourself become the villain.                                      
*/

pragma solidity 0.8.17;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

contract Villainz is 
    ERC721A, 
    Ownable, 
    OperatorFilterer, 
    ERC2981, 
    ReentrancyGuard {

    // =============================================================
    //                            STORAGE
    // =============================================================

    uint256 public maxSupply = 5555;
    uint256 public mintPrice = 0.0089 ether;
    uint256 public maxPerWallet = 10;

    bool public saleActive;
    bool public operatorFilteringEnabled;

    string public baseURI;

    modifier StockCount(uint256 _amount) {
        if (_amount + totalSupply() > maxSupply) revert SoldOut();
        _;
    }

    // =============================================================
    //                            ERRORS
    // =============================================================

    error SaleNotActive();
    error SoldOut();
    error NotEOA();
    error IncorrectAmountOfEth();
    error ExceedsMaxPerWallet();
    error WithdrawFailed();


    // =============================================================
    //                          INITIALIZER
    // =============================================================

    constructor() ERC721A("Villainz", "VIL") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        _setDefaultRoyalty(msg.sender, 420);
    }

    // =============================================================
    //                          MINTING
    // =============================================================


    function mintVillainz(uint256 _amount) external payable StockCount(_amount) nonReentrant {
        if (!saleActive) revert SaleNotActive();
        if (tx.origin != msg.sender) revert NotEOA();
        if (msg.value != _amount * mintPrice) revert IncorrectAmountOfEth();
        if (_numberMinted(msg.sender) + _amount > maxPerWallet) revert ExceedsMaxPerWallet();

        _mint(msg.sender, _amount);
    }

    function teamMint(uint256 _amount, address _recipient) external StockCount(_amount) onlyOwner {
        _mint(_recipient, _amount);
    }

    // =============================================================
    //                          ADMIN
    // =============================================================

    function setBaseURI(string calldata _URI) external onlyOwner {
        baseURI = _URI;
    }

    function changeMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setSaleState() external onlyOwner {
        saleActive = !saleActive;
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    // =============================================================
    //                          OVERRIDES
    // =============================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721A, ERC2981)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId)
            || ERC2981.supportsInterface(interfaceId);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}