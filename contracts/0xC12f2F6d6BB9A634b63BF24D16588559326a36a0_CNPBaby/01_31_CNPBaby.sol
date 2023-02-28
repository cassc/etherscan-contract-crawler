// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "contract-allow-list/contracts/ERC721AntiScam/restrictApprove/ERC721RestrictApprove.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

//tokenURI interface
interface iTokenURI {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract CNPBaby is
    AccessControl,
    Ownable,
    RevokableDefaultOperatorFilterer,
    ERC2981,
    ERC721RestrictApprove
{
    // == Constants ==
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    address public constant HITODUMADAO_ADDRESS =
        0x376E2F69A4cF1E73A444055291F9b250166746a9;

    address public constant WITHDRAW_ADDRESS = HITODUMADAO_ADDRESS;

    // == For Creator fee ==
    address public royaltyAddress = HITODUMADAO_ADDRESS;
    uint96 public royaltyFee; // 0%, changable.

    constructor() ERC721Psi("CNP Baby", "CNPB") {
        //Role initialization
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AIRDROP_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(ADMIN, HITODUMADAO_ADDRESS);
        _grantRole(AIRDROP_ROLE, HITODUMADAO_ADDRESS);

        // Psiは0スタートなので、あとでバーンする
        _safeMint(msg.sender, 1);

        // ロイヤリティ0セット
        _setDefaultRoyalty(payable(HITODUMADAO_ADDRESS), 0);
    }

    //
    // withdraw section
    //
    function withdraw() external payable onlyRole(ADMIN) {
        (bool os, ) = payable(WITHDRAW_ADDRESS).call{
            value: address(this).balance
        }("");
        require(os);
    }

    //
    // Royalty setting
    // ロイヤリティパーセンテージセット（10%なら1000）
    // 
    function setRoyaltyFee(uint96 _feeNumerator) external onlyRole(ADMIN) {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    // ロイヤリティ受け取りアドレスセット
    function setRoyaltyAddress(
        address _royaltyAddress
    ) external onlyRole(ADMIN) {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    //
    // mint section
    //
    uint256 public cost; // freemint：0
    uint256 public maxSupply = 10000; // 総数1万
    uint256 public maxMintAmountPerTransaction = 60; //１トランザクションごとのミント最大数
    bool public paused = true; // コントラクトの停止フラグ
    bool public burnAndMintMode; //バー忍モードフラグ:false
    bytes32 public merkleRoot; // マークルツリールート
    uint256 public saleId; // ALセールからバー忍実施の時にミント済み数をリセットするため：0
    mapping(uint256 => mapping(address => uint256)) public userMintedAmount; // 前回ミント済み数

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    //mint with merkle tree
    function mint(
        uint256 _mintAmount,
        uint256 _maxMintAmount,
        bytes32[] calldata _merkleProof,
        uint256 _burnId
    ) external payable callerIsUser {
        // コントラクトがポーズ状態ではないか
        require(!paused, "the contract is paused");
        // ミントサイトから入力されたミント数量が1以上か
        require(0 < _mintAmount, "need to mint at least 1 NFT");
        // １トランザクションの最大ミント数以下か
        require(_mintAmount <= maxMintAmountPerTransaction, "max mint amount per session exceeded");
        // 現在のトークンIDとミント数量を合わせても最大供給量を超えないか
        require(
            _nextTokenId() - 1 + _mintAmount <= maxSupply,
            "max NFT limit exceeded"
        );
        // コスト×ミント数量より手持ちのETHが多いか
        require(cost * _mintAmount <= msg.value, "insufficient funds");

        //Merkle tree
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _maxMintAmount));

        // ALに登録されているか
        require(
            MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf),
            "user is not allowlisted"
        );

        // 今回ミント数量は「アドレスごとの最大ミント許可数ー前回ミント済み数」以下か
        require(
            _mintAmount <=
                _maxMintAmount - userMintedAmount[saleId][msg.sender],
            "max NFT per address exceeded"
        );

        // ミント済み数量に今回ミント数を加算
        userMintedAmount[saleId][msg.sender] += _mintAmount;

        // バー忍モードか
        if (burnAndMintMode == true) {
            require(_mintAmount == 1, "The number of mints is over");
            require(msg.sender == ownerOf(_burnId), "Owner is different");
            _burn(_burnId);
        }

        // ミント数量分ミント処理を行う
        _safeMint(msg.sender, _mintAmount);
    }

