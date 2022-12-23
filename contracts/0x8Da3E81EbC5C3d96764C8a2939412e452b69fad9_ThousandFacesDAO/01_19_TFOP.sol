// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//  /$$$$$$$$ /$$                                                               /$$       /$$$$$$$$
// |__  $$__/| $$                                                              | $$      | $$_____/
//    | $$   | $$$$$$$   /$$$$$$  /$$   /$$  /$$$$$$$  /$$$$$$  /$$$$$$$   /$$$$$$$      | $$    /$$$$$$   /$$$$$$$  /$$$$$$   /$$$$$$$
//    | $$   | $$__  $$ /$$__  $$| $$  | $$ /$$_____/ |____  $$| $$__  $$ /$$__  $$      | $$$$$|____  $$ /$$_____/ /$$__  $$ /$$_____/
//    | $$   | $$  \ $$| $$  \ $$| $$  | $$|  $$$$$$   /$$$$$$$| $$  \ $$| $$  | $$      | $$__/ /$$$$$$$| $$      | $$$$$$$$|  $$$$$$
//    | $$   | $$  | $$| $$  | $$| $$  | $$ \____  $$ /$$__  $$| $$  | $$| $$  | $$      | $$   /$$__  $$| $$      | $$_____/ \____  $$
//    | $$   | $$  | $$|  $$$$$$/|  $$$$$$/ /$$$$$$$/|  $$$$$$$| $$  | $$|  $$$$$$$      | $$  |  $$$$$$$|  $$$$$$$|  $$$$$$$ /$$$$$$$/
//    |__/   |__/  |__/ \______/  \______/ |_______/  \_______/|__/  |__/ \_______/      |__/   \_______/ \_______/ \_______/|_______/

/**
 * @title Thousand Faces Contract
 * @notice This contract handles minting and distribution of Thousand Faces NFT tokens.
 */

