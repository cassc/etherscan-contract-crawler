// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC3525.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract LOOTaDOG is ERC3525, Ownable, Pausable {
    bool private _allow_transfer;
    bool private _allow_transfer_value;

    address private _signer;
    mapping(uint256 => bool) private _order_ids;
    string private _baseTokenURI;
    uint256 private _token_count_limit;
    /* Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function. */
    struct Voucher {
        uint256 id;
        /* The tokenId  */
        uint256 tokenId;
        /* The amount  */
        uint256 amount;
        /*expiration Time*/
        uint256 expirationTime;
        /*owner*/
        address owner;
    }

    constructor() ERC3525("LOOTaDOG Pass Card", "LADT", 2) {
        _allow_transfer = false;
        _allow_transfer_value = false;
        _signer = msg.sender;
        _token_count_limit = 1000;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function queryId(uint256 id) public view returns (bool) {
        return _order_ids[id];
    }

    function blockId(uint256 id) public {
        _order_ids[id] = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mintToken(
        uint256 id,
        uint256 amount,
        uint256 expirationTime,
        address owner,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable whenNotPaused {
        require(block.timestamp < expirationTime, "Expired voucher");
        require(totalSupply() < _token_count_limit, "Sold out");
        require(balanceOf(msg.sender) == 0, "Already minted");
        require(_order_ids[id] == false, "Duplicate id");
        require(owner == msg.sender, "Invalid owner");
        _verifySign(Voucher(id, 0, amount, expirationTime, owner), v, r, s);
        _mint(msg.sender, 1, amount);
        _order_ids[id] = true;
    }

    function mintValue(
        uint256 id,
        uint256 tokenId,
        uint256 amount,
        uint256 expirationTime,
        address owner,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable whenNotPaused {
        require(block.timestamp < expirationTime, "Expired voucher");
        require(_order_ids[id] == false, "Duplicate id");
        require(owner == msg.sender, "Invalid owner");
        require(amount > 0, "Invalid amount");
        _verifySign(Voucher(id, tokenId, amount, expirationTime, owner), v, r, s);
        _mintValue(tokenId, amount);
        _order_ids[id] = true;
    }

    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override whenNotPaused returns (uint256) {
        require(_allow_transfer_value, "Value does not allow transfer");
        return super.transferFrom(fromTokenId_, to_, value_);
    }

    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override whenNotPaused {
        super.transferFrom(fromTokenId_, toTokenId_, value_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override whenNotPaused {
        require(_allow_transfer, "Token does not allow transfer");
        super.transferFrom(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable virtual override whenNotPaused {
        require(_allow_transfer, "Token does not allow transfer");
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override whenNotPaused {
        require(_allow_transfer, "Token does not allow transfer");
        super.safeTransferFrom(from_, to_, tokenId_);
    }

    function setTokenCountLimit(uint256 count) public onlyOwner {
        _token_count_limit = count;
    }

    function getTokenCountLimit() public view returns (uint256) {
        return _token_count_limit;
    }

    function setSigner(address addr) public onlyOwner {
        _signer = addr;
    }

    function getSigner() public view returns (address) {
        return _signer;
    }

    bytes32 private constant salt = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;
    //string private constant EIP712_DOMAIN ="EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472; //keccak256(bytes(EIP712_DOMAIN));

    //string private constant VOUCHER_TYPE =
    //"Voucher(uint256 id,uint256 tokenId,uint256 amount,uint256 expirationTime,address owner)";
    bytes32 private constant VOUCHER_TYPEHASH = 0x4bd317336ea30fdfa31168cda381dacdf9ed1dd92eda94108d28629b6cf9b8c7; //keccak256(bytes(VOUCHER_TYPEHASH));

    function _verifySign(
        Voucher memory voucher,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        address signer = ecrecover(_hashVoucher(voucher), v, r, s);
        require(_signer == signer, "Invalid signer");
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _hashVoucher(Voucher memory voucher) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _hashDomainSeparator(), _encodeVoucher(voucher)));
    }

    function _encodeVoucher(Voucher memory voucher) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    VOUCHER_TYPEHASH,
                    voucher.id,
                    voucher.tokenId,
                    voucher.amount,
                    voucher.expirationTime,
                    voucher.owner
                )
            );
    }

    function _hashDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes("LOOTaDOG Dapp")),
                    keccak256(bytes("1")),
                    _getChainID(),
                    address(this),
                    salt
                )
            );
    }

    /*Since v0.5.12, Solidity provides a CHAINID OPCODE in assembly */
    function _getChainID() internal view returns (uint256) {
        return block.chainid;
    }
}