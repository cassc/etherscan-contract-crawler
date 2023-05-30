// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                 +
+                                                                                                                 +
.                        .^!!~:                                                 .^!!^.                            .
.                            :7Y5Y7^.                                       .^!J5Y7^.                             .
.                              :!5B#GY7^.                             .^!JP##P7:                                  .
.   7777??!         ~????7.        :[email protected]@@@&GY7^.                    .^!JG#@@@@G^        7????????????^ ~????77     .
.   @@@@@G          [email protected]@@@@:       J#@@@@@@@@@@&G57~.          .^7YG#@@@@@@@@@@&5:      #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:     :[email protected]@@@@[email protected]@@@@@@@@&B5?~:^7YG#@@@@@@@@[email protected]@@ @@&!!     #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:    [email protected]@@@#[email protected]@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@P   ^[email protected]@@@@~.   ^~~~~~^[email protected] @@@@??:~~~~~    .
.   @@@@@B^^^^^^^^. [email protected]@@@@:   [email protected]@@@&^   [email protected][email protected]@@@@@&@@@@@@@@@@@&@J7&@@@@@#.   [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@B   ^B&&@@@@@#!#@@@@@@@@@@7G&&@@@@@#!     [email protected]@@@#.           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@&^    !YPGPY!  [email protected]@@@@Y&@@@@Y  ~YPGP57.    [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@B~~~~~~~!!.?GPPGP:   [email protected]@@@&7           ?&@@@@P [email protected]@@@@5.          [email protected]@@@&^            [email protected]@@@@?            .
.   @@@@@G          ^~~~~~.    :[email protected]@@@@BY7~^^~75#@@@@@5.    [email protected]@@@@&P?~^^^[email protected]@@@@#~             [email protected]@@@@?            .
.   @@@@@G          [email protected]@@@@:      [email protected]@@@@@@@@@@@@@@@B!!      ^[email protected]@@@@@@@@@@@@@@@&Y               [email protected]@@@@?            .
.   @@@@@G.         [email protected]@@@@:        !YB&@@@@@@@@&BY~           ^JG#@@@@@@@@&#P7.                [email protected]@@@@?            .
.   YYYYY7          !YJJJJ.            :~!7??7!^:                 .^!7??7!~:                   ^YJJJY~            .
.                                                                                                                 .
.                                                                                                                 .
.                                                                                                                 .
.                                  ………………               …………………………………………                  …………………………………………        .
.   PBGGB??                      7&######&5            :B##############&5               .G#################^      .
.   &@@@@5                      [email protected]@@@@@@@@@           :@@@@@@@@@@@@@@@@@G               &@@@@@@@@@@@@ @@@@@^      .
.   PBBBBJ                 !!!!!JPPPPPPPPPY !!!!!     :&@@@@P?JJJJJJJJJJJJJJ?      :JJJJJJJJJJJJJJJJJJJJJJ.       .
.   ~~~~~:                .#@@@@Y          [email protected]@@@@~    :&@@@@7           [email protected]@@&.      ^@@@@.                        .
.   #@@@@Y                .#@@@@[email protected]@@@@~    :&@@@@7   !JJJJJJJJJJJJ?     :JJJJJJJJJJJJJJJJJ!!           .
.   #@@@@Y                .#@@@@@@@@@@@@@@@@@@@@@@~   :&@@@@7   [email protected]@@@@@@@G &@@             @@@@@@@@@@P            .
.   #@@@@Y                .#@@@@&##########&@@@@@~    :&@@@@7   7YYYYYYYYJ???7             JYYYYYYYYYYYYJ???7     .
.   #@@@@Y                .#@@@@5 ........ [email protected]@@@@~    :&@@@@7            [email protected]@@&.                         [email protected]@@#     .
.   #@@@@#5PPPPPPPPPJJ    .#@@@@Y          [email protected]@@@@~    :&@@@@P7??????????JYY5J      .?????????? ???????JYY5J       .
.   &@@@@@@@@@@@@@@@@@    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@@@P            .
.   PBBBBBBBBBBBBBBBBY    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@ @@5           .
+                                                                                                                 +
+                                                                                                                 +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/

pragma solidity ^0.8.0;

import "../hootbase/base/erc721/HootERC721A.sol";
import "../hootbase/base/erc721/features/HootBaseERC721Raising.sol";
import "../hootbase/base/erc721/features/HootBaseERC721Refund.sol";
import "../hootbase/base/erc721/features/HootBaseERC721URISample.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

abstract contract YINGInterface {
    function mintTransfer(address address_, uint256 blindTokenId_)
        public
        virtual
        returns (uint256);

    function mintTransferBatch(
        address address_,
        uint256[] calldata blindTokenIds_
    ) public virtual returns (uint256[] memory);
}

/**
 * @title HootAirdropBox
 * @author HootLabs
 */
