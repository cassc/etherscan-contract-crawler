// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/ERC721.sol";
import "./interfaces/IERC1271.sol";
import "./interfaces/IEMates.sol";
import "./libraries/Signature.sol";

contract EMates is Ownable, ERC721("DSC E-MATES | 4 DA NEXT LEVEL", "EMATES"), IERC2981, IEMates {
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    // keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

    // keccak256("Permit(address owner,address spender,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_ALL_TYPEHASH = 0xdaab21af31ece73a508939fedd476a5ee5129a5ed4bb091f3236ffb45394df62;

    mapping(uint256 => uint256) public nonces;
    mapping(address => uint256) public noncesForAll;

    uint256 public totalSupply;
    mapping(address => bool) public isMinter;

    address public feeReceiver;
    uint256 public fee; //out of 10000

    string internal __baseURI;
    string public contractURI;

    constructor(address _feeReceiver, uint256 _fee) {
        _CACHED_CHAIN_ID = block.chainid;
        _HASHED_NAME = keccak256(bytes("DSC E-MATES | 4 DA NEXT LEVEL"));
        _HASHED_VERSION = keccak256(bytes("1"));
        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, _CACHED_CHAIN_ID, address(this))
        );

        isMinter[msg.sender] = true;
        _setRoyaltyInfo(_feeReceiver, _fee);

        __baseURI = "https://api.dogesound.club/emates/";
        contractURI = "https://api.dogesound.club/emates";
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        __baseURI = baseURI_;

        emit SetBaseURI(baseURI_);
    }

    function setContractURI(string calldata uri) external onlyOwner {
        contractURI = uri;

        emit SetContractURI(uri);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, block.chainid, address(this)));
        }
    }

    function permit(
        address spender,
        uint256 id,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "EMATES: Expired deadline");
        bytes32 _DOMAIN_SEPARATOR = DOMAIN_SEPARATOR();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, spender, id, nonces[id]++, deadline))
            )
        );

        address owner = ownerOf(id);
        require(spender != owner, "EMATES: Invalid spender");

        if (Address.isContract(owner)) {
            require(
                IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e,
                "EMATES: Unauthorized"
            );
        } else {
            address recoveredAddress = Signature.recover(digest, v, r, s);
            require(recoveredAddress == owner, "EMATES: Unauthorized");
        }

        _approve(spender, id);
    }

    function permitAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "EMATES: Expired deadline");
        bytes32 _DOMAIN_SEPARATOR = DOMAIN_SEPARATOR();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_ALL_TYPEHASH, owner, spender, noncesForAll[owner]++, deadline))
            )
        );

        if (Address.isContract(owner)) {
            require(
                IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e,
                "EMATES: Unauthorized"
            );
        } else {
            address recoveredAddress = Signature.recover(digest, v, r, s);
            require(recoveredAddress == owner, "EMATES: Unauthorized");
        }

        _setApprovalForAll(owner, spender, true);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setMinter(address target, bool _isMinter) external onlyOwner {
        require(isMinter[target] != _isMinter, "EMATES: Permission not changed");
        isMinter[target] = _isMinter;
        emit SetMinter(target, _isMinter);
    }

    function setRoyaltyInfo(address _receiver, uint256 _fee) external onlyOwner {
        _setRoyaltyInfo(_receiver, _fee);
    }

    function _setRoyaltyInfo(address _receiver, uint256 _fee) internal {
        require(_fee < 10000, "EMATES: Invalid Fee");
        feeReceiver = _receiver;
        fee = _fee;
        emit SetRoyaltyInfo(_receiver, _fee);
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (feeReceiver, (_salePrice * fee) / 10000);
    }
    
    function mint(address to) external returns (uint256 id) {
        require(isMinter[msg.sender], "EMATES: Forbidden");
        id = totalSupply;
        _mint(to, id);
        totalSupply += 1;
    }

    function mintBatch(uint256 limit) external {
        require(isMinter[msg.sender], "EMATES: Forbidden");
        uint256 id = totalSupply;
        for (uint256 i = 0; i < limit - id; i++) {
            _mint(msg.sender, id + i);
        }
        totalSupply = limit;
    }
}