// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../../library/ERC20/IERC20Partition.sol";
import "../../../library/ERC721/KEIERC721.sol";

import "../../../library/Governance/GovernanceLibrary.sol";
import "../../../core/Staking/IStaking.sol";

import "./IStakingPositionManager.sol";

contract StakingPositionManager is IStakingPositionManager, KEIERC721 {

    address public immutable override STAKING;
    address public immutable override STAKING_TOKEN;

    // mapping from NFT id to stake id
    mapping(uint256 => TokenDetails) private $details;

    uint256 private $nextTokenId = 1;

    constructor(address staking)
    ERC721("Staked Kei Positions", "sKEI.POS") {
        STAKING = staking;
        STAKING_TOKEN = IStaking(staking).STAKING_TOKEN();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IStakingPositionManager).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function stakeBalanceOf(uint256 tokenId) external view override returns (bytes32 _stakeId, uint256 _stakeBalance) {
        _requireMinted(tokenId);
        TokenDetails memory _details = $details[tokenId];
        _stakeId = _details.stakeId;
        _stakeBalance = IERC20Partition(STAKING_TOKEN).balanceOf(_details.container, _stakeId);
    }

    function stakeId(uint256 tokenId) external view override returns (bytes32) {
        return $details[tokenId].stakeId;
    }

    function setDelegate(uint256 tokenId, address target) external whenNotPaused override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        IVotesContainer($details[tokenId].container).delegate(STAKING_TOKEN, target);
    }

    function mint(
        bytes32 stakeId_,
        uint256 amount,
        address owner,
        bytes memory data
    ) external whenNotPaused override returns (uint256 tokenId) {
        tokenId = $nextTokenId++;

        IERC20Partition stakingToken = IERC20Partition(STAKING_TOKEN);
        address container = GovernanceLibrary.createVotesContainer();

        require(amount > 0, 'StakingPositionManager: INVALID_AMOUNT');

        $details[tokenId] = TokenDetails(stakeId_, container);

        stakingToken.transferFrom(
            _msgSender(),
            container,
            stakeId_,
            amount,
            "StakingPositionManager: MINT"
        );

        _safeMint(owner, tokenId, data);

        emit Mint(
            tokenId,
            stakeId_,
            amount,
            container,
            owner,
            _msgSender()
        );
    }

    function burn(
        uint256 tokenId,
        address recipient,
        bytes memory data
    ) external override whenNotPaused returns (bytes32 stakeId_, uint256 tokensReleased) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        IERC20Partition stakingToken = IERC20Partition(STAKING_TOKEN);

        _burn(tokenId);

        TokenDetails memory _details = $details[tokenId];
        delete $details[tokenId];

        stakeId_ = _details.stakeId;
        tokensReleased = stakingToken.balanceOf(_details.container, stakeId_);

        IVotesContainer(_details.container).transfer(
            STAKING_TOKEN,
            stakeId_,
            recipient,
            tokensReleased,
            data
        );

        emit Burn(tokenId, stakeId_, tokensReleased, _msgSender());
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal whenNotPaused virtual override {
        if (to != address(0)) {
            IVotesContainer($details[firstTokenId].container).delegate(STAKING_TOKEN, to);
        }
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _tokenURIData(uint256 tokenId) internal view override returns (bytes memory) {
        TokenDetails memory _details = $details[tokenId];
        return abi.encode(
            _details.stakeId,
            IERC20Partition(STAKING_TOKEN).balanceOf(_details.container, _details.stakeId)
        );
    }
}