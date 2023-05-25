// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional lock extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface ISingleMint {

    /**
    @notice Stock all data about the minting process: sales date, price, max per tx, max per wallet, pause.
    */
    struct Mint {
        uint64 start;
        uint64 end;
        uint16 maxPerWallet;
        uint16 maxPerTx;
        uint256 price;
        bool paused;
    }

    /**
    @dev Emitted when the Mint data are changed
    */
    event EventSaleChange(Mint sale);

    /**
    @notice Set new values for Mint struct
    */
    function setMint(Mint memory _sale) external;

    /**
    @notice Shortcut for change only the pause variable of the Mint struct
    */
    function pauseMint(bool _pause) external;

    /**
    @notice Check if the mint process is open, by checking the block.timestamp
    */
    function mintIsOpen() external returns(bool);

    /**
    @notice Calculation of the current token price
    */
    function mintPrice(uint256 _count) external returns(uint256);

    /**
    @return The amount of token minted by the _wallet
    */
    function mintBalance(address _wallet) external view returns(uint16);
}