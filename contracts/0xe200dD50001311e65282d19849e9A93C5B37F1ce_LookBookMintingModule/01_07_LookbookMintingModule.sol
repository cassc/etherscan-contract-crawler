//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IPassport {
    function mintPassport(address to) external returns (uint256);

    function maxSupply() external view returns (uint256);
}

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract LookBookMintingModule is AccessControl {
    IPassport public lookbook;
    IERC721 public admitOne;

    // admit one token ID => did mint in window 1
    mapping(uint256 => bool) public mintedWindow1;

    // admit one token ID => block number minted in window 2
    mapping(uint256 => uint256) public mintedWindow2;

    // lookbook token ID => size
    mapping(uint256 => Size) public sizeSelection;

    // max amount can claim per admit one token in window 2
    uint256 public constant MAX_CLAIM_WINDOW_2 = 10;

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

    // amount reserved for team
    uint256 public teamSupplyRemaining;

    // amount for public sale
    uint256 public publicSupplyRemaining;

    uint256 private mintState;

    //events
    event Withdraw(uint256 value, address indexed withdrawnBy);
    event SizeSelection(address indexed holderAddress, uint256[] lookbookTokenIds, Size[] sizes);

    constructor(
        address lookbookAddress,
        address admitOneAddress,
        uint256 price,
        uint256 initialTeamSupply,
        uint256 initialPublicSupply
    ) {
        lookbook = IPassport(lookbookAddress);
        admitOne = IERC721(admitOneAddress);
        mintPrice = price;
        mintState = 0;
        teamSupplyRemaining = initialTeamSupply;
        publicSupplyRemaining = initialPublicSupply;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Mint lookbook token(s) to caller
    /// @dev Must first enable claim & set fee/amount (if desired)
    /// @param a1TokenIds Admit One token ID(s) of tokens to mint.
    /// @param sizes T shirt size(s)
    function mint(uint256[] calldata a1TokenIds, Size[] calldata sizes) external payable returns (uint256[] memory) {
        require(msg.value == mintPrice * sizes.length, "payment not correct");
        require(publicSupplyRemaining >= sizes.length, "supply reached");

        publicSupplyRemaining = publicSupplyRemaining - sizes.length;

        // window 1
        if (mintState == 1) {
            require(a1TokenIds.length == sizes.length, "arr length mismatch");

            // mint tokens
            uint256[] memory lbTokenIds = new uint256[](sizes.length);
            for (uint256 i = 0; i < sizes.length; i++) {
                require(admitOne.ownerOf(a1TokenIds[i]) == msg.sender, "doesn't own token");
                require(!mintedWindow1[a1TokenIds[i]], "token already minted");
                mintedWindow1[a1TokenIds[i]] = true;

                lbTokenIds[i] = lookbook.mintPassport(msg.sender);
                sizeSelection[lbTokenIds[i]] = sizes[i];
            }
            emit SizeSelection(msg.sender, lbTokenIds, sizes);
            return lbTokenIds;
        }
        // window 2
        else if (mintState == 2) {
            require(sizes.length <= a1TokenIds.length * MAX_CLAIM_WINDOW_2, "too many requested");

            // check a1 array for duplicates & ownership & already minted this block
            for (uint256 i = 0; i < a1TokenIds.length; i++) {
                require(mintedWindow2[a1TokenIds[i]] < block.number, "already minted this block");
                require(admitOne.ownerOf(a1TokenIds[i]) == msg.sender, "doesn't own token");
                mintedWindow2[a1TokenIds[i]] = block.number;
            }

            // mint tokens
            uint256[] memory lbTokenIds = new uint256[](sizes.length);
            for (uint256 i = 0; i < sizes.length; i++) {
                lbTokenIds[i] = lookbook.mintPassport(msg.sender);
                sizeSelection[lbTokenIds[i]] = sizes[i];
            }
            emit SizeSelection(msg.sender, lbTokenIds, sizes);
            return lbTokenIds;
        } else {
            revert("minting disabled");
        }
    }

    /// @notice Convenience function to determine if token(s) can mint during the first window
    /// @param a1TokenIds Admit One token ID(s) of tokens to mint
    function canMintWindow1(uint256[] calldata a1TokenIds) external view returns (bool[] memory) {
        bool[] memory canTokensMint = new bool[](a1TokenIds.length);
        for (uint256 i = 0; i < a1TokenIds.length; i++) {
            canTokensMint[i] = !mintedWindow1[a1TokenIds[i]];
        }
        return canTokensMint;
    }

    /// @notice Returns mint state. 0 - not started, 1 - window 1, 2 - window 2, 3 - closed/completed (max supply reached)
    function getMintState() external view returns (uint256) {
        if (publicSupplyRemaining == 0) {
            return 3;
        }
        return mintState;
    }

    /// @notice Set mint state
    /// @dev 0 - not started, 1 - window 1, 2 - window 2
    /// @param newMintState New mint state. Must be 0, 1, 2
    function setMintState(uint256 newMintState) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newMintState <= 2, "invalid mint state");
        require(this.getMintState() != 3, "minting done");
        mintState = newMintState;
    }

    /// @notice Team mint function
    /// @param sizes T shirt size(s)
    function teamMint(Size[] calldata sizes) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256[] memory) {
        require(teamSupplyRemaining >= sizes.length, "supply reached");
        teamSupplyRemaining = teamSupplyRemaining - sizes.length;

        uint256[] memory lbTokenIds = new uint256[](sizes.length);
        for (uint256 i = 0; i < sizes.length; i++) {
            lbTokenIds[i] = lookbook.mintPassport(msg.sender);
            sizeSelection[lbTokenIds[i]] = sizes[i];
        }

        emit SizeSelection(msg.sender, lbTokenIds, sizes);
        return lbTokenIds;
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 value = address(this).balance;
        address payable to = payable(msg.sender);
        emit Withdraw(value, msg.sender);
        to.transfer(value);
    }
}