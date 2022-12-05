//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

interface IPassport {
    function mintPassports(address[] calldata _addresses, uint256[] calldata _amounts)
        external
        returns (uint256, uint256);
}

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract IT02MintingModule is AccessControl, ERC721Holder {
    IPassport public passport;
    IERC721 public admitOne;

    // admit one token ID => number of tokens minted
    mapping(uint256 => uint256) public a1Minted;

    // token ID => size
    mapping(uint256 => Size) public sizeSelection;

    // size => number of remaining shirt
    mapping(Size => uint256) public stockRemaining;

    // t-shirt size (XS - 0, S - 1, M - 2, L - 3, XL - 4, XXL - 5)
    enum Size {
        XS,
        S,
        M,
        L,
        XL,
        XXL
    }

    // price per token in wei
    uint256 public mintPrice;

    uint256 public maxClaimPerA1;

    uint256 private mintState;

    //events
    event Withdraw(uint256 value, address indexed withdrawnBy);
    event SizeSelection(address indexed holderAddress, uint256[] lookbookTokenIds, Size[] sizes);
    event StockRemainingUpdated(Size[] sizes, uint256[] remaining);
    event MaxClaimPerA1Updated(uint256 newMaxClaimPerA1);
    event MintPriceUpdated(uint256 newMintPrice);

    constructor(
        address lookbookAddress,
        address admitOneAddress,
        uint256 price,
        uint256 maxClaim,
        uint256 xsStock,
        uint256 sStock,
        uint256 mStock,
        uint256 lStock,
        uint256 xlStock,
        uint256 xxlStock
    ) {
        passport = IPassport(lookbookAddress);
        admitOne = IERC721(admitOneAddress);

        mintPrice = price;
        mintState = 0;
        maxClaimPerA1 = maxClaim;

        stockRemaining[Size.XS] = xsStock;
        stockRemaining[Size.S] = sStock;
        stockRemaining[Size.M] = mStock;
        stockRemaining[Size.L] = lStock;
        stockRemaining[Size.XL] = xlStock;
        stockRemaining[Size.XXL] = xxlStock;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Mint  token(s) to caller
    /// @dev Must first enable claim
    /// @param a1TokenIds Admit One token ID(s) of tokens to mint
    /// @param sizes T shirt size(s)
    function mint(uint256[] memory a1TokenIds, Size[] calldata sizes) external payable returns (uint256[] memory) {
        require(msg.value == mintPrice * sizes.length, "payment not correct"); // check payment
        require(this.getMintState() == 1, "minting disabled"); // check mint state

        uint256 totalMintsAble; // track how many total mints a user can make
        for (uint256 i = 0; i < a1TokenIds.length; i++) {
            // number of mints left for a1 token
            uint256 numMintsCompleted = a1Minted[a1TokenIds[i]];
            // check sender owns token
            require(admitOne.ownerOf(a1TokenIds[i]) == msg.sender, "doesn't own token");
            // check that indv token has remaining mints
            require(numMintsCompleted < maxClaimPerA1, "token minted max reached");
            // add number of mints left for a1 to total
            totalMintsAble += (maxClaimPerA1 - numMintsCompleted);
        }
        // check that number of shirts requested is less than total able to mint
        require(sizes.length <= totalMintsAble, "too many requested");

        uint256[] memory passportTokenIds = new uint256[](sizes.length); // track which token IDs we are minting
        uint256 startIndex = 0; // keep track of which a1 token we are counting against, starting at  0
        for (uint256 i = 0; i < sizes.length; i++) {
            // check that size stock remains
            require(stockRemaining[sizes[i]] != 0, "size out of stock");
            // decrement size stock
            stockRemaining[sizes[i]]--;

            // increment number of mints for a1 token
            uint256 numMinted = a1Minted[a1TokenIds[startIndex]];
            numMinted++;
            a1Minted[a1TokenIds[startIndex]] = numMinted;
            if (numMinted == maxClaimPerA1) {
                // if a1 token has maxxed out mint, move to next token
                // we checked each token for being less than max claim previously
                // so we know they have at least 1 claim left each
                startIndex++;
            }

            // mint token

            address[] memory to = new address[](1);
            to[0] = msg.sender;
            uint256[] memory amount = new uint256[](1);
            amount[0] = 1;
            (, uint256 end) = passport.mintPassports(to, amount); // start and end should always be the same since we are minting 1 token
            passportTokenIds[i] = end;
            // store size selection
            sizeSelection[passportTokenIds[i]] = sizes[i];
        }

        emit SizeSelection(msg.sender, passportTokenIds, sizes);
        return passportTokenIds;
    }

    function setStockRemaining(Size[] calldata sizes, uint256[] calldata remaining)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(sizes.length == remaining.length, "Array length mismatch");
        for (uint256 i = 0; i < sizes.length; i++) {
            stockRemaining[sizes[i]] = remaining[i];
        }
        emit StockRemainingUpdated(sizes, remaining);
    }

    /// @notice Returns total number of shirts remaining across all sizes
    function totalSupplyRemaining() external view returns (uint256) {
        return
            stockRemaining[Size.XS] +
            stockRemaining[Size.S] +
            stockRemaining[Size.M] +
            stockRemaining[Size.L] +
            stockRemaining[Size.XL] +
            stockRemaining[Size.XXL];
    }

    /// @notice Returns mint state. 0 - not started, 1 - active, 2 - closed/completed (all sizes sold out)
    function getMintState() external view returns (uint256) {
        if (this.totalSupplyRemaining() == 0) {
            return 2;
        }
        return mintState;
    }

    /// @notice Set mint state
    /// @dev 0 - not started, 1 - active
    /// @param newMintState New mint state. Must be 0 or 1
    function setMintState(uint256 newMintState) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newMintState <= 1, "invalid mint state");
        require(this.getMintState() != 2, "minting done");
        mintState = newMintState;
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 value = address(this).balance;
        address payable to = payable(msg.sender);
        emit Withdraw(value, msg.sender);
        to.transfer(value);
    }

    function setMaxClaimPerA1(uint256 newMaxClaimPerA1) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxClaimPerA1 = newMaxClaimPerA1;
        emit MaxClaimPerA1Updated(newMaxClaimPerA1);
    }

    function setMintPrice(uint256 newMintPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPrice = newMintPrice;
        emit MintPriceUpdated(newMintPrice);
    }
}