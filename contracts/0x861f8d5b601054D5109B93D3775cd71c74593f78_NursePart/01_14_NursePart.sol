// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/ERC1155.sol";
import "./interfaces/IERC1271.sol";
import "./interfaces/INursePart.sol";
import "./libraries/Signature.sol";
import "./interfaces/IERC2981.sol";

contract NursePart is Ownable, ERC1155("https://api.maidcoin.org/nurseparts/{id}"), IERC2981, INursePart {
    string public constant name = "MaidCoin Nurse Parts";

    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    // keccak256("Permit(address owner,address spender,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0xdaab21af31ece73a508939fedd476a5ee5129a5ed4bb091f3236ffb45394df62;

    mapping(address => uint256) public override nonces;

    uint256 private royaltyFee = 25; // out of 1000
    address private royaltyReceiver; // MaidCafe

    constructor(address _royaltyReceiver) {
        _CACHED_CHAIN_ID = block.chainid;
        _HASHED_NAME = keccak256(bytes("MaidCoin Nurse Parts"));
        _HASHED_VERSION = keccak256(bytes("1"));
        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("MaidCoin Nurse Parts")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        royaltyReceiver = _royaltyReceiver;
    }

    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, block.chainid, address(this)));
        }
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external override onlyOwner {
        _mint(to, id, amount, "");
    }

    function burn(uint256 id, uint256 amount) external override {
        _burn(msg.sender, id, amount);
    }

    function permit(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(block.timestamp <= deadline, "NursePart: Expired deadline");
        bytes32 _DOMAIN_SEPARATOR = DOMAIN_SEPARATOR();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, nonces[owner], deadline))
            )
        );
        nonces[owner] += 1;

        if (Address.isContract(owner)) {
            require(
                IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e,
                "NursePart: Unauthorized"
            );
        } else {
            address recoveredAddress = Signature.recover(digest, v, r, s);
            require(recoveredAddress == owner, "NursePart: Unauthorized");
        }

        _setApprovalForAll(owner, spender, true);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, IERC165) returns (bool) {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address, uint256) {
        return (royaltyReceiver, (_salePrice * royaltyFee) / 1000);
    }

    function setRoyaltyInfo(address _receiver, uint256 _royaltyFee) external onlyOwner {
        royaltyReceiver = _receiver;
        royaltyFee = _royaltyFee;
    }
}