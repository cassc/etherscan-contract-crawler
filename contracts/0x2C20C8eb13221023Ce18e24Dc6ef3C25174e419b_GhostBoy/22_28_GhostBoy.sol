// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./Marketplace.sol";
import "./AdminControls.sol";

contract GhostBoy is Marketplace, AdminControls, Multicall {
    using MerkleProof for bytes32[];

    uint256 public constant mintPrice = 0.025 ether;

    uint256 public constant cap = 6666;
    uint256 public immutable reserved;
    string public baseUri = "";
    string public placeholderTokenUri;
    address public immutable _vault;

    mapping(address => uint256) public minterTokenId;

    event UpdateBaseUri(string updatedBaseUri);

    error MissingValue(uint256 provided, uint256 required);
    error OutsideWindow(uint256 startTime, uint256 endTime);
    error MintingLocked();
    error MintingCapped(address minter);
    error MintingComplete();

    constructor(
        address vault,
        uint96 _reserved,
        string memory _placeholderTokenUri
    ) Marketplace("NOT Blocky", "XYZ") AccessControl() {
        _grantRole(DEFAULT_ADMIN_ROLE, vault);
        _grantRole(MANAGER_ROLE, vault);
        _grantRole(DOMAIN_SETTER_ROLE, vault);
        _grantRole(DOMAIN_SETTER_ROLE, _msgSender());
        _grantRole(LIST_SETTER_ROLE, _msgSender());
        _vault = vault;
        placeholderTokenUri = _placeholderTokenUri;
        reserved = _reserved;
        _mintReserves(vault);
    }

    function owner() public view returns (address) {
        return _vault;
    }

    /**
     * mints a reserve of token ids during constructor
     * @param vault the address of a vault to hold the first 60
     * tokens in - reserved for givaways and key players in projects history
     * @notice only called once during constructor
     * not available to anyone outside of deploy key during constructor
     */
    function _mintReserves(address vault) internal {
        uint256 tokenId = 1;
        uint256 _reserve = reserved;
        do {
            _mint(vault, tokenId);
            ++tokenId;
        } while (tokenId <= _reserve);
    }

    /**
     * allow funds to be deposited
     */
    receive() external payable {}

    /**
     * prove that an account exists in a merkle root
     * @param account the leaf to check in the merkle root
     * @param proof a list of merkle branches prooving that the leaf is valid
     */
    function isGhostlisted(
        address account,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return
            proof.verify(ghostlistRoot, keccak256(abi.encodePacked(account)));
    }

    /**
     * mint an nft by either providing a proof that you are in a merkle tree ghostlist
     * or by minting after the ghostlist duration is over
     * @param proof a proof of merkle branches to show that a leaf is in a tree
     */
    function mint(bytes32[] calldata proof) external payable {
        if (msg.value < mintPrice) {
            revert MissingValue(msg.value, mintPrice);
        }
        uint256 startTime = mintStart;
        if (startTime == 0) {
            revert OutsideWindow(0, 0);
        }
        uint256 timestamp = block.timestamp;
        if (timestamp < startTime) {
            revert OutsideWindow(startTime, 0);
        }
        address sender = _msgSender();
        if (timestamp < (startTime + ghostlistDuration)) {
            if (!isGhostlisted(sender, proof)) {
                revert OutsideWindow(startTime, startTime + ghostlistDuration);
            }
        }
        uint256 supply = totalSupply() + 1;
        minterTokenId[sender] = supply;
        if (supply > cap) {
            revert MintingComplete();
        }
        _safeMint(sender, supply);
    }

    /**
     * sets the base uri
     * @param _baseUri the updated base uri
     * the final resting place of ghost boy
     */
    function setBaseURI(
        string memory _baseUri
    ) public onlyRole(DOMAIN_SETTER_ROLE) {
        baseUri = _baseUri;
    }

    /**
     * retrieve the token id's uri
     * @param tokenId the token id to retreive the uri for
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory tokenUri = super.tokenURI(tokenId);
        if (bytes(tokenUri).length > 0) {
            return string(abi.encodePacked(tokenUri, ".json"));
        }
        return string(placeholderTokenUri);
    }

    /**
     * gets the base uri - the domain and path where the metadata is held
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    /**
     * looks for a method to check for compatability
     * @param interfaceId the method to look for
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AdminControls, Marketplace) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}