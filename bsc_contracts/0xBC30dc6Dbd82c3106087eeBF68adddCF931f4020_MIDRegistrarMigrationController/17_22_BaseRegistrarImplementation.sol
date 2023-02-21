// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../registry/MID.sol";
import "./BaseRegistrar.sol";

contract BaseRegistrarImplementation is
    Pausable,
    ERC721,
    IERC721Enumerable,
    BaseRegistrar
{
    /**
     * @dev A map of expiry times
     */
    mapping(uint256 => uint256) expiries;

    /**
     * @dev Base URI of NFT metadata
     */
    string public baseURI;

    /**
     * @dev All minted token ids
     */
    uint256[] internal tokens;

    /**
     * @dev The max minting count per account
     */
    uint256 public maxMintPerUser = 10e18;

    /**
     * @dev mapping from token id to index in tokens array
     */
    mapping(uint256 => uint256) internal idToIndexes;

    /**
     * @dev mapping from owner address to token ids
     */
    mapping(address => uint256[]) internal ownerToIds;

    bytes4 private constant INTERFACE_META_ID =
        bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 private constant ERC721_ID =
        bytes4(
            keccak256("balanceOf(address)") ^
                keccak256("ownerOf(uint256)") ^
                keccak256("approve(address,uint256)") ^
                keccak256("getApproved(uint256)") ^
                keccak256("setApprovalForAll(address,bool)") ^
                keccak256("isApprovedForAll(address,address)") ^
                keccak256("transferFrom(address,address,uint256)") ^
                keccak256("safeTransferFrom(address,address,uint256)") ^
                keccak256("safeTransferFrom(address,address,uint256,bytes)")
        );
    bytes4 private constant RECLAIM_ID =
        bytes4(keccak256("reclaim(uint256,address)"));

    event BaseURIChanged(string indexed URI);
    event MaxMintCapChanged(uint256 indexed cap);
    event GracePeriodChanged(uint256 indexed period);

    /**
     * v2.1.3 version of _isApprovedOrOwner which calls ownerOf(tokenId) and takes grace period into consideration instead of ERC721.ownerOf(tokenId);
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721.sol#L187
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    constructor(MID _mid, bytes32 _baseNode) ERC721("Monster Domain", "MID") {
        mid = _mid;
        baseNode = _baseNode;
    }

    modifier live() {
        require(mid.owner(baseNode) == address(this), "not live");
        _;
    }

    modifier onlyController() {
        require(controllers[msg.sender], "only ctrl");
        _;
    }

    /**
     * @dev Pause the register & renew globally
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the register & renew globally
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *      when their registration expires.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId)
        public
        view
        override(IERC721, ERC721)
        returns (address)
    {
        require(expiries[tokenId] > block.timestamp, "expired");
        return super.ownerOf(tokenId);
    }

    /**
     * @dev Reset the grace period
     */
    function setGracePeriod(uint256 gracePeriod_) external override onlyOwner {
        gracePeriod = gracePeriod_;
        emit GracePeriodChanged(gracePeriod);
    }

    /**
     * @dev Authorises a controller, who can register and renew domains.
     */
    function addController(address controller) external override onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    /**
     * @dev Revoke controller permission for an address.
     */
    function removeController(address controller) external override onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    /**
     * @dev Set the resolver for the TLD this registrar manages.
     */
    function setResolver(address resolver) external override onlyOwner {
        mid.setResolver(baseNode, resolver);
    }

    /**
     * @dev Returns the expiration timestamp of the specified id.
     */
    function nameExpires(uint256 id) external view override returns (uint256) {
        return expiries[id];
    }

    /**
     * @dev Returns true iff the specified name is available for registration.
     */
    function available(uint256 id) public view override returns (bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] + gracePeriod < block.timestamp;
    }

    /**
     * @dev Register a name.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function register(
        uint256 id,
        address owner,
        uint256 duration
    ) external override returns (uint256) {
        return _register(id, owner, duration, true);
    }

    /**
     * @dev Register a name, without modifying the registry.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function registerOnly(
        uint256 id,
        address owner,
        uint256 duration
    ) external returns (uint256) {
        return _register(id, owner, duration, false);
    }

    function _register(
        uint256 id,
        address owner,
        uint256 duration,
        bool updateRegistry
    ) internal live onlyController whenNotPaused returns (uint256) {
        require(available(id), "not available");
        require(
            block.timestamp + duration + gracePeriod >
                block.timestamp + gracePeriod,
            "timestamp overflow"
        ); // Prevent future overflow

        // balance check
        require(balanceOf(owner) < maxMintPerUser, "balance exceeds cap");

        expiries[id] = block.timestamp + duration;
        if (_exists(id)) {
            // Name was previously owned, and expired
            _burn(id);
        }
        _mint(owner, id);
        if (updateRegistry) {
            mid.setSubnodeOwner(baseNode, bytes32(id), owner);
        }

        emit NameRegistered(id, owner, block.timestamp + duration);

        return block.timestamp + duration;
    }

    /**
     * @dev Renew the name with input duration
     */
    function renew(uint256 id, uint256 duration)
        external
        override
        live
        onlyController
        whenNotPaused
        returns (uint256)
    {
        require(
            expiries[id] + gracePeriod >= block.timestamp,
            "still in grace period"
        ); // Name must be registered here or in grace period
        require(
            expiries[id] + duration + gracePeriod > duration + gracePeriod,
            "timestamp overflowed"
        ); // Prevent future overflow

        expiries[id] += duration;
        emit NameRenewed(id, expiries[id]);
        return expiries[id];
    }

    /**
     * @dev Reclaim ownership of a name in MID, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external override live whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, id), "not approved or owner");
        mid.setSubnodeOwner(baseNode, bytes32(id), owner);
    }

    /**
     * @dev Support directly set the baseURI.
     * @param baseURI_ the new base URI
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit BaseURIChanged(baseURI);
    }

    /**
     * @dev Return the metadata URI by token ID
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "tokenId does not exist");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
                : "";
    }

    /**
     * @dev Support token metadata
     */
    function totalSupply() external view override returns (uint256) {
        return tokens.length;
    }

    /**
     * @dev Get token ID by stored order
     */
    function tokenByIndex(uint256 _index)
        external
        view
        override
        returns (uint256)
    {
        require(_index < tokens.length, "invalid index");
        return tokens[_index];
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        override
        returns (uint256)
    {
        require(_index < ownerToIds[_owner].length, "invalid index");
        return ownerToIds[_owner][_index];
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        return ownerToIds[_owner];
    }

    function _mint(address _to, uint256 _tokenId) internal virtual override {
        super._mint(_to, _tokenId);
        tokens.push(_tokenId);
        idToIndexes[_tokenId] = tokens.length - 1;
    }

    function _burn(uint256 _tokenId) internal virtual override {
        super._burn(_tokenId);
        uint256 tokenIndex = idToIndexes[_tokenId];
        uint256 lastTokenIndex = tokens.length - 1;
        uint256 lastToken = tokens[lastTokenIndex];
        tokens[tokenIndex] = lastToken;
        tokens.pop();
        // This wastes gas if you are burning the last token but saves a little gas if you are not.
        idToIndexes[lastToken] = tokenIndex;
        idToIndexes[_tokenId] = 0;
    }

    /**
     * @dev modify `transferFrom` and `safeTransferFrom` to make the domain automatically
     *  transfer to target owner as well
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not approved or owner"
        );
        _transfer(from, to, tokenId);
        mid.setSubnodeOwner(baseNode, bytes32(tokenId), to);
    }

    /**
     * @dev modify `transferFrom` and `safeTransferFrom` to make the domain automatically
     *  transfer to target owner as well
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(ERC721, IERC721) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not approved or owner"
        );
        _safeTransfer(from, to, tokenId, _data);
        mid.setSubnodeOwner(baseNode, bytes32(tokenId), to);
    }

    /**
     * @dev max mint per user setter
     */
    function setMaxMintPerUser(uint256 cap) onlyOwner external {
        require(cap > 0, "invalid mint cap");
        maxMintPerUser = cap;
        emit MaxMintCapChanged(cap);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        pure
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceID == INTERFACE_META_ID ||
            interfaceID == ERC721_ID ||
            interfaceID == RECLAIM_ID;
    }
}