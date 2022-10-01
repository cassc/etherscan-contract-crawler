// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

interface NFTcontract {
    function mint(address _to, uint256 _id) external;

    function getTotalMinted() external view returns (uint256);
}

contract launchpad is Ownable {
    NFTcontract public tokenContract;

    address payable public Treasury_wallet;

    uint16 public maxTotalSupply;
    uint256 public mintPrice;

    uint256 public startAt;
    uint256 public expiresAt;

    event LaunchpadStarting(
        uint256 expiresAt,
        uint16 maxTotalSupply,
        uint256 mintPrice
    );

    constructor(address payable _Treasury) {
        Treasury_wallet = _Treasury;
    }

    // external ----------------------------------------------------

    function privateMint(address to, uint16 count) external payable {
        require(block.timestamp < expiresAt, "Launchpad time has expired");
        require(
            msg.value == mintPrice * count,
            "Value is not equal to price * count"
        );

        _mintToken(to, count);
    }

    // internal ----------------------------------------------------

    function _mintToken(address _to, uint16 _count) internal {
        require(_count > 0, "Min amount is 1");
        require(
            maxTotalSupply - _count >= 0,
            "Limit: launchpad NFT has ended or too much count"
        );

        for (uint16 i = 0; i < _count; i++) {
            uint256 totalMinted = tokenContract.getTotalMinted();

            tokenContract.mint(_to, totalMinted + 1);
        }

        maxTotalSupply -= _count;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // admin -------------------------------------------------------

    function setLaunchpadStart(
        uint16 _maxTotalSupply,
        uint256 _mintPrice,
        uint256 _duration,
        uint256 _startAfter
    ) external onlyOwner {
        require(block.timestamp + _duration > block.timestamp, "Invalid input");

        maxTotalSupply = _maxTotalSupply;
        mintPrice = _mintPrice;
        startAt = block.timestamp + _startAfter;
        expiresAt = startAt + _duration;

        emit LaunchpadStarting(expiresAt, maxTotalSupply, mintPrice);
    }

    // set ERC721 deployed contract address
    function setTokenContract(NFTcontract _tokenContract) external onlyOwner {
        tokenContract = _tokenContract;
    }
}