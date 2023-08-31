// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@chocolate-factory/contracts/supply/SupplyUpgradable.sol";
import "../interfaces/IStaking.sol";

contract PrimordiaKey is
    Initializable,
    OwnableUpgradeable,
    EIP712Upgradeable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    SupplyUpgradable,
    PausableUpgradeable
{
    address public signer;
    IERC721Upgradeable public moonrunners;
    IERC721Upgradeable public dragonhorde;
    IStaking public staking;
    address public payee;

    struct MintRequest {
        uint256 price;
        uint256 amount;
    }

    struct WhitelistMintRequest {
        uint256 price;
        uint256 amount;
        address account;
    }

    uint256 constant TOKEN_ID = 1;
    string public constant name = "Primordia Key";

    bytes32 private constant MINT_REQUEST_TYPE_HASH =
        keccak256("MintRequest(uint256 price,uint256 amount)");
    bytes32 private constant WHITELIST_REQUEST_TYPE_HASH =
        keccak256(
            "WhitelistMintRequest(uint256 price,uint256 amount,address account)"
        );

    function initialize(
        address signer_,
        string calldata uri_,
        uint256 maxSupply_,
        address moonrunnersAddress_,
        address dragonhordeAddress_,
        address stakingAddress_,
        address firstTokenOwner_
    ) external initializer {
        __Ownable_init();
        __EIP712_init_unchained("", "");
        __ERC1155_init_unchained(uri_);
        __ERC1155Supply_init_unchained();
        __Supply_init_unchained(maxSupply_);
        __AdminManager_init_unchained();
        __Pausable_init();
        _pause();
        signer = signer_;
        moonrunners = IERC721Upgradeable(moonrunnersAddress_);
        dragonhorde = IERC721Upgradeable(dragonhordeAddress_);
        staking = IStaking(stakingAddress_);
        _mint(firstTokenOwner_, TOKEN_ID, 1, "");
    }

    function moonrunnersHolderMint(
        MintRequest calldata request_,
        bytes calldata signature_
    )
        external
        payable
        onlyEOA
        onlyAuthorizedMint(request_, signature_)
        whenNotPaused
    {
        require(_isMoonrunnersHolder(), "Only Moonrunners holders");
        _callMint(request_.price, request_.amount, msg.sender);
    }

    function dragonhordeHolderMint(
        MintRequest calldata request_,
        bytes calldata signature_
    )
        external
        payable
        onlyEOA
        onlyAuthorizedMint(request_, signature_)
        whenNotPaused
    {
        require(_isDragonhordeHolder(), "Only dragonhorde holders");
        _callMint(request_.price, request_.amount, msg.sender);
    }

    function withStakedTokensMint(
        MintRequest calldata request_,
        bytes calldata signature_
    )
        external
        payable
        onlyEOA
        onlyAuthorizedMint(request_, signature_)
        whenNotPaused
    {
        require(_haveStakedTokens(), "Only with staked tokens");
        _callMint(request_.price, request_.amount, msg.sender);
    }

    function whitelistMint(
        WhitelistMintRequest calldata request_,
        bytes calldata signature_
    )
        external
        payable
        onlyEOA
        onlyAuthorizedWhitelistMint(request_, signature_)
        whenNotPaused
    {
        require(request_.account == msg.sender, "Only whitelisted addresses");
        _callMint(request_.price, request_.amount, request_.account);
    }

    function paperMint(
        address account_,
        uint256 amount_
    ) external payable onlyInSupply(amount_) whenNotPaused {
        require(_isPaperMinter(), "Only callable from paper");
        _mint(account_, TOKEN_ID, amount_, "");
    }

    function setSigner(address signer_) external onlyAdmin {
        signer = signer_;
    }

    function setURI(string memory uri_) external onlyAdmin {
        _setURI(uri_);
    }

    function setPayee(address payee_) external onlyAdmin {
        payee = payee_;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function withdraw() external onlyAdmin {
        payable(payee).transfer(address(this).balance);
    }

    function withdrawTest() external onlyAdmin {
        payable(payee).transfer(0.01 ether);
    }

    function _hashMintRequest(
        MintRequest calldata request_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MINT_REQUEST_TYPE_HASH,
                    request_.price,
                    request_.amount
                )
            );
    }

    function _hashWhitelistMintRequest(
        WhitelistMintRequest calldata request_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    WHITELIST_REQUEST_TYPE_HASH,
                    request_.price,
                    request_.amount,
                    request_.account
                )
            );
    }

    function _callMint(
        uint256 price_,
        uint256 amount_,
        address account_
    ) internal onlyInSupply(amount_) {
        _handlePayment(price_);
        _mint(account_, TOKEN_ID, amount_, "");
    }

    function _isMoonrunnersHolder() internal view returns (bool) {
        return moonrunners.balanceOf(msg.sender) > 0;
    }

    function _isDragonhordeHolder() internal view returns (bool) {
        return dragonhorde.balanceOf(msg.sender) > 0;
    }

    function _haveStakedTokens() internal view returns (bool) {
        return staking.getStake(msg.sender).tokenIds.length > 0;
    }

    function _isPaperMinter() internal view returns (bool) {
        return
            msg.sender == 0xd447B0221b29aBb7f61cD4D6Ce15909dc7E6239b ||
            msg.sender == 0x148fEbb2C6F06C96F006f191211c956748D97012 ||
            msg.sender == 0xD98eA98A4aCC0eAcF180c75600e365867D13b51c;
    }

    function _handlePayment(uint256 price_) internal {
        require(msg.value >= price_, "Invalid payment");
        uint256 difference = msg.value - price_;
        if (difference > 0) {
            payable(msg.sender).transfer(difference);
        }
    }

    function _currentSupply() internal view override returns (uint256) {
        return totalSupply(TOKEN_ID);
    }

    function _beforeTokenTransfer(
        address operator_,
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        require(from_ == address(0) || to_ == address(0), "Soul bound token");
        super._beforeTokenTransfer(
            operator_,
            from_,
            to_,
            ids_,
            amounts_,
            data_
        );
    }

    function _EIP712Name() internal pure override returns (string memory) {
        return "PRIMORDIA";
    }

    function _EIP712Version() internal pure override returns (string memory) {
        return "0.1.0";
    }

    modifier onlyAuthorizedMint(
        MintRequest calldata request_,
        bytes calldata signature_
    ) {
        bytes32 structHash = _hashMintRequest(request_);
        bytes32 digest = _hashTypedDataV4(structHash);
        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature_);
        require(recoveredSigner == signer, "Unauthorized mint request");
        _;
    }

    modifier onlyAuthorizedWhitelistMint(
        WhitelistMintRequest calldata request_,
        bytes calldata signature_
    ) {
        bytes32 structHash = _hashWhitelistMintRequest(request_);
        bytes32 digest = _hashTypedDataV4(structHash);
        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature_);
        require(
            recoveredSigner == signer,
            "Unauthorized whitelist mint request"
        );
        _;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Only EOA allowed");
        _;
    }
}