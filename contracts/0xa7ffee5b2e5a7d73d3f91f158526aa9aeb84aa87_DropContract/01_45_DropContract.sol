// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@thirdweb-dev/contracts/extension/PlatformFee.sol";
import "./BaseContract.sol";

contract DropContract is BaseContract, PlatformFee  {
    address public deployer;

    mapping(uint256 => bool) private tokenLocks;
    mapping(address => bool) private walletLocks;
    mapping(address => bool) private contractAllowList;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    event LockStatusChanged(
        address indexed lockedAddress,
        uint256 indexed tokenId,
        bool isLocked
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    ) BaseContract(
        _name, 
        _symbol,
        _royaltyRecipient,
        _royaltyBps,
        _primarySaleRecipient
    ) 
    {
        deployer = msg.sender;
    }
    
    function _canSetPlatformFeeInfo() internal view virtual override returns (bool) {
        return msg.sender == deployer;
    }

    function transform(
        uint256 _batchId,
        string memory _newUri
    ) public virtual returns (string memory) {
        require(deployer == msg.sender, "Not authorized");
        //string memory tokenURI = tokenURI(_batchId);
        _setBaseURI(_batchId, _newUri);
        return _newUri;
    }

    // トークンごとのロックを設定する関数
    function lockToken(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Not Owner of Token");
        tokenLocks[_tokenId] = true;
        emit LockStatusChanged(msg.sender, _tokenId, true);
    }

    // トークンごとのロックを解除する関数
    function unlockToken(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Not Owner of Token");
        tokenLocks[_tokenId] = false;
        emit LockStatusChanged(msg.sender, _tokenId, false);
    }

    // ウォレットのロックを設定する関数
    function lockWallet(address _wallet) external {
        require(_wallet == msg.sender || deployer == msg.sender, "Not authorized");
        walletLocks[_wallet] = true;
        emit LockStatusChanged(_wallet, 0, true);
    }

    // ウォレットのロックを解除する関数
    function unlockWallet(address _wallet) external {
        require(_wallet == msg.sender || deployer == msg.sender, "Not authorized");
        walletLocks[_wallet] = false;
        emit LockStatusChanged(_wallet, 0, false);
    }

    // コントラクトのアドレスを許可する関数
    function allowContract(address _contract) external {
        require(deployer == msg.sender, "Not authorized");
        contractAllowList[_contract] = true;
    }

    // コントラクトのアドレスを禁止する関数
    function disallowContract(address _contract) external {
        require(deployer == msg.sender, "Not authorized");
        contractAllowList[_contract] = false;
    }

    // コントラクトのアドレスが許可リストに含まれているかどうかを確認するヘルパー関数
    function isContractAllowed(address _contract) public view returns (bool) {
        return contractAllowList[_contract];
    }

    // トークンのロック状態を確認するヘルパー関数
    function isTokenLocked(uint256 _tokenId) public view returns (bool) {
        return tokenLocks[_tokenId];
    }

    // ウォレットのロック状態を確認するヘルパー関数
    function isWalletLocked(address _wallet) public view returns (bool) {
        return walletLocks[_wallet];
    }

    // トークンごとの Approval を設定する関数
    function approve(address _operator, uint256 _tokenId) public override {
        require(!tokenLocks[_tokenId], "Approval is locked for this token.");
        require(
            !tokenLocks[_tokenId] && (contractAllowList[_operator] || _operator == deployer),
            "Approval is locked for this token."
        );
        super.approve(_operator, _tokenId);
    }

    // ウォレットの ApprovalForAll の実装
    function setApprovalForAll(
        address _operator,
        bool _approved
    ) public override {
        require(
            !walletLocks[_operator] && (contractAllowList[_operator] || _operator == deployer),
            "ApprovalForAll is locked for this wallet."
        );
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
        super.setApprovalForAll(_operator, _approved);
    }

    // ApprovalForAllの状態を取得する関数
    function getApprovalForAll(
        address _owner,
        address _operator
    ) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }
}