// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interface/IBlueChipGenesis.sol";

error InvalidMerkleProof();
error NotEnoughFunds(uint256 balance);
error NoMintFromContract();
error ExceedsAllocation();
error WrongMintAmount();
error MaxSupplyOver();

contract BlueChipGenesisMinter is AccessControl {
    IBlueChipGenesis public blueChipGenesis;

    bytes32 internal constant ADMIN = keccak256("ADMIN");

    bytes32 public merkleRoot;

    uint256 public constant MAX_SUPPLY = 9000;
    uint256 public constant MINT_COST = 0.005 ether;

    // フルミント済フラグ用bit配列 256*6=1536 が取り扱えるALウォレットの数
    uint256 private constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256[6] arr = [MAX_INT, MAX_INT, MAX_INT, MAX_INT, MAX_INT, MAX_INT];

    // 部分ミント済み数マッピング
    mapping(address => uint256) public mintCount;

    address public withdrawAddress = 0x4f4823F3639DdCC2B14093a28802E214C7C28D03;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(ADMIN, 0x407211BeF7cbca2C8897C580EC16c80F2ad5c966);
        _grantRole(ADMIN, 0x11F51b553ed8175Bf26faD5Eec20BEbAB31c0893);
    }

    /**
     * セール用ミント関数
     */
    /// @dev マークルツリーによるALミント関数（フルミント用）
    function allowListFullMint(uint256 _ticketNumber, uint256 _allocated, bytes32[] calldata _merkleProof)
        external
        payable
    {
        // コントラクトからのミントガード
        if (tx.origin != msg.sender) revert NoMintFromContract();

        //　部分ミント済みの場合はリバート
        if (mintCount[msg.sender] > 0) revert ExceedsAllocation();

        // merkleProofのチェック
        bytes32 leaf = keccak256(abi.encodePacked(_ticketNumber, "|", msg.sender, "|", _allocated));
        if (!MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf)) revert InvalidMerkleProof();

        // ミント代金のチェック
        if (msg.value == 0 || msg.value < _allocated * MINT_COST) revert NotEnoughFunds(msg.value);

        // ミントによりMAX SUPPLYを超えないかチェック
        if (_allocated + totalSupply() > MAX_SUPPLY) revert MaxSupplyOver();

        // フルミント済みかどうかのチェックと登録
        claimTicketOrBlockTransaction(_ticketNumber);

        // ミント
        blueChipGenesis.mint(msg.sender, _allocated);
    }

    /// @dev マークルツリーによるALミント関数（部分ミント用）
    function allowListPartialMint(
        uint256 _ticketNumber,
        uint256 _allocated,
        bytes32[] calldata _merkleProof,
        uint256 _mintAmount
    ) external payable {
        // コントラクトからのミントガード
        if (tx.origin != msg.sender) revert NoMintFromContract();

        // フルミント済みの場合はリバート
        if (getStoredBit(_ticketNumber) != 1) revert ExceedsAllocation();

        // merkleProofのチェック
        bytes32 leaf = keccak256(abi.encodePacked(_ticketNumber, "|", msg.sender, "|", _allocated));
        if (!MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf)) revert InvalidMerkleProof();

        // ミント代金のチェック
        if (msg.value == 0 || msg.value < _mintAmount * MINT_COST) revert NotEnoughFunds(msg.value);

        // ミントによりMAX SUPPLYを超えないかチェック
        if (_mintAmount + totalSupply() > MAX_SUPPLY) revert MaxSupplyOver();

        // ミント数の保有枠上限チェック
        if (mintCount[msg.sender] + _mintAmount > _allocated) revert ExceedsAllocation();

        // ミント数済み数加算
        unchecked {
            mintCount[msg.sender] += _mintAmount;
        }

        // ミント
        blueChipGenesis.mint(msg.sender, _mintAmount);
    }

    // ウォレット番号（ticket）ごとにミント済フラグを管理する関数
    function claimTicketOrBlockTransaction(uint256 ticketNumber) private {
        require(ticketNumber < arr.length * 256, "bad ticket");

        uint256 storageOffset;
        uint256 offsetWithin256;
        uint256 localGroup;
        uint256 storedBit;

        unchecked {
            storageOffset = ticketNumber / 256;
            offsetWithin256 = ticketNumber % 256;
        }
        localGroup = arr[storageOffset];
        storedBit = (localGroup >> offsetWithin256) & uint256(1);
        // ミント済みの場合はリバート
        if (storedBit != 1) revert ExceedsAllocation();
        // 未ミントの場合はフラグを立てる
        localGroup = localGroup & ~(uint256(1) << offsetWithin256);
        arr[storageOffset] = localGroup;
    }

    /// @dev ミント済フラグのgetter関数
    function getStoredBit(uint256 ticketNumber) public view returns (uint256) {
        require(ticketNumber < arr.length * 256, "bad ticket");

        uint256 storageOffset;
        uint256 offsetWithin256;
        uint256 localGroup;
        uint256 storedBit;

        unchecked {
            storageOffset = ticketNumber / 256;
            offsetWithin256 = ticketNumber % 256;
        }

        localGroup = arr[storageOffset];
        storedBit = (localGroup >> offsetWithin256) & uint256(1);

        return storedBit;
    }

    /**
     * withdraw関数
     */
    /// @dev 引出し先アドレスのsetter関数
    function setWithdrawAddress(address _withdrawAddress) external onlyRole(ADMIN) {
        withdrawAddress = _withdrawAddress;
    }

    /// @dev 引出し用関数
    function withdraw() external payable onlyRole(ADMIN) {
        require(withdrawAddress != address(0), "withdrawAddress can't be 0");
        (bool sent,) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(sent, "failed to withdraw");
    }

    /**
     * ADMIN用 setter関数
     */
    /// @dev 親コントラクトのsetter関数
    function setBlueChipGenesis(address _contractAddress) external onlyRole(ADMIN) {
        blueChipGenesis = IBlueChipGenesis(_contractAddress);
    }

    /// @dev マークルルートのsetter関数
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(ADMIN) {
        merkleRoot = _merkleRoot;
    }

    /**
     * その他の関数
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return (AccessControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId));
    }

    function totalSupply() public view returns (uint256) {
        return blueChipGenesis.totalSupply();
    }
}