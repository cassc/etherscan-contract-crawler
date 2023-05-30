// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./utils/Monotonic.sol";
import "./utils/SignatureChecker.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract DfansPass is ERC721, ERC721Royalty, ERC721Pausable, Ownable, Initializable, DefaultOperatorFilterer {
    using Monotonic for Monotonic.Increaser;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// ===================
    /// basic NFT features
    /// ===================
    address payable public beneficiary;
    Monotonic.Increaser private _totalPublished;
    Monotonic.Increaser private _mintPosition;
    // internal collection id
    string private _collectionId;
    string private _passName;
    string private _passSymbol;
    
    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "The caller is another contract");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        // consturctor name and symbol have no use
    }

    function name() public view override(ERC721) returns (string memory) {
        return _passName;
    }

    function symbol() public view override(ERC721) returns (string memory) {
        return _passSymbol;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory collectionId,
        uint96 royaltyFraction,
        address payable _beneficiary,
        address payable owner,
        uint256 initialPublish,
        bool transferMintETH_,
        uint256 fixedPrice_
    ) initializer public {
        _passName = name_;
        _passSymbol = symbol_;
        _collectionId = collectionId;
        _totalPublished.add(initialPublish);
        beneficiary = _beneficiary;
        _setDefaultRoyalty(_beneficiary, royaltyFraction);
        transferMintETH = transferMintETH_;
        fixedPrice = fixedPrice_;
        _transferOwnership(owner);
    }

    function _baseURI() internal view override returns (string memory) {
        return string.concat("https://dfans.xyz/api/nft/commodity/v1/query/", _collectionId,"/");
    }

    function contractURI() public view returns (string memory) {
        return string.concat("https://dfans.xyz/api/nft/v1/album/query/", _collectionId);        
    }

    /// @notice Sets the recipient of revenues.
    function setBeneficiary(address payable _beneficiary,uint96 royaltyFraction) public onlyOwner {
        // mint beneficiary and royalty receiver are same
        beneficiary = _beneficiary;
        _setDefaultRoyalty(_beneficiary, royaltyFraction);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /// ===================
    /// airdrop
    /// ===================

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        // public mint must after the token being published
        require(_published(tokenId), "private mint for nonpublished token");
        _safeMint(to, tokenId);
    }

    function safeBatchMint(address to, uint256[] calldata tokenIds) public onlyOwner {
        // simple loop for safe mint
        for (uint256 j = 0; j < tokenIds.length; j++) {
            require(_published(tokenIds[j]), string.concat("private mint for nonpublished token:",Strings.toString(tokenIds[j])));
            require(_ownerOf(tokenIds[j]) == address(0), "ERC721: token already minted");
        }
        for (uint256 j = 0; j < tokenIds.length; j++) {
            _safeMint(to, tokenIds[j]);
        }
    }

    /// ===================
    /// public mint
    /// ===================
    function publicMint(
        address to,
        uint256 tokenId,
        uint256 price,
        string calldata nonce,
        bytes calldata sig
    ) public payable callerIsUser {
        /**
         * ##### CHECKS
         */
        // public mint must after the token being published
        require(_published(tokenId), "public mint for nonpublished token");

        // value is enough
        require(msg.value >= price, "mint value is not enough");
        // if fixedPrice is not 0, check price must bigger than that
        require(fixedPrice == 0 || price >= fixedPrice , "mint value is not enough");

        // validate sig, it has effects so place at the end of check
        // only check it when fixedPrice is 0
        if (fixedPrice == 0){
            SignatureChecker.requireValidSignature(
                signers,
                signaturePayload(to, nonce, price, _collectionId, 1),
                sig,
                usedMessages
            );
        }

        /**
         * ##### EFFECTS
         */
        _safeMint(to, tokenId);

        /**
         * ##### INTERACTIONS
         */
        if (msg.value > 0 && transferMintETH) {
            _transfer(beneficiary, msg.value);
        }
    }

    function publicRandomMint(
        address to,
        uint256 price,
        string calldata nonce,
        bytes calldata sig,
        uint256 n
    ) public payable callerIsUser {
        /**
         * ##### CHECKS
         */

        // value is enough
        require(msg.value >= price, "mint value is not enough");

        // if fixedPrice is not 0, check price must bigger than that
        require(fixedPrice == 0 || price >= n * fixedPrice , "mint value is not enough");

        // simple check 
        require(_mintPosition.current() < _totalPublished.current(), "token sold out");
        // check there are enough nfts
        // find next n tokenid to mint
        uint256[] memory tokens = new uint256[](n);
        uint256 filled = 0;
        uint256 position = _mintPosition.current();
        while (position < _totalPublished.current() && filled < n) {
            if (_ownerOf(position) == address(0)) {
                // find one fit
                tokens[filled] = position;
                filled++;
            } 
            position++;
        }
        require(filled == n, "token sold out");

        // validate sig, it has effects so place at the end of check
        // only check it when fixedPrice is 0
        if (fixedPrice == 0){
            SignatureChecker.requireValidSignature(
                signers,
                signaturePayload(to, nonce, price, _collectionId, n),
                sig,
                usedMessages
            );
        }

        /**
         * ##### EFFECTS
         */

        for (uint256 index = 0; index < n; index++) {
            _safeMint(to, tokens[index]);
        }

        //set the new position
        _mintPosition.add(position - _mintPosition.current());

        /**
         * ##### INTERACTIONS
         */
        // maynot not transfer every time, save in the contract
        if (msg.value > 0 && transferMintETH) {
            _transfer(beneficiary, msg.value);
        }
    }

    /// ===================
    /// publish NFTs
    /// ===================
    function _published(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _totalPublished.current();
    }

    function totalPublished() public view returns (uint256) {
        return _totalPublished.current();
    }


    /**
     * @dev Safely publish next `quantity` tokens.
     *
     * Requirements:
     *
     * - `quantity` must greater then 0.
     * - `price` not used any more
     *
     */
    function safePublish(uint256 quantity, uint256 price) public whenNotPaused onlyOwner {
        require(quantity > 0, "quantity must greater than 0");

        _totalPublished.add(quantity);
        //emit Publish(beforeCount, _totalPublished.current() - 1, price);
    }

    /// ===================
    /// signiture validation
    /// ===================
    /**
    @dev Addresses from which signatures can be accepted.
     */
    EnumerableSet.AddressSet internal signers;
    
    /**
    @dev If a fixedPrice is set, we do not need signiture validation.
     */
    uint256 public fixedPrice;
    function setFixedPrice(uint256 newPrice) external onlyOwner {
        fixedPrice = newPrice;
    }

    /**
    @dev Record of already-used signatures.
     */
    mapping(bytes32 => bool) public usedMessages;
    // every owner is signer
    function _transferOwnership(address newOwner) internal override {
        super._transferOwnership(newOwner);
        signers.add(newOwner);
    }
    /**
    @notice Add an address to the set of accepted signers.
     */
    function addSigner(address signer) external onlyOwner {
        signers.add(signer);
    }
    /**
    @dev Constructs the buffer that is hashed for validation with a minting
    signature.
     */
    function signaturePayload(address to, string memory nonce, uint256 price, string memory albumId, uint256 n)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(string.concat(Strings.toHexString(to),
                '_' , nonce,
                '_' , Strings.toString(price),
                '_' , albumId,
                '_' , Strings.toString(n)));
    }

    /// ===================
    /// revenue sharing
    /// ===================
    // total ETH received
    uint256 public totalReceived;
    // total ETH released
    uint256 public totalReleased;
    // address level release&withdrawn records
    mapping (address => uint256) private _released;
    mapping (address => uint256) private _withdrawn;    
    // event
    event PaymentReleased(uint256 unitAmount, uint256 totalAmount); 
    event PaymentWithdrawn(address indexed to, uint256 totalAmount);

    // track totalreceived whenever an ETH payment is made
    receive () external payable {
        totalReceived += msg.value;
    }

    /**
     * @dev Getter for the amount of total releasable Ether.
     */
    function totalReleasable() public view returns (uint256) {
        return totalReceived - totalReleased;
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of Ether can be withdrawn by a payee.
     */
    function withdrawable(address account) public view returns (uint256) {
        return _released[account] - _withdrawn[account];
    }

    /**
     * @dev Release the current releasable ETH to every NFT holder.
     *
     * Requirements:
     *
     */
    function release() public onlyOwner { 

        uint256 releasablePayment = totalReleasable();
        require(releasablePayment != 0, "insufficient balance to release");

        uint256 totalCount = totalPublished();
        require(totalCount != 0, "no NFT published to release");

        // check overflow
        unchecked {
            require(totalReleased + releasablePayment > totalReleased , "overflow");
        }

        // 8 digital ether value at most
        uint256 unitPayment = releasablePayment / 1e10 / totalCount * 1e10;
        require(unitPayment != 0, "insufficient balance to release");
        // if not every nft is minted, not all the releaseablePayment will released
        uint256 totalPayment = 0;

        // holders will get unitPayment for every nft
        for (uint256 i = 0; i < totalCount; i++) {
            address nftOwner = _ownerOf(i);
            if (nftOwner != address(0)) {
                // If "totalReleased += releasablePayment" does not overflow, then "_released[nftOwner] += unitPayment" cannot overflow.
                unchecked {
                    _released[nftOwner] += unitPayment;
                    totalPayment += unitPayment;
                }
            }
        }
        // totalReleased is the sum of all values in _released.
        if (totalPayment > 0) {
            unchecked {
                totalReleased += totalPayment;
            }
        }

        emit PaymentReleased(unitPayment, totalPayment);

    }

    function withdraw() external whenNotPaused {

        uint256 payment = withdrawable(_msgSender());
        require(payment != 0, "account is not due payment");

        _withdrawn[_msgSender()] += payment;
        _transfer(_msgSender(), payment);
        emit PaymentWithdrawn(_msgSender(), payment);
    }

    function withdrawForBeneficiary() external whenNotPaused {
        uint256 withdrawableForBeneficiary = payable(address(this)).balance - totalReceived;
        require(withdrawableForBeneficiary > 0, "nothing to withdraw");
        _transfer(beneficiary, withdrawableForBeneficiary);
    }

    /// ===================
    /// OperatorFilterer for OpenSea
    /// ===================

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    /// ===================
    /// utility functions
    /// ===================
    // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
    error TransferFailed();
    function _transfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferFailed();
    }
    // do we transfer the eth right after the mint, or save it in the contract
    bool public transferMintETH = true;

    function setTransferMintETH(bool open) external onlyOwner {
        transferMintETH = open;
    }
}