// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SignatureVerifier.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract ShinikiCampaign is
    Initializable,
    SignatureVerifier,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    // Info collection
    mapping(bytes => uint256) internal collectionDetail;

    // Info current index for each token
    mapping(address => uint256) internal currentIndex;

    //Info claimed reward for each address
    mapping(bytes => bool) public claimed;

    // Info current index for each token
    mapping(address => uint256) internal collectionIndex;

    event Claimed(
        address receiver,
        address[] token,
        uint256[] amount,
        uint256[] campaignIds,
        uint256 nonce
    );

    function initialize() external initializer {
        __ReentrancyGuard_init();
        __Pausable_init();

        TRUSTED_PARTY = 0x86B5E0Db161f38abf70Ace5e02a08F7f2856B80D;
        isOperators[0x11ace0cDA4debDd500FED5Da2B7fBfCdfAe5BFAA] = true;
    }

    /**
    @notice User claim reward
     * @param tokens 'address' token reward
     * @param amounts 'uint256' number token to claim
     * @param campaignIds 'uint256' maximum number reward (not claimed + claimed)
     * @param nonce 'uint256' a number random
     * @param signature 'bytes' a signature to verify data when claim
     */
    function claimCampaign(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory campaignIds,
        uint256 nonce,
        bytes memory signature
    ) public nonReentrant whenNotPaused {
        verifyClaimCampaign(
            msg.sender,
            tokens,
            amounts,
            campaignIds,
            nonce,
            signature
        );
        require(
            tokens.length == amounts.length,
            "ShinikiCampaign: input is invalid"
        );
        for (uint256 i = 0; i < campaignIds.length; i++) {
            bytes memory data = abi.encode(msg.sender, campaignIds[i]);
            require(!claimed[data], "ShinikiCampaign: campaign is claimed");
            claimed[data] = true;
        }
        for (uint256 i = 0; i < tokens.length; i++) {
            while (amounts[i] != 0) {
                address collection = tokens[i];
                require(currentIndex[collection] < collectionIndex[collection], "ShinikiCampaign: campaign is out of stock");
                bytes memory data = abi.encode(
                    collection,
                    currentIndex[collection]
                );
                uint256 tokenId = collectionDetail[data];
                // while (
                //     IERC721Upgradeable(collection).ownerOf(tokenId) !=
                //     address(this)
                // ) {
                //     currentIndex[collection]++;
                //     bytes memory _data = abi.encode(
                //         collection,
                //         currentIndex[collection]
                //     );
                //     tokenId = collectionDetail[_data];
                // }
                currentIndex[collection]++;
                amounts[i]--;

                IERC721Upgradeable(collection).safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId,
                    ""
                );
            }
        }

        emit Claimed(msg.sender, tokens, amounts, campaignIds, nonce);
    }

    /**
    @notice Deposite token ETH to pool
     */
    function depositeERC721(address token, uint256[] memory tokenIds)
        public
        onlyOperator
    {
        require(
            tokenIds.length != 0,
            "ShinikiCamPaign: input tokenIds is invalid"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            bytes memory data = abi.encode(token, collectionIndex[token]);
            collectionIndex[token]++;
            collectionDetail[data] = tokenIds[i];
            IERC721Upgradeable(token).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
        }
    }

    /**
    @notice Withdraw token erc721
     */
    function withdrawERC721(address token, uint256[] memory tokenIds)
        public
        onlyOperator
    {
        require(tokenIds.length != 0, "ShinikiCamPaign: input is not zero");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721Upgradeable(token).safeTransferFrom(address(this), msg.sender, tokenIds[i], "");
        }
    }

    /**
    @dev Pause the contract
     */
    function pause() public onlyOperator {
        _pause();
    }

    /**
    @dev Unpause the contract
     */
    function unpause() public onlyOperator {
        _unpause();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}