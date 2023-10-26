// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CharaBaton is ERC1155, AccessControl, ERC1155Supply, DefaultOperatorFilterer {
    string public name;
    string public symbol;
    bool public burnEnabled = false;

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public merkleRoot;

    address public withdrawAddress = 0xCEF8d9251d3fF8674ba91ab24F0ee3652074EC64;
    uint256 public maxSupplyPerId = 1500;
    uint256 public mintCost = 0.001 ether;
    uint256 public maxMintForFCFS = 1;

    // 'id'はShikibuWorld.solの'burnMintIndex'と一致させて使うと分かりやすいです
    uint256 public id;
    // tokenIdごとにミント済みを記録
    mapping(address => mapping(uint256 => uint256)) public alMintCount;
    mapping(address => mapping(uint256 => uint256)) public fcfsMintCount;
    // tokenIdごとにtokenURIを設定
    mapping(uint256 => string) private _tokenURIs;

    enum SalePhase {
        Locked,
        ALSale,
        FCFSSale
    }

    SalePhase public phase = SalePhase.Locked;

    event phaseChanged(SalePhase phase);

    constructor() ERC1155("") {
        name = "Chara Baton";
        symbol = "CBT";
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);
        _grantRole(ADMIN, 0x1b632c9a883DF07A18d4b2813840E029bEceFf6D);
        _grantRole(ADMIN, 0x480d565527086DC3dc2262648194E1e9cCAB70EF);
        _grantRole(ADMIN, 0xf3CfAD477A0f8443b0b6E81BF7A4a1fF7B69D46f);
        _grantRole(ADMIN, 0x0dAE5FcaD0DF8E5C029D76927582DFBdFd7eeC79);
    }

    //// public functions ////

    // ミントにはAL登録が必須ですが、早押しもできるようにしてあります
    function publicMint(
        uint256 _mintAmount,
        uint256 _alAllocated,
        uint256 _fcfsAllocated,
        bytes32[] calldata _merkleProof
    ) external payable {
        // コントラクトからのミントガード
        require(msg.sender == tx.origin, "No smart contract");

        // セールフェイズチェック
        if (phase == SalePhase.Locked) {
            revert("Mint paused");
        }

        // ミント数がゼロでないこと
        require(_mintAmount > 0, "Mint more than 1");

        // merkleproofのチェック
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _alAllocated, _fcfsAllocated));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Merkle Proof");

        // ミントコストチェック
        require(mintCost * _mintAmount <= msg.value, "Not enough eth");

        // ミント数がmaxSupplyPerIdを超えていないかチェック
        require(_mintAmount + totalSupply(id) <= maxSupplyPerId, "Claim is over the max supply");

        // セール種別による分岐
        if (phase == SalePhase.ALSale) {
            // ミント数上限チェック
            require(alMintCount[msg.sender][id] + _mintAmount <= _alAllocated, "Exceeds your allocation");

            _mint(msg.sender, id, _mintAmount, "");

            // ミント数済み数加算
            alMintCount[msg.sender][id] += _mintAmount;
        } else if (phase == SalePhase.FCFSSale) {
            // ミント数上限チェック
            require(
                alMintCount[msg.sender][id] + fcfsMintCount[msg.sender][id] + _mintAmount
                    <= _alAllocated + maxMintForFCFS,
                "Exceeds your allocation"
            );

            _mint(msg.sender, id, _mintAmount, "");

            // ミント数済み数加算
            fcfsMintCount[msg.sender][id] += _mintAmount;
        }
    }

    // burnは「後から」でもidを指定して出来るようにしてあります
    function burn(address account, uint256 _id, uint256 amount) external {
        require(burnEnabled, "Burn paused");
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, _id, amount);
    }

    //// admin functions ////

    // 'id'はShikibuWorld.solの'burnMintIndex'と一致させて使うと分かりやすいです
    function setId(uint256 _newId) external onlyRole(ADMIN) {
        id = _newId;
    }

    function setPhase(SalePhase _phase) external onlyRole(ADMIN) {
        phase = _phase;
        emit phaseChanged(_phase);
    }

    function enableBurn(bool bool_) external onlyRole(ADMIN) {
        burnEnabled = bool_;
    }

    // tokenIdごとにtokenURIを設定
    function setURI(uint256 tokenId, string memory tokenURI) external onlyRole(ADMIN) {
        require(exists(tokenId), "URI query for nonexistent token");
        _tokenURIs[tokenId] = tokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(ADMIN) {
        merkleRoot = _merkleRoot;
    }

    function setMintCost(uint256 _newCost) external onlyRole(ADMIN) {
        mintCost = _newCost;
    }

    function setMaxMintForFCFS(uint256 _newAmount) external onlyRole(ADMIN) {
        maxMintForFCFS = _newAmount;
    }

    function setMaxSupplyPerId(uint256 _newSupply) external onlyRole(ADMIN) {
        maxSupplyPerId = _newSupply;
    }

    function adminMint(address to, uint256 tokenId, uint256 _mintAmount) public onlyRole(ADMIN) {
        _mint(to, tokenId, _mintAmount, "");
    }

    //// withdraw functions ////

    function setWithdrawAddress(address _withdrawAddress) external onlyRole(ADMIN) {
        withdrawAddress = _withdrawAddress;
    }

    function withdraw() external payable onlyRole(ADMIN) {
        require(withdrawAddress != address(0), "withdrawAddress shouldn't be 0");
        (bool sent,) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(sent, "failed to move fund to withdrawAddress contract");
    }

    //// overrides required by Solidity ////

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];
        return tokenURI;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //// overrides required by DefaultOperatorFilterer ////

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}