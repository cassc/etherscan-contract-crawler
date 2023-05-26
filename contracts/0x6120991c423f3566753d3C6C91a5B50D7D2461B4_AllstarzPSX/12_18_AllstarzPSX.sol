//
//              @@@@                                                                                       
//           @@@(@@@                                                                           @@@@        
//         @@@/((@@&@                                                                         &@(#@%#@     
//        @@%///(@@(#@&                                                                       @@((/@@./@   
//       @@@////((@@//@@                     @@@@@@@@@@@&@@@%%@@@@@&&&%%##@@@                @@#(///@@##@  
//       @@//////((@@*  @@/           @@@@@@@@((((((((((((((((((((((&@@@/(##%%%%@@          @@#(/////@,,,@ 
//       @@///////((@@@****@@(   *@@@@@((((((((///////////////(((((((((((((@@(      @@   [email protected]@@#(//////@. [email protected] 
//       @@@///////((#@@@@&&&&@@@@&(((((////////////////////////////////(((((((@@@@@@@@@@@@#((///////@[email protected] 
//        @@%////////(###@@@@@@((((@@@@@@@@&/////////////////////%@@@@@@@@@@@/((((@@@@@###((///////(@@//@@ 
//         @@@////////(((@@@#@@@@#///////////%@@@@((((((((((@@@@#/////////////@@@@(((@@@((////////(@@##@@  
//          @@@////////@@@(((/%@@@@@@@@@@@@&((((((@@#((((@@@(((((@@@@@@@@@@@@@@@//((((@@@///////(&@@/(@@   
//            @@@(///@@@(&@@@   @@@@@@@ @@@@@@@@@((((((((((((@@@@@@@@@ @@@@@@@#  @@@((((@@/((((@@@,,,@     
//              %@@@@@((#@@     @@       [email protected]@@@@  @@#((((((@@*  @@@@(     &@@@@@  [email protected]@@((((@@(@@@@@@@@.      
//                @@@((////@@@@ @@@@@@ @@@@@@@&  [email protected]@(((((@@@   @@@@@@@@ @@@@@@@@@@////(((@@@@@@@@@         
//               (@@((//////***@@@@@@@@@@@@@@@@@@(((((((((((@@@@@@@@@@@@@@@@@@////////((((@@@@&@           
//               @@((//**************/////(((((((((((((((((((((////*************///////(((@&&&&@           
//               @@(//****,,,,,,,,*****////(((((((@@@@@@%((((/////***,,,,,,,******////((((@%%%@@           
//               @@(/****,,,,,,,,,,,*****///(((((@@@@@@@@((((///****,,,,,,,,,,,*****//(((%@#((@            
//               @@(//****,,,,,,,,,,***////(((((((@@@@@@((((/////***,,,,,,,,,,,****///(((@/[email protected]#            
//               @@@(//****,*,,,,,,****///(((((((((((((((((((////*****,**,,,,,,***///(((@@,,@/             
//                @@(((/*************/////((((((((((((((((((((/////***************//(((@@%%@               
//                 @@(((///*******//////((((((((((((((((((((((((/////*/******/////(((#@(#@@                
//                  @@@((///////////////(((((@@(((((((((((@@(((((///////////////((((@@#@@                  
//                    @@%(((/////////////((((@@@((((((((%@@((((///////////////((((@#%@@                    
//                      @@@((((/////////////(((@@@@@@@@@@((////////////////((((@@@%@                       
//                        @@@#((((/////////////////////////////////////(((((@%@&@                          
//                           @@@@((((((///////////////////////////((((((@@@@@                              
//                               @@@@@((((((((((((((((((((((((((((&@@@@@.                                  
//                                     @@@@@@@@@%%((((%%@@@@@@@@@/                                         
//    

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "closedsea/src/OperatorFilterer.sol";

/**
 * @dev Minting contract for Allstarz PSX
 */
