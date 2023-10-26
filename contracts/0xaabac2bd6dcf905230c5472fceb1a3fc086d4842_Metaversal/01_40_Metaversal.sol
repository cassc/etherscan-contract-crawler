// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "@chocolate-factory/contracts/token/ERC721/presets/MultiStage.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract Metaversal is MultiStage {
    function initialize(
        bytes32 phaseOneMerkleRoot_,
        bytes32 phaseTwoMerkleRoot_,
        address royaltiesRecipient_,
        uint256 royaltiesValue_,
        address[] memory shareholders,
        uint256[] memory shares
    ) public initializerERC721A initializer {
        __ERC721A_init("Omega RUNNER", "OmegaRUNNER");
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        __AdminManager_init_unchained();
        __Supply_init_unchained(5555);
        __AdminMint_init_unchained();
        __Whitelist_init_unchained();
        __BalanceLimit_init_unchained();
        __UriManager_init_unchained("https://ipfs.io/ipfs/bafybeiepn6zp6ry4lncfcg56bvjullw2n324zwmodq7o3jat5cezhvipie/", ".json");
        __CustomPaymentSplitter_init(shareholders, shares);
        __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);

        // public
        setPrice(1, 0.06 ether);
        updateBalanceLimit(1, 2);
        // phase 1
        setPrice(2, 0.06 ether);
        updateBalanceLimit(2, 2);
        updateMerkleTreeRoot(2, phaseOneMerkleRoot_);
        // phase 2
        setPrice(3, 0.06 ether);
        updateBalanceLimit(3, 1);
        updateMerkleTreeRoot(3, phaseTwoMerkleRoot_);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}