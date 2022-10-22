// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
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

abstract contract MintableInterface {
    function mintTransfer(address to) public virtual;
}

abstract contract EnhancementInterface {
    function restore(address driverOwner, uint256 enhancementId)
        public
        virtual
        returns (bool);

    function use(address driverOwner, uint256 enhancementId)
        public
        virtual
        returns (bool);
}

contract Dr1ver is Ownable, Pausable, ReentrancyGuard, ERC721Enumerable {
    address private _bankWallet = 0x04d0d24c72F9A95026a37389EEA64d2df1f2239B;
    address private _approved = 0x04d0d24c72F9A95026a37389EEA64d2df1f2239B;

    uint256 public price = 0.05 ether;
    string private _baseTokenURI = "https://dr1ver.cult1vate.com/metadata/";

    address genesisSorceAddress; // Approved mintvial contract
    address sorceAddress; // Something ~ ~ ~
    uint256 currentTokenId = 24;

    struct Enhancement {
        address addr;
        uint tokenId;
    }

    mapping(uint256 => uint256) private enhancementMap;
    mapping(uint256 => address) private enhancementContractMap;
    mapping(uint256 => uint256) private enhancementTokenIdMap;
    mapping(address => uint256) private authorizedEnhancementContracts;

    constructor() ERC721("CULTIVATE | DR1VER GENESIS", "DR1VER") {
        unchecked {
            for (uint i = 1; i <= 24; i++) {
                // Mint 23 Dr1vers for Cultivate Vault
                _safeMint(msg.sender, i);
            }
        }
    }

    /*
     *
     * Migration
     *
     */

    function mintTransfer(address to) public payable {
        require(msg.sender == genesisSorceAddress, "Not authorized");
        require(price <= msg.value, "KD: Insufficient eth");

        MintableInterface sorceContract = MintableInterface(sorceAddress);
        sorceContract.mintTransfer(to);

        currentTokenId++;

        _safeMint(to, currentTokenId);
    }

    /*
     *
     * Staking
     *
     */

    mapping(uint256 => uint256) private stakingStarted;
    mapping(uint256 => uint256) private stakingTotal;
    mapping(uint256 => uint256) private lastStakeEnd;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(!paused(), "Contract is paused");
        require(stakingStarted[tokenId] == 0, "Dr1ver staked");
        require(
            block.timestamp - lastStakeEnd[tokenId] > 1800,
            "Dr1ver just unstaked, you need to wait some time before transferring"
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }

    bool public stakingOpen = false;

    function setStakingOpen(bool open) external onlyOwner {
        stakingOpen = open;
    }

    function toggleStaking(uint256 tokenId) internal onlyOwnerOrApproved {
        unchecked {
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

    /*
     *
     * ownerMint
     *
     */

    function ownerMint(
        address[] calldata addresses,
        uint256[] calldata airdropAmount
    ) public onlyOwner {
        require(
            addresses.length == airdropAmount.length,
            "KD: addresses does not match amount length"
        );
        unchecked {
            for (uint256 i = 0; i < addresses.length; i++) {
                for (uint256 j = 0; j < airdropAmount[i]; j++) {
                    currentTokenId++;
                    _safeMint(addresses[i], currentTokenId);

                    MintableInterface sorceContract = MintableInterface(
                        sorceAddress
                    );
                    sorceContract.mintTransfer(addresses[i]);
                }
            }
        }
    }

    /*
     *
     * Enhancement
     *
     */

    bool enhancementStarted = false;
    uint256 constant enhancementShift = 10_000;

    function setEnhancementStarted(bool isStarted)
        internal
        onlyOwnerOrApproved
    {
        enhancementStarted = isStarted;
    }

    function setAuthorizedEnhancementContract(
        address enhancementContract,
        bool allowed
    ) external onlyOwnerOrApproved {
        if (allowed) {
            authorizedEnhancementContracts[enhancementContract] = 1;
        } else {
            authorizedEnhancementContracts[enhancementContract] = 0;
        }
    }

    // Called by the Dressing system to burn/remint the token when enhanced
    function enhanceToken(
        uint256 tokenId,
        address enhancementContract,
        uint256 enhancementTokenId
    ) public {
        require(
            enhancementStarted == true,
            "Enhancement session has not started"
        );
        require(ownerOf(tokenId) == _msgSender(), "Doesn't own the token");
        require(
            authorizedEnhancementContracts[enhancementContract] == 1,
            "Not a valid Enhancement"
        );

        uint256 newTokenId = tokenId + enhancementShift;

        _burn(tokenId);
        _safeMint(_msgSender(), newTokenId);

        // increase enhancement count for enhanced dr1ver
        enhancementMap[newTokenId] = enhancementMap[tokenId] + 1;
        enhancementMap[tokenId] = 0;

        // Store enhancement data
        enhancementContractMap[newTokenId] = enhancementContract;
        enhancementTokenIdMap[newTokenId] = enhancementTokenId;

        // Burn the used enhancement
        EnhancementInterface enhancement = EnhancementInterface(
            enhancementContract
        );
        enhancement.use(msg.sender, enhancementTokenId);
    }

    function resetToken(uint256 tokenId) public {
        require(ownerOf(tokenId) == _msgSender(), "Doesn't own the token");
        require(tokenId > 6400, "Already reset");

        uint256 enhancementCount = enhancementMap[tokenId];

        for (uint i = 0; i < enhancementCount; i++) {
            uint256 dr1verTokenId = tokenId - enhancementShift * i;
            address enhancementContract = enhancementContractMap[dr1verTokenId];
            uint256 enhancementTokenId = enhancementTokenIdMap[dr1verTokenId];

            // Restore the enhancement
            EnhancementInterface enhancement = EnhancementInterface(
                enhancementContract
            );
            enhancement.restore(msg.sender, enhancementTokenId);

            enhancementMap[dr1verTokenId] = 0;
            enhancementContractMap[dr1verTokenId] = address(0);
            enhancementTokenIdMap[dr1verTokenId] = 0;
        }

        // Restore the original dr1ver
        _burn(tokenId);
        _safeMint(_msgSender(), tokenId - enhancementShift * enhancementCount);
    }

    function removeEnhancement(
        uint256 tokenId,
        address enhancementContractToRemove,
        uint256 enhancementIdToRemove
    ) public {
        require(ownerOf(tokenId) == _msgSender(), "Doesn't own the token");
        require(tokenId > 6400, "No enhancement to remove");

        uint256 enhancementCount = enhancementMap[tokenId];

        // find the enhancement for this token
        for (uint i = 0; i < enhancementCount; i++) {
            uint256 dr1verTokenId = tokenId - enhancementShift * i;
            address enhancementContract = enhancementContractMap[dr1verTokenId];
            uint256 enhancementTokenId = enhancementTokenIdMap[dr1verTokenId];

            if (
                enhancementContract == enhancementContractToRemove &&
                enhancementTokenId == enhancementIdToRemove
            ) {
                // Enhancement found, restore it
                EnhancementInterface enhancement = EnhancementInterface(
                    enhancementContractToRemove
                );
                enhancement.restore(msg.sender, enhancementIdToRemove);

                // Override removed enhancement with last enhancement
                enhancementContractMap[dr1verTokenId] = enhancementContractMap[
                    tokenId
                ];
                enhancementTokenIdMap[dr1verTokenId] = enhancementTokenIdMap[
                    tokenId
                ];

                // Remove last enhancement
                enhancementMap[tokenId] = 0;
                enhancementContractMap[tokenId] = address(0);
                enhancementTokenIdMap[tokenId] = 0;

                // Remint
                _burn(tokenId);
                _safeMint(_msgSender(), tokenId - enhancementShift);

                break;
            }
        }
    }

    function getEnhancements(uint256 tokenId)
        external
        view
        returns (Enhancement[] memory enhancements)
    {
        uint256 enhancementCount = enhancementMap[tokenId];
        for (uint i = 0; i < enhancementCount; i++) {
            uint256 dr1verTokenId = tokenId - enhancementShift * i;
            enhancements[i] = Enhancement(
                enhancementContractMap[dr1verTokenId],
                enhancementTokenIdMap[dr1verTokenId]
            );
        }
    }

    /*
     ** Retrieve the funds of the sale
     */
    function retrieveFunds() external nonReentrant {
        // Only the Bank Wallet or the owner can withraw the funds
        require(
            msg.sender == _bankWallet || msg.sender == owner(),
            "Not allowed"
        );
        uint256 balance = address(this).balance;
        (bool success, ) = _bankWallet.call{value: balance}("");
        require(success, "TRANSFER_FAIL");
    }

    /**
     *  Set the bank address
     */
    function setBankWallet(address addr) external onlyOwner {
        require(addr != address(0), "Invalid address");
        _bankWallet = addr;
    }

    /**
     *  Set the purchase price
     */
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwnerOrApproved {
        _baseTokenURI = baseURI;
    }

    function setGenesisSorceAddress(address newAddress)
        public
        onlyOwnerOrApproved
    {
        genesisSorceAddress = newAddress;
    }

    function setSorceAddress(address newAddress) public onlyOwnerOrApproved {
        sorceAddress = newAddress;
    }

    function contractURI() public pure returns (string memory) {
        return "https://dr1ver.cult1vate.com/opensea";
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