// SPDX-License-Identifier: MIT

/*
  _______ _    _ ______    _____ _____ _____  _      ______
 |__   __| |  | |  ____|  / ____|_   _|  __ \| |    |___  /
    | |  | |__| | |__    | |  __  | | | |__) | |       / / 
    | |  |  __  |  __|   | | |_ | | | |  _  /| |      / /  
    | |  | |  | | |____  | |__| |_| |_| | \ \| |____ / /__ 
    |_|  |_|  |_|______|  \_____|_____|_|  \_\______/_____|
                                                           
*/

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "./IGoodGuys.sol";
import "./Claims.sol";

contract GoodGirls is Ownable, ERC721A, Claims {
    using Strings for uint256;

    event GoodGirlClaimed(uint256 indexed ggId, uint256 indexed ggrlId);
    event TokenURISet(string indexed tokenUri);

    string private constant METADATA_INFIX = "/metadata/";
    IGoodGuys private constant IGG =
        IGoodGuys(0x13e7d08Ed191346d9FEE3b46a91c1596393dCd66);

    string private baseURI;

    constructor() ERC721A("Good Girls", "GGRL") {}

    /* ============= VIEWS ============= */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory result)
    {
        require(_exists(tokenId), "UnknownTokenId");

        return
            string(
                abi.encodePacked(
                    baseURI,
                    METADATA_INFIX,
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    /* ============= MUTATORS ============= */
    /**
     * @dev Find identities of the GoodGuys tokens that
     *   haven't been used to claim GoodGirls and execute
     *   claiming, 1:1.
     *
     *  - Emits `GoodGirlClaimed` for every GGRL minted.
     *  - Reverts if no unused GoodGuys are found.
     */
    function claim() external {
        (
            uint256[] memory unclaimedIds,
            uint256 unclaimedCount
        ) = _collectUnclaimed();

        uint256 ts = totalSupply();
        for (uint256 t = 0; t < unclaimedCount; t++) {
            _setClaimed(unclaimedIds[t]);
            emit GoodGirlClaimed(unclaimedIds[t],  ts + t + 1);
        }
        
        _safeMint(msg.sender, unclaimedCount, "");
    }

    /* ============= MUTATORS (ADMIN) ============= */
    function setTokenURI(string calldata newUri) external {
        require(msg.sender == owner(), "Unauthorized");
        emit TokenURISet(newUri);
        baseURI = newUri;
    }

    /* ============= INTERNALS ============= */
    function _collectUnclaimed()
        internal
        view
        returns (uint256[] memory, uint256)
    {
        uint256 callerGGBalance = IGG.balanceOf(msg.sender);
        require(callerGGBalance > 0, "GGsNotFound");

        uint256 unclaimedCount = 0;
        uint256[] memory unclaimedIds = new uint256[](callerGGBalance);

        for (uint256 t = 0; t < callerGGBalance; t++) {
            uint256 tokenId = IGG.tokenOfOwnerByIndex(msg.sender, t);

            if (!_isClaimed(tokenId)) {
                unclaimedIds[unclaimedCount] = tokenId;
                unclaimedCount++;
            }
        }

        require(unclaimedCount > 0, "GGsNotFound");
        return (unclaimedIds, unclaimedCount);
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }
}