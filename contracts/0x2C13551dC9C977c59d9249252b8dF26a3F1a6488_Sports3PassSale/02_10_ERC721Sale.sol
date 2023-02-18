// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC721Core } from "./interfaces/IERC721Core.sol";
import { SaleRoles } from "./SaleRoles.sol";

contract ERC721Sale is SaleRoles {
    struct SecretSaleData {
        bytes32 merkleRoot;
        uint256 totalSupply;
        uint256 maxSupply;
        mapping(address => uint256) issuedAmountPerAddress;
        bool isSale;
    }

    struct SaleData {
        mapping(address => uint256) issuedAmountPerAddress;
        uint256 maxAmountPerAddress;
        bool isSale;
    }

    SecretSaleData private _freeSecretSaleData;
    SecretSaleData private _preSecretSaleData;
    SaleData private _publicSaleData;
    address private _earningAddress;
    address private _mintAddress;
    uint256 private _prePrice;
    uint256 private _publicPrice;

    /*------------------------------------------------
     * ERC721Sale
     *----------------------------------------------*/

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "caller is another contract"); // solhint-disable-line avoid-tx-origin
        _;
    }

    event FreeMintData(bytes32 merkleRoot, uint256 maxSupply, bool isSale);

    event PreMintData(
        bytes32 merkleRoot,
        uint256 maxSupply,
        uint256 price,
        bool isSale
    );

    event PublicMintData(
        uint256 maxAmountPerAddress,
        uint256 price,
        bool isSale
    );

    event MintAddress(
        address indexed previousAddress,
        address indexed newAddress
    );

    event EarningAddress(
        address indexed previousAddress,
        address indexed newAddress
    );

    event Withdraw(address indexed recipient, uint256 sendValue);

    constructor(address newMintAddress) {
        _setMintAddress(newMintAddress);
    }

    /*------------------------------------------------
     * Free Mint
     *----------------------------------------------*/

    function freeMint(
        bytes32[] calldata proof,
        uint256 amount,
        uint256 maxAmountPerAddress
    ) external callerIsUser whenNotPaused {
        require(_freeSecretSaleData.isSale == true, "not sale");
        require(
            (_freeSecretSaleData.issuedAmountPerAddress[msg.sender] + amount) <=
                maxAmountPerAddress,
            "over amount by address"
        );
        require(
            (_freeSecretSaleData.totalSupply + amount) <=
                _freeSecretSaleData.maxSupply,
            "over amount by total"
        );
        bytes32 leaf = keccak256(
            abi.encodePacked(msg.sender, maxAmountPerAddress)
        );
        require(
            MerkleProof.verify(proof, _freeSecretSaleData.merkleRoot, leaf),
            "invalid proof"
        );

        _freeSecretSaleData.issuedAmountPerAddress[msg.sender] += amount;
        _freeSecretSaleData.totalSupply += amount;

        IERC721Core erc721CoreMint = IERC721Core(_mintAddress);
        erc721CoreMint.mint(msg.sender, amount);
    }

    function setFreeMintData(
        bytes32 newMerkleRoot,
        uint256 newMaxSupply,
        bool newSale
    ) external onlyOperator {
        _freeSecretSaleData.merkleRoot = newMerkleRoot;
        _freeSecretSaleData.maxSupply = newMaxSupply;
        _freeSecretSaleData.isSale = newSale;
        emitFreeMintData();
    }

    function setFreeMintMerkleRoot(bytes32 newMerkleRoot)
        external
        onlyOperator
    {
        _freeSecretSaleData.merkleRoot = newMerkleRoot;
        emitFreeMintData();
    }

    function setFreeMintMaxSupply(uint256 newMaxSupply) external onlyOperator {
        _freeSecretSaleData.maxSupply = newMaxSupply;
        emitFreeMintData();
    }

    function setFreeMintSale(bool newSale) external onlyOperator {
        _freeSecretSaleData.isSale = newSale;
        emitFreeMintData();
    }

    function freeMintData()
        external
        view
        returns (
            bytes32,
            uint256,
            uint256,
            bool
        )
    {
        return (
            _freeSecretSaleData.merkleRoot,
            _freeSecretSaleData.totalSupply,
            _freeSecretSaleData.maxSupply,
            _freeSecretSaleData.isSale
        );
    }

    function freeMintIssuedAmountOf(address minter)
        external
        view
        returns (uint256)
    {
        return _freeSecretSaleData.issuedAmountPerAddress[minter];
    }

    function freeMintRemainAmountOf(address minter, uint256 maxAmountPerAddress)
        external
        view
        returns (uint256)
    {
        require(_freeSecretSaleData.isSale == true, "not sale");
        require(
            _freeSecretSaleData.issuedAmountPerAddress[minter] <
                maxAmountPerAddress,
            "address reached the max"
        );
        require(
            _freeSecretSaleData.totalSupply < _freeSecretSaleData.maxSupply,
            "total reached the max"
        );

        IERC721Core erc721Core = IERC721Core(_mintAddress);
        uint256 remainSupply = erc721Core.remainSupply();
        require(0 < remainSupply, "core reached the max");

        uint256 remainByAddress = maxAmountPerAddress -
            _freeSecretSaleData.issuedAmountPerAddress[minter];
        uint256 remainByTotal = _freeSecretSaleData.maxSupply -
            _freeSecretSaleData.totalSupply;
        if (
            (remainSupply < remainByTotal) && (remainSupply < remainByAddress)
        ) {
            return remainSupply;
        }
        return
            remainByTotal < remainByAddress ? remainByTotal : remainByAddress;
    }

    function emitFreeMintData() internal {
        emit FreeMintData(
            _freeSecretSaleData.merkleRoot,
            _freeSecretSaleData.maxSupply,
            _freeSecretSaleData.isSale
        );
    }

    /*------------------------------------------------
     * Pre Mint
     *----------------------------------------------*/

    function preMint(
        bytes32[] calldata proof,
        uint256 amount,
        uint256 maxAmountPerAddress
    ) external payable callerIsUser whenNotPaused {
        require(_preSecretSaleData.isSale == true, "not sale");
        require(
            (_preSecretSaleData.issuedAmountPerAddress[msg.sender] + amount) <=
                maxAmountPerAddress,
            "over amount by address"
        );
        require(
            (_preSecretSaleData.totalSupply + amount) <=
                _preSecretSaleData.maxSupply,
            "over amount by total"
        );
        require((_prePrice * amount) <= msg.value, "not enough value");
        bytes32 leaf = keccak256(
            abi.encodePacked(msg.sender, maxAmountPerAddress)
        );
        require(
            MerkleProof.verify(proof, _preSecretSaleData.merkleRoot, leaf),
            "invalid proof"
        );

        if ((_earningAddress != address(0)) && (0 < msg.value)) {
            (bool success, ) = _earningAddress.call{ value: msg.value }(""); // solhint-disable-line avoid-low-level-calls
            require(success, "failed to withdraw");
        }

        _preSecretSaleData.issuedAmountPerAddress[msg.sender] += amount;
        _preSecretSaleData.totalSupply += amount;

        IERC721Core erc721Core = IERC721Core(_mintAddress);
        erc721Core.mint(msg.sender, amount);
    }

    function setPreMintData(
        bytes32 newMerkleRoot,
        uint256 newMaxSupply,
        uint256 newPrice,
        bool newSale
    ) external onlyOperator {
        _preSecretSaleData.merkleRoot = newMerkleRoot;
        _preSecretSaleData.maxSupply = newMaxSupply;
        _prePrice = newPrice;
        _preSecretSaleData.isSale = newSale;
        emitPreMintData();
    }

    function setPreMintMerkleRoot(bytes32 newMerkleRoot) external onlyOperator {
        _preSecretSaleData.merkleRoot = newMerkleRoot;
        emitPreMintData();
    }

    function setPreMintMaxSupply(uint256 newMaxSupply) external onlyOperator {
        _preSecretSaleData.maxSupply = newMaxSupply;
        emitPreMintData();
    }

    function setPreMintPrice(uint256 newPrice) external onlyOperator {
        _prePrice = newPrice;
        emitPreMintData();
    }

    function setPreMintSale(bool newSale) external onlyOperator {
        _preSecretSaleData.isSale = newSale;
        emitPreMintData();
    }

    function preMintData()
        external
        view
        returns (
            bytes32,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            _preSecretSaleData.merkleRoot,
            _preSecretSaleData.totalSupply,
            _preSecretSaleData.maxSupply,
            _prePrice,
            _preSecretSaleData.isSale
        );
    }

    function preMintIssuedAmountOf(address minter)
        external
        view
        returns (uint256)
    {
        return _preSecretSaleData.issuedAmountPerAddress[minter];
    }

    function preMintRemainAmountOf(address minter, uint256 maxAmountPerAddress)
        external
        view
        returns (uint256)
    {
        require(_preSecretSaleData.isSale == true, "not sale");
        require(
            _preSecretSaleData.issuedAmountPerAddress[minter] <
                maxAmountPerAddress,
            "address reached the max"
        );
        require(
            _preSecretSaleData.totalSupply < _preSecretSaleData.maxSupply,
            "total reached the max"
        );

        IERC721Core erc721Core = IERC721Core(_mintAddress);
        uint256 remainSupply = erc721Core.remainSupply();
        require(0 < remainSupply, "core reached the max");

        uint256 remainByAddress = maxAmountPerAddress -
            _preSecretSaleData.issuedAmountPerAddress[minter];
        uint256 remainByTotal = _preSecretSaleData.maxSupply -
            _preSecretSaleData.totalSupply;
        if (
            (remainSupply < remainByTotal) && (remainSupply < remainByAddress)
        ) {
            return remainSupply;
        }
        return
            remainByTotal < remainByAddress ? remainByTotal : remainByAddress;
    }

    function emitPreMintData() internal {
        emit PreMintData(
            _preSecretSaleData.merkleRoot,
            _preSecretSaleData.maxSupply,
            _prePrice,
            _preSecretSaleData.isSale
        );
    }

    /*------------------------------------------------
     * Public Mint
     *----------------------------------------------*/

    function publicMint(uint256 amount)
        external
        payable
        callerIsUser
        whenNotPaused
    {
        require(_publicSaleData.isSale == true, "not sale");
        require(
            (_publicSaleData.issuedAmountPerAddress[msg.sender] + amount) <=
                _publicSaleData.maxAmountPerAddress,
            "over amount by address"
        );
        require((_publicPrice * amount) <= msg.value, "not enough value");

        if ((_earningAddress != address(0)) && (0 < msg.value)) {
            (bool success, ) = _earningAddress.call{ value: msg.value }(""); // solhint-disable-line avoid-low-level-calls
            require(success, "failed to withdraw");
        }

        _publicSaleData.issuedAmountPerAddress[msg.sender] += amount;

        IERC721Core erc721Core = IERC721Core(_mintAddress);
        erc721Core.mint(msg.sender, amount);
    }

    function setPublicMintData(
        uint256 newMaxAmountPerAddress,
        uint256 newPrice,
        bool newSale
    ) external onlyOperator {
        _publicSaleData.maxAmountPerAddress = newMaxAmountPerAddress;
        _publicPrice = newPrice;
        _publicSaleData.isSale = newSale;
        emitPublicMintData();
    }

    function setPublicMintMaxAmountPerAddress(uint256 newMaxAmountPerAddress)
        external
        onlyOperator
    {
        _publicSaleData.maxAmountPerAddress = newMaxAmountPerAddress;
        emitPublicMintData();
    }

    function setPublicMintPrice(uint256 newPrice) external onlyOperator {
        _publicPrice = newPrice;
        emitPublicMintData();
    }

    function setPublicMintSale(bool newSale) external onlyOperator {
        _publicSaleData.isSale = newSale;
        emitPublicMintData();
    }

    function publicMintData()
        external
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (
            _publicSaleData.maxAmountPerAddress,
            _publicPrice,
            _publicSaleData.isSale
        );
    }

    function publicMintIssuedAmountOf(address minter)
        external
        view
        returns (uint256)
    {
        return _publicSaleData.issuedAmountPerAddress[minter];
    }

    function publicMintRemainAmountOf(address minter)
        external
        view
        returns (uint256)
    {
        require(_publicSaleData.isSale == true, "not sale");
        require(
            _publicSaleData.issuedAmountPerAddress[minter] <
                _publicSaleData.maxAmountPerAddress,
            "address reached the max"
        );

        IERC721Core erc721Core = IERC721Core(_mintAddress);
        uint256 remainSupply = erc721Core.remainSupply();
        require(0 < remainSupply, "core reached the max");

        uint256 remainByAddress = _publicSaleData.maxAmountPerAddress -
            _publicSaleData.issuedAmountPerAddress[minter];
        return remainSupply < remainByAddress ? remainSupply : remainByAddress;
    }

    function emitPublicMintData() internal {
        emit PublicMintData(
            _publicSaleData.maxAmountPerAddress,
            _publicPrice,
            _publicSaleData.isSale
        );
    }

    /*------------------------------------------------
     * Other external
     *----------------------------------------------*/

    function coreSupplies()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IERC721Core erc721Core = IERC721Core(_mintAddress);
        return erc721Core.supplies();
    }

    function mintAddress() external view returns (address) {
        return _mintAddress;
    }

    function setMintAddress(address newMintAddress) external onlyOperator {
        _setMintAddress(newMintAddress);
    }

    function earningAddress() external view returns (address) {
        return _earningAddress;
    }

    function setEarningAddress(address newEarningAddress)
        external
        onlyFinancial
    {
        _setEarningAddress(newEarningAddress);
    }

    function withdraw() external onlyFinancial {
        require(_earningAddress != address(0), "invalid earning address");
        uint256 sendValue = address(this).balance;
        require(0 < sendValue, "empty balance");

        (bool success, ) = _earningAddress.call{ value: sendValue }(""); // solhint-disable-line avoid-low-level-calls
        require(success, "failed to withdraw");
        emit Withdraw(_earningAddress, sendValue);
    }

    /*------------------------------------------------
     * Other internal
     *----------------------------------------------*/

    function _setMintAddress(address newMintAddress) internal {
        address previousMintAddress = _mintAddress;
        _mintAddress = newMintAddress;
        emit MintAddress(previousMintAddress, _mintAddress);
    }

    function _setEarningAddress(address newEarningAddress) internal {
        address previousEarningAddress = _earningAddress;
        _earningAddress = newEarningAddress;
        emit EarningAddress(previousEarningAddress, _earningAddress);
    }
}