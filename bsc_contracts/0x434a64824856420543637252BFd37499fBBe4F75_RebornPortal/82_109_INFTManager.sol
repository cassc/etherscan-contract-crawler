// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface INFTManagerDefination {
    enum StageType {
        Invalid,
        WhitelistMint,
        PublicMint,
        Merge,
        Burn
    }
    struct StageTime {
        uint256 startTime;
        uint256 endTime; // mint end time,if no need set 4294967295(2106-02-07 14:28:15)
    }

    struct BurnRefundConfig {
        uint256 nativeToken;
        uint256 degenToken;
    }

    /**********************************************
     * errors
     **********************************************/
    error ZeroOwnerSet();
    error NotSigner();
    error OutOfMaxMintCount();
    error AlreadyMinted();
    error ZeroRootSet();
    error InvalidProof();
    error NotTokenOwner();
    error InvalidTokens();
    error MintFeeNotEnough();
    error InvalidParams();
    error InvalidTime();
    error TokenIdNotExsis();
    error MysteryBoxCannotBurn();
    error OnlyShardsCanMerge();
    error CanNotOpenMysteryBoxTwice();

    /**********************************************
     * events
     **********************************************/
    event Minted(
        address indexed receiver,
        uint256 quantity,
        uint256 startTokenId
    );
    event SignerUpdate(address indexed signer, bool valid);
    event MerkleTreeRootSet(bytes32 root);
    // burn the tokenId of from account
    event MergeTokens(
        address indexed from,
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 newTokenId
    );
    event BurnToken(
        address account,
        uint256 tokenId,
        uint256 refundNativeToken,
        uint256 refundDegenToken
    );
    event SetDegenNFT(address degenNFT);
    event MintFeeSet(uint256 mintFee);
    event SetMintTime(StageType stageType, StageTime stageTime);
    event SetBurnRefundConfig(
        uint256 level,
        BurnRefundConfig burnRefundConfigs
    );
    event SetBucket(uint256 bucket, uint256 bucketValue);
}

interface INFTManager is INFTManagerDefination {
    /**
     * @dev users in whitelist can mint mystery box
     */
    function whitelistMint(bytes32[] calldata merkleProof) external payable;

    /**
     * public mint
     * @param quantity quantities want to mint
     */
    function publicMint(uint256 quantity) external payable;

    function merge(uint256 tokenId1, uint256 tokenId2) external;

    function burn(uint256 tokenId) external;

    function setMerkleRoot(bytes32 root) external;

    function setBurnRefundConfig(
        uint256[] calldata levels,
        BurnRefundConfig[] calldata configs
    ) external;

    function withdraw(address to, uint256 amount) external;
}