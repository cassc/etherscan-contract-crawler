// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {DefaultOperatorFilterer} from "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Pausable} from "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

/**
    @title  Ordinalist by Funerals
    @author curion, opensea, openzeppelin
        -1000 => 500 reserved for pendings holders, 500+remainder public mint
    @notice methods: 2 pendings == 1 ordinalist, burn 6 transactions == 1 ordinalist. public mint remaining supply
 */
contract PENDINGS_BTM is ERC721, DefaultOperatorFilterer, Ownable {
    using Strings for uint256;

    address public paymentSplitterAddress;
    address public pendingsAddress;
    address public transactionsAddress;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    bool public publicMintIsOpen = false;
    bool public burnTransactionsMintIsOpen = false;
    bool public pendingsHolderClaimIsOpen = false;

    string private baseURI;

    /// @notice collection-specific params
    uint256 public amountMinted = 0;
    uint256 public totalSupply = 1000;
    uint256 public mintPrice = 0.069 ether;
    uint256 public mintLimitPerTxnAndWallet = 5;
    uint256 public pendingsRequiredForClaim = 2;
    uint256 public transactionsToBurnForFreeToken = 6;
    uint256 public burnedTransactionCount = 0;
    
    uint256 public publicAmountMinted = 0;
    uint256 public holderAmountMinted = 0;
    uint256 public reservedForHoldersAmount = 500;

    mapping (address => uint256) public mintedByAddress;
    mapping (uint256 => bool) public pendingsIdUsedForClaim;

    error MaxSupplyReached();
    error MaxSupplyWillBeReached();
    error ForwardFailed();
    error QueryForNonexistentToken();
    error InsufficientFunds();
    error PublicConditionsNotMet();
    error PendingsTokenAlreadyUsedForClaim();
    error MintIsClosed();
    error MathError();
    error NotTokenOwner();
    error InvalidNumberOfPendingsUsedForClaim();
    error InvalidNumberOfTransactionsToBeBurned();

    constructor() ERC721("Ordinalist", "ORD") {}

    // fallback payable functions for anything sent to contract not via mint functions
    receive() external payable {} //msg.data must be empty
    fallback() external payable {} //when msg.data is not empty

    //=========================================================================
    // MINTING
    //=========================================================================

    modifier publicMintChecks(uint256 _amount) {
        if(!publicMintIsOpen && msg.sender != owner()) { revert MintIsClosed(); }
        if(_amount == 0) { revert PublicConditionsNotMet(); }
        if(msg.value < mintPrice * _amount) { revert InsufficientFunds(); }
        if(mintedByAddress[msg.sender] + _amount > mintLimitPerTxnAndWallet) { revert PublicConditionsNotMet(); }
        if(publicAmountMinted + _amount > totalSupply - reservedForHoldersAmount) { revert MaxSupplyWillBeReached(); }
        _;        
    }

    modifier totalSupplyChecks(uint256 _amount) {
        if(_amount == 0) { revert MathError(); }
        if(amountMinted >= totalSupply) { revert MaxSupplyReached(); }
        if(amountMinted + _amount > totalSupply) { revert MaxSupplyWillBeReached(); }
        _;
    }

    function mintPublic(uint256 _amount) 
        external 
        payable 
        publicMintChecks(_amount) 
        totalSupplyChecks(_amount) 
    {
        
        mintedByAddress[msg.sender] += _amount;
        
        for(uint256 i = 0; i < _amount; ++i){
            ++amountMinted;
            ++publicAmountMinted;
            _safeMint(msg.sender, amountMinted);
        }

    }

    /// @notice owners of 2 pendings can claim 1 token

    function pendingsHolderClaim(uint256[] memory _pendingsIds) 
        external   
        totalSupplyChecks(_pendingsIds.length/pendingsRequiredForClaim)
    {
        if(!pendingsHolderClaimIsOpen) { revert MintIsClosed(); }
        if(_pendingsIds.length % pendingsRequiredForClaim != 0) { revert InvalidNumberOfPendingsUsedForClaim(); }
        if(_pendingsIds.length < pendingsRequiredForClaim) { revert InvalidNumberOfPendingsUsedForClaim(); }
        if(_pendingsIds.length/pendingsRequiredForClaim + holderAmountMinted > reservedForHoldersAmount) { revert MaxSupplyWillBeReached(); }

        address sender = msg.sender;
        uint256 thisPendingId;
        holderAmountMinted += _pendingsIds.length/pendingsRequiredForClaim;

        for(uint256 i = 0; i < _pendingsIds.length; ++i){
            thisPendingId = _pendingsIds[i];
            if(IERC721(pendingsAddress).ownerOf(thisPendingId)!=sender){ revert NotTokenOwner(); }
            if(pendingsIdUsedForClaim[thisPendingId]){ revert PendingsTokenAlreadyUsedForClaim(); }
            pendingsIdUsedForClaim[thisPendingId] = true;
        }

        for(uint256 i = 0; i < _pendingsIds.length/pendingsRequiredForClaim; ++i){
            ++amountMinted;
            _safeMint(sender, amountMinted);
        }

    }

    /// @notice must burn N%6 transactions to mint 1 token, i.e. burn 12 get 2.

    function burnToClaim(uint256[] memory _transactionIds) 
        external 
        totalSupplyChecks(_transactionIds.length/transactionsToBurnForFreeToken) 
    {
        if(!burnTransactionsMintIsOpen) { revert MintIsClosed(); }

        //must burn the exact amount of transactions to free drop
        if(_transactionIds.length % transactionsToBurnForFreeToken != 0) { revert InvalidNumberOfTransactionsToBeBurned(); }
        if(_transactionIds.length < transactionsToBurnForFreeToken) { revert InvalidNumberOfTransactionsToBeBurned(); }
        if(_transactionIds.length/transactionsToBurnForFreeToken + holderAmountMinted > reservedForHoldersAmount) { revert MaxSupplyWillBeReached(); }

        address sender = msg.sender;
        uint256 thisTransactionId;

        for(uint256 i=0; i<_transactionIds.length; ++i){
            thisTransactionId = _transactionIds[i];
            if(ERC721(transactionsAddress).ownerOf(thisTransactionId) != sender) { revert NotTokenOwner(); }
            ERC721(transactionsAddress).transferFrom(sender, deadAddress, thisTransactionId);
        }

        holderAmountMinted += _transactionIds.length/transactionsToBurnForFreeToken;
        burnedTransactionCount += _transactionIds.length;       

        for(uint256 i=0; i<_transactionIds.length/transactionsToBurnForFreeToken; ++i){
            ++amountMinted;
            _safeMint(sender, amountMinted);
        }
    }

    /// @notice "burning" remaining supply reduce it beyond the originally planned supply
    function reduceMaxSupply(uint256 _amount) external onlyOwner {
        if(totalSupply-_amount < amountMinted) { revert MathError(); }
        totalSupply -= _amount;
    }

    function burn(uint256 tokenId) external {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    //=========================================================================
    // SETTERS
    //=========================================================================

    function setreservedForHoldersAmount(uint256 _reservedForHoldersAmount) external onlyOwner {
        reservedForHoldersAmount = _reservedForHoldersAmount;
    }
    
    function setPublicMintIsOpen(bool _publicMintIsOpen) external onlyOwner {
        publicMintIsOpen = _publicMintIsOpen;
    }

    function setBurnTransactionsMintIsOpen(bool _burnTransactionsMintIsOpen) external onlyOwner {
        burnTransactionsMintIsOpen = _burnTransactionsMintIsOpen;
    }

    function setPendingsHolderClaimIsOpen(bool _pendingsHolderClaimIsOpen) external onlyOwner {
        pendingsHolderClaimIsOpen = _pendingsHolderClaimIsOpen;
    }

    function setNumberOfTransactionsToBurn(uint256 _transactionsToBurnForFreeToken) external onlyOwner {
        transactionsToBurnForFreeToken = _transactionsToBurnForFreeToken;
    }

    function setMaxMintsPerWallet(uint256 _mintLimitPerTxnAndWallet) external onlyOwner {
        mintLimitPerTxnAndWallet = _mintLimitPerTxnAndWallet;
    }
    
    function setPaymentSplitterAddress(address payable _paymentSplitterAddress) external onlyOwner {
        require(_paymentSplitterAddress != address(0));
        paymentSplitterAddress = payable(_paymentSplitterAddress);
    }

    function setPendingsAddress(address _pendingsAddress) external onlyOwner {
        pendingsAddress = _pendingsAddress;
    }
    
    function setTransactionsAddress(address _transactionsAddress) external onlyOwner {
        transactionsAddress = _transactionsAddress;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setHolderClaimAmounts(uint256 _pendingsRequiredForClaim, uint256 _transactionsToBurnForFreeToken) external onlyOwner {
        pendingsRequiredForClaim = _pendingsRequiredForClaim;
        transactionsToBurnForFreeToken = _transactionsToBurnForFreeToken;
    }

    /// @notice in the case that one burn address doesnt work - just covering bases, but want to make sure the address cant be a non-burn address
    function toggleDeadAddress() external onlyOwner {
        if(deadAddress == address(0)) {
            deadAddress = 0x000000000000000000000000000000000000dEaD;
        } else {
            deadAddress = address(0);
        }
    }

    //=========================================================================
    // GETTERS
    //=========================================================================

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if( !_exists(tokenId) ) { revert QueryForNonexistentToken(); }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function uri(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

    function getTotalMintedSoFar() external view returns (uint256) {
        return amountMinted;
    }

    function getBurnedTransactionCount() external view returns (uint256) {
        return burnedTransactionCount;
    }

    //=========================================================================
    // WITHDRAWALS
    //=========================================================================

    function withdrawERC20FromContract(address _to, address _token) external onlyOwner {
        bool os = IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
        if(!os){ revert ForwardFailed(); }
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