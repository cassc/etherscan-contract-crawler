// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "./interface/IOlimpoPass.sol";

error AddressNotFoundInAllowlist(address minter);
error AddressMintedInPhase(address minter);
error AddressUnauthorized(address sender);
error MismatchingPrice(uint256 amount);
error NonExistantTokenId(uint256 tokenId);
error PhaseDoesNotExist(uint256 phaseId);
error PhaseNotActive(uint256 phaseId);
error PhaseMustBeNamed();
error PurchaseExceedsMaxSupply();

/**
 *  ██████╗ ██╗     ██╗███╗   ███╗██████╗  ██████╗
 * ██╔═══██╗██║     ██║████╗ ████║██╔══██╗██╔═══██╗
 * ██║   ██║██║     ██║██╔████╔██║██████╔╝██║   ██║
 * ██║   ██║██║     ██║██║╚██╔╝██║██╔═══╝ ██║   ██║
 * ╚██████╔╝███████╗██║██║ ╚═╝ ██║██║     ╚██████╔╝
 *  ╚═════╝ ╚══════╝╚═╝╚═╝     ╚═╝╚═╝      ╚═════╝
 * ██╗  ██╗
 * ╚██╗██╔╝
 *  ╚███╔╝
 *  ██╔██╗
 * ██╔╝ ██╗
 * ╚═╝  ╚═╝
 * ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗███████╗██╗   ██╗██╗
 * ██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██║   ██║██║
 * ██████╔╝██║     ██║   ██║██║     █████╔╝ █████╗  ██║   ██║██║
 * ██╔══██╗██║     ██║   ██║██║     ██╔═██╗ ██╔══╝  ██║   ██║██║
 * ██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗██║     ╚██████╔╝███████╗
 * ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚══════╝
 *
 * @title Olimpo Pass
 * @author @0xneves | @Blockful_io - https://blockful.io
 * @dev Extends ERC721 Non-Fungible Token Standard
 */
