//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#(//,,           .,,/(#%&@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.                          ,%@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@#            .              %@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@,                ,         ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&                    ,      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@        ,             ,,.  @@@@@@@@@@(%@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@%            .,         .,,,@@@@@@@@@*,&@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@                ,,,,. .,,,,,,,,,##,,,,(@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@*                  .,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@                     ,,,,,,,,,,,,,,,,,,,                      /@@@@@@@
@@@@@@@@@,                   ,,,,,,,,,,,,,,,,,,,,,,,                    %@@@@@@@
@@@@@@@@%            ..,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,..            @@@@@@@@
@@@@@@@@                      ,,,,,,,,,,,,,,,,,,,,,                    @@@@@@@@@
@@@@@@@@.                     .,,,,,,,,,,,,,,,,,,,                    @@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,.                  @@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,,,&@@@@,,,,,,.    .,,,               &@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@&,%@@@@@@@@@/,,,          .,           @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@#&@@@@@@@@@&   .,              .      [email protected]@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(       ,                  ,@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#           .               &@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@(                           %@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@%/                           .(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
harry830622 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract Em is
    Context,
    AccessControlEnumerable,
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply
{
    uint256 public constant OG_TOKEN_ID = 0;
    uint256 public constant FOUNDER_TOKEN_ID = 1;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Merge public immutable merge;
    uint256 public immutable blueMergeId;

    address public vault;
    uint256 public royaltyInBips;
    address public royaltyReceiver;

    bool public isOgTokenClaimingEnabled;
    bool public isFounderTokenClaimingEnabled;
    bool public isFounderTokenMintingEnabled;
    bool public isFounderTokenMintingEnabled1;
    bool public isFounderTokenMintingEnabled2;

    mapping(address => uint256) public addressToNumClaimableOgTokens;
    mapping(address => uint256) public addressToNumClaimableFounderTokens;

    uint256 public targetMass;
    uint256 public pricePerToken = 1000 ether;
    uint256 public fundGoal;
    uint256 public fundRaised;
    SubVault[] public subVaults;
    uint256[] private emptySubVaultIdxs_;

    event OgTokenClaimed(address indexed to, uint256 qty);
    event FounderTokenClaimed(address indexed to, uint256 qty);
    event FounderTokenMinted(
        address indexed to,
        uint256 qty,
        uint256 indexed mergeId
    );
    event FounderTokenMinted1(
        address indexed to,
        uint256 qty,
        uint256 indexed mergeId
    );
    event FounderTokenMinted2(address indexed to, uint256 qty, uint256 value);
    event SubVaultCreated(address indexed subVault);

    constructor(
        string memory uri,
        address merge_,
        uint256 blueMergeId_,
        address vault_,
        uint256 royaltyInBips_,
        address royaltyReceiver_
    ) ERC1155(uri) {
        merge = Merge(merge_);
        blueMergeId = blueMergeId_;
        vault = vault_;
        royaltyInBips = royaltyInBips_;
        royaltyReceiver = royaltyReceiver_;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);

        targetMass = merge.massOf(blueMergeId_);

        uint256 numSubVaultsToCreate = 5;
        for (uint256 i = 0; i < numSubVaultsToCreate; ++i) {
            SubVault subVault = new SubVault(merge);
            subVaults.push(subVault);

            emit SubVaultCreated(address(subVault));
        }
        // TODO: Why is `i >= 0` failed to compile?
        for (uint256 i = numSubVaultsToCreate - 1; i > 0; --i) {
            emptySubVaultIdxs_.push(i);
        }
        emptySubVaultIdxs_.push(0);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address, uint256)
    {
        uint256 royaltyAmount = (salePrice * royaltyInBips) / 10000;
        return (royaltyReceiver, royaltyAmount);
    }

    function numSubVaults() external view returns (uint256) {
        return subVaults.length;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        bytes4 _ERC2981_ = 0x2a55205a;
        return super.supportsInterface(interfaceId) || interfaceId == _ERC2981_;
    }

    function setUri(string memory uri) external onlyRole(ADMIN_ROLE) {
        _setURI(uri);
    }

    function setVault(address vault_) external onlyRole(ADMIN_ROLE) {
        vault = vault_;
    }

    function setRoyaltyInBips(uint256 royaltyInBips_)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(royaltyInBips_ <= 10000, "More than 100%");
        royaltyInBips = royaltyInBips_;
    }

    function setRoyaltyReceiver(address royaltyReceiver_)
        external
        onlyRole(ADMIN_ROLE)
    {
        royaltyReceiver = royaltyReceiver_;
    }

    function toggleOgTokenClaiming() external onlyRole(ADMIN_ROLE) {
        isOgTokenClaimingEnabled = !isOgTokenClaimingEnabled;
    }

    function toggleFounderTokenClaiming() external onlyRole(ADMIN_ROLE) {
        isFounderTokenClaimingEnabled = !isFounderTokenClaimingEnabled;
    }

    function toggleFounderTokenMinting() external onlyRole(ADMIN_ROLE) {
        isFounderTokenMintingEnabled = !isFounderTokenMintingEnabled;
    }

    function toggleFounderTokenMinting1() external onlyRole(ADMIN_ROLE) {
        isFounderTokenMintingEnabled1 = !isFounderTokenMintingEnabled1;
    }

    function toggleFounderTokenMinting2() external onlyRole(ADMIN_ROLE) {
        isFounderTokenMintingEnabled2 = !isFounderTokenMintingEnabled2;
    }

    function setNumClaimableOgTokensForAddresses(
        address[] calldata addresses,
        uint256[] calldata numClaimableTokenss
    ) external onlyRole(ADMIN_ROLE) {
        require(
            numClaimableTokenss.length == addresses.length,
            "Lengths are not equal"
        );

        uint256 numAddresses = addresses.length;
        for (uint256 i = 0; i < numAddresses; ++i) {
            addressToNumClaimableOgTokens[addresses[i]] = numClaimableTokenss[
                i
            ];
        }
    }

    function setNumClaimableFounderTokensForAddresses(
        address[] calldata addresses,
        uint256[] calldata numClaimableTokenss
    ) external onlyRole(ADMIN_ROLE) {
        require(
            numClaimableTokenss.length == addresses.length,
            "Lengths are not equal"
        );

        uint256 numAddresses = addresses.length;
        for (uint256 i = 0; i < numAddresses; ++i) {
            addressToNumClaimableFounderTokens[
                addresses[i]
            ] = numClaimableTokenss[i];
        }
    }

    function setTargetMass(uint256 mass) external onlyRole(ADMIN_ROLE) {
        targetMass = mass;
    }

    function setPricePerToken(uint256 price) external onlyRole(ADMIN_ROLE) {
        pricePerToken = price;
    }

    function setFundGoal(uint256 goal) external onlyRole(ADMIN_ROLE) {
        fundGoal = goal;
    }

    function claimOgToken(address to) external {
        require(isOgTokenClaimingEnabled, "Not enabled");

        uint256 qty = addressToNumClaimableOgTokens[to];
        require(qty > 0, "Not enough quota");
        addressToNumClaimableOgTokens[to] = 0;

        _mint(to, OG_TOKEN_ID, qty, "");

        emit OgTokenClaimed(to, qty);
    }

    function claimFounderToken(address to) external {
        require(isFounderTokenClaimingEnabled, "Not enabled");

        uint256 qty = addressToNumClaimableFounderTokens[to];
        require(qty > 0, "Not enough quota");
        addressToNumClaimableFounderTokens[to] = 0;

        _mint(to, FOUNDER_TOKEN_ID, qty, "");

        emit FounderTokenClaimed(to, qty);
    }

    function mintFounderToken(address to, uint256 mergeId) external {
        require(isFounderTokenMintingEnabled, "Not enabled");

        uint256 mass = merge.massOf(mergeId);

        require(mass <= merge.massOf(merge.tokenOf(vault)), "Too big");
        merge.safeTransferFrom(merge.ownerOf(mergeId), vault, mergeId);

        _mint(to, FOUNDER_TOKEN_ID, mass, "");

        emit FounderTokenMinted(to, mass, mergeId);
    }

    function mintFounderToken1(address to, uint256 mergeId) external {
        require(isFounderTokenMintingEnabled1, "Not enabled");

        uint256 mass = merge.massOf(mergeId);

        merge.safeTransferFrom(merge.ownerOf(mergeId), vault, mergeId);
        uint256 massAfterMerge = merge.massOf(merge.tokenOf(vault));
        require(massAfterMerge <= targetMass, "Too big");

        if (massAfterMerge == targetMass) {
            address dest = address(0);
            uint256 numEmptySubVaults = emptySubVaultIdxs_.length;
            if (numEmptySubVaults > 0) {
                dest = address(
                    subVaults[emptySubVaultIdxs_[numEmptySubVaults - 1]]
                );
                emptySubVaultIdxs_.pop();
            }
            if (dest == address(0)) {
                SubVault subVault = new SubVault(merge);
                subVaults.push(subVault);

                emit SubVaultCreated(address(subVault));

                dest = address(subVault);
            }
            merge.safeTransferFrom(vault, dest, merge.tokenOf(vault));
        }

        _mint(to, FOUNDER_TOKEN_ID, mass, "");

        emit FounderTokenMinted1(to, mass, mergeId);
    }

    function mintFounderToken2(address to, uint256 qty) external payable {
        require(isFounderTokenMintingEnabled2, "Not enabled");
        require(msg.value == qty * pricePerToken, "Wrong value");
        require(fundGoal > 0, "Fund goal not set");

        fundRaised += msg.value;
        if (fundRaised >= fundGoal) {
            fundRaised = 0;
            fundGoal = 0;
            isFounderTokenMintingEnabled2 = false;
        }

        _mint(to, FOUNDER_TOKEN_ID, qty, "");

        emit FounderTokenMinted2(to, qty, msg.value);
    }

    function withdrawMerges(address to, uint256[] calldata idxs)
        external
        onlyRole(ADMIN_ROLE)
    {
        uint256 numIdxs = idxs.length;
        for (uint256 i = 0; i < numIdxs; ++i) {
            uint256 idx = idxs[i];
            address from = address(subVaults[idx]);
            if (merge.balanceOf(from) != 1) {
                continue;
            }
            emptySubVaultIdxs_.push(idx);
            merge.safeTransferFrom(from, to, merge.tokenOf(from));
        }
    }

    function withdrawAllMerges(address to) external onlyRole(ADMIN_ROLE) {
        uint256 subVaultsLength = subVaults.length;
        for (uint256 i = 0; i < subVaultsLength; ++i) {
            address from = address(subVaults[i]);
            if (merge.balanceOf(from) != 1) {
                continue;
            }
            emptySubVaultIdxs_.push(i);
            merge.safeTransferFrom(from, to, merge.tokenOf(from));
        }
    }

    function mint(
        address to,
        uint256 id,
        uint256 qty
    ) external onlyRole(MINTER_ROLE) {
        _mint(to, id, qty, "");
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata qtys
    ) external onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, qtys, "");
    }

    function withdraw(address payable to) external onlyRole(ADMIN_ROLE) {
        to.transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        return
            super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

contract Merge {
    function balanceOf(address owner) public view returns (uint256) {}

    function ownerOf(uint256 tokenId) public view returns (address owner) {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {}

    function setApprovalForAll(address operator, bool approved) public {}

    function massOf(uint256 tokenId) public view returns (uint256) {}

    function getValueOf(uint256 tokenId) public view returns (uint256) {}

    function decodeClass(uint256 value) public pure returns (uint256) {}

    function decodeMass(uint256 value) public pure returns (uint256) {}

    function tokenOf(address owner) public view returns (uint256) {}
}

contract SubVault is Context, ERC721Holder {
    constructor(Merge merge) {
        merge.setApprovalForAll(_msgSender(), true);
    }
}