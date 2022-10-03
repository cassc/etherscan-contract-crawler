// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./BaseFixedPriceAuctionERC721A.sol";

contract LevelingUpHeroesMagical is BaseFixedPriceAuctionERC721A {
    string public mintWhitelistWithAmountPrefix =
        "Leveling Up Heroes Magical Whitelist Verification:";

    constructor(
        address[] memory payees,
        uint256[] memory shares,
        string memory name,
        string memory symbol,
        uint256 _whitelistMaxMint,
        uint256 _publicListMaxMint,
        uint256 _nonReservedMax,
        uint256 _reservedMax,
        uint256 _price
    )
        BaseFixedPriceAuctionERC721A(
            payees,
            shares,
            name,
            symbol,
            _whitelistMaxMint,
            _publicListMaxMint,
            _nonReservedMax,
            _reservedMax,
            _price
        )
    {}

    function _hashRegisterForWhitelistWithAmount(
        string memory _prefix,
        address _address,
        uint256 amount
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_prefix, _address, amount));
    }

    function registerAndMintForWhitelist(
        bytes32 hash,
        bytes calldata signature,
        uint256 numberOfTokens,
        uint256 customLimit
    ) external payable {
        require(_verify(hash, signature), "Signature invalid.");
        require(
            _hashRegisterForWhitelistWithAmount(
                mintWhitelistWithAmountPrefix,
                msg.sender,
                customLimit
            ) == hash,
            "Hash invalid."
        );
        require(
            _whitelistClaimed[msg.sender] + numberOfTokens <= customLimit,
            "You cannot mint this many."
        );
        require(
            _whitelistClaimed[msg.sender] + numberOfTokens <= whitelistMaxMint,
            "You cannot mint this many."
        );

        _whitelistClaimed[msg.sender] += numberOfTokens;
        _nonReservedMintHelper(numberOfTokens);
    }
}