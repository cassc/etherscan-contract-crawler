// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./GravitonTorrentERC721.sol";
import "./HasSecondarySaleFees.sol";

contract GravitonTorrentERC721Factory is Ownable {
    address[] public deployedContracts;
    address public lastDeployedContractAddress;
    address private _tnftSigner;

    event LogGravitonTorrentERC721ContractDeployed(
        string tokenName,
        string tokenSymbol,
        address contractAddress,
        address owner,
        uint256 time
    );

    constructor(address _signer) {
        _tnftSigner = _signer;
    }

    function deployGravitonTorrentERC721(
        string memory tokenName,
        string memory tokenSymbol,
        address payable[] memory _feeRecipients,
        uint96[] memory _feeValues
    )
        external
        returns (address gravitonTERC721Contract)
    {
        GravitonTorrentERC721 deployedContract = new GravitonTorrentERC721(
            tokenName, tokenSymbol, _tnftSigner, _feeRecipients, _feeValues);

        deployedContract.transferOwnership(msg.sender);
        address deployedContractAddress = address(deployedContract);
        deployedContracts.push(deployedContractAddress);
        lastDeployedContractAddress = deployedContractAddress;

        emit LogGravitonTorrentERC721ContractDeployed(
            tokenName,
            tokenSymbol,
            deployedContractAddress,
            msg.sender,
            block.timestamp
        );

        return deployedContractAddress;
    }

    function getDeployedContractsCount() external view returns (uint256 count) {
        return deployedContracts.length;
    }
}