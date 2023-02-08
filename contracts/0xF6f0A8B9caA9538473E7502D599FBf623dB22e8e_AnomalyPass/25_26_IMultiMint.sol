// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface IMultiMint {

    struct Mint {
        uint256 start;
        uint256 end;
        uint256 maxPerWallet;
        uint256 maxPerTx;
        uint256 price;
        bool paused;
        bool valid;
    }

    event EventMintChange(string _name, Mint sale);

    function setMint(string calldata _name, Mint memory _sale) external;

    function pauseMint(string calldata _name, bool _pause) external;

    function mintIsOpen(string memory _name) external returns(bool);

    function mintCurrent() external returns(string memory);

    function mintNames() external returns(string[] memory);

    function mintPrice(string memory _name, uint256 _count) external returns(uint256);

    function mintBalance(string memory _name, address _wallet) external view returns(uint256);
}