// SPDX-License-Identifier: MIT

// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@.....        
// @[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@[email protected]        
// @@[email protected]@@@@[email protected]@@@@[email protected]@        
// @@[email protected]@@@[email protected]@@@[email protected]@@        
// @@@[email protected]@@@[email protected]@@@@@@@@@@@@@@@@@@@[email protected]@@@[email protected]@@        
// @@@@[email protected]@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@[email protected]@@@        
// @@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@[email protected]@@@@        
// @@@@@[email protected]@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@[email protected]@@@@        
// @@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@        
// @@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@        
// @@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@        
// @@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@        
// @@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@        
// @@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@        
// @@@@@@@@@[email protected]@@@@@[email protected]@@@@@@@@@@//////////@@@@@@@[email protected]@@@@@@@@@        
// @@@@@@@@@@[email protected]@@@@@@[email protected]@@@@@@@@@@/////////@@@@@@@[email protected]@@@@@@@@@@        
// @@@@@@@@@@@[email protected]@@@@@@@[email protected]@@@@@@@@@@////////@@@@@@@@[email protected]@@@@@@@@@@@        
// @@@@@@@@@@@@[email protected]@@@@@@@[email protected]@@@@@@@@@@///////@@@@@@@@[email protected]@@@@@@@@@@@@        
// @@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@        
// @@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@        
// @@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@        
// @@@@@@@@@@@@@@[email protected]@@@[email protected]@@@@@[email protected]@@@@[email protected]@@@@@@@@@@@@@@        
// @@@@@@@@@@@@@@@@@@@[email protected]@@@[email protected]@@@@@[email protected]@@@@[email protected]@@@@@@@@@@@@@@@@@@@        
// @@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@        
// @@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@ 

// By Top Dog Studios (@topdogstudios)
// We're hiring - come say hi!

pragma solidity ^0.8.17;

error MaxSupplyExceeded(uint256 maxSupply);
error SaleStateLimitExceeded(uint256 limit);
error IncorrectFunds(uint256 fundsRequired);
error InvalidSignature();
error SaleStateClosed();
error SaleStateNotActive();
error SaleStateAlreadyMinted();
error SaleStateQuantityExceeded();

import "./ERC721AQueryableWithOperatorFilterer.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

