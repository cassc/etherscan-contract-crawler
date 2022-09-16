/* solhint-disable quotes */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./POAPBoard.sol";
import "./POAPLibrary.sol";
import "./IDescriptor.sol";
import "./IBadgesVerifier.sol";
import "./ICheeth.sol";

contract AnonymiceBadges is POAPBoard {
    address public cheethAddress;
    address public descriptorAddress;
    address public badgesVerifierAddress;
    bool public isPaused = true;
    mapping(uint256 => uint256) public boardPrices;
    mapping(address => string) public boardNames;
    mapping(address => bool) private _auth;

    constructor() POAPBoard("Anonymice Collector Cards", "AnonymiceCollectorCards") {}

    function mint() external pure override {
        revert("no free mint");
    }

    function claimAll(
        uint256[] calldata ids,
        bytes32[][] calldata proofs,
        uint256[] calldata genesisMice,
        uint256[] calldata babyMice
    ) external {
        for (uint256 index = 0; index < ids.length; index++) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(proofs[index], merkleRootsByPOAPId[ids[index]], leaf), "not in whitelist");
            _claimPOAP(ids[index], msg.sender);
        }

        uint256[] memory badgeIds = IBadgesVerifier(badgesVerifierAddress).claimableBadges(
            genesisMice,
            babyMice,
            msg.sender
        );

        for (uint256 index = 0; index < badgeIds.length; index++) {
            uint256 badgeId = badgeIds[index];
            if (badgeId == 0) break;
            if (!_poapOwners[badgeId][msg.sender]) {
                _claimPOAP(badgeIds[index], msg.sender);
            }
        }
    }

    function claimVerifiedBadge(
        uint256[] calldata genesisMice,
        uint256[] calldata babyMice,
        uint256 badgeIdToClaim
    ) external {
        uint256[] memory badgeIds = IBadgesVerifier(badgesVerifierAddress).claimableBadges(
            genesisMice,
            babyMice,
            msg.sender
        );

        for (uint256 index = 0; index < badgeIds.length; index++) {
            uint256 badgeId = badgeIds[index];
            if (badgeId == 0) break;
            if (badgeIdToClaim == badgeId) {
                if (!_poapOwners[badgeId][msg.sender]) {
                    _claimPOAP(badgeIds[index], msg.sender);
                }
            }
        }
    }

    function getVerifiedBadges(uint256[] memory genesisMice, uint256[] memory babyMice)
        external
        view
        returns (uint256[] memory)
    {
        return IBadgesVerifier(badgesVerifierAddress).claimableBadges(genesisMice, babyMice, msg.sender);
    }

    function buyBoard(uint256 boardId) external {
        require(boardPrices[boardId] > 0, "price not set");
        ICheeth(cheethAddress).burnFrom(msg.sender, boardPrices[boardId]);
        if (!_minted(msg.sender)) {
            _mint(msg.sender);
            currentBoard[msg.sender] = boardId;
        }
        _claimBoard(boardId, msg.sender);
    }

    function setBoardName(string memory name) external {
        boardNames[msg.sender] = name;
    }

    function externalClaimBoard(uint256 boardId, address to) external {
        require(_auth[msg.sender], "no auth");
        _claimBoard(boardId, to);
    }

    function externalClaimPOAP(uint256 id, address to) external {
        require(_auth[msg.sender], "no auth");
        _claimPOAP(id, to);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return IDescriptor(descriptorAddress).tokenURI(id);
    }

    function rearrangeBoardAndName(
        uint256 boardId,
        uint256[] memory slots,
        string memory text
    ) external {
        if (boardId != currentBoard[msg.sender]) _swapBoard(boardId, false);
        _rearrangePOAPs(slots);
        boardNames[msg.sender] = text;
    }

    function previewBoard(
        uint256 boardId,
        uint256[] calldata badges,
        string memory text
    ) external view returns (string memory) {
        return IDescriptor(descriptorAddress).buildSvg(boardId, badges, text, true);
    }

    function setDescriptorAddress(address _descriptorAddress) external onlyOwner {
        descriptorAddress = _descriptorAddress;
    }

    function setCheethAddress(address _cheethAddress) external onlyOwner {
        cheethAddress = _cheethAddress;
    }

    function setBadgesVerifierAddress(address _badgesVerifierAddress) external onlyOwner {
        badgesVerifierAddress = _badgesVerifierAddress;
    }

    function setAuth(address wallet, bool value) external onlyOwner {
        _auth[wallet] = value;
    }

    function setIsPaused(bool value) external onlyOwner {
        isPaused = value;
    }

    function setBoardPrice(uint256 boardId, uint256 boardPrice) external onlyOwner {
        boardPrices[boardId] = boardPrice;
    }
}
/* solhint-enable quotes */