contract YINGHelloNewWorld is
    HootBaseERC721Raising,
    HootBaseERC721Refund,
    HootBaseERC721URISample,
    HootERC721A
{
    event YINGConfigChanged(YINGConfig cfg);
    event HolderMintConfigChanged(address contractAddr, HolderMintConfig cfg);
    event WhitelistSaleConfigChanged(SaleConfig cfg);
    event PartnerContractAdded(address partnerContract, uint256 maxSupply);
    event PublicSaleConfigChanged(SaleConfig cfg);
    event RevealConfigChanged(RevealConfig cfg);

    event PartnerSaled(
        address partnerContract,
        address receiver,
        uint64 amount_
    );
    /**
     * used to mark the contract, each contract have to make a different CONTRACT_SHIELD
     */
    uint256 public constant CONTRACT_SHIELD = 1942123432145421;

    struct YINGConfig {
        uint256 maxSupply;
        uint256 maxSaleSupply;
        uint256 maxSelfSupply;
        bool rejectFreeMintRefund;
    }
    struct SaleConfig {
        uint256 price;
        uint256 startTime;
        uint256 stopTime;
        uint64 supplyOfOwner;
    }
    struct HolderMintConfig {
        uint256 price;
        uint256 startTime;
        uint256 stopTime;
        uint64 supplyOfHolder;
    }
    struct RevealConfig {
        uint256 startTime;
        uint256 stopTime;
        address yingAddress;
    }

    YINGConfig public yingCfg;
    mapping(address => HolderMintConfig) _holderMintCfg;
    SaleConfig public whitelistSaleCfg;
    SaleConfig public publicSaleCfg;
    RevealConfig public revealCfg;
    mapping(address => uint64) _partnerMaxSupply;

    // contract_address => contract_token_id => amount
    mapping(address => mapping(uint256 => uint256)) _holderMintedAmounts;
    mapping(uint256 => bool) _freeMintTokens;
    mapping(uint256 => bool) _freeMintYINGTokens;
    bytes32 public merkleRoot; // merkle root for whitelist checking
    uint64 public selfMinted;

    constructor() HootERC721A("YING: Hello New World", "YING") {}

    /***********************************|
    |               Config              |
    |__________________________________*/
    function setYINGConfig(YINGConfig calldata cfg_) external onlyOwner {
        yingCfg = cfg_;
        emit YINGConfigChanged(cfg_);
    }

    function setHolderMintConfig(
        address contractAddr_,
        HolderMintConfig calldata cfg_
    ) external onlyOwner {
        _holderMintCfg[contractAddr_] = cfg_;
        emit HolderMintConfigChanged(contractAddr_, cfg_);
    }

    function setWhitelistSaleConfig(SaleConfig calldata cfg_, bytes32 root_)
        external
        onlyOwner
    {
        whitelistSaleCfg = cfg_;
        merkleRoot = root_;
        emit WhitelistSaleConfigChanged(cfg_);
    }

    function addPartnerContract(address partnerContract_, uint64 maxSupply_)
        external
        onlyOwner
    {
        _partnerMaxSupply[partnerContract_] = maxSupply_;
        emit PartnerContractAdded(partnerContract_, maxSupply_);
    }

    function setPublicSaleConfig(SaleConfig calldata cfg_) external onlyOwner {
        publicSaleCfg = cfg_;
        emit PublicSaleConfigChanged(cfg_);
    }

    // Set authorized contract address for minting the ERC-721 token
    function setRevealConfig(RevealConfig calldata cfg_) external onlyOwner {
        revealCfg = cfg_;
        emit RevealConfigChanged(cfg_);
    }

    function isWhitelistSaleEnabled() public view returns (bool) {
        return
            block.timestamp > whitelistSaleCfg.startTime &&
            block.timestamp < whitelistSaleCfg.stopTime;
    }

    function isPublicSaleEnabled() public view returns (bool) {
        return
            block.timestamp > publicSaleCfg.startTime &&
            block.timestamp < publicSaleCfg.stopTime;
    }

    // whitelist sale config
    function isWhitelistAddress(address address_, bytes32[] calldata signature_)
        public
        view
        returns (bool)
    {
        if (merkleRoot == "") {
            return false;
        }
        return
            MerkleProof.verify(
                signature_,
                merkleRoot,
                keccak256(abi.encodePacked(address_))
            );
    }

    /**
     * @notice isRevealEnabled is used to return whether the reveal has been enabled.
     */
    function isRevealEnabled() public view returns (bool) {
        return
            block.timestamp > revealCfg.startTime &&
            block.timestamp < revealCfg.stopTime &&
            revealCfg.yingAddress != address(0);
    }

    /***********************************|
    |               Core                |
    |__________________________________*/
    // The maximum number of mint tokens allowed selfSupply
    function selfMint(uint64 numberOfTokens_) external onlyOwner nonReentrant {
        require(numberOfTokens_ > 0, "invalid number of tokens");
        unchecked {
            uint64 nextMinted = selfMinted + numberOfTokens_;
            require(
                nextMinted <= yingCfg.maxSelfSupply,
                "max self supply exceeded"
            );
            _mint(_msgSender(), numberOfTokens_);
            selfMinted = nextMinted;
        }
    }

    function checkAndGetHolderConfig(address contractAddr_)
        private
        view
        returns (HolderMintConfig memory)
    {
        require(contractAddr_ != address(0), "contract address is invalid");
        HolderMintConfig memory holderCfg = _holderMintCfg[contractAddr_];
        require(
            holderCfg.startTime > 0 && block.timestamp > holderCfg.startTime,
            "holder mint is not start"
        );
        require(
            block.timestamp < holderCfg.stopTime,
            "holder mint has been stoped"
        );
        require(
            holderCfg.supplyOfHolder > 0,
            "the input contract does not support to mint"
        );
        return holderCfg;
    }

    function holdersSale(
        address contractAddr_,
        uint256[] calldata tokenIDs_,
        uint64[] calldata amounts_
    ) external payable callerIsUser nonReentrant {
        require(
            tokenIDs_.length == amounts_.length,
            "the length of Listing TokenIDs is different from that of Listing Amounts"
        );
        HolderMintConfig memory holderCfg = checkAndGetHolderConfig(
            contractAddr_
        );
        require(
            tokenIDs_.length < yingCfg.maxSaleSupply,
            "max sale supply exceeded"
        );

        uint64 amountTotal = 0;
        unchecked {
            for (uint256 i = 0; i < tokenIDs_.length; i++) {
                uint64 amount = amounts_[i];
                require(amount < 3, "an token can only mint two tokens");
                require(amount > 0, "invalid number of tokens");

                uint256 nextSupply = _holderMintedAmounts[contractAddr_][
                    tokenIDs_[i]
                ] + amount;
                require(
                    nextSupply <= holderCfg.supplyOfHolder,
                    "max sale supply exceeded"
                );

                // 验证是否是 owner
                ERC721 contractAddress = ERC721(contractAddr_);
                require(
                    contractAddress.ownerOf(tokenIDs_[i]) == _msgSender(),
                    "doesn't own the token"
                );
                _holderMintedAmounts[contractAddr_][tokenIDs_[i]] = nextSupply;

                amountTotal += amount;
            }
            _sale(_msgSender(), amountTotal, holderCfg.price);
        }
    }

    // Only one token can be mint at a time
    function whitelistSale(bytes32[] calldata signature_, uint64 amount_)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(isWhitelistSaleEnabled(), "whitelist sale has not enabled");
        require(
            isWhitelistAddress(_msgSender(), signature_),
            "caller is not in whitelist or invalid signature"
        );
        require(amount_ > 0, "invalid number of tokens");
        require(amount_ < 3, "can only mint 2 tokens at a time");

        uint64 nextSupply = _getAux(_msgSender()) + amount_;
        require(
            nextSupply <= whitelistSaleCfg.supplyOfOwner,
            "out of max mint amount"
        );
        _sale(_msgSender(), amount_, whitelistSaleCfg.price);
        _setAux(_msgSender(), uint64(nextSupply));
    }

    function partnerSale(address receiver, uint64 amount_)
        external
        payable
        nonReentrant
    {
        require(isWhitelistSaleEnabled(), "whitelist sale has not enabled");
        require(amount_ > 0, "invalid number of tokens");
        require(amount_ < 3, "can only mint 2 tokens at a time");

        uint64 maxSupply = _partnerMaxSupply[_msgSender()];
        uint64 nextSupply = _getAux(_msgSender()) + amount_;
        require(nextSupply <= maxSupply, "out of max mint amount");

        _sale(receiver, amount_, whitelistSaleCfg.price);
        _setAux(_msgSender(), uint64(nextSupply));

        emit PartnerSaled(_msgSender(), receiver, amount_);
    }

    /**
     * @notice public sale.
     * @param amount_ sale amount
     */
    function publicSale(uint64 amount_)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(isPublicSaleEnabled(), "public sale has not enabled");
        require(amount_ > 0, "invalid number of tokens");
        require(amount_ < 3, "can only mint 2 tokens at a time");

        uint64 nextSupply = _getAux(_msgSender()) + amount_;
        require(
            nextSupply <= publicSaleCfg.supplyOfOwner,
            "out of max mint amount"
        );
        _sale(_msgSender(), amount_, publicSaleCfg.price);
        _setAux(_msgSender(), nextSupply);
    }

    // The maximum number of mint tokens allowed saleSupply
    function _sale(
        address receiver,
        uint64 numberOfTokens_,
        uint256 price_
    ) internal {
        require(
            _totalMinted() + numberOfTokens_ - selfMinted <= yingCfg.maxSaleSupply,
            "max sale supply exceeded"
        );
        uint256 amount = price_ * numberOfTokens_;
        require(amount <= msg.value, "ether value sent is not correct");
        _safeMint(receiver, numberOfTokens_);
        refundExcessPayment(amount);
        if (price_ == 0) {
            for (uint256 i = 0; i < numberOfTokens_; ++i) {
                _freeMintTokens[_totalMinted() - i] = true;
            }
        }
    }

    /**
     * @notice when the amount paid by the user exceeds the actual need, the refund logic will be executed.
     * @param amount_ the actual amount that should be paid
     */
    function refundExcessPayment(uint256 amount_) private {
        if (msg.value > amount_) {
            payable(_msgSender()).transfer(msg.value - amount_);
        }
    }

    /**
     * @notice Determine whether it is the Token of a FreeMint
     * @param tokenId_ YING: Hello New World token id
     */
    function isFreeMintToken(uint256 tokenId_)
        public
        view
        virtual
        returns (bool)
    {
        return _freeMintTokens[tokenId_];
    }

    /**
     * @notice Determine whether it is the Token of a FreeMint
     * @param tokenId_ YING token id
     */
    function isFreeMintYINGToken(uint256 tokenId_)
        public
        view
        virtual
        returns (bool)
    {
        return _freeMintYINGTokens[tokenId_];
    }

    /**
     * Gets the number of Mint of the holder
     */
    function getHolderMinted(
        address contractAddr_,
        uint256[] calldata tokenIDs_
    ) external view returns (uint256[] memory) {
        mapping(uint256 => uint256) storage tokenAmount = _holderMintedAmounts[
            contractAddr_
        ];
        uint256[] memory amounts = new uint256[](tokenIDs_.length);
        for (uint256 i = 0; i < tokenIDs_.length; i++) {
            amounts[i] = tokenAmount[tokenIDs_[i]];
        }
        return amounts;
    }

    /**
     * gets the number of Mint during the whitelist and the public sale
     */
    function getSaleBalanceOf(address owner) public view returns (uint256) {
       return _getAux(owner);
    }

    /**
     * @notice reveal is used to open the blind box.
     * @param tokenId_ tokenId of the blind box to be revealed.
     * @return tokenId after revealing the blind box.
     */
    function reveal(uint256 tokenId_)
        external
        callerIsUser
        nonReentrant
        returns (uint256)
    {
        require(isRevealEnabled(), "reveal has not enabled");
        require(ownerOf(tokenId_) == _msgSender(), "caller is not owner");
        _burn(tokenId_);
        YINGInterface yingContract = YINGInterface(revealCfg.yingAddress);
        uint256 yingTokenId = yingContract.mintTransfer(_msgSender(), tokenId_);
        if (isFreeMintToken(tokenId_)) {
            _freeMintYINGTokens[yingTokenId] = true;
        }
        return yingTokenId;
    }

    function revealBatch(uint256[] calldata tokenIds_)
        external
        callerIsUser
        nonReentrant
        returns (uint256[] memory)
    {
        require(isRevealEnabled(), "reveal has not enabled");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            require(ownerOf(tokenId) == _msgSender(), "caller is not owner");
            _burn(tokenId);
        }
        YINGInterface yingContract = YINGInterface(revealCfg.yingAddress);
        uint256[] memory yingTokenIds = yingContract.mintTransferBatch(
            _msgSender(),
            tokenIds_
        );
        for (uint256 i = 0; i < yingTokenIds.length; i++) {
            if (isFreeMintToken(tokenIds_[i])) {
                _freeMintYINGTokens[yingTokenIds[i]] = true;
            }
        }
        return yingTokenIds;
    }

    /***********************************|
    |        HootBaseERC721Refund       |
    |__________________________________*/
    function _refundPrice(uint256 tokenId_)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        if (yingCfg.rejectFreeMintRefund) {
            require(
                !_freeMintTokens[tokenId_],
                "No refunds are allowed for free mint token"
            );
        }
        return super._refundPrice(tokenId_);
    }

    /***********************************|
    | HootBaseERC721URIStorageWithLevel |
    |__________________________________*/
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override(ERC721A, HootBaseERC721URISample)
        returns (string memory)
    {
        return HootBaseERC721URISample.tokenURI(tokenId_);
    }

    /***********************************|
    |               ERC721A             |
    |__________________________________*/
    /**
     * @notice hook function, used to intercept the transfer of token.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(HootBaseERC721Raising, HootERC721A) {
        HootBaseERC721Raising._beforeTokenTransfers(
            from,
            to,
            startTokenId,
            quantity
        );
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}