contract ThousandFacesDAO is
    ERC721,
    ERC721Enumerable,
    ERC721Royalty,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    string[] private _provenanceHashes;
    uint256 private _nextProvenanceHashIndex;

    mapping(uint256 => string) private _ipfsURI;
    uint256 private _ipfsURIIndex;

    mapping(uint256 => string) private _arweaveURI;
    uint256 private _arweaveURIIndex;

    string public contractURI;
    uint256 private _tokenIndex = 0;
    uint256 private _availablesupply;
    bool public isBurningAllowed = false;
    bool public isAllowlistActive = false;
    bool public isSaleActive = false;
    uint256 public allowlistStartTime;
    uint256 public saleStartTime;
    uint256 public pricePerToken;

    string public baseURI;
    uint96 public royaltyFee;
    address public royaltyRecipient;
    address public withdrawAddress;

    uint256 public MAX_SUPPLY = 9999;
    uint256 public maxAllowlistTokens = 10;
    uint256 public maxPublicTokens = 20;

    bytes32 public merkleRoot;
    mapping(address => uint256) private _allowlistMinted;

    event BaseURISet(string baseUri);
    event ContractURISet(string contractUri);
    event ProvenanceHashAdded(string provenanceHash);
    event ToggleSale(bool saleState, uint256 startTime);
    event ToggleAllowlistSale(bool saleState, uint256 startTime);
    event MerkleRootAdded(bytes32 merkleRoot);
    event AllowlistMinted(address allowlistedAddress, uint256 numberOfTokens);
    event PublicMinted(address publicAddress, uint256 numberOfTokens);
    event Airdrop(address[] publicAddresses);
    event TokenBurnt(uint256 tokenId);

    // support eth transactions to the contract
    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @notice Construct a Thousand Faces contract instance
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _baseTokenURI Base URI for all tokens
     * @param _royaltyRecipient Royalty Fees Recepient
     * @param _royaltyFee Royalty Fees
     * @param _initialContractURI Initial Contract URI
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _royaltyRecipient,
        uint96 _royaltyFee,
        string memory _initialContractURI
    ) ERC721(_name, _symbol) {
        baseURI = _baseTokenURI;
        royaltyRecipient = _royaltyRecipient;
        royaltyFee = _royaltyFee;
        contractURI = _initialContractURI;
        _setDefaultRoyalty(royaltyRecipient, royaltyFee);
        withdrawAddress = msg.sender;
    }

    /**
     * @notice Read the base token URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        require(bytes(_newBaseURI).length != 0, "Base URI cannot be empty");
        baseURI = _newBaseURI;
        emit BaseURISet(_newBaseURI);
    }

    /**
     * @notice Update the contract URI
     */
    function setContractURI(string calldata _newContractURI)
        external
        onlyOwner
    {
        require(
            bytes(_newContractURI).length != 0,
            "Contract URI cannot be empty"
        );
        contractURI = _newContractURI;
        emit ContractURISet(_newContractURI);
    }

    /**
     * @notice Update the maximum tokens allowed for allowlist mint
     */
    function setMaxAllowlistTokens(uint256 _count) external onlyOwner {
        require(_count != 0, "Max Allowlist tokens cannot be zero");
        maxAllowlistTokens = _count;
    }

    /**
     * @notice Update the maximum tokens allowed for public mint
     */
    function setMaxPublicTokens(uint256 _count) external onlyOwner {
        require(_count != 0, "Max Public tokens cannot be zero");
        maxPublicTokens = _count;
    }

    /**
     * @notice Update the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyRecipient, royaltyFee);
    }

    /**
     * @notice Update the royalty address where royalty payouts are sent
     */
    function setRoyaltyRecipient(address _royaltyRecipient) external onlyOwner {
        require(
            _royaltyRecipient != address(0),
            "Royalty recepient cannot be address zero"
        );
        royaltyRecipient = _royaltyRecipient;
        _setDefaultRoyalty(royaltyRecipient, royaltyFee);
    }

    /**
     * @notice Allow the owner to start/stop the public sale
     */
    function toggleAllowlistState() external onlyOwner {
        isAllowlistActive = !isAllowlistActive;
        if (allowlistStartTime == 0) {
            allowlistStartTime = block.timestamp;
        } else {
            allowlistStartTime = 0;
        }
        emit ToggleAllowlistSale(isAllowlistActive, allowlistStartTime);
    }

    /**
     * @notice Allow the owner to start/stop the public sale
     */
    function toggleSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
        if (saleStartTime == 0) {
            saleStartTime = block.timestamp;
        } else {
            saleStartTime = 0;
        }
        emit ToggleSale(isSaleActive, saleStartTime);
    }

    /**
     * @notice Allow the owner to start/stop the public sale
     */
    function toggleBurningState() external onlyOwner {
        isBurningAllowed = !isBurningAllowed;
    }

    /**
     * @notice Add Provenance hash for the batch
     */
    function addProvenanceHash(string calldata _provenanceHash)
        external
        onlyOwner
    {
        require(
            bytes(_provenanceHash).length > 0,
            "Provenance Hash cannot be empty"
        );
        _provenanceHashes.push(_provenanceHash);
        _nextProvenanceHashIndex++;
        emit ProvenanceHashAdded(_provenanceHash);
    }

    /**
     * @notice Get last Provenance Hash for the batch
     */
    function getLastProvenance() external view returns (string memory) {
        return _provenanceHashes[_nextProvenanceHashIndex - 1];
    }

    /**
     * @notice Read all Provenance Hashes
     */
    function getAllProvenanceHashes() external view returns (string[] memory) {
        return _provenanceHashes;
    }

    /**
     * @notice Update the IPFS Token URI
     */
    function setIpfsTokenURI(string[] calldata _cids) external onlyOwner {
        require(_cids.length != 0, "TokenURI input cannot be empty");
        for (uint256 i = 0; i < _cids.length; ) {
            _ipfsURI[_ipfsURIIndex + i] = _cids[i];
            unchecked {
                i++;
            }
        }
        _ipfsURIIndex += _cids.length;
    }

    /**
     * @notice Reverts with the IPFS Token URI
     */
    function ipfsTokenURI(uint256 _tokenId)
        external
        view
        virtual
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked("ipfs://", _ipfsURI[_tokenId]));
    }

    /**
     * @notice Update the IPFS Token URI
     */
    function setArweaveTokenURI(string[] calldata _dataURIs) public onlyOwner {
        require(_dataURIs.length != 0, "TokenURI input cannot be empty");
        for (uint256 i = 0; i < _dataURIs.length; ) {
            _arweaveURI[_arweaveURIIndex + i] = _dataURIs[i];
            unchecked {
                i++;
            }
        }
        _arweaveURIIndex += _dataURIs.length;
    }

    /**
     * @notice Reverts with the IPFS Token URI
     */
    function arweaveTokenURI(uint256 _tokenId)
        external
        view
        virtual
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked("https://arweave.net/", _arweaveURI[_tokenId])
            );
    }

    /**
     * @notice Read the available token supply
     */
    function getAvailableSupply() external view returns (uint256) {
        return _availablesupply;
    }

    /**
     * @notice Update the available token supply
     */
    function setAvailableSupply(uint256 _supply) external onlyOwner {
        require(
            _supply <= MAX_SUPPLY,
            "Supply cannot exceed the total supply limit of 10k tokens"
        );
        require(
            _supply > _availablesupply,
            "Supply cannot be lesser than or equal to the existing supply"
        );
        _availablesupply = _supply;
    }

    /**
     * @notice Update the token index for the new batch
     */
    function setTokenIndex(uint256 _newIndex) external onlyOwner {
        require(
            _newIndex > _tokenIndex,
            "New index cannot be lesser than or equal to the current token index"
        );
        _tokenIndex = _newIndex;
    }

    /**
     * @notice Update the price per token
     */
    function setTokenPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0 ether, "Cannot set price to zero");
        pricePerToken = _newPrice;
    }

    /**
     * @notice Update the merkle root for the allowlist
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(_merkleRoot.length != 0, "Merkle Root cannot be empty");
        merkleRoot = _merkleRoot;
        emit MerkleRootAdded(_merkleRoot);
    }

    /**
     * @notice Verify address eligibility for the allow list mint
     */
    function isAllowListEligible(address addr, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @notice Allow minting for allowlisted addresses
     */
    function mintAllowlist(
        bytes32[] calldata _merkleProof,
        uint256 _numberOfTokens
    ) external payable nonReentrant {
        address sender = _msgSender();
        require(isSaleActive, "Sale must be active to mint tokens");
        require(isAllowlistActive, "Allowlist must be active to mint tokens");
        require(
            (_numberOfTokens + balanceOf(sender)) <= maxAllowlistTokens,
            "Number of tokens exceeds the max allowed tokens"
        );
        require(
            isAllowListEligible(msg.sender, _merkleProof),
            "Address not eligible for the allowlist"
        );
        require(
            msg.value == pricePerToken * _numberOfTokens,
            "Incorrect payable amount"
        );

        _allowlistMinted[sender] += _numberOfTokens;
        _internalMint(sender, _numberOfTokens);
        emit AllowlistMinted(sender, _numberOfTokens);
    }

    /**
     * @notice Allow minting for public addresses
     */
    function mintPublic(uint256 _numberOfTokens) external payable nonReentrant {
        address sender = _msgSender();

        uint256 ts = totalSupply();
        require(isSaleActive, "Sale must be active to mint tokens");
        require(
            !isAllowlistActive,
            "Public sale must be active to mint tokens"
        );
        require(
            (_numberOfTokens + balanceOf(sender)) <= maxPublicTokens,
            "Number of tokens exceeds the max allowed tokens"
        );
        // require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(
            ts + _numberOfTokens <= _availablesupply,
            "Purchase would exceed max tokens"
        );
        require(
            pricePerToken * _numberOfTokens <= msg.value,
            "Incorrect payable amount"
        );

        _internalMint(sender, _numberOfTokens);
        emit PublicMinted(sender, _numberOfTokens);
    }

    /**
     * @notice Private Internal Mint function
     */
    function _internalMint(address _to, uint256 _numberOfTokens) private {
        require(
            _tokenIndex + _numberOfTokens <= _availablesupply,
            "Purchase would exceed max tokens"
        );

        for (uint256 i = 0; i < _numberOfTokens; ) {
            _safeMint(_to, _tokenIndex + i);
            unchecked {
                i++;
            }
        }
        _tokenIndex += _numberOfTokens;
    }

    /**
     * @notice Reserve tokens for the team
     */
    function reserve(uint256 _numberOfTokens) external onlyOwner {
        require(
            _numberOfTokens != 0,
            "Number of tokens should be more than zero"
        );
        _internalMint(msg.sender, _numberOfTokens);
    }

    /**
     * @notice Allow the owner to gift tokens to an arbitrary number of addresses
     */
    function airdrop(address[] calldata _receivers) external onlyOwner {
        require(
            _tokenIndex + _receivers.length <= _availablesupply,
            "Not enough tokens available"
        );

        for (uint256 i; i < _receivers.length; ) {
            _safeMint(_receivers[i], _tokenIndex + i);
            unchecked {
                i++;
            }
        }
        _tokenIndex += _receivers.length;
        emit Airdrop(_receivers);
    }

    /**
     * @notice Burn the NFT tokens
     */
    function burnNFT(uint256 _tokenId) external {
        require(isBurningAllowed, "Burning is disbled at present");
        require(
            ownerOf(_tokenId) == msg.sender,
            "Only token owner can burn thier NFTs"
        );
        _burn(_tokenId);
        emit TokenBurnt(_tokenId);
    }

    /**
     * @notice Private internal burn function
     */
    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Royalty)
    {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @notice Allow withdrawing funds to the withdrawAddress
     */
    function withdraw() external onlyOwner {
        require(
            msg.sender != address(0),
            "Address set to 0x0, set the recepient address"
        );
        uint256 balance = address(this).balance;
        require(balance > 0, "NOTHING_TO_WITHDRAW");
        require(payable(withdrawAddress).send(balance));
    }

    /**
     * @notice Change the withdraw address for the collection
     */
    function setWithdrawAddress(address _address) external onlyOwner {
        require(_address != address(0), "input cannot be address zero");
        withdrawAddress = _address;
    }

    // Utils
    /**
     * @notice Allow external checks for token existence
     */
    function tokenExists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @notice Returns a list of NFT token IDs owned by a given address
     */
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; ) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
            unchecked {
                i++;
            }
        }

        return tokensId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Template input for the constructor
    // ThousandFacesDAO,TF,https://tokens.thousandfaces.art/,0xb33eFA6203A18A3696509d98D29574Dd07820a81,1000,ipfs://QmW47JiUFT53tm9KDdrDFXPMUW94a2htBCevxB7a41meuv
}