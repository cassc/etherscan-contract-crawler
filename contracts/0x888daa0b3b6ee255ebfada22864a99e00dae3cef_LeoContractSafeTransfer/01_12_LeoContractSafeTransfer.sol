// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "./DefaultOperatorFilterer.sol";
import "@openzeppelin/[email protected]/security/ReentrancyGuard.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/Strings.sol";
import "@openzeppelin/[email protected]/utils/cryptography/ECDSA.sol";

error ContractPaused();
error ProhibitTransfer();

contract LeoContractSafeTransfer is ERC721A, ReentrancyGuard, Ownable, Pausable, DefaultOperatorFilterer {
    using ECDSA for bytes32;
    using Strings for uint256;

    // var for token uri
    string public uriPrefix;
    string public uriSuffix = ".json";
  
    // switch for sale active
    bool public isSaleActive = false;
    uint256 public price = 0.004 ether;

    // also, the value of maxSupply is for allowlist, need to be change in public func
    uint256 public maxSupply = 2222;

    // used to validate authorized mint addresses
    address private signerAddress = 0x272422f38181F3887dA85A7C886619A83BA9feEE;

    // Prohibit NFT Transfer
    mapping(uint256 => bool) private _prohibitTransferTokenId;

    constructor() ERC721A("LeoStudio VIP", "LSVIP") {
        setUriPrefix("https://leostudio.io/nft/metadata/");
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : "";
    }

    // function for pause
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        if (paused()) revert ContractPaused();
        uint256 endTokenId = startTokenId + quantity;
        for (uint256 tokenId = startTokenId; tokenId < endTokenId; ++tokenId) {
            if (_prohibitTransferTokenId[tokenId]) revert ProhibitTransfer();
        }
    }

    // function for mint
    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        require(price != _newMintPrice, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        price = _newMintPrice;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(maxSupply != _maxSupply, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        maxSupply = _maxSupply;
    }

    function setSaleState(bool _saleActiveState) public onlyOwner {
        require(isSaleActive != _saleActiveState, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        isSaleActive = _saleActiveState;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0));
        signerAddress = _signerAddress;
    }

    function verifyAddressSigner(bytes32 _messageHash, bytes memory _signature) private view returns (bool) {
        return signerAddress == _messageHash.toEthSignedMessageHash().recover(_signature);
    }

    function hashMessage(address _sender, uint256 _maximumAllowedMints) private pure returns (bytes32) {
        return keccak256(abi.encode(_sender, _maximumAllowedMints));
    }

    /**
     * @notice Allow for minting of tokens up to the maximum allowed for a given address.
     * The address of the sender and the number of mints allowed are hashed and signed
     * with the server's private key and verified here to prove allowlisting status.
     */
    function mint(
        bytes32 _messageHash,
        bytes calldata _signature,
        uint256 _mintAmount,
        uint256 _maxAllowedMints
    ) external payable virtual nonReentrant {
        require(isSaleActive, "SALE_IS_NOT_ACTIVE");
        require(_mintAmount > 0 && _mintAmount <= _maxAllowedMints, "INVALID_MINT_AMOUNT");
        unchecked {
            // It has been checked that _mintAmount will not exceed maxMintAmountPerAddress.
            // First, numberMinted is less than maxMintAmountPerAddress, and totalMinted is less than maxSupply
            // So numberMinted(msg.sender) + _mintAmount is less than 2 * maxMintAmountPerAddress,
            // and totalMinted + _mintAmount is less than 2 * maxSupply， neither number will overflow.
            require(_numberMinted(msg.sender) + _mintAmount <= _maxAllowedMints, "MINT_TOO_MUCH");
            require(_totalMinted() + _mintAmount <= maxSupply, "NOT_ENOUGH_MINTS_AVAILABLE");
        }
        // Check signature
        require(hashMessage(msg.sender, _maxAllowedMints) == _messageHash, "MESSAGE_INVALID");
        require(verifyAddressSigner(_messageHash, _signature), "SIGNATURE_VALIDATION_FAILED");
        // Imprecise floats are scary, adding margin just to be safe to not fail txs
        require(msg.value >= ((price * _mintAmount) - 0.0001 ether) && msg.value <= ((price * _mintAmount) + 0.0001 ether), "INVALID_PRICE");
        
        // ALL checks passed
        _safeMint(msg.sender, _mintAmount);
    }

    function gift(address _receiver, uint256 _mintAmount) external onlyOwner {
        unchecked {
            // Uncheck reason as same as mint
            require(_totalMinted() + _mintAmount <= maxSupply, "MINT_TOO_LARGE");
        }
        _safeMint(_receiver, _mintAmount);
    }

    function getProhibitStatus(uint256 _tokenId) external view returns (bool) {
        return _prohibitTransferTokenId[_tokenId];
    }

    function prohibitTransfer(uint256 _tokenId) external onlyOwner {
        _prohibitTransferTokenId[_tokenId] = true;
    }

    function allowTransfer(uint256 _tokenId) external onlyOwner {
        _prohibitTransferTokenId[_tokenId] = false;
    }

    function burn(uint256 _tokenId) external onlyOwner {
        _burn(_tokenId);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    /**
     * @notice Allow contract owner to withdraw to specific accounts
     */
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(0x272422f38181F3887dA85A7C886619A83BA9feEE).send(balance));
    }
}