// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

abstract contract DialUpState {
    error WalletAlreadyMinted();
    error WithdrawTransfer();
    error EthValueTooLow();
    error NotEnoughTokens();

    bool internal baseURIFrozen;
    string public baseURI;
    address public adminWallet;

    uint256 public constant TOTAL_SUPPLY = 5_600;
    uint256 public constant MINT_PRICE = 0.0065 ether;

    address public diskAddress;

    struct Disk {
        uint16 burn;
        uint16 uploads;
        uint16 writes;
        bool active;
        bool loaded;
    }

    struct OS {
        mapping(uint8 => uint16) disks;
        uint8 writes;
    }

    mapping(uint16 => Disk) public disks;
    mapping(uint16 => OS) public operatingSystms;
}