// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable no-empty-blocks, not-rely-on-time

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../interface/core/IGameFiProfileVaultV2.sol";
import "../interface/core/component/IProfileV2.sol";

/**
 * @author Alex Kaufmann
 * @dev Game profile vault contract. Usually deployed as an implementation.
 * Deployed by contract as clone proxy (see https://eips.ethereum.org/EIPS/eip-1167).
 *
 * In fact, it is a special storage for assets, only the owner of a token
 * associated with this storage has access to the short ones.
 */
contract GameFiProfileVaultV2 is
    Initializable,
    ReentrancyGuardUpgradeable,
    BaseRelayRecipient,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    IGameFiProfileVaultV2
{
    address internal _gameFiCore;

    modifier checkProfileAccess() {
        // TODO подумать над логикой разрешения на коллы коре
        uint256 myTokenId = IProfileV2(_gameFiCore).profileVaultToId(address(this));
        require(
            IERC721Upgradeable(_gameFiCore).ownerOf(myTokenId) == _msgSender(),
            "ProfileVaultV2: caller is not the owner"
        );
        require(!IProfileV2(_gameFiCore).profileIsLocked(myTokenId), "ProfileVaultV2: profile locked");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Constructor method (https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers).
     * @param gameFiCore_ GameFiCore contract address.
     */
    function initialize(address gameFiCore_) external override initializer {
        __ReentrancyGuard_init();
        __ERC1155Holder_init();
        __ERC721Holder_init();

        _gameFiCore = gameFiCore_;
    }

    receive() external payable {}

    /**
     * @dev Makes a call to the specified address.
     * @param target The destination address of the message.
     * @param data ABI byte string containing the data of the function call on a contract.
     * @param value The value transferred for the transaction in wei.
     */
    function call(
        address target,
        bytes memory data,
        uint256 value
    ) external override nonReentrant checkProfileAccess returns (bytes memory result) {
        emit Call({owner: _msgSender(), target: target, data: data, value: value, timestamp: block.timestamp});

        return (_call(target, data, value));
    }

    /**
     * @dev Makes multiple calls to the specified address.
     * @param target The destination address of the message.
     * @param data ABI byte string containing the data of the function call on a contract.
     * @param value The value transferred for the transaction in wei.
     */
    function multiCall(
        address[] memory target,
        bytes[] memory data,
        uint256[] memory value
    ) external override nonReentrant checkProfileAccess returns (bytes[] memory results) {
        require(
            (target.length == data.length) && (target.length == value.length),
            "ProfileVaultV2: wrong arguments length"
        );

        emit MultiCall({owner: _msgSender(), target: target, data: data, value: value, timestamp: block.timestamp});

        results = new bytes[](target.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _call(target[i], data[i], value[i]);
        }

        return results;
    }

    /**
     * @dev Returns linked GameFiCore contract.
     * @return GameFiCore address.
     */
    function gameFiCore() external view override returns (address) {
        return _gameFiCore;
    }

    //
    // Internal methods
    //

    function _call(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory result) {
        result = AddressUpgradeable.functionCallWithValue(target, data, value);
    }

    //
    // GSN
    //

    /**
     * @dev Returns the current trusted forwarder of GSN (see https://docs.opengsn.org/).
     * @return Trusted Forwarder addreess.
     */
    function trustedForwarder() public view override returns (address) {
        return (BaseRelayRecipient(_gameFiCore).trustedForwarder());
    }

    /**
     * @dev Return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay (see https://docs.opengsn.org/).
     * @return Bool flag.
     */
    function isTrustedForwarder(address forwarder) public view override returns (bool) {
        return (BaseRelayRecipient(_gameFiCore).isTrustedForwarder(forwarder));
    }

    /**
     * @dev Returns recipient version of the GSN protocol (see https://docs.opengsn.org/).
     * @return Version string in SemVer.
     */
    function versionRecipient() external view override returns (string memory) {
        return (BaseRelayRecipient(_gameFiCore).versionRecipient());
    }
}