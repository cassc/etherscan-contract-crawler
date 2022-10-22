// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

//                    @@@@@@@@@@@@@@@@@@@
//                 @@@@@@             @@@@@@
//              @@@@@                     @@@@
//            @@@@                          @@@@
//           @@@@                             @@@@
//          @@@@             @@@@@             @@@@
//          @@@           @@@@@@@@@@@           @@@
//          @@@         @@@         @@@         @@@
//          @@@        @@@    @@@@   @@@        @@@
//          @@@        @@@   @@@@@@  @@@        @@@
//          @@@        @@@    @@@@   @@@        @@@
//          @@@          @@@        @@@         @@@
//          @@@           @@@@@@@@@@@           @@@
//          @@@               @@@@              @@@
//          @@@                                 @@@
//          @@@                                 @@@
//

contract Sorce2 is ERC721AQueryable, Ownable, ReentrancyGuard, Pausable {
    constructor() ERC721A("CULTIVATE - SORCE VIAL", "SORCE") {
        _mint(msg.sender, 24);
    }

    address dr1verAddress; // Approved dr1ver contract
    address private _approved = 0x04d0d24c72F9A95026a37389EEA64d2df1f2239B;
    string private _baseTokenURI =
        "https://dr1ver.cult1vate.com/sorce/metadata/";

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setDr1verAddress(address newAddress) public onlyOwner {
        dr1verAddress = newAddress;
    }

    function mintTransfer(address to) public {
        require(msg.sender == dr1verAddress, "Not authorized");

        _mint(to, 1);
    }

    /*
     *
     * Staking
     *
     */

    mapping(uint256 => uint256) private stakingStarted;
    mapping(uint256 => uint256) private stakingTotal;
    mapping(uint256 => uint256) private lastStakeEnd;

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(!paused(), "Contract is paused");
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(stakingStarted[tokenId] == 0, "Sorce staked");
            require(
                block.timestamp - lastStakeEnd[tokenId] > 1800,
                "Sorce just unstaked, you need to wait some time before transferring"
            );
        }
    }

    bool public stakingOpen = false;

    function setStakingOpen(bool open) external onlyOwner {
        stakingOpen = open;
    }

    function toggleStaking(uint256 tokenId) internal onlyOwnerOrApproved {
        uint256 start = stakingStarted[tokenId];
        if (start == 0) {
            require(stakingOpen, "Staking Closed");
            stakingStarted[tokenId] = block.timestamp;
        } else {
            stakingTotal[tokenId] += block.timestamp - start;
            stakingStarted[tokenId] = 0;
            lastStakeEnd[tokenId] = block.timestamp;
        }
    }

    function toggleStaking(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleStaking(tokenIds[i]);
        }
    }

    function stakingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool isStaked,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = stakingStarted[tokenId];
        if (start != 0) {
            isStaked = true;
            current = block.timestamp - start;
        }
        total = current + stakingTotal[tokenId];
    }

    function ownerMint(
        address[] memory addresses,
        uint256[] memory amountToMintList
    ) public onlyOwner {
        require(
            addresses.length == amountToMintList.length,
            "KD: addresses does not match amount length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], amountToMintList[i]);
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function contractURI() public pure returns (string memory) {
        return "https://dr1ver.cult1vate.com/sorce/opensea";
    }

    function pause() public onlyOwnerOrApproved {
        Pausable._pause();
    }

    function unpause() public onlyOwnerOrApproved {
        Pausable._unpause();
    }

    modifier onlyOwnerOrApproved() {
        require(
            msg.sender == owner() || msg.sender == _approved,
            "Not owner or approved"
        );
        _;
    }

    function setApproved(address approved) external onlyOwner {
        _approved = approved;
    }
}