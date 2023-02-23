// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IHATVaultsData.sol";

/*
An NFT contract that mints specail tokens for each vault of
the HATVaults system.
@note: Thoroughout the whole contract, the HATVaults address 
       should always be the wrapper contract, not the actual
       HATVaults contract
*/
contract HATVaultsNFT is ERC1155, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    Counters.Counter public totalSupplyCounter;
    uint256 public deadline;

    uint256 public constant HUNDRED_PERCENT = 10000;
    uint256 public constant TIERS = 3;

    mapping(bytes32 => bool) public pausedVaults;
    mapping(bytes32 => bool) public vaultsRegistered;
    mapping(uint256 => mapping(address => bool)) public tokensRedeemed;

    mapping(uint256 => string) public uris;

    event MerkleTreeChanged(string merkleTreeIPFSRef, bytes32 root, uint256 deadline);
    event VaultPaused(address indexed hatVaults, uint256 indexed pid);
    event VaultResumed(address indexed hatVaults, uint256 indexed pid);

    modifier notPaused(address hatVaults, uint256 pid) {
        require(!pausedVaults[keccak256(abi.encodePacked(hatVaults, pid))], "Vault paused");
        _;
    }

    constructor(
        string memory _merkleTreeIPFSRef,
        bytes32 _root,
        uint256 _deadline
    // solhint-disable-next-line func-visibility
    ) ERC1155("") {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < _deadline, "Deadline already passed");
        root = _root;
        deadline = _deadline;
        emit MerkleTreeChanged(_merkleTreeIPFSRef, _root, _deadline);
    }

    function addVault(address hatVaults, uint256 pid, string memory _uri) external onlyOwner {
        require(!vaultsRegistered[getVaultId(hatVaults, pid)], "Vault already exists");
        vaultsRegistered[getVaultId(hatVaults, pid)] = true;
        for(uint8 i = 1; i <= TIERS; i++) {
            uris[getTokenId(hatVaults, pid, i)] = string(abi.encodePacked(_uri, Strings.toString(i)));
        }
    }

    function pauseVault(address hatVaults, uint256 pid) external onlyOwner {
        pausedVaults[keccak256(abi.encodePacked(hatVaults, pid))] = true;
        emit VaultPaused(hatVaults, pid);
    }


    function resumeVault(address hatVaults, uint256 pid) external onlyOwner {
        pausedVaults[keccak256(abi.encodePacked(hatVaults, pid))] = false;
        emit VaultResumed(hatVaults, pid);
    }

    /**
     * @dev Update the merkle tree root only after 
     * the deadline for minting has been reached.
     * @param _merkleTreeIPFSRef new merkle tree ipfs reference.
     * @param _root new merkle tree root to use for verifying.
     * @param _deadline number of days to the next minting deadline.
     */
    function updateTree(string memory _merkleTreeIPFSRef, bytes32 _root, uint256 _deadline) external onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp > deadline, "Minting deadline was not reached");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < _deadline, "New deadline already passed");
        root = _root;
        deadline = _deadline;
        emit MerkleTreeChanged(_merkleTreeIPFSRef, _root, _deadline);
    }

    function redeemMultipleFromTree(
        address[] calldata hatVaults,
        uint256[] calldata pids,
        address account,
        uint8[] calldata tiers,
        bytes32[][] calldata proofs
    ) external {
        uint256 arraysLength = hatVaults.length;
        require(arraysLength == pids.length, "Arrays lengths must match");
        require(arraysLength == tiers.length, "Arrays lengths must match");
        require(arraysLength == proofs.length, "Arrays lengths must match");
        for (uint256 i = 0; i < arraysLength; i++) {
            redeemSingleFromTree(hatVaults[i], pids[i], account, tiers[i], proofs[i]);
        }
    }

    function redeemSingleFromTree(
        address hatVaults,
        uint256 pid,
        address account,
        uint8 tier,
        bytes32[] calldata proof
    ) public notPaused(hatVaults, pid) {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < deadline, "Minting deadline passed");
        require(_verify(proof, _leaf(hatVaults, pid, account, tier)), "Invalid merkle proof");
        _mintTokens(hatVaults, pid, account, tier);
    }

    function redeemMultipleFromShares(
        address[] calldata hatVaults,
        uint256[] calldata pids,
        address account
    ) external {
        uint256 arraysLength = hatVaults.length;
        require(arraysLength == pids.length, "Arrays lengths must match");
        for (uint256 i = 0; i < arraysLength; i++) {
            redeemSingleFromShares(hatVaults[i], pids[i], account);
        }
    }

    function redeemSingleFromShares(
        address hatVaults,
        uint256 pid,
        address account
    ) public {
        uint8 tier = getTierFromShares(hatVaults, pid, account);
        if (tier != 0) {
            _mintTokens(hatVaults, pid, account, tier);
        } 
    }

    function _mintTokens(
        address hatVaults,
        uint256 pid,
        address account,
        uint8 tier
    ) internal {
        require(vaultsRegistered[getVaultId(hatVaults, pid)], "Token does not exist");
        for(uint8 i = 1; i <= tier; i++) {
            if (!tokensRedeemed[getTokenId(hatVaults, pid, i)][account]) {
                tokensRedeemed[getTokenId(hatVaults, pid, i)][account] = true;
                _mint(account, getTokenId(hatVaults, pid, i));
            }
        }
    }

    function _leaf(address _hatVaults, uint256 _pid, address _account, uint8 _tier) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_hatVaults, _pid, _account, _tier));
    }

    function _verify(bytes32[] calldata proof, bytes32 leaf) internal view returns (bool) {
        return MerkleProof.verifyCalldata(proof, root, leaf);
    }

    function _mint(address to, uint256 id) internal {
        totalSupplyCounter.increment();
        super._mint(to, id, 1, "");
    }

    function getTierFromShares(
        address hatVaults,
        uint256 pid,
        address account
    ) public view notPaused(hatVaults, pid) returns(uint8) {
        uint256 shares = IHATVaultsData(hatVaults).getShares(pid, account);
        uint256 totalShares = IHATVaultsData(hatVaults).getTotalShares(pid);
        require(totalShares != 0, "Pool is empty");
        uint16[3] memory tierPercents = [10, 100, 1500];
        uint8 tier = 0;

        for(uint8 i = 0; i < tierPercents.length; i++) {
            if (shares < totalShares * tierPercents[i] / HUNDRED_PERCENT) {
                break;
            }
            tier++;
        }

        return tier;
    }

    function getTiersToRedeemFromShares(
        address hatVaults,
        uint256 pid,
        address account
    ) external view returns(bool[3] memory tiers) {
        require(vaultsRegistered[getVaultId(hatVaults, pid)], "Token does not exist");
        for(uint8 i = 1; i <= getTierFromShares(hatVaults, pid, account); i++) {
            if (!tokensRedeemed[getTokenId(hatVaults, pid, i)][account]) {
                tiers[i - 1] = true;
            }
        }
    }

    function isEligible(
        address hatVaults,
        uint256 pid,
        address account
    ) external view returns(bool) {
        uint8 tier = getTierFromShares(hatVaults, pid, account);
        return tier != 0 && (vaultsRegistered[getVaultId(hatVaults, pid)] && !tokensRedeemed[getTokenId(hatVaults, pid, tier)][account]);
    }

    function getTokenId(
        address hatVaults,
        uint256 pid,
        uint8 tier
    ) public pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(hatVaults, pid, tier)));
    }

    function getVaultId(
        address hatVaults,
        uint256 pid
    ) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(hatVaults, pid));
    }

    /**
        @dev Returns thze total tokens minted so far.
     */
    function totalSupply() public view returns (uint256) {
        return totalSupplyCounter.current();
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return uris[tokenId];
    }
}