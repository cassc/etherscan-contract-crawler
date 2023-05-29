import "@openzeppelin/contracts/access/Ownable.sol";
import "../ChainRunnersXR.sol";
import "../ChainRunnersItems.sol";
import "../ChainRunners.sol";

contract ChainRunnersBurnEvent is Ownable, IERC721Receiver {
    address private _xrContractAddress;
    uint256 private _eventStartTimestamp;
    uint256 private _lastMintedXrTokenId;
    uint256[] private _availableXrTokenIds;
    uint256 private _maxRerollsPerTransaction;

    error TokenDoesNotExist();
    error NotTokenOwner();
    error CannotBurnRerolledTokens();
    error BurnEventHasNotStarted();
    error MaxSupplyExceeded();
    error IncorrectNumberOfTokens();

    event RerolledXrTokens(uint256[] burnedTokenIds, uint256[] mintedTokenIds);

    constructor(address xrContractAddress) {
        _xrContractAddress = xrContractAddress;
        _maxRerollsPerTransaction = 10;
    }

    // MODIFIERS
    modifier onlyWhenEventActive() {
        if (_eventStartTimestamp == 0 || block.timestamp < _eventStartTimestamp || _maxRerollsPerTransaction == 0)
            revert BurnEventHasNotStarted();
        _;
    }

    // REROLL - MANAGE
    function burnAndRerollXrTokens(uint256[] memory xrTokenIds) public onlyWhenEventActive returns (uint256[] memory) {
        if (xrTokenIds.length == 0 || xrTokenIds.length > _maxRerollsPerTransaction) revert IncorrectNumberOfTokens();
        _burnXrTokens(xrTokenIds);
        uint256[] memory mintedTokenIds = _mintXrTokens(xrTokenIds.length);
        emit RerolledXrTokens(xrTokenIds, mintedTokenIds);
        return mintedTokenIds;
    }

    // REROLL - VIEW
    function getAvailableXrTokenIds() public view returns (uint256[] memory) {
        return _availableXrTokenIds;
    }

    function getNumberOfAvailableXrTokens() public view returns (uint256) {
        return _availableXrTokenIds.length;
    }

    function getTokenIdAtIndex(uint256 i) public view returns (uint256) {
        return _availableXrTokenIds[i];
    }

    function getLastMintedXrTokenId() public view returns (uint256) {
        return _lastMintedXrTokenId;
    }

    // INTERNAL - MANAGE
    function _burnXrTokens(uint256[] memory xrTokenIds) internal {
        ChainRunnersXR xrContract = ChainRunnersXR(_xrContractAddress);
        for (uint256 i; i < xrTokenIds.length; i++) {
            if (xrTokenIds[i] > _lastMintedXrTokenId) revert CannotBurnRerolledTokens();
            if (xrContract.ownerOf(xrTokenIds[i]) != _msgSender()) revert NotTokenOwner();
            xrContract.burn(xrTokenIds[i]);
        }
    }

    function _mintXrTokens(uint256 quantity) internal returns (uint256[] memory mintedXrTokenIds) {
        ChainRunnersXR xrContract = ChainRunnersXR(_xrContractAddress);
        if (quantity > _availableXrTokenIds.length) revert MaxSupplyExceeded();
        mintedXrTokenIds = new uint256[](quantity);
        for (uint256 i; i < quantity; i++) {
            uint256 tokenIdIndex = randomNumber(_msgSender(), _availableXrTokenIds.length) %
            _availableXrTokenIds.length;
            uint256 tokenId = _availableXrTokenIds[tokenIdIndex];
            _availableXrTokenIds[tokenIdIndex] = _availableXrTokenIds[_availableXrTokenIds.length - 1];
            _availableXrTokenIds.pop();
            xrContract.safeTransferFrom(address(this), _msgSender(), tokenId);
            mintedXrTokenIds[i] = tokenId;
        }
        return mintedXrTokenIds;
    }

    // INTERNAL - VIEW
    function randomNumber(address to, uint256 remainingSupply) internal view returns (uint256) {
        return
        uint256(
            keccak256(
                abi.encode(
                    to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this),
                    remainingSupply
                )
            )
        );
    }

    // ADMIN - MANAGE
    function setXrContractAddress(address xrContractAddress) public onlyOwner {
        _xrContractAddress = xrContractAddress;
    }

    function setEventStartTimestamp(uint256 eventStartTimestamp) public onlyOwner {
        _eventStartTimestamp = eventStartTimestamp;
    }

    function setLastMintedXrTokenId(uint256 lastMintedXrTokenId) public onlyOwner {
        _lastMintedXrTokenId = lastMintedXrTokenId;
    }

    function setMaxRerollsPerTransaction(uint256 maxRerollsPerTransaction) public onlyOwner {
        _maxRerollsPerTransaction = maxRerollsPerTransaction;
    }

    function devMintXr(uint256 quantity) public onlyOwner {
        ChainRunnersXR xrContract = ChainRunnersXR(_xrContractAddress);
        xrContract.mintDev(quantity);
    }

    function transferXrContractOwnership(address newOwner) public onlyOwner {
        Ownable xrContract = Ownable(_xrContractAddress);
        xrContract.transferOwnership(newOwner);
    }

    function emergencyTransferXrTokens(address to, uint256[] memory tokenIds) public onlyOwner {
        ChainRunnersXR xrContract = ChainRunnersXR(_xrContractAddress);
        for (uint256 i; i < tokenIds.length; i++) {
            xrContract.safeTransferFrom(address(this), to, tokenIds[i]);
        }
    }

    function emergencyDeleteTokenIndex(uint256 i) public onlyOwner {
        _availableXrTokenIds[i] = _availableXrTokenIds[_availableXrTokenIds.length - 1];
        _availableXrTokenIds.pop();
    }

    // ADMIN -READ
    function xrContractAddress() public view returns (address) {
        return _xrContractAddress;
    }

    function eventStartTimestamp() public view returns (uint256) {
        return _eventStartTimestamp;
    }

    function lastMintedXrTokenId() public view returns (uint256) {
        return _lastMintedXrTokenId;
    }

    function maxRerollsPerTransaction() public view returns (uint256) {
        return _maxRerollsPerTransaction;
    }

    /**
     * @dev See {IERC1155Receiver-onERC721Received}.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        if (operator == address(this)) {
            _availableXrTokenIds.push(tokenId);
        }
        return this.onERC721Received.selector;
    }
}