// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// ============ Imports ============
import {ERC721Delegated} from "gwei-slim-nft-contracts/contracts/base/ERC721Delegated.sol";
import {IBaseERC721Interface, ConfigSettings} from "gwei-slim-nft-contracts/contracts/base/ERC721Base.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/// @notice WitchHearts Contract for https://witchhearts.com
/// @author iain @isiain
contract WitchHearts is ERC721Delegated {
    /// @notice used to track if the sale is enabled
    bool public saleEnabled = false;

    /// @notice Minting info data struct
    struct MintInfo {
        uint256 witchId;
        bool main;
        bool companion;
        address sendTo;
    }

    /// @notice wraps up provenance hash into the baseuri update
    event BaseUriUpdated(string baseUri, bytes32 provenanceHash);

    /// @notice cost for the companion
    uint256 public constant COMPANION_COST = 0.04666 ether;

    /// @notice coven contract
    address private immutable covenContract;

    /// @notice delegate constructor for gwei saving nft impl
    /// @param baseFactory base contract factory for delegated
    /// @param _covenContract crypto coven ownership base contract
    constructor(address baseFactory, address _covenContract)
        ERC721Delegated(
            baseFactory,
            "WitchHearts",
            "WTCHHRTS",
            ConfigSettings({
                royaltyBps: 2000,
                uriBase: "https://minter-api-production.up.railway.app/nft/",
                uriExtension: ".json",
                hasTransferHook: false
            })
        )
    {
        covenContract = _covenContract;
    }

    /// @notice allows admin to update the baseUri
    /// @param baseUri new base uri
    /// @param provenanceHash associated provenance hash for the given base uri
    function setBaseURI(string memory baseUri, bytes32 provenanceHash)
        public
        onlyOwner
    {
        _setBaseURI(baseUri, ".json");
        emit BaseUriUpdated(baseUri, provenanceHash);
    }

    /// @notice starts and stops sale
    /// @param _saleEnabled boolean if the sale is currently enabled
    function setSaleEnabled(bool _saleEnabled) external onlyOwner {
        saleEnabled = _saleEnabled;
    }

    /// @notice guard to ensure user owns the given witch id
    /// @param witchId pass in the id of the witch the user is claiming to own
    function ownsWitch(uint256 witchId) internal view {
        require(
            IERC721Upgradeable(covenContract).ownerOf(witchId) == msg.sender,
            "Need to own this witch"
        );
    }

    /// @notice withdraw funds after sale by owner
    function withdraw() external onlyOwner {
        AddressUpgradeable.sendValue(payable(_owner()), address(this).balance);
    }

    /// @notice burn shim to prevent users from burning due to bookkeeping
    /// @param tokenId token id to attempt to burn
    function burn(uint256 tokenId) external {
        revert('not supported');
    }

    /// @notice main mint function that takes in a MintInfo struct
    /// @param mintInfo mint info struct
    function mintWithWitches(MintInfo[] calldata mintInfo) external payable {
        require(saleEnabled, "Sale not started");
        uint256 cost = 0;
        for (uint256 i = 0; i < mintInfo.length; i++) {
            ownsWitch(mintInfo[i].witchId);
            if (mintInfo[i].companion) {
                cost += COMPANION_COST;
            }
        }
        require(cost == msg.value, "Wrong payment value");

        for (uint256 i = 0; i < mintInfo.length; i++) {
            uint256 mintId = mintInfo[i].witchId * 10;

            if (mintInfo[i].main) {
                _mint(msg.sender, mintId);
            }
            if (mintInfo[i].companion) {
                _mint(mintInfo[i].sendTo, mintId + 1);
            }
        }
    }
}