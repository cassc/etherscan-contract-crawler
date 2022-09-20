// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract TeamSplits {
    address[14] private _recipients = [
        0x541cCB0beE71aff14393FfB2B17F0DBa4c0dA69c,
        0xC72b7D827078Ff46FA49c17A60347a3E279F0333,
        0xC72b7D827078Ff46FA49c17A60347a3E279F0333,
        0xfE0a82ed145a93EDDAD828a058D1ffA89438B10D,
        0x93709E7eF7e4D06542cEC90d5cEAb6aa040c561A,
        0x5326e93c95b08c0B6217f716Fe3167E45B99F631,
        0x5326e93c95b08c0B6217f716Fe3167E45B99F631,
        0xebf75c76061bae4b3dc0b565D4d6deDed7f79F79,
        0xD91a94622B6C9f42383E9846BdA7c7a15B8e510b,
        0x848F2aa56abdB4E40B130a0fC261609d76515D8A,
        0xC72b7D827078Ff46FA49c17A60347a3E279F0333,
        0xC72b7D827078Ff46FA49c17A60347a3E279F0333,
        0xF7fF1B2782eB756DAa5fcd89D70CB6911e52eC93,
        0xA7CFaB25fB29311dAec2954C0D526BA697ad5eb9
    ];

    function _paySplit(uint8 _songId, uint256 _amount) internal {
        (bool sent, bytes memory data) = _recipients[_songId - 1].call{
            value: _amount
        }("");
        require(sent, "Failed to send Ether");
    }

    function recipients() public view returns (address[14] memory) {
        return _recipients;
    }
}