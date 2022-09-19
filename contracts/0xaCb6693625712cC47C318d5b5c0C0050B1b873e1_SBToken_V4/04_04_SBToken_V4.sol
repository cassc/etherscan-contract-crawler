// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract SBToken_V4 is EIP712{
    using ECDSA for bytes32;

    struct approveSBT {
        address emitent;       
        address to;
        uint256 nonce;        
        string path;
    }

    bytes32 private constant _TYPEHASH = keccak256("approveSBT(address emitent,address to,uint256 nonce,string path)");

    address public owner;
    
    string public name;

    string public version;

    string public symbol;

    uint currentTokenId;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal balances;

    mapping(uint256 => string) internal paths;

    mapping(address => uint256) private nonces;

    event Attest(address indexed to, uint256 indexed tokenId);

    /**
     * @dev This emits when an existing SBT is revoked from an account and
     * destroyed by any mechanism.
     * Note: For a reliable `from` parameter, retrieve the transaction's
     * authenticated `from` field.
     */
    event Burn(address indexed from, uint256 indexed tokenId);

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor(string memory _name, string memory _symbol, string memory _version) EIP712(_name, _version){
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        currentTokenId = 0;
    }

    function getNonce(address _from) public view returns (uint256) {
        return nonces[_from];
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "SBToken: address zero is not a valid owner");
        return balances[_owner];
    }


    function ownerOf(uint256 _tokenId) public view returns (address) {
        address _owner = owners[_tokenId];
        require(owners[_tokenId] != address(0), "SBToken: invalid token ID");
        return _owner;
    }

    function verify(approveSBT calldata _aSBT, bytes calldata _signature) public view returns (bool) {
        address _signer = _hashTypedDataV4(keccak256(abi.encode(
            _TYPEHASH,
            _aSBT.emitent,
            _aSBT.to,
            _aSBT.nonce,
            keccak256(abi.encodePacked(_aSBT.path))
        ))).recover(_signature);
        return nonces[_aSBT.to] == _aSBT.nonce && _signer == _aSBT.emitent && _signer == owner;
    }

    function attest(approveSBT calldata _aSBT, bytes calldata _signature) external returns (uint256) {
        require(verify(_aSBT, _signature), "Invalid signature");
        require(_aSBT.to == msg.sender, "Invalid sender");
        require(_aSBT.to != address(0), "Address is empty");
        require(balances[_aSBT.to] == 0, "SBT already exists");
        nonces[_aSBT.to] = _aSBT.nonce + 1;

        currentTokenId++;
        uint256 _tokenId = currentTokenId;

        owners[_tokenId] = _aSBT.to;
        balances[_aSBT.to] = _tokenId;
        paths[_tokenId] = _aSBT.path;

        emit Attest(_aSBT.to, _tokenId);
        emit Transfer(address(0), _aSBT.to, _tokenId);
    }

    function burn() external {
        address _sender = msg.sender;

        require(
            balances[_sender] != 0,
            "The account does not have any SBT"
        );

        uint256 _tokenId = balances[_sender];

        balances[_sender] = 0;
        owners[_tokenId] = address(0);
        paths[_tokenId] = '';

        emit Burn(_sender, _tokenId);
        emit Transfer(_sender, address(0), _tokenId);
    }


    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return paths[_tokenId];
    }
}