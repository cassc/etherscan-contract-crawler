// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./openzeppelin/ERC2981.sol";

/**
 * @title Ballerz NFT of your team
 * @notice In this NFT sale we chose to only allow transactions signed by our server, in order to prioritize human buyers
 * over bots.
 */
contract NFT is ERC721Enumerable, Ownable, ERC2981 {
    using ECDSA for bytes32;

    // Base URI
    string private _baseURI;

    // Mapping from whitelist ID to bool determining if the sale is open to that list
    mapping(uint256 => bool) private _canMint;

    // Mapping from nonce value to bool documenting whether the given nonce was already used, used to guard against replay attacks
    mapping(uint256 => bool) private _nonceUsed;

    // Max supply that overrides the hard-coded value of 8889
    uint128 private _maxSupply;

    // Used to lock owner configuration functions
    bool private _locked;

    // The address of the server that signs all buy transactions; see docs on the buy function for more info
    address public _signerAddress;

    /**
     * @dev Burns token ID 0 because we want tokens to start at 1.
     */
    constructor(
        string memory baseURI,
        string memory name,
        string memory symbol,
        address owner,
        address signer,
        address royaltiesReceiver,
        uint96 royaltiesFeeNumerator
    ) ERC721(name, symbol) {
        _baseURI = baseURI;
        _signerAddress = signer;
        _setDefaultRoyalty(royaltiesReceiver, royaltiesFeeNumerator);
        transferOwnership(owner);

        // Product decision: burn token 0 to start minting at ID 1
        _owners.push(address(0));
    }

    /**
     * Public Transactions
     */

    /**
     * @notice Buy NFTs with transactions signed by our server, to prioritize human buyers over bots.
     * @param mintList The whitelist the buyer is part of.
     * @param nonceSeq The nonce of this transaction; must be unique to protect against replay attacks.
     * @param numTokens The number of tokens to mint in this transaction.
     * @param sig The server's signature over all inputs: mintList, numTokens, nonceSeq, this.address, msg.sender, msg.value
     */
    function buy(
        uint256 mintList,
        uint256 nonceSeq,
        uint256 numTokens,
        bytes memory sig
    ) external payable {
        require(checkSig(mintList, numTokens, nonceSeq, msg.sender, msg.value, sig), "Invalid signature");
        _buy(mintList, nonceSeq, numTokens);
    }

    /**
     * @notice Burn is not supported, because the gas optimizations we've implemented make it so that burning tokens renders
     * other functions buggy, like {totalSupply} and {tokenByIndex}.
     */
    function burn(uint256) external pure {
        revert("Burn is not supported");
    }

    /**
     * Public View Functions
     */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId > 0 && _exists(tokenId), "Token does not exist.");
        return string(abi.encodePacked(_baseURI, Strings.toString(tokenId)));
    }

    function mintingOpen(uint256 mintList) public view returns (bool) {
        return _canMint[mintList];
    }

    function getMaxSupply() public view returns (uint128) {
        return _getMaxSupply() - 1; // Account for having Zero TokenId burnt
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length - 1; // Subtract Zero TokenId burnt
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index + 1 < _owners.length, "ERC721Enumerable: global index out of bounds");
        return index + 1;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721Enumerable)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * Internal Functions
     */

    function _buy(
        uint256 mintList,
        uint256 nonceSeq,
        uint256 numTokens
    ) internal {
        require(numTokens > 0 && numTokens <= 10, "numTokens must be between 1 and 10");
        require(_canMint[mintList], "mintList not open");
        require(_nonceUsed[nonceSeq] == false, "Nonce already used");

        _nonceUsed[nonceSeq] = true;

        _mintTokens(numTokens);
    }

    function _mintTokens(uint256 numTokens) internal {
        uint256 nextTokenId = _owners.length;
        require(nextTokenId + numTokens <= _getMaxSupply(), "Cannot exceed maxSupply");

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    /**
     * @dev Added nonce and contract address in sig to guard against replay attacks
     */
    function checkSig(
        uint256 mintList,
        uint256 numTokens,
        uint256 nonceSeq,
        address user,
        uint256 price,
        bytes memory sig
    ) internal view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(mintList, numTokens, nonceSeq, address(this), user, price))
            )
        );
        return _signerAddress == hash.recover(sig);
    }

    /**
     * @dev this function is designed to allow the compiler to inline.
     * @return the real max supply plus one, because token IDs start at one.
     */
    function _getMaxSupply() internal view returns (uint128) {
        if (_maxSupply == 0) {
            // We actually have 8888 tokens, we're just starting at ID 1
            return 8889;
        }
        return _maxSupply;
    }

    /**
     * Owner Functions
     */

    /**
     * @notice Owner must mint before the sale starts, to get the first 250 tokens.
     * @dev We're avoiding using {balanceOf} because it would use up a lot of gas.
     */
    function ownerMint(uint256 numTokens) external onlyOwner {
        require(totalSupply() + numTokens <= 250, "Owner cannot mint more than 250 tokens");
        _mintTokens(numTokens);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(!_locked, "Contract locked");
        _baseURI = baseURI;
    }

    function setMintingOpen(uint256 mintList, bool isOpen) public onlyOwner {
        require(!_locked, "Contract locked");
        _canMint[mintList] = isOpen;
    }

    function changeSigner(address signerAddress) public onlyOwner {
        require(!_locked, "Contract locked");
        _signerAddress = signerAddress;
    }

    function updateMaxSupply(uint128 maxSupply) public onlyOwner {
        require(!_locked, "Contract locked");
        require(totalSupply() <= maxSupply, "Cannot be below totalSupply");

        // Adding 1 due to burning token 0
        _maxSupply = maxSupply + 1;
    }

    function lockContract() public onlyOwner {
        _locked = true;
    }

    function withdraw(uint256 amount, address payable to) public onlyOwner {
        require(amount <= address(this).balance, "Cannot withdraw more than current balance");
        to.transfer(amount);
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }
}