//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.9;

interface IDAOFactory {

    function isSigner(address signer_) external view returns (bool);
    function increaseNonce(address account_) external returns (uint256 _nonce);

    struct DistributionParam {
        address recipient;
        uint256 amount;
        uint256 lockDate;
    }

    struct Reserve {
        address token;
        uint256 amount;
        uint256 lockDate;
    }

}