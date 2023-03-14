// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ERC1155Contract.sol";

contract ERC1155Factory is Ownable {

    mapping(uint256 => address) public deployments;
    address public treasuryAddress;
    address public launchpassAddress;
    uint16 public treasuryShare;
    address public fiatMinter;
    address public r2eAddress;
    address public dcAddress;

    function updateConfig(address _treasuryAddress, address _launchpassAddress, uint16 _treasuryShare, address _fiatMinter, address _r2eAddress, address _dcAddress) external onlyOwner {
        treasuryShare = _treasuryShare;
        launchpassAddress = _launchpassAddress;
        treasuryAddress = _treasuryAddress;
        r2eAddress = _r2eAddress;
        dcAddress = _dcAddress;
        fiatMinter = _fiatMinter;
    }

    function deploy(
        uint16 _id,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint16 _launchpassId,
        address[] memory _payees,
        uint256[] memory _shares,
        ERC1155Contract.Token memory _token,
        ERC1155Contract.RoyaltyInfo memory _royalties
    ) external {
        require(_payees.length == _shares.length);
        require(IERC721(launchpassAddress).ownerOf(_launchpassId) == msg.sender);
        address[] memory _interfaces = new address[](3);
        _interfaces[0] = r2eAddress;
        _interfaces[1] = dcAddress;
        _interfaces[2] = fiatMinter;
        ERC1155Contract nft = new ERC1155Contract(_id, _name, _symbol, _uri, _payees, _shares, msg.sender, _interfaces, _token, _royalties);
        deployments[_launchpassId] = address(nft);
    }
}