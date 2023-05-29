// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {Auth, Authority} from "@rari-capital/solmate/src/auth/Auth.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC2981} from "./ERC2981.sol";
import {VRFv2Consumer} from "./VRFConsumer.sol";

/// @title Frank
/// @author exp.table
contract Frank is ERC721, ERC2981, Auth, VRFv2Consumer {
    using Strings for uint256;
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    bool public unpaused;
    uint256 public totalSupply = 1;
    uint256 public pricePerFrank = 0.05 ether;
    uint256 public VRF_SEED;

    string public ipfsCID;

    uint256 public immutable totalFranks = 2000;
    uint256 public immutable transactionLimit = 20;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address owner,
        uint64 subscriptionId,
        address vrfCoordinator,
        address link,
        bytes32 keyHash_
    )
    ERC721("frank", "FRANK")
    Auth(owner, Authority(address(0)))
    VRFv2Consumer(subscriptionId, vrfCoordinator, link, keyHash_) {
        _mint(owner, 0);
        _royaltyFee = 700;
        _royaltyRecipient = owner;
    }

    /*//////////////////////////////////////////////////////////////
                    FRANKLY OWNER-RESTRICTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setPrice(uint256 newPrice) requiresAuth public {
        pricePerFrank = newPrice;
    }

    function switchPause() requiresAuth public {
        unpaused = !unpaused;
    }

    function setRoyaltyRecipient(address recipient) requiresAuth public {
        _royaltyRecipient = recipient;
    }

    function setRoyaltyFee(uint256 fee) requiresAuth public {
        _royaltyFee = fee;
    }

    function setIPFS(string calldata cid) requiresAuth public {
        ipfsCID = cid;
    }

    /*//////////////////////////////////////////////////////////////
                        FRANKLY INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        VRF_SEED = randomWords[0];
    }

    /*//////////////////////////////////////////////////////////////
                        FRANKLY PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mintFrank(uint256 amount) public payable {
        require(unpaused, "FRANKLY_PAUSED");
        require(amount <= transactionLimit, "FRANKLY_OVER_LIMIT");
        require(totalSupply + amount <= totalFranks, "TOO_MANY_FRANKS");
        require(msg.value == amount * pricePerFrank, "FRANKLY_TOO_CHEAP");
        uint256 currentSupply = totalSupply;
        for(uint i; i < amount; i++) {
            _safeMint(msg.sender, currentSupply + i);
        }
        totalSupply += amount;
    }

    function withdraw() public {
        SafeTransferLib.safeTransferETH(owner, (address(this).balance * 8000) / 10000);
        SafeTransferLib.safeTransferETH(0xD2927a91570146218eD700566DF516d67C5ECFAB, address(this).balance);
    }

    /*//////////////////////////////////////////////////////////////
                        FRANKLY VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (bytes(ipfsCID).length == 0) return "ipfs://QmX9izUxcZ6KjahnP5n5JaT4s8mTWr1HDyJxMKoKSDYXhC";
        uint256 shuffledId = (tokenId + VRF_SEED) % totalFranks;
        return string(abi.encodePacked("ipfs://", ipfsCID, "/", shuffledId.toString()));

    }

    function supportsInterface(bytes4 interfaceId) public pure override(ERC721, ERC2981) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}