contract OlimpoPass is IOlimpoPass, ERC721, ERC2981 {
    using Strings for uint256;

    // Counters for token IDs and phases
    uint256 public currentSupply;
    uint256 public phasesCount;

    // Contract details
    uint256 public constant totalSupply = 888;
    address public immutable treasury;
    address public immutable dev;
    address public immutable admin;

    // Mappings
    mapping(uint256 => MintPhases) private phases;
    mapping(uint256 => mapping(address => bool)) private mintedInPhase;

    /**
     * @dev Initializes the contract by setting the `name` and `symbol` to the token collection.
     */
    constructor(
        address _treasury,
        address _dev,
        address _admin
    ) ERC721("OLIMPO PASS", "OLP") {
        dev = _dev;
        treasury = _treasury;
        admin = _admin;
        _setDefaultRoyalty(address(this), 1000);
    }

    /**
     * @dev Throws if the sender is not the admin.
     */
    modifier onlyAdmin() {
        if (admin != msg.sender) {
            revert AddressUnauthorized(msg.sender);
        }
        _;
    }

    /**
     * @dev Safely mint `tokenId` to the `msg.sender`.
     *
     * `currentSupply` starts at 1 and increments every mint.
     *
     * This external function allows anyone to mint a token if the phase is active,
     * the currentSupply is less than the maximum, and the `msg.sender` has not
     * minted already. If the phase has an allowlist, the `msg.sender` must be in
     * the allowlist, otherwise anyone can mint.
     *
     * IMPORTANT! When the public mint starts, allowlists would not matter anymore.
     *
     * Requirements:
     *
     * - Phase `_id` and `msg.sender` must match all validation criteria.
     * - `currentSupply` must be less than maximum (1111).
     *
     * Emits a {IOlimpoPass-Minted} event.
     */
    function mint(
        uint256 _id,
        uint256 _addressIndex
    ) external payable returns (uint256) {
        // Verify minting process
        _safeCheck(_id, _addressIndex);

        // Check supply overflow
        if (currentSupply + 1 > totalSupply) {
            revert PurchaseExceedsMaxSupply();
        }

        // Increase supply
        unchecked {
            currentSupply++;
        }

        // Mint token and emit event
        _safeMint(msg.sender, currentSupply);
        emit Minted(msg.sender, currentSupply);

        return currentSupply;
    }

    /**
     * @dev This internal verification will validate the minting process and set
     * the `mintedInPhase` mapping to an address as true if the verification passes.
     *
     * Minting Phases are created by the admin and can be activated or deactivated.
     * When a phase is active, anyone can mint a token if the `msg.sender` is in the
     * allowlist, otherwise only the admin can mint.
     *
     * Requirements:
     * - Phase `_id` must be an active phase.
     * - `msg.value` must be equal to `mintPrice` settled in the phase.
     * - `msg.sender` must be in the `allowlist` if there is one.
     * - `msg.sender` cannot mint two tokens.
     */
    function _safeCheck(uint256 _id, uint256 _addressIndex) internal {
        MintPhases memory phase = phases[_id];

        if (!phase.isActive) {
            revert PhaseNotActive(_id);
        }

        if (msg.value != phase.mintPrice) {
            revert MismatchingPrice(msg.value);
        }

        if (
            phase.allowlist.length != 0 &&
            phase.allowlist[_addressIndex] != msg.sender
        ) {
            revert AddressNotFoundInAllowlist(msg.sender);
        }

        if (mintedInPhase[_id][msg.sender]) {
            revert AddressMintedInPhase(msg.sender);
        }

        mintedInPhase[_id][msg.sender] = true;
    }

    /**
     * @dev This function allows the admin to airdrop tokens to an array of addresses.
     *
     * Requirements:
     * - `currentSupply` must be less than maximum (1111).
     * - `msg.sender` must be the admin.
     *
     * @param _addrs Array of addresses to airdrop tokens to.
     */
    function airdrop(address[] calldata _addrs) public onlyAdmin {
        uint length = _addrs.length;

        if (currentSupply + length > totalSupply) {
            revert PurchaseExceedsMaxSupply();
        }

        for (uint i = 0; i < length; i++) {
            unchecked {
                currentSupply++;
            }

            address addr = _addrs[i];
            _safeMint(addr, currentSupply);
            emit Minted(addr, currentSupply);
        }
    }

    /**
     * @dev See {IOlimpoPass-createMintingPhase}.
     */
    function createMintingPhase(
        string memory _name,
        uint256 _price,
        address[] calldata _addresses
    ) external onlyAdmin {
        if (abi.encodePacked(_name).length == 0) {
            revert PhaseMustBeNamed();
        }

        unchecked {
            phasesCount++;
        }

        phases[phasesCount].phaseName = _name;
        phases[phasesCount].mintPrice = _price;
        phases[phasesCount].allowlist = _addresses;

        emit PhaseCreated(phasesCount, _name);
    }

    /**
     * @dev See {IOlimpoPass-createMintingPhase}.
     */
    function deletePhase(uint _id) external onlyAdmin {
        _phaseExists(_id);
        delete phases[_id];

        unchecked {
            phasesCount--;
        }

        emit PhaseDeleted(_id);
    }

    /**
     * @dev See {IOlimpoPass-changePhaseActiveState}.
     */
    function changePhaseActiveState(uint256 _id) external onlyAdmin {
        _phaseExists(_id);

        MintPhases memory phase = phases[_id];
        phases[_id].isActive = !phase.isActive;

        emit PhaseActivity(_id, phase.phaseName, !phase.isActive);
    }

    /**
     * @dev Overrides the the original baseURI to return what is set in the contract
     * @return The base URI for all tokens
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return
            "ipfs://bafybeicfbuttpn6tdnfg4rfwycgoqf5vhy3ni5ejr5jnf6cruczijxr3ii/";
    }

    /**
     * @dev Returns the token URI for a given token ID
     * @param _tokenId The token ID to return the URI for
     * @return The token URI for the given token ID
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert NonExistantTokenId(_tokenId);
        }

        string memory currBaseURI = _baseURI();
        return
            bytes(currBaseURI).length > 0
                ? string(abi.encodePacked(currBaseURI, _tokenId.toString()))
                : "";
    }

    /**
     * @dev See {IOlimpoPass-getPhase}.
     */
    function getPhase(uint256 _id) public view returns (MintPhases memory) {
        _phaseExists(_id);
        return phases[_id];
    }

    /**
     * @dev See {IOlimpoPass-getMintedStatus}.
     */
    function getMintedStatus(
        uint256 _id,
        address _addr
    ) public view returns (bool) {
        _phaseExists(_id);
        return mintedInPhase[_id][_addr];
    }

    /**
     * @dev Returns the index of an address in a given phase `_id`
     *
     * Notice this is only used for the front/back to fetch the index
     * of an `address` before minting the NFT, which will be used to
     * determine if the user is whitelisted or not.
     *
     * `for` method, might have multiple loops. When called on-chain,
     * becomes very costly, so it's not present in the interface and
     * should only be called off-chain.
     *
     * Requirements:
     *
     * - Phase `_id` must exist.
     * - `msg.sender` must exist in the phase.
     *
     * @param _id The phase ID to search for the address
     * @param _addr The address to search for
     * @return The index of the address in the phase
     */
    function getIndexOfAddressInAllowlist(
        uint256 _id,
        address _addr
    ) public view returns (uint256) {
        _phaseExists(_id);

        MintPhases memory phase = phases[_id];

        for (uint i = 0; i < phase.allowlist.length; i++) {
            if (phase.allowlist[i] == _addr) {
                return i;
            }
        }

        revert AddressNotFoundInAllowlist(_addr);
    }

    /**
     * @dev See {IOlimpoPass-getRoyaltyInfo}.
     */
    function getRoyaltyInfo() external view returns (address, uint96) {
        return (address(this), 1000);
    }

    /**
     * @dev Returns the address of the current owner.
     * This is the `bytes4` recognized interface for Ownable.
     * Marketplaces like OpenSea will read this value to let
     * the returned address edit the page of the contract.
     *
     * @return The address of the current owner
     */
    function owner() public view virtual returns (address) {
        return admin;
    }

    /**
     * @dev This internal function is used to check if a given phase `_id` exists.
     */
    function _phaseExists(uint256 _id) internal view {
        if (abi.encodePacked(phases[_id].phaseName).length == 0) {
            revert PhaseDoesNotExist(_id);
        }
    }

    /**
     * @dev Supports interface
     * @param interfaceId The interface ID
     * @return True if the interface is supported
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC2981) returns (bool) {
        return
            interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IOlimpoPass-withdraw}.
     */
    function withdraw() external payable {
        uint256 balance = address(this).balance;
        uint256 treasuryAmount = (balance / 10000) * 9700; // 97%
        uint256 devAmount = address(this).balance - treasuryAmount; // 3%

        payable(treasury).call{value: treasuryAmount}("");

        payable(dev).call{value: devAmount}("");
    }

    /* Receive ETH */
    receive() external payable {}
}