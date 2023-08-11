// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IPToken, Metadata as TokenMetadata } from "./IPToken.sol";
import { IPermissioner } from "./Permissioner.sol";
import { IPNFT } from "./IPNFT.sol";

error MustOwnIpnft();
error AlreadyTokenized();

/// @title Tokenizer 1.1
/// @author molecule.to
/// @notice tokenizes an IPNFT to an ERC20 token (called IPT) and controls its supply.
contract Tokenizer is UUPSUpgradeable, OwnableUpgradeable {
    event TokensCreated(
        uint256 indexed moleculesId,
        uint256 indexed ipnftId,
        address indexed tokenContract,
        address emitter,
        uint256 amount,
        string agreementCid,
        string name,
        string symbol
    );

    IPNFT internal ipnft;

    //this is the old term to keep the storage layout intact
    mapping(uint256 => IPToken) public synthesized;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address immutable tokenImplementation;

    /// @dev the permissioner checks if senders have agreed to legal requirements
    IPermissioner permissioner;

    /**
     * @param _ipnft the IPNFT contract
     * @param _permissioner a permissioning contract that checks if callers have agreed to the tokenized token's legal agreements
     */
    function initialize(IPNFT _ipnft, IPermissioner _permissioner) external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
        ipnft = _ipnft;
        permissioner = _permissioner;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        tokenImplementation = address(new IPToken());
        _disableInitializers();
    }

    /**
     * @dev called after an upgrade to reinitialize a new permissioner impl. This is 4 for görli compatibility
     * @param _permissioner the new TermsPermissioner
     */
    function reinit(IPermissioner _permissioner) public onlyOwner reinitializer(4) {
        permissioner = _permissioner;
    }

    /**
     * @notice initializes synthesis on ipnft#id for the current asset holder.
     *         IPTokens are identified by the original token holder and the token id
     * @param ipnftId the token id on the underlying nft collection
     * @param tokenAmount the initially issued supply of IP tokens
     * @param tokenSymbol the ip token's ticker symbol
     * @param agreementCid a content hash that contains legal terms for IP token owners
     * @param signedAgreement the sender's signature over the signed agreemeent text (must be created on the client)
     * @return token a new created ERC20 token contract that represents the tokenized ipnft
     */
    function tokenizeIpnft(
        uint256 ipnftId,
        uint256 tokenAmount,
        string memory tokenSymbol,
        string memory agreementCid,
        bytes calldata signedAgreement
    ) external returns (IPToken token) {
        if (ipnft.ownerOf(ipnftId) != _msgSender()) {
            revert MustOwnIpnft();
        }

        // https://github.com/OpenZeppelin/workshops/tree/master/02-contracts-clone
        token = IPToken(Clones.clone(tokenImplementation));
        string memory name = string.concat("IP Tokens of IPNFT #", Strings.toString(ipnftId));
        token.initialize(name, tokenSymbol, TokenMetadata(ipnftId, _msgSender(), agreementCid));

        uint256 tokenHash = token.hash();
        // ensure we can only call this once per sales cycle
        if (address(synthesized[tokenHash]) != address(0)) {
            revert AlreadyTokenized();
        }

        synthesized[tokenHash] = token;

        //this has been called MoleculesCreated before
        emit TokensCreated(tokenHash, ipnftId, address(token), _msgSender(), tokenAmount, agreementCid, name, tokenSymbol);
        permissioner.accept(token, _msgSender(), signedAgreement);
        token.issue(_msgSender(), tokenAmount);
    }

    /// @notice upgrade authorization logic
    function _authorizeUpgrade(address /*newImplementation*/ )
        internal
        override
        onlyOwner // solhint-disable--line no-empty-blocks
    {
        //empty block
    }
}