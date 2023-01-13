// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

/**
 * @title ERC-721 Non-Fungible Token Standard, optional lock extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IMultiMint {

    struct MintName {
        string name;
        uint256 start;
        uint256 end;
        uint256 maxPerWallet;
        uint256 maxPerTx;
        uint256 price;
        bool paused;
    }
    struct Mint {
        uint256 start;
        uint256 end;
        uint256 maxPerWallet;
        uint256 maxPerTx;
        uint256 price;
        bool paused;
        bool valid;
    }

    /**
     * @dev Emitted when `tokenId` token is lock.
     */
    event EventMintChange(string _name, Mint sale);

    /**
     * @dev Returns the total amount of tokens locked on the contract.
     */
    function setMint(string calldata _name, Mint memory _sale) external;

    /**
     * @dev Lock a token, it will not be possible to transfer it
     */
    function pauseMint(string calldata _name, bool _pause) external;

    /**
     * @dev unlock a token, it will be possible to transfer it
     */
    function mintIsOpen(string memory _name) external returns(bool);

    /**
     * @dev unlock a token, it will be possible to transfer it
     */
    function mintCurrent() external returns(string memory);

    /**
     * @dev unlock a token, it will be possible to transfer it
     */
    function mintNames() external returns(string[] memory);

    /**
     * @dev unlock a token, it will be possible to transfer it
     */
    function mintPrice(string memory _name, uint256 _count) external returns(uint256);

    /**
     * @dev Return the state of a token
     */
    function mintBalance(string memory _name, address _wallet) external view returns(uint256);
}