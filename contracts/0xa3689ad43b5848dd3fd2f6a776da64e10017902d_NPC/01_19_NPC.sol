// SPDX-License-Identifier: GPL-3.0

/// @title The NPC ERC-721 token

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import "./base/ERC721URIStorage.sol";
import './base/ERC721Enumerable.sol';
import './interfaces/INPC.sol';
import './external/opensea/IProxyRegistry.sol';
import './ERC-2981/ERC2981ContractWideRoyalties.sol';

contract NPC is INPC, Ownable, ERC721Enumerable, ERC721URIStorage, ERC2981ContractWide {
    // The NPC Founders address (creators org)
    address public NPCWallet;

    // An address who has permissions to mint NPC
    address public minter;

    // An address who has permissions to set tokenURI 
    address public setter;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // Whether the setter can be updated
    bool public isSetterLocked;

    // The internal npc ID tracker
    uint256 private _currentNPCId;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash;

    // Base URI for contract pre reveal
    string public baseURI;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, 'Minter is locked');
        _;
    }

    /**
     * @notice Require that the setter has not been locked.
     */
    modifier whenSetterNotLocked() {
        require(!isSetterLocked, 'Minter is locked');
        _;
    }

    /**
     * @notice Require that the sender is the NPC Wallet.
     */
    modifier onlyNPCWallet() {
        require(msg.sender == NPCWallet, 'Sender is not the NPC Wallet');
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, 'Sender is not the minter');
        _;
    }

    /**
     * @notice Require that the sender is the setter.
     */
    modifier onlySetter() {
        require(msg.sender == setter, 'Sender is not the setter');
        _;
    }

    constructor(
        address _NPCWallet,
        address _minter,
        address _setter,
        string memory _contractURI,
        string memory _baseURI,
        IProxyRegistry _proxyRegistry
    ) ERC721('NPC', 'NPC') {
        NPCWallet = _NPCWallet;
        minter = _minter;
        setter = _setter;
        _contractURIHash = _contractURI;
        proxyRegistry = _proxyRegistry;
        baseURI = _baseURI;

        _setRoyalties(_NPCWallet, 1000);
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ar://', _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string calldata newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /** 
     * @notice Mint a NPC to the minter, along with a possible Founder NPC reward
     * NPC. Founder NPC reward NPCs are minted every 5 NPC starting at 0,
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        require(_currentNPCId < 333, "All NPCs have been minted");

        if (_currentNPCId % 5 == 0) {
            emit FounderNPCCreated(_currentNPCId);
            _mintTo(NPCWallet, _currentNPCId++);
        }
        return _mintTo(minter, _currentNPCId++);
    }

    /**
     * @notice Burn a NPC.
     */
    function burn(uint256 npcId) public override onlyMinter {
        _burn(npcId);
        emit NPCBurned(npcId);
    }

    /**
     * @notice Set the NPC Wallet.
     * @dev Only callable by the NPC Wallet address.
     */
    function setNPCWallet(address _NPCWallet) external override onlyNPCWallet {
        NPCWallet = _NPCWallet;

        emit NPCWalletUpdated(_NPCWallet);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }

    /**
     * @notice Set the URI setter.
     * @dev Only callable by the owner when not locked.
     */
    function setSetter(address _setter) external override onlyOwner whenSetterNotLocked {
        setter = _setter;

        emit SetterUpdated(_setter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSetter() external override onlyOwner whenSetterNotLocked {
        isSetterLocked = true;

        emit SetterLocked();
    }

    /**
     * @notice Mint a NPC with `npcId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 npcId) internal returns (uint256) {
        _mint(owner(), to, npcId);
        emit NPCCreated(npcId);

        return npcId;
    }

    /**
     * @notice Set the tokenURU of `npcId`.
     * @dev This can only be called by Setter.
     */
    function setTokenURI(uint256 tokenId, string calldata _tokenURI) external onlySetter {
        _setTokenURI(tokenId, _tokenURI);

        emit NPCTokenURISet(tokenId, _tokenURI);
    }

    /**
     * @notice returns current tracker `npcId`.
     */   
    function npcTracker() external view virtual returns (uint256) {
        return _currentNPCId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, IERC165, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal virtual 
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage){
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}