contract BasedHeads is
    ERC721AQueryableWithOperatorFilterer,
    EIP712,
    IERC2981,
    Ownable,
    PaymentSplitter,
    CantBeEvil
{
    enum SaleState {
        closed,
        open,
        allowlist,
        supporter
    }

    struct SaleStateParams {
        uint256 open;
        uint256 allowlist;
        uint256 supporter;
    }

    struct SaleInfo {
        mapping(SaleState => uint256) prices;
        mapping(SaleState => uint256) txLimits;
        mapping(SaleState => uint256) saleStateLimits;
        mapping(SaleState => uint256) saleStateMintCounter;
        mapping(SaleState => mapping(address => bool)) hasWalletMinted;
        SaleState saleState;
    }

    struct MintKey {
        SaleState saleState;
        uint8 quantity;
        address to;
    }

    bytes32 private constant MINTKEY_TYPE_HASH =
        keccak256("MintKey(uint8 saleState,uint8 quantity,address to)");
    uint256 private constant MAX_SUPPLY = 10_000;
    string private _baseTokenURI;
    address private _signer;
    address private _treasury;
    uint256 private _royaltyBps;
    SaleInfo private _saleInfo;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address signer,
        address treasury,
        uint256 royaltyBps,
        address[] memory payees,
        uint256[] memory shares,
        SaleStateParams memory prices,
        SaleStateParams memory txLimits,
        SaleStateParams memory saleStateLimits
    )
        ERC721AQueryableWithOperatorFilterer(name, symbol)
        EIP712(name, "1")
        CantBeEvil(LicenseVersion.EXCLUSIVE)
        PaymentSplitter(payees, shares)
    {
        _baseTokenURI = baseTokenURI;
        _signer = signer;
        _treasury = treasury;
        _royaltyBps = royaltyBps;
        _setPrices(prices);
        _setTxLimits(txLimits);
        _setSaleStateLimits(saleStateLimits);
    }

    modifier doesNotExceedMaxSupply(uint256 quantity) {
        if (totalSupply() + quantity > MAX_SUPPLY)
            revert MaxSupplyExceeded(MAX_SUPPLY);
        _;
    }

    modifier saleStateLimitGuard(uint256 quantity) {
        SaleState saleState = getSaleState();

        if (saleState == SaleState.closed)
            revert SaleStateClosed();

        if (
            _saleInfo.saleStateMintCounter[saleState] + quantity >
            _saleInfo.saleStateLimits[saleState]
        )
            revert SaleStateLimitExceeded(_saleInfo.saleStateLimits[saleState]);

        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string calldata baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function getSaleState() public view returns (SaleState) {
        return _saleInfo.saleState;
    }

    function setSaleState(SaleState saleState) external onlyOwner {
        _saleInfo.saleState = saleState;
    }

    function getPrice() public view returns (uint256) {
        SaleState saleState = getSaleState();

        if (saleState == SaleState.closed)
            return 0;

        return _saleInfo.prices[saleState];
    }

    function getMintCounter() public view returns (uint256) {
        SaleState saleState = getSaleState();
        
        if (saleState == SaleState.closed)
            return 0;

        return _saleInfo.saleStateMintCounter[saleState];
    }

    function getRemainingSaleStateSupply() public view returns (uint256) {
        SaleState saleState = getSaleState();

        if (saleState == SaleState.closed)
            return 0;

        return
            _saleInfo.saleStateLimits[saleState] -
            _saleInfo.saleStateMintCounter[saleState];
    }

    function canWalletMintInPhase(address minter) public view returns (bool) {
        SaleState saleState = getSaleState();
        return !_saleInfo.hasWalletMinted[saleState][minter];
    }

    function getSaleConfig(address minter) public view returns (SaleState, bool, uint256, uint256, uint256, uint256, uint256) {
        SaleState saleState = getSaleState();
        return (saleState, canWalletMintInPhase(minter), getPrice(), _saleInfo.txLimits[saleState], totalSupply(), getMintCounter(), getRemainingSaleStateSupply());
    }

    function _setPrices(SaleStateParams memory prices) private {
        _saleInfo.prices[SaleState.open] = prices.open;
        _saleInfo.prices[SaleState.allowlist] = prices.allowlist;
        _saleInfo.prices[SaleState.supporter] = prices.supporter;
    }

    function setPrices(SaleStateParams calldata prices) external onlyOwner {
        _setPrices(prices);
    }

    function _setTxLimits(SaleStateParams memory txLimits) private {
        _saleInfo.txLimits[SaleState.open] = txLimits.open;
        _saleInfo.txLimits[SaleState.allowlist] = txLimits.allowlist;
        _saleInfo.txLimits[SaleState.supporter] = txLimits.supporter;
    }

    function setTxLimits(SaleStateParams calldata txLimits) external onlyOwner {
        _setTxLimits(txLimits);
    }

    function _setSaleStateLimits(SaleStateParams memory saleStateLimits)
        private
    {
        _saleInfo.saleStateLimits[SaleState.open] = saleStateLimits.open;
        _saleInfo.saleStateLimits[SaleState.allowlist] = saleStateLimits.allowlist;
        _saleInfo.saleStateLimits[SaleState.supporter] = saleStateLimits.supporter;
    }

    function setSaleStateLimits(SaleStateParams calldata saleStateLimits)
        external
        onlyOwner
    {
        _setSaleStateLimits(saleStateLimits);
    }

    function reserveBasedHeads(address to, uint256 quantity)
        external
        doesNotExceedMaxSupply(quantity)
        onlyOwner
    {
        _safeMint(to, quantity);
    }

    function mintBasedHeads(bytes calldata signature, MintKey calldata mintKey)
        external
        payable
        doesNotExceedMaxSupply(mintKey.quantity)
        saleStateLimitGuard(mintKey.quantity)
    {
        SaleState saleState = getSaleState();

        if (getPrice() * mintKey.quantity != msg.value)
            revert IncorrectFunds(getPrice() * mintKey.quantity);

        if (saleState != mintKey.saleState)
            revert SaleStateNotActive();

        if (mintKey.quantity > _saleInfo.txLimits[saleState])
            revert SaleStateQuantityExceeded();

        // we need a valid signature from the API if it's not in the public phase
        if (saleState != SaleState.open) {
            if (_saleInfo.hasWalletMinted[saleState][mintKey.to])
                revert SaleStateAlreadyMinted();

            if (!verify(signature, mintKey))
                revert InvalidSignature();

            _saleInfo.hasWalletMinted[saleState][mintKey.to] = true;
        }

        _saleInfo.saleStateMintCounter[saleState] += mintKey.quantity;

        _safeMint(mintKey.to, mintKey.quantity);
    }

    function burnBasedHead(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function verify(bytes calldata signature, MintKey calldata mintKey)
        public
        view
        returns (bool)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    MINTKEY_TYPE_HASH,
                    mintKey.saleState,
                    mintKey.quantity,
                    mintKey.to
                )
            )
        );
        return ECDSA.recover(digest, signature) == _signer;
    }

    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _salePrice
    ) external view override returns (address, uint256) {
        return (_treasury, ((_salePrice * _royaltyBps) / 10000));
    }

    function setRoyaltyBps(uint256 royaltyBps) external onlyOwner {
        _royaltyBps = royaltyBps;
    }

    function setTreasury(address treasury) external onlyOwner {
        _treasury = treasury;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721A, IERC721A, CantBeEvil)
        returns (bool)
    {
        return
            _interfaceId == type(IERC2981).interfaceId ||
            ERC721A.supportsInterface(_interfaceId) ||
            CantBeEvil.supportsInterface(_interfaceId);
    }
}