// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Clover ERC20 token contract
contract SakuraBridge is AccessControl {
    // bridge role which could mint bridge transactions
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    event TxMinted(
        uint32 indexed blockNumber,
        uint32 txIndex,
        address dest,
        uint256 amount
    );

    IERC20 _token;

    mapping(uint64 => bool) private _mintedTxs;

    constructor(IERC20 token) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BRIDGE_ROLE, _msgSender());
        _token = token;
    }

    // return the token info
    function getToken() public view returns (IERC20) {
        return _token;
    }

    // mint a tx from clover to bsc chain
    // note here we use the blockNumber + txIndex instead of txHash to identify the transaction
    // because tx hash is not guarantee to be unique in substrate based chains.
    // refer to: https://wiki.polkadot.network/docs/en/build-protocol-info#unique-identifiers-for-extrinsics
    function mintTx(
        uint32 blockNumber,
        uint32 txIndex,
        address dest,
        uint256 amount
    ) public returns (bool) {
        require(
            hasRole(BRIDGE_ROLE, _msgSender()),
            "CloverBridge: must have bridge role"
        );
        require(dest != address(0), "SakuraBridge: invalid address");
        require(dest != address(this), "SakuraBridge: invalid dest address");
        require(
            _token.balanceOf(address(this)) >= amount,
            "SakuraBridge: balance is not enough in the bridge contract!"
        );

        uint64 txKey = getTxKey(blockNumber, txIndex);
        // check whether this tx is minted
        require(!_mintedTxs[txKey], "SakuraBridge: tx already minted!");

        // transfer might fail with some reason
        // e.g. the transfer is paused in the token contract
        require(
            _token.transfer(dest, amount),
            "SakuraBridge: transfer failed!"
        );
        _mintedTxs[txKey] = true;

        emit TxMinted(blockNumber, txIndex, dest, amount);
        return true;
    }

    function hasMinted(uint32 blockNumber, uint32 txIndex)
        public
        view
        returns (bool)
    {
        return _mintedTxs[getTxKey(blockNumber, txIndex)];
    }

    // build a uint64 key from blockNumber and tx index
    // the left 32bit is the blocki number
    // the right 32bit is the tx index
    function getTxKey(uint32 blockNumber, uint32 txIndex)
        internal
        pure
        returns (uint64)
    {
        return uint64((uint64(blockNumber) << 32) | txIndex);
    }

    // helper method to withdraw tokens to the admin account
    function withdraw(IERC20 token) public returns (bool) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "SakuraBridge: must have admin role"
        );
        token.transfer(msg.sender, token.balanceOf(address(this)));
        return true;
    }
}