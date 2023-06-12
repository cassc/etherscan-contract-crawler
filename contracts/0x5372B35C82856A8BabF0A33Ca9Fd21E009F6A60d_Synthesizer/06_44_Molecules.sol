// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { ERC20BurnableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

struct Metadata {
    uint256 ipnftId;
    address originalOwner;
    string agreementCid;
}

error TokenCapped();
error OnlyIssuerOrOwner();

/**
 * @title Molecules
 * @author molecule.to
 * @notice this is a template contract that's spawned by the Synthesizer
 * @notice the owner of this contract is always the Synthesizer contract.
 *         the issuer of a token bears the right to increase the supply as long as the token is not capped.
 */
contract Molecules is ERC20BurnableUpgradeable, OwnableUpgradeable {
    event Capped(uint256 atSupply);

    //this will only go up.
    uint256 public totalIssued;
    /**
     * @notice when true, no one can ever mint tokens again.
     */
    bool public capped;
    Metadata internal _metadata;

    function initialize(string calldata name, string calldata symbol, Metadata calldata metadata_) external initializer {
        __Ownable_init();
        __ERC20_init(name, symbol);
        _metadata = metadata_;
    }

    modifier onlyIssuerOrOwner() {
        if (_msgSender() != _metadata.originalOwner && _msgSender() != owner()) {
            revert OnlyIssuerOrOwner();
        }
        _;
    }

    function issuer() external view returns (address) {
        return _metadata.originalOwner;
    }

    function metadata() external view returns (Metadata memory) {
        return _metadata;
    }
    /**
     * @notice Molecules are identified by the original token holder and the underlying token id
     * @return uint256 a token hash that's unique for [`originaOwner`,`ipnftid`]
     */

    function hash() external view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_metadata.originalOwner, _metadata.ipnftId)));
    }

    /**
     * @notice we deliberately allow the synthesis initializer to increase the supply of Molecules at will as long as the underlying asset has not been sold yet
     * @param receiver address
     * @param amount uint256
     */
    function issue(address receiver, uint256 amount) external onlyIssuerOrOwner {
        if (capped) revert TokenCapped();
        totalIssued += amount;
        _mint(receiver, amount);
    }

    /**
     * @notice mark this token as capped. After calling this, no new tokens can be `issue`d
     */
    function cap() external onlyIssuerOrOwner {
        capped = true;
        emit Capped(totalIssued);
    }

    /**
     * @notice contract metadata, compatible to ERC1155
     * @return string base64 encoded data url
     */
    function uri() external view returns (string memory) {
        string memory tokenId = Strings.toString(_metadata.ipnftId);

        string memory props = string.concat(
            '"properties": {',
            '"ipnft_id": ',
            tokenId,
            ',"agreement_content": "ipfs://',
            _metadata.agreementCid,
            '","original_owner": "',
            Strings.toHexString(_metadata.originalOwner),
            '","erc20_contract": "',
            Strings.toHexString(address(this)),
            '","supply": "',
            Strings.toString(totalIssued),
            '"}'
        );

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name": "Molecules of IPNFT #',
                        tokenId,
                        '","description": "Molecules, derived from IP-NFTs, are ERC-20 tokens governing IP pools.","decimals": 18,"external_url": "https://molecule.to","image": "",',
                        props,
                        "}"
                    )
                )
            )
        );
    }
}