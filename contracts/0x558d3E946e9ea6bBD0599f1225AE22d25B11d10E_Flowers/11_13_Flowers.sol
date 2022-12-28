// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @author narghev dactyleth

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "erc721a/contracts/interfaces/IERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface INyoStaking {
    function tokenStakedInfo(uint256)
        external
        view
        returns (
            address owner,
            uint256 stakedAt,
            uint256 tokenId
        );
}

contract Flowers is Ownable, ERC1155 {
    string private baseUri =
        "ipfs://QmUduQg1nrNMjgyyRNfFLqYk25n899VuKZp45Xx85PPNhN/";
    uint256 public constant ULTIMATE_FLOWER_ID = 0;
    uint256 public constant MAX_FLOWER_ID = 10;
    uint256 public constant TIME_TO_STAKE = 1 weeks;
    address public stakingAddress;
    address public nyolingContractAddress;
    INyoStaking private staking;
    IERC721A private nyolings;

    struct NyoInfo {
        uint256 lastClaimedAt;
        uint256 lastFlowerId;
    }

    mapping(uint256 => bool) public upgradedNyos;
    mapping(uint256 => NyoInfo) public nyoInfos;

    constructor(address _stakingAddress, address _nyolingContractAddress)
        ERC1155(baseUri)
    {
        stakingAddress = _stakingAddress;
        nyolingContractAddress = _nyolingContractAddress;
        staking = INyoStaking(_stakingAddress);
        nyolings = IERC721A(_nyolingContractAddress);
    }

    function getClaimableCount(uint256 tokenId) public view returns (uint256) {
        (address owner, uint256 stakedAt, ) = staking.tokenStakedInfo(tokenId);

        if (owner == address(0)) return 0;

        NyoInfo memory nyoInfo = nyoInfos[tokenId];

        uint256 baseDate = stakedAt > nyoInfo.lastClaimedAt
            ? stakedAt
            : nyoInfo.lastClaimedAt;

        uint256 timeCount = (block.timestamp - baseDate) / TIME_TO_STAKE;
        uint256 leftToClaim = MAX_FLOWER_ID - nyoInfo.lastFlowerId;

        return timeCount > leftToClaim ? leftToClaim : timeCount;
    }

    function claim(uint256[] memory nyolingIds) public {
        for (uint256 i = 0; i < nyolingIds.length; i++) {
            (address owner, , ) = staking.tokenStakedInfo(nyolingIds[i]);
            require(owner == msg.sender, "Can only stake claim own Nyo");

            uint256 count = getClaimableCount(nyolingIds[i]);

            uint256 lastFlowerId = nyoInfos[nyolingIds[i]].lastFlowerId;

            for (uint256 j = 1 + lastFlowerId; j <= count + lastFlowerId; j++) {
                _mint(msg.sender, j, 1, "");
            }

            nyoInfos[nyolingIds[i]] = NyoInfo(
                block.timestamp,
                count + lastFlowerId
            );
        }
    }

    function burnForUltimate(uint16 n) public {
        for (uint256 i = 1; i <= MAX_FLOWER_ID; i++) {
            _burn(msg.sender, i, n);
        }

        _mint(msg.sender, ULTIMATE_FLOWER_ID, n, "");
    }

    function upgrade(uint256[] memory nyolingIds) public {
        _burn(msg.sender, ULTIMATE_FLOWER_ID, nyolingIds.length);

        for (uint256 i = 0; i < nyolingIds.length; i++) {
            require(!upgradedNyos[nyolingIds[i]], "Already upgraded");
            (address stakedOwner, , ) = staking.tokenStakedInfo(nyolingIds[i]);
            require(
                stakedOwner == msg.sender ||
                    nyolings.ownerOf(nyolingIds[i]) == msg.sender,
                "Only owner can upgrade"
            );

            upgradedNyos[nyolingIds[i]] = true;
        }
    }

    function uri(uint256 flowerId)
        public
        view
        override
        returns (string memory)
    {
        require(flowerId <= MAX_FLOWER_ID, "Flower does not exist");

        return
            string(
                abi.encodePacked(baseUri, Strings.toString(flowerId), ".json")
            );
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }
}