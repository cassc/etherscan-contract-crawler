// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";

contract ERC721NESDrop is ERC721Drop {
    uint256 multiplier;

    // Event published when a token is staked.
    event Staked(uint256 tokenId);
    // Event published when a token is unstaked.
    event Unstaked(uint256 tokenId);

    mapping(uint256 => uint256) public tokenToWhenStaked;
    mapping(uint256 => uint256) public tokenToTotalDurationStaked;
    // Mapping of tokenId storing its staked status
    mapping(uint256 => bool) public tokenToIsStaked;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient,
        uint256 _multipler
    )
        ERC721Drop(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {
        multiplier = _multipler;
    }

    function getCurrentAdditionalBalance(
        uint256 tokenId
    ) public view returns (uint256) {
        if (tokenToWhenStaked[tokenId] > 0) {
            return block.number - tokenToWhenStaked[tokenId];
        } else {
            return 0;
        }
    }

    /**
     *  @dev returns total duration the token has been staked.
     */
    function getCumulativeDurationStaked(
        uint256 tokenId
    ) public view returns (uint256) {
        return
            tokenToTotalDurationStaked[tokenId] +
            getCurrentAdditionalBalance(tokenId);
    }

    /**
     *  @dev Returns the amount of tokens rewarded up until this point.
     */
    function getStakingRewards(uint256 tokenId) public view returns (uint256) {
        return getCumulativeDurationStaked(tokenId) * multiplier;
    }

    /**
     *  @dev Stakes a token and records the start block number or time stamp.
     */
    function stake(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );

        tokenToWhenStaked[tokenId] = block.number;
        _stake(tokenId);
    }

    /**
     *  @dev Unstakes a token and records the start block number or time stamp.
     */
    function unstake(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );

        tokenToTotalDurationStaked[tokenId] += getCurrentAdditionalBalance(
            tokenId
        );
        _unstake(tokenId);
    }

    /**
     *  @dev Mints token.
     */
    function mint(uint256 _quanity) external {
        _mint(msg.sender, _quanity);
    }

    /*
    function _setStakingController(address _stakingController) external {
        stakingController = _stakingController;
    }
*/
    /**
     *  @dev returns whether a token is currently staked
     */
    function isStaked(uint256 tokenId) public view returns (bool) {
        return tokenToIsStaked[tokenId];
    }

    /**
     *  @dev marks a token as staked, calling this function
     *  you disable the ability to transfer the token.
     */
    function _stake(uint256 tokenId) internal {
        require(!isStaked(tokenId), "token is already staked");

        tokenToIsStaked[tokenId] = true;
        emit Staked(tokenId);
    }

    /**
     *  @dev marks a token as unstaked. By calling this function
     *  you re-enable the ability to transfer the token.
     */
    function _unstake(uint256 tokenId) internal {
        require(isStaked(tokenId), "token isn't staked");

        tokenToIsStaked[tokenId] = false;
        emit Unstaked(tokenId);
    }

    /**
     *  @dev marks a token as staked, can only be performed by delegated
     *  staking controller contract. By calling this function you
     *  disable the ability to transfer the token.
     */
    /*
    function stakeFromController(uint256 tokenId, address originator) public {
        require(
            msg.sender == stakingController,
            "Function can only be called from staking controller contract"
        );
        require(
            ownerOf(tokenId) == originator,
            "Originator is not the owner of this token"
        );

        _stake(tokenId);
    }
*/
    /**
     *  @dev marks a token as unstaked, can only be performed delegated
     *  staking controller contract. By calling this function you
     *  re-enable the ability to transfer the token.
     */
    /*
    function unstakeFromController(uint256 tokenId, address originator) public {
        require(
            msg.sender == stakingController,
            "Function can only be called from staking controller contract"
        );
        require(
            ownerOf(tokenId) == originator,
            "Originator is not the owner of this token"
        );

        _unstake(tokenId);
    }
*/
    /**
     *  @dev perform safe mint and stake
     */
    function _safemintAndStake(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;

        for (uint256 i = 0; i < quantity; i++) {
            startTokenId++;
            tokenToIsStaked[startTokenId] = true;
        }

        _safeMint(to, quantity, "");
    }

    /**
     *  @dev perform mint and stake
     */
    function _mintAndStake(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;

        for (uint256 i = 0; i < quantity; i++) {
            startTokenId++;
            tokenToIsStaked[startTokenId] = true;
        }

        _mint(to, quantity);
    }

    /**
     * @dev overrides transferFrom to prevent transfer if token is staked
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            isStaked(tokenId) == false,
            "You can not transfer a staked token"
        );

        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev overrides safeTransferFrom to prevent transfer if token is staked
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            isStaked(tokenId) == false,
            "You can not transfer a staked token"
        );
        super.safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev overrides safeTransferFrom to prevent transfer if token is staked
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            isStaked(tokenId) == false,
            "You can not transfer a staked token"
        );

        super.safeTransferFrom(from, to, tokenId, _data);
    }
}