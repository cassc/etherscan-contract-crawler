pragma solidity 0.8.15;
//SPDX-License-Identifier: MIT

import "./Base.sol";

error TooManyTokensToMintPerTransaction();
error TooManyTokensToMint();
error MintingAlreadyStarted();
error EtherSentIsNotCorrect();
error MintingNotStarted();
error CantChangeRenderer();

contract OnChainRobotClubPass is Base {
    constructor(address defaultTreasury)
        ERC1155("OnChain Robot Club Pass", "ORCPASS")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        setTreasuryAddress(payable(defaultTreasury));
        setRoyaltyInfo(750);
    }

    function setRendererContract(IORCPassRender render_) public onlyAdmin {
        if (!canChangeRenderer) revert CantChangeRenderer();
        render = render_;

        emit RendererContractChanged(
            address(render),
            address(render_),
            block.timestamp
        );
    }

    function disableRendererChange() public onlyAdmin {
        canChangeRenderer = false;

        emit RendererChangeBlockedForever(_msgSender());
    }

    function startMinting() public onlyAdmin {
        if (mintStartTime != 0) revert MintingAlreadyStarted();
        mintStartTime = block.timestamp;

        emit MintingStarted(mintStartTime);
    }

    function mint(address to, uint16 numberOfTokens) public payable {
        if (numberOfTokens > MAX_TOKENS_PER_TRANSACTION)
            revert TooManyTokensToMintPerTransaction();
        _mintTokens(to, numberOfTokens);
    }

    function _mintTokens(address to, uint16 numberOfTokens) private {
        if (mintStartTime == 0) revert MintingNotStarted();

        if (msg.value != getMintPrice() * numberOfTokens)
            revert EtherSentIsNotCorrect();

        uint256 currentTokenSupply = totalSupply;

        if (totalSupply + numberOfTokens > MAX_SUPPLY)
            revert TooManyTokensToMint();

        unchecked {
            totalSupply += numberOfTokens;
        }

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            uint16 tokenID = uint16(currentTokenSupply + i);

            if (tokenID == MAX_SUPPLY) {
                _owners[tokenID].passType = PassType.SOLD_OUT;
            } else if (tokenID % 100 == 0) {
                _owners[tokenID].passType = PassType.FIRE;
            } else {
                uint256 randomPercent = (getRandomNounce() % 1000) + 1;
                if (randomPercent <= 50) {
                    _owners[tokenID].passType = PassType.PLATINUM;
                } else if (randomPercent <= 200) {
                    _owners[tokenID].passType = PassType.GOLD;
                } else if (randomPercent <= 500) {
                    _owners[tokenID].passType = PassType.BRONZE;
                } else {
                    _owners[tokenID].passType = PassType.SILVER;
                }
            }

            _mint(to, tokenID, 1, "");
            emit Minted(msg.sender, to, tokenID);
        }
    }

    function uri(uint256 tokenID) public view override returns (string memory) {
        return
            render.getSVGContent(
                tokenID,
                _owners[tokenID].addr,
                _owners[tokenID].passType
            );
    }

    function getMintPrice() public view returns (uint256) {
        if (mintStartTime == 0) {
            return 1 ether;
        }

        uint256 mintPrice = _mintPrice;

        for (
            uint256 i = 0;
            i < (block.timestamp - mintStartTime) / 1 weeks;
            i++
        ) {
            mintPrice *= mintPrice;
        }

        return mintPrice;
    }

    // ============================================================
    // ====================  UTIL FUNCTIONS =======================
    // ============================================================
    function getRandomNounce() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.coinbase,
                        block.difficulty,
                        block.timestamp
                    )
                )
            );
    }
}