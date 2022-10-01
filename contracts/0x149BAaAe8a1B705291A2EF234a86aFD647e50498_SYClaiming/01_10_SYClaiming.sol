// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract SYClaiming is Ownable, ERC1155Receiver {
    error InsufficientSportsyachts(uint256 available, uint256 required);
    error InsufficientOgYachts(uint256 available, uint256 required);
    error NonExistentSportsyachtId(uint256 suppliedId);
    error GeneralClaimingStopped();
    error GeneralClaimingActive();
    error StartTimeHasNotPassed();

    event ClaimingStarted();
    event ClaimingStopped();

    address constant BURNER_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    uint256 constant REQUIRED_SPORTS_YACHTS = 1;

    uint256 constant SILVER_YACHT_ID =
        36573846584833278925172985243645009649481595570072332284486852001384296880128;
    uint256 constant BLACK_YACHT_ID =
        36573846584833278925172985243645009649481595570072332284486852001384296880129;
    uint256 constant RED_YACHT_ID =
        36573846584833278925172985243645009649481595570072332284486852001384305264640;

    uint256 constant START_TS = 1664553600;

    uint256 constant REQUIRED_OG_YACHTS_SILVER = 2;
    uint256 constant REQUIRED_OG_YACHTS_BLACK = 3;
    uint256 constant REQUIRED_OG_YACHTS_RED = 4;

    mapping(uint256 => uint256) requiredOgYachts;

    mapping(uint256 => uint256) requiredYachts;

    IERC721 public immutable ogYachts;
    IERC1155 public immutable sportsYachts;
    bool public claimingActive;

    modifier onlyDuringClaiming() {
        if (!claimingActive) {
            revert GeneralClaimingStopped();
        }
        _;
    }

    modifier onlyAfterStartTime() {
        if (START_TS > block.timestamp) {
            revert StartTimeHasNotPassed();
        }
        _;
    }

    modifier onlyWhenClaimingStopped() {
        if (claimingActive) {
            revert GeneralClaimingActive();
        }
        _;
    }

    constructor(address _ogYachts, address _sportsYachts) {
        sportsYachts = IERC1155(_sportsYachts);
        ogYachts = IERC721(_ogYachts);

        requiredOgYachts[RED_YACHT_ID] = REQUIRED_OG_YACHTS_RED;
        requiredOgYachts[BLACK_YACHT_ID] = REQUIRED_OG_YACHTS_BLACK;
        requiredOgYachts[SILVER_YACHT_ID] = REQUIRED_OG_YACHTS_SILVER;

        claimingActive = true;
        emit ClaimingStarted();
    }

    function claimAH() external onlyOwner onlyWhenClaimingStopped {
        // console.log("block.ts %s, START_TS %s", block.timestamp, START_TS);
        uint256[] memory ids = new uint256[](3);
        ids[0] = RED_YACHT_ID;
        ids[1] = BLACK_YACHT_ID;
        ids[2] = SILVER_YACHT_ID;

        uint256[] memory balances = new uint256[](3);
        balances[0] = sportsYachts.balanceOf(address(this), ids[0]);
        balances[1] = sportsYachts.balanceOf(address(this), ids[1]);
        balances[2] = sportsYachts.balanceOf(address(this), ids[2]);

        sportsYachts.safeBatchTransferFrom(
            address(this),
            msg.sender,
            ids,
            balances,
            ""
        );
    }

    function claim(uint256 _sportsYachtId, uint256[] memory _ogYachts)
        external
        onlyDuringClaiming
        onlyAfterStartTime
    {
        if (
            _sportsYachtId != RED_YACHT_ID &&
            _sportsYachtId != BLACK_YACHT_ID &&
            _sportsYachtId != SILVER_YACHT_ID
        ) {
            revert NonExistentSportsyachtId({suppliedId: _sportsYachtId});
        }

        uint256 sportsYachtsBalance = sportsYachts.balanceOf(
            address(this),
            _sportsYachtId
        );

        if (sportsYachtsBalance < REQUIRED_SPORTS_YACHTS) {
            revert InsufficientSportsyachts({
                available: sportsYachtsBalance,
                required: REQUIRED_SPORTS_YACHTS
            });
        }

        if (_ogYachts.length != requiredOgYachts[_sportsYachtId]) {
            revert InsufficientOgYachts({
                available: _ogYachts.length,
                required: requiredOgYachts[_sportsYachtId]
            });
        }

        // passed all preliminary checks, we're good to transfer now
        for (uint i = 0; i < _ogYachts.length; i++) {
            ogYachts.transferFrom(msg.sender, BURNER_ADDRESS, _ogYachts[i]);
        }

        sportsYachts.safeTransferFrom(
            address(this),
            msg.sender,
            _sportsYachtId,
            REQUIRED_SPORTS_YACHTS,
            ""
        );
    }

    function startClaiming() external onlyOwner onlyWhenClaimingStopped {
        claimingActive = true;
        emit ClaimingStarted();
    }

    function stopClaiming() external onlyOwner onlyDuringClaiming {
        claimingActive = false;
        emit ClaimingStopped();
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }
}