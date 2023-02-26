// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC1155Contract.sol";

abstract contract IERC721 {
    function ownerOf(uint256 id)
        public
        view
        virtual
        returns (address owner);
}

contract ERC1155Factory is Ownable {

    mapping(uint256 => address) public deployments;
    address public treasuryAddress;
    address public launchpassAddress;
    uint16 public treasuryShare;
    address[] public fiatMinters;
    address public r2eAddress;
    address public dcAddress;
    address[] payees;
    uint256[] shares;

    function updateConfig(address _treasuryAddress, address _launchpassAddress, uint16 _treasuryShare, address[] memory _fiatMinters, address _r2eAddress, address _dcAddress) external onlyOwner {
        treasuryShare = _treasuryShare;
        launchpassAddress = _launchpassAddress;
        treasuryAddress = _treasuryAddress;
        r2eAddress = _r2eAddress;
        dcAddress = _dcAddress;
        fiatMinters = _fiatMinters;
    }

    function deploy(
        uint16 _id,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint16 _launchpassId,
        address[] memory _payees,
        uint256[] memory _shares,
        ERC1155Contract.Token memory _token
    ) external {
        require(_payees.length == _shares.length,  "Failed");
        payees = _payees;
        shares = _shares;
        require(IERC721(launchpassAddress).ownerOf(_launchpassId) == msg.sender,  "Not owner");
        ERC1155Contract nft = new ERC1155Contract(_id, _name, _symbol, _uri, payees, shares, msg.sender, r2eAddress, dcAddress, fiatMinters, _token);
        deployments[_launchpassId] = address(nft);
        payees = new address[](0);
        shares = new uint256[](0);
    }
}