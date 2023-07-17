// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {XXYYZZMint} from "./XXYYZZMint.sol";
import {ISeaDrop, PublicDrop} from "./lib/SeaDropSpecific.sol";

abstract contract XXYYZZSeaDrop is XXYYZZMint {
    error OnlySeadrop();

    address immutable SEADROP;
    address immutable CREATOR_PAYOUT;
    uint256 immutable DEPLOYED_TIME;

    uint256 private constant SEADROP_TOKEN_CREATED_EVENT_TOPIC =
        0xd7aca75208b9be5ffc04c6a01922020ffd62b55e68e502e317f5344960279af8;
    address private constant SEADROP_FEE_RECIPIENT = 0x0000a26b00c1F0DF003000390027140000fAa719;
    address private constant SEADROP_ALLOWED_PAYER_1 = 0xf408Bee3443D0397e2c1cdE588Fb060AC657006F;
    address private constant SEADROP_ALLOWED_PAYER_2 = 0xE3d3D0eD702504e19825f44BC6542Ff2ec45cB9A;
    uint256 private constant INONFUNGIBLESEADROP_INTERFACE_ID = 0x1890fe8e;

    constructor(address seadrop, address creatorPayout, address initialOwner, uint256 maxBatchSize)
        XXYYZZMint(initialOwner, maxBatchSize)
    {
        SEADROP = seadrop;
        DEPLOYED_TIME = block.timestamp;
        CREATOR_PAYOUT = creatorPayout;

        // log without adding event to abi
        assembly {
            log1(0, 0, SEADROP_TOKEN_CREATED_EVENT_TOPIC)
        }
    }

    /**
     * @notice Configure the SeaDrop contract. onlyOwner.
     * @dev SeaDrop calls supportsInterface, so this unfortunately can't live in the constructor.
     */
    function configureSeaDrop() external onlyOwner {
        ISeaDrop seadrop = ISeaDrop(SEADROP);
        seadrop.updatePublicDrop(
            PublicDrop({
                mintPrice: uint80(0.005 ether),
                startTime: uint48(DEPLOYED_TIME),
                endTime: uint48(MAX_MINT_CLOSE_TIMESTAMP),
                maxTotalMintableByWallet: type(uint16).max,
                feeBps: uint16(1000),
                restrictFeeRecipients: true
            })
        );
        seadrop.updateCreatorPayoutAddress(CREATOR_PAYOUT);
        seadrop.updateAllowedFeeRecipient(SEADROP_FEE_RECIPIENT, true);
        seadrop.updatePayer(SEADROP_ALLOWED_PAYER_1, true);
        seadrop.updatePayer(SEADROP_ALLOWED_PAYER_2, true);
    }

    function mintSeaDrop(address recipient, uint256 quantity) external {
        if (msg.sender != SEADROP) {
            revert OnlySeadrop();
        }
        // increment supply before minting
        uint128 newAmount;
        // this can be unchecked because an ID can only be minted once, and all IDs are later validated to be uint24s
        unchecked {
            newAmount = _numMinted + uint128(quantity);
        }
        _numMinted = newAmount;
        _mintTo(recipient, quantity, newAmount);
    }

    /**
     * @dev See {IERC165-supportsInterface}. Overridden to support SeaDrop.
     */
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool result) {
        assembly {
            let s := shr(224, interfaceId)
            // ERC165: 0x01ffc9a7, ERC721: 0x80ac58cd, ERC721Metadata: 0x5b5e139f. ERC4906: 0x49064906
            result :=
                or(
                    or(or(or(eq(s, 0x01ffc9a7), eq(s, 0x80ac58cd)), eq(s, 0x5b5e139f)), eq(s, 0x49064906)),
                    eq(s, INONFUNGIBLESEADROP_INTERFACE_ID)
                )
        }
    }

    /**
     * @dev Hard-coded for SeaDrop support
     */
    function getMintStats(address) external view returns (uint256, uint256, uint256) {
        return (0, _numMinted, 16777216);
    }

    /**
     * @dev Hard-coded for SeaDrop support
     */
    function maxSupply() external pure returns (uint256) {
        return 16777216;
    }
}