contract AllstarzPSX is ERC721AQueryable, ERC721ABurnable, OperatorFilterer, ReentrancyGuard, Ownable, ERC2981 {
    
    // Variables
    // ---------------------------------------------------------------

    bool public operatorFilteringEnabled;

    uint256 public immutable maxPerWalletAllowlist;
    uint256 public immutable maxPerWallet;

    uint256 public numFreeMint;
    uint256 public numAllowlistMint;
    bytes32 public merkleRootFreeMint;
    bytes32 public merkleRootAllowlist;

    bool public isFreeMintActive = false;
    bool public isAllowlistMintActive = false;
    bool public isMintActive = false;

    uint256 private collectionSize;
    uint256 private reservedFreeMint;
    uint256 private maxAllowlistMint;
    uint256 private allowlistMintPrice = 0.03 ether;
    uint256 private publicMintPrice = 0.05 ether;
    string private _baseTokenURI;

    // Helper functions
    // ---------------------------------------------------------------
    
    /**
     * @dev This function packs three uint16 values into a single uint64 value.
     * @param a: first uint16
     * @param b: second uint16
     * @param c: third uint16
     */
    function pack(uint16 a, uint16 b, uint16 c) internal pure returns (uint64) {
        return uint64(a) << 32 | uint64(b) << 16 | uint64(c);
    }

    /**
     * @dev This function unpacks a uint64 value into three uint16 values.
     * @param a: uint64 value
     */
    function unpack(uint64 a) internal pure returns (uint16, uint16, uint16) {
        return (uint16(a >> 32), uint16(a >> 16), uint16(a));
    }
    
    /**
     * @dev This function increases the number of free mints for an address
     * @param account: address to increase free mints for
     * @param quantity: number of free mints to increase by
     */

    function increaseFreeMints(address account, uint256 quantity) internal {
        (uint16 senderFreeMints, uint16 senderGifts, uint16 senderAllowlistMints) = unpack(_getAux(account));
        _setAux(account, pack(senderFreeMints + uint16(quantity), senderGifts, senderAllowlistMints));
    }

    /**
     * @dev This function increases the number of gifts for an address
     * @param account: address to increase gifts for
     * @param quantity: number of gifts to increase by
     */

    function increaseGifts(address account, uint256 quantity) internal {
        (uint16 senderFreeMints, uint16 senderGifts, uint16 senderAllowlistMints) = unpack(_getAux(account));
        _setAux(account, pack(senderFreeMints, senderGifts + uint16(quantity), senderAllowlistMints));
    }

    /**
     * @dev This function increases the number of allowlist mints for an address
     * @param account: address to increase allowlist mints for
     * @param quantity: number of allowlist mints to increase by
     */

    function increaseAllowlistMints(address account, uint256 quantity) internal {
        (uint16 senderFreeMints, uint16 senderGifts, uint16 senderAllowlistMints) = unpack(_getAux(account));
        _setAux(account, pack(senderFreeMints, senderGifts, senderAllowlistMints + uint16(quantity)));
    }

    // Modifiers
    // ---------------------------------------------------------------

    /** 
     * @dev This modifier ensures that the caller is a user and not a contract.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    /**
     * @dev This modifier ensures that free mint is open.
     */
    modifier freeMintActive() {
        require(isFreeMintActive, "Free mint is not open.");
        _;
    }

    /**
     * @dev This modifier ensures that allowlist mint is open.
     */
    modifier allowlistMintActive() {
        require(isAllowlistMintActive, "Allowlist mint is not open.");
        _;
    }

    /**
     * @dev This modifier ensures that public mint is open.
     */
    modifier publicMintActive() {
        require(isMintActive, "Mint is not open.");
        _;
    }

    /**
     * @dev This modifier checks that the merkle proof is valid.
     * @param merkleProof The merkle proof bytes32 array.
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in this allowlist."
        );
        _;
    }

    /**
     * @dev This modifier ensures that there are free mint tokens left.
     * @param quantity The number of tokens to be minted.
     */
    modifier freeMintLeft(uint256 quantity) {
        require(
            numFreeMint + quantity <= reservedFreeMint,
            "There are no free mint tokens left."
        );
        _;
    }

    /**
     * @dev This modifier ensures that there are allowlist mint tokens left.
     * @param quantity The number of tokens to be minted.
     */
    modifier allowlistMintLeft(uint256 quantity) {
        require(
            numAllowlistMint + quantity <= maxAllowlistMint,
            "There are no allowlist mint tokens left."
        );
        _;
    }

    /**
     * @dev This modifier ensures that there are public mint tokens left.
     * @param quantity The number of tokens to be minted.
     */
    modifier mintLeft(uint256 quantity) {
        require(
            totalSupply() + quantity <=
                collectionSize
                    - (reservedFreeMint - numFreeMint),
            "There are no tokens left to mint."
        );
        _;
    }

    /**
     * @dev This modifier ensures that the caller has not free minted.
     */
    modifier hasNotReceivedFree() {
        (uint16 senderFreeMints, uint16 senderGifts, uint16 senderAllowlistMints) = unpack(_getAux(msg.sender));
        require(
            senderFreeMints == 0,
            "This wallet has already claimed from free mint"
        );
        _;
    }

    /**
     * @dev This modifier ensures that the caller does not mint more than the max number of allowlist tokens per wallet.
     * @param quantity The number of tokens to be minted.
     */
    modifier lessThanMaxPerWalletAllowlist(uint256 quantity) {
        (uint16 senderFreeMints, uint16 senderGifts, uint16 senderAllowlistMints) = unpack(_getAux(msg.sender));
        require(
            senderAllowlistMints + quantity <= maxPerWalletAllowlist,
            "The maximum number of allowlist minted tokens per wallet is 3."
        );
        _;
    }

    /**
     * @dev This modifier ensures that the caller does not mint more than the max number of tokens per wallet.
     * @param quantity The number of tokens to be minted.
     */
    modifier lessThanMaxPerWallet(uint256 quantity) {
        (uint16 senderFreeMints, uint16 senderGifts, uint16 senderAllowlistMints) = unpack(_getAux(msg.sender));
        require(
            _numberMinted(msg.sender) + quantity <=
                maxPerWallet + senderFreeMints + senderGifts + senderAllowlistMints,
            "The maximum number of minted tokens per wallet is 16."
        );
        _;
    }

    /**
     * @dev This modifier ensures that the caller has sent the correct amount of ETH.
     * @param price The price of the token.
     * @param quantity The number of tokens to be minted.
     */
    modifier isCorrectPayment(uint256 price, uint256 quantity) {
        require(price * quantity == msg.value, "Incorrect amount of ETH sent.");
        _;
    }

    // Constructor
    // ---------------------------------------------------------------

    /**
     * @dev This function is the constructor for the contract.
     * @param collectionSize_ The number of tokens in the collection.
     * @param reservedFreeMint_ The number of tokens reserved for free mint.
     * @param maxAllowlistMint_ The number of tokens reserved for allowlist mint.
     * @param maxPerWalletAllowlist_ The maximum number of tokens that can be minted per wallet.
     * @param maxPerWallet_ The maximum number of tokens that can be minted per wallet.
     */
    constructor(
        uint256 collectionSize_,
        uint256 reservedFreeMint_,
        uint256 maxAllowlistMint_,
        uint256 maxPerWalletAllowlist_,
        uint256 maxPerWallet_
    ) ERC721A("Allstarz PSX", "PSX") {
        collectionSize = collectionSize_;
        reservedFreeMint = reservedFreeMint_;
        maxAllowlistMint = maxAllowlistMint_;
        maxPerWalletAllowlist = maxPerWalletAllowlist_;
        maxPerWallet = maxPerWallet_;

        // Initialize ClosedSea filterer
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // TODO: change to final royalty and check wallet address.
        // Set royalty receiver to the 0xSplits contract,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(0xe256E9BB36DB3Af6754d368Bb9A3408bC7818BF3, 500);
    }

    // Public minting functions
    // ---------------------------------------------------------------

    /**
     * @notice Free mint one token from free mint allowlist.
     * @param merkleProof The merkle proof bytes32 array.
     */
    function freeMint(bytes32[] calldata merkleProof)
        external
        nonReentrant
        callerIsUser
        freeMintActive
        isValidMerkleProof(merkleProof, merkleRootFreeMint)
        hasNotReceivedFree
        freeMintLeft(1)
    {
        numFreeMint++;
        increaseFreeMints(msg.sender, 1);
        _safeMint(msg.sender, 1);
    }


    /**
     * @notice Mint multiple tokens from allowlist paid mint.
     * @param quantity The number of tokens to be minted.
     * @param merkleProof The merkle proof bytes32 array.
     */
    function allowlistMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        callerIsUser
        allowlistMintActive
        isValidMerkleProof(merkleProof, merkleRootAllowlist)
        allowlistMintLeft(quantity)
        mintLeft(quantity)
        lessThanMaxPerWalletAllowlist(quantity)
        isCorrectPayment(allowlistMintPrice, quantity)
    {
        numAllowlistMint += quantity;
        increaseAllowlistMints(msg.sender, quantity);
        _safeMint(msg.sender, quantity);
    }

    /**
     * @notice Mint multiple tokens from public paid mint.
     * @param quantity The number of tokens to be minted.
     */
    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
        publicMintActive
        mintLeft(quantity)
        lessThanMaxPerWallet(quantity)
        isCorrectPayment(publicMintPrice, quantity)
    {
        uint256 batchSize = 8;
        uint256 numBatches = quantity / batchSize;
        uint256 remainder = quantity % batchSize;
        for (uint256 i = 0; i < numBatches; i++) {
            _safeMint(msg.sender, batchSize);
        }
        if (remainder > 0) {
            _safeMint(msg.sender, remainder);
        }
    }
    
    /**
     * @notice Mint a token to each address in an array.
     * @param addresses An array of addresses to mint to.
     */
    function gift(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        mintLeft(addresses.length)
    {
        uint256 numToGift = addresses.length;
        for (uint256 i = 0; i < numToGift; i++) {
            increaseGifts(addresses[i], 1);
            _safeMint(addresses[i], 1);
        }
    }

    /**
     * @notice Mint multiple tokens to each address in an array.
     * @param addresses An n-sized array of addresses to mint to.
     * @param quantities An n-sized array  quantities to mint to each corresponding address.
     */
    function giftMultiple(address[] calldata addresses, uint256[] calldata quantities)
        external
        nonReentrant
        onlyOwner
    {
        require(addresses.length == quantities.length, "The number of recipients and quantities must be the same.");
        uint256 totalGifts = 0;
        for (uint256 i = 0; i < quantities.length; i++) {
            totalGifts += quantities[i];
        }
        require(
            totalSupply() + totalGifts <=
                collectionSize
                    - (reservedFreeMint - numFreeMint),
            "There are no tokens left to mint."
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            increaseGifts(addresses[i], quantities[i]);
            _safeMint(addresses[i], quantities[i]);
        }
    }

    // Public read-only functions
    // ---------------------------------------------------------------

    /**
     * @notice Get the number of tokens minted by an address.
     * @param owner The address to check.
     * @return The number of tokens minted by the address.
     */
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @notice Get the mint price for allowlist sale.
     * @return The allowlist mint price.
     */
    function getAllowlistMintPrice() public view returns (uint256) {
        return allowlistMintPrice;
    }

    /**
     * @notice Get the mint price for public sale.
     * @return The public mint price.
     */
    function getPublicMintPrice() public view returns (uint256) {
        return publicMintPrice;
    }

    /**
     * @notice Get the total number of tokens reserved for free mint and gifts combined.
     * @return The total number of reserved for free mint and gifts combined.
     */
    function getReservedFreeMint() public view returns (uint256) {
        return reservedFreeMint;
    }

    /**
     * @notice Get the total maximum amount of tokens in the allowlist sale.
     * @return The total maximum amount of tokens in the allowlist sale.
     */
    function getAllowlistMintMax() public view returns (uint256) {
        return maxAllowlistMint;
    }

    /**
     * @notice Get the total number of tokens that can ever be minted in the collection.
     * @return The total number of tokens.
     */
    function getCollectionSize() public view returns (uint256) {
        return collectionSize;
    }

    /**
     * @notice Get the number of tokens that address has free minted.
     * @return The number of free mint tokens that address has free minted.
     */
    function getOwnerFreeMintCount(address owner) public view returns (uint16) {
        (uint16 ownerFreeMints, , ) = unpack(_getAux(owner));
        return ownerFreeMints;
    }

    /**
     * @notice Get the number of tokens that address has been gifted.
     * @return The number of free mint tokens that address has been gifted.
     */
    function getOwnerGiftsCount(address owner) public view returns (uint16) {
        (, uint16 ownerGifts, ) = unpack(_getAux(owner));
        return ownerGifts;
    }

    /**
     * @notice Get the number of tokens that address has allowlist minted.
     * @return The number of free mint tokens that address has allowlist minted.
     */
    function getOwnerAllowlistMintCount(address owner) public view returns (uint16) {
        (, , uint16 ownerAllowlistMints) = unpack(_getAux(owner));
        return ownerAllowlistMints;
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId The token ID to query.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override (IERC721A, ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    // Internal read-only functions
    // ---------------------------------------------------------------

    /**
     * @dev Returns base token metadata URI.
     * @return Base token metadata URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Owner only administration functions
    // ---------------------------------------------------------------

    /**
     * @notice Set free mint to active or inactive.
     * @param _isFreeMintActive True to set free mint to active, false to set to inactive.
     */ 
    function setFreeMintActive(bool _isFreeMintActive) external onlyOwner {
        isFreeMintActive = _isFreeMintActive;
    }
    
    /**
     * @notice Set allowlist paid mint to active or inactive.
     * @param _isAllowlistMintActive True to set free mint to active, false to set to inactive.
     */ 
    function setAllowlistMintActive(bool _isAllowlistMintActive) external onlyOwner {
        isAllowlistMintActive = _isAllowlistMintActive;
    }

    /**
     * @notice Set public mint to active or inactive.
     * @param _isMintActive True to set mint to active, false to set to inactive.
     */
    function setMintActive(bool _isMintActive) external onlyOwner {
        isMintActive = _isMintActive;
    }

    /**
     * @notice Set the allowlist mint price.
     * @param _allowlistMintPrice The new mint price.
     */
    function setAllowlistMintPrice(uint256 _allowlistMintPrice) external onlyOwner {
        allowlistMintPrice = _allowlistMintPrice;
    }

    /**
     * @notice Set the public mint price.
     * @param _publicMintPrice The new mint price.
     */
    function setPublicMintPrice(uint256 _publicMintPrice) external onlyOwner {
        publicMintPrice = _publicMintPrice;
    }

    /**
     * @notice Set the number of tokens reserved for free mint and gifts combined.
     * @param _reservedFreeMint The new number of tokens reserved for free mint and gifts combined. Cannot be less than the number of tokens already free minted.
     */
    function setReservedFreeMint(uint256 _reservedFreeMint) external onlyOwner {
        require(
            numFreeMint <= _reservedFreeMint,
            "Cannot set reserved free mint to less than the amount already free minted."
        );
        reservedFreeMint = _reservedFreeMint;
    }

    /**
     * @notice Set the number of tokens reserved for allowlist.
     * @param _maxAllowlistMint The new number of tokens reserved for allowlist. Cannot be less than the number of tokens already allowlist minted.
     */
    function setMaxAllowlistMint(uint256 _maxAllowlistMint) external onlyOwner {
        require(
            numAllowlistMint <= _maxAllowlistMint,
            "Cannot set reserved allowlist mint to less than the amount already allowlist minted."
        );
        maxAllowlistMint = _maxAllowlistMint;
    }
    
    /**
     * @notice Reduce the number of tokens that can be minted.
     * @param _collectionSize The new number of total tokens that can ever be minted in the collection. Cannot be greater than the current collection size or smaller than the remaining tokens.
     */
    function setCollectionSize(uint256 _collectionSize) external onlyOwner {
        require(
            _collectionSize <= collectionSize,
            "Cannot increase collection size."
        );
        require(
            _collectionSize >= totalSupply() + reservedFreeMint - numFreeMint,
            "Cannot set collection size to less than the number of tokens already minted plus the remaining reserved free mint tokens."
        );
        collectionSize = _collectionSize;
    }

    /**
     * @notice Set the base metadata URI.
     * @param baseURI The new base metadata URI.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Set the merkle root for the free mint allowlist.
     * @param _merkleRootFreeMint The new merkle root.
     */
    function setFreeMintMerkleRoot(bytes32 _merkleRootFreeMint) external onlyOwner {
        merkleRootFreeMint = _merkleRootFreeMint;
    }
    
    /**
     * @notice Set the merkle root for the paid mint allowlist.
     * @param _merkleRootAllowlist The new merkle root.
     */
    function setAllowlistMerkleRoot(bytes32 _merkleRootAllowlist) external onlyOwner {
        merkleRootAllowlist = _merkleRootAllowlist;
    }

    /**
     * @notice Withdraw ETH from the contract.
     * @dev 100% of the contract balance is sent to the owner.
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool ownerWithdrawSuccess, ) = msg.sender.call{
            value: address(this).balance
        }("");
        require(ownerWithdrawSuccess, "Owner transfer failed");
    }

    /**
     * @notice Withdraw ERC-20 tokens from the contract.
     * @dev In case someone accidentally sends ERC-20 tokens to the contract.
     * @param token The token to withdraw.
     */
    function withdrawTokens(IERC20 token) external onlyOwner nonReentrant {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    // ClosedSea functions

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

}