// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IFSushi.sol";

contract FSushiAirdrops is Ownable {
    bytes32 private constant CLAIM_TYPEHASH =
        keccak256("Claim(uint256 chainId,address contract,uint256 id,address account,uint256 amount)");

    address public immutable fSushi;
    address public signer;
    string[] public airdrops;
    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    error NotEOA();
    error InvalidName();
    error InvalidId();
    error InvalidSignature();
    error Expired();
    error Claimed();

    event UpdateSigner(address indexed signer);
    event AddAirdrop(uint256 indexed id, string name);
    event Claim(uint256 indexed id, string name, address indexed account, uint256 amount, address indexed beneficiary);

    constructor(address _fSushi) {
        fSushi = _fSushi;
    }

    function updateSigner(address _signer) external onlyOwner {
        if (_signer.code.length > 0) revert NotEOA();

        signer = _signer;

        emit UpdateSigner(_signer);
    }

    function addAirdrop(string memory name) external onlyOwner {
        if (bytes(name).length == 0) revert InvalidName();

        uint256 id = airdrops.length;
        airdrops.push(name);

        emit AddAirdrop(id, name);
    }

    function claim(
        uint256 id,
        uint256 amount,
        address beneficiary,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > deadline) revert Expired();

        string memory name = airdrops[id];
        if (bytes(name).length == 0) revert InvalidId();

        if (hasClaimed[id][msg.sender]) revert Claimed();
        hasClaimed[id][msg.sender] = true;

        bytes32 hash = keccak256(
            abi.encodePacked(block.chainid, address(this), id, msg.sender, amount, beneficiary, deadline)
        );
        address _signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), v, r, s);
        if (_signer != signer) revert InvalidSignature();

        IFSushi(fSushi).mint(beneficiary, amount);

        emit Claim(id, name, msg.sender, amount, beneficiary);
    }
}