    // エアドロミント
    function airdropMint(
        address[] calldata _airdropAddresses,
        uint256[] memory _UserMintAmount
    ) external {
        require(
            hasRole(AIRDROP_ROLE, msg.sender),
            "Caller is not a air dropper"
        );
        require(
            _airdropAddresses.length == _UserMintAmount.length,
            "Array lengths are different"
        );
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            require(0 < _UserMintAmount[i], "need to mint at least 1 NFT");
            _mintAmount += _UserMintAmount[i];
        }
        require(
            (_nextTokenId() - 1) + _mintAmount <= maxSupply,
            "max NFT limit exceeded"
        );
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i]);
        }
    }

    // バー忍モードフラグ セット関数
    function setBurnAndMintMode(
        bool _burnAndMintMode
    ) external onlyRole(ADMIN) {
        burnAndMintMode = _burnAndMintMode;
    }

    // マークルルート セット関数
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(ADMIN) {
        merkleRoot = _merkleRoot;
    }

    // セール停止フラグ セット関数
    function setPause(bool _state) external onlyRole(ADMIN) {
        paused = _state;
    }

    // セールID　セット関数
    function setSaleId(uint256 _saleId) external onlyRole(ADMIN) {
        saleId = _saleId;
    }

    // NFTの総数 セット関数
    function setMaxSupply(uint256 _maxSupply) external onlyRole(ADMIN) {
        maxSupply = _maxSupply;
    }

    // NFTの値段　セット関数
    function setCost(uint256 _newCost) external onlyRole(ADMIN) {
        cost = _newCost;
    }

    // １回の処理で最大ミントできる枚数　セット関数
    function setMaxMintAmountPerTransaction(
        uint256 _maxMintAmountPerTransaction
    ) external onlyRole(ADMIN) {
        maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
    }

    // ALに登録されている人がどれだけすでにミントしたかセールIDごとに取得する関数
    function getUserMintedAmountBySaleId(
        uint256 _saleId,
        address _address
    ) external view returns (uint256) {
        return userMintedAmount[_saleId][_address];
    }

    // ALに登録されている人がどれだけすでにミントしたか取得する関数
    function getUserMintedAmount(
        address _address
    ) external view returns (uint256) {
        return userMintedAmount[saleId][_address];
    }

    //
    //URI section
    //
    string public baseURI;
    string public baseExtension = ".json";

    // JSONを取得するパスを保持する
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // JSONを取得するパスを保持する　セット関数
    function setBaseURI(string memory _newBaseURI) external onlyRole(ADMIN) {
        baseURI = _newBaseURI;
    }

    // JSONの拡張子を変更する　セット関数
    function setBaseExtension(
        string memory _newBaseExtension
    ) external onlyRole(ADMIN) {
        baseExtension = _newBaseExtension;
    }

    //
    //interface metadata
    //

    iTokenURI public interfaceOfTokenURI;
    bool public useInterfaceMetadata = false;

    function setInterfaceOfTokenURI(address _address) external onlyRole(ADMIN) {
        interfaceOfTokenURI = iTokenURI(_address);
    }

    function setUseInterfaceMetadata(bool _useInterfaceMetadata) external onlyRole(ADMIN) {
        useInterfaceMetadata = _useInterfaceMetadata;
    }


    //
    //token URI
    //
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (useInterfaceMetadata == true) {
            return interfaceOfTokenURI.tokenURI(tokenId);
        }
        
        return string(abi.encodePacked(ERC721Psi.tokenURI(tokenId), baseExtension));
    }

    //
    //burnin' section
    //
    function externalMint(address _address, uint256 _amount) external payable {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(
            _nextTokenId() - 1 + _amount <= maxSupply,
            "max NFT limit exceeded"
        );
        _safeMint(_address, _amount);
    }

    function externalBurn(uint256[] memory _burnTokenIds) external {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            require(msg.sender == ownerOf(tokenId), "Owner is different");
            _burn(tokenId);
        }
    }

    //
    // override ERC721RestrictApprove
    //
    function addLocalContractAllowList(
        address transferer
    ) external onlyRole(ADMIN) {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(
        address transferer
    ) external onlyRole(ADMIN) {
        _removeLocalContractAllowList(transferer);
    }

    function getLocalContractAllowList()
        external
        view
        returns (address[] memory)
    {
        return _getLocalContractAllowList();
    }

    function setCAL(address calAddress) external onlyRole(ADMIN) {
        _setCAL(calAddress);
    }

    function setCALLevel(uint256 level) external onlyRole(ADMIN) {
        CALLevel = level;
    }

    function setEnableRestrict(bool value) external onlyRole(ADMIN) {
        enableRestrict = value;
    }

    //
    //setDefaultRoyalty
    //
    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    //
    // override section
    //
    function grantRole(
        bytes32 role,
        address account
    ) public override onlyOwner {
        _grantRole(role, account);
    }

    function revokeRole(
        bytes32 role,
        address account
    ) public override onlyOwner {
        _revokeRole(role, account);
    }

    // OVERRIDES OperatorFilter functions
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    //
    //ERC721PsiAddressData section
    //

    // Mapping owner address to address data
    mapping(address => AddressData) _addressData;

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(
        address _owner
    ) public view virtual override returns (uint) {
        require(
            _owner != address(0),
            "ERC721Psi: balance query for the zero address"
        );
        return uint256(_addressData[_owner].balance);
    }

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(quantity < 2 ** 64);
        uint64 _quantity = uint64(quantity);

        if (from != address(0)) {
            _addressData[from].balance -= _quantity;
        } else {
            // Mint
            _addressData[to].numberMinted += _quantity;
        }

        if (to != address(0)) {
            _addressData[to].balance += _quantity;
        } else {
            // Burn
            _addressData[from].numberBurned += _quantity;
        }
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981,ERC721RestrictApprove, AccessControl)
        returns (bool)
    {
        return
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721RestrictApprove.supportsInterface(interfaceId);
    }
}