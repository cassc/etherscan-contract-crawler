// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../security/Administered.sol";

contract RamdomWallet is Administered {
    /// @dev array address
    address[] public arrayAddress = [
        0x4C54d42aB8a14E0142df679a075E4C4dE767d8D0,
        0x78303360ec1ACA06F195f48F75D6D59107810Dff,
        0x6f1d983B8372953EAd083Bc08b20CC4214D3bB11,
        0x3Fa035CEBC1D0F0Fd5776f93c0979652f82A47b2,
        0x08a2C2E025777Acf2966c973d64830c20dEC05a6,
        0xE18CcD9c9707415BbDa5773aCcfFce6f946bB13f
    ];

    /**
     *  @dev get ramdom address
     */
    function getRamdomAddress() public view returns (address) {
        return arrayAddress[rand()];
    }

    /**
     * @dev set wallet receive
     */
    function setWalletReceive(
        uint256 _index,
        address _walletAddress
    ) external onlyUser returns (bool) {
        arrayAddress[_index] = _walletAddress;
        return true;
    }

    /**
     * @dev set list wallet receive
     */
    function setListWalletReceive(
        address[] memory _listaWalletAddress
    ) external onlyUser returns (bool) {
        arrayAddress = _listaWalletAddress;
        return true;
    }

    /**
     * @dev get ramdom number
     */
    function rand() public view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return (seed - ((seed / arrayAddress.length) * arrayAddress.length));
    }
}