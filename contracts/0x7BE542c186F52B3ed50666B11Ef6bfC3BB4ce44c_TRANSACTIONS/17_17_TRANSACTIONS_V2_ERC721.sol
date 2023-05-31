// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {DefaultOperatorFilterer} from "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Pausable} from "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

/**
 
 @title  Transactions
 @author curion, opensea, openzeppelin
 [ ] 0.05 / mint
 [ ] max 3 per wallet public, public opens after airdrop
 [ ] ERC721
 [ ] 6% creator royalties
 [ ] No Blur Access (DefaultOperatorFilterer)
 * 
 */
contract TRANSACTIONS is ERC721, DefaultOperatorFilterer, Ownable {
    using Strings for uint256;

    address public paymentSplitterAddress;
    
    bool public pendingsHolderAirdropMintComplete = false;
    bool public mintIsOpen = false;
    bool public revealed = false;

    string private baseURI;
    string private unrevealedBaseURI; 

    uint256 public amountMinted = 0;
    uint256 public pendingsSupply = 998;
    uint256 public nominalMaxSupply = 2000;
    uint256 public blurMaxSupply = 9;
    uint256 public mintPrice = 0.05 ether;
    uint256 public mintLimitPerTxnAndWallet = 3;

    uint256 public displayAmountMinted = 0; //for website

    uint256 public totalSupply = 2009; // 2000 + 9 blur -- etherscan display

    mapping (address => uint256) public mintedByAddress;

    error MaxSupplyReached();
    error MaxSupplyWillBeReached();
    error ForwardFailed();
    error QueryForNonexistentToken();
    error InsufficientFunds();
    error PublicConditionsNotMet();
    error MintIsClosed();
    error MathError();

    constructor() ERC721("Transactions", "TXN") {}

    //=========================================================================
    // MINTING
    //=========================================================================

    // if mint is closed, no mint
    // if the max supply has been reached, no mint
    // if the max supply will be surpassed with the requested quantity, no mint
    // if the msg.value is insufficient, no mint
    // mint the requested quantity
    function mintPublic(uint256 _amount) public payable {
        
        if(!mintIsOpen && msg.sender != owner()) { revert MintIsClosed(); }

        if(_amount == 0) { revert PublicConditionsNotMet(); }

        if(amountMinted + pendingsSupply >= nominalMaxSupply) { revert MaxSupplyReached(); }

        if(amountMinted + _amount + pendingsSupply > nominalMaxSupply) { revert MaxSupplyWillBeReached(); }
        
        if(msg.value < mintPrice * _amount) { revert InsufficientFunds(); }
        
        if(mintedByAddress[msg.sender] + _amount > mintLimitPerTxnAndWallet) { revert PublicConditionsNotMet(); }
        
        mintedByAddress[msg.sender] += _amount;
        
        for(uint256 i = 0; i < _amount; i++){
            _safeMint(msg.sender, pendingsSupply + amountMinted + 1);
            amountMinted++;
            displayAmountMinted++;
        }

    }

    // fallback payable functions for anything sent to contract not via mint functions
    receive() external payable {} //msg.data must be empty
    fallback() external payable {} //when msg.data is not empty

    function airdropToBlurVictims(address[] memory _recipients) public onlyOwner {
        
        for(uint256 i = 0; i < blurMaxSupply; i++){
            _safeMint(_recipients[i], i+2001);
            displayAmountMinted++;
        }

    }

    function airdropToPendingsHolders(address[] memory _recipients, uint256[] memory _ids) public onlyOwner {
        
        if(_recipients.length != _ids.length) { revert MathError(); }

        for(uint256 i = 0; i < _recipients.length; i++){
            _safeMint(_recipients[i], _ids[i]);
            displayAmountMinted++;
        }

    }

    // admin backup emergency functions because this absolutely has to work lol
    function ZADMINFINISHPUBLIC() public onlyOwner {
        for(uint256 i=(pendingsSupply+amountMinted+1); i<=nominalMaxSupply; i++){
            _safeMint(msg.sender, i);
            amountMinted++;
            displayAmountMinted++;
        }

    }

    function ZADMINMINTIDTO(address _recipient, uint256 _id) public onlyOwner {
        _safeMint(_recipient, _id);
        displayAmountMinted++;
    }


    //=========================================================================
    // SETTERS
    //=========================================================================

    function setMintIsOpen(bool _mintIsOpen) public onlyOwner {
        mintIsOpen = _mintIsOpen;
    }
    
    function setPaymentSplitterAddress(address payable _paymentSplitterAddress) public onlyOwner {
        paymentSplitterAddress = payable(_paymentSplitterAddress);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setUnrevealedBaseURI(string memory _uri) public onlyOwner {
        unrevealedBaseURI = _uri;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    //=========================================================================
    // GETTERS
    //=========================================================================

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if( !_exists(tokenId) ) { revert QueryForNonexistentToken(); }
        if(revealed){
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
        } else {
            return bytes(unrevealedBaseURI).length > 0 ? string(abi.encodePacked(unrevealedBaseURI, tokenId.toString(), ".json")) : "";
        }
    }

    function uri(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

    function getTotalMintedSoFar() public view returns (uint256) {
        return displayAmountMinted;
    }

    //=========================================================================
    // WITHDRAWALS
    //=========================================================================

    function withdrawERC20FromContract(address _to, address _token) external onlyOwner {
        IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
    }

    function withdrawEthFromContract() external onlyOwner  {
        require(paymentSplitterAddress != address(0), "Payment splitter address not set");
        (bool os, ) = payable(paymentSplitterAddress).call{ value: address(this).balance }('');
        if(!os){ revert ForwardFailed(); }
    }

    //=========================================================================
    // OPENSEA-PROVIDED OVERRIDES for OPERATOR FILTER REGISTRY
    //=========================================================================

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}