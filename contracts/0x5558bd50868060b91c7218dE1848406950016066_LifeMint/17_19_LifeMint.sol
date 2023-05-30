// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "./Life.sol";

contract LifeMint is Ownable, ERC721Holder {
    using SafeMath for uint256;
    using Address for address;

    event Mint(uint256 indexed bioId, address indexed owner, uint8[] bioDNA);
    event Received(address sender, uint256 value);
    event Withdraw(uint256 value);

    constructor(address _lifeAddress, uint256 _bioPrice) public {
        LifeContract = Life(_lifeAddress);
        bioPrice = _bioPrice;
    }

    Life public LifeContract;
    uint256 public bioPrice;
    bool public isEnabled = true;

    function setBioPrice(uint256 _bioPrice) external onlyOwner {
        bioPrice = _bioPrice;
    }

    function setStatus(bool _isEnabled) external onlyOwner {
        isEnabled = _isEnabled;
    }

    function mintBio(uint8[] memory bioDNA) external payable {
        require(isEnabled == true, "This contract is not enabled");
        require(msg.value == bioPrice, "Ether value sent is not correct");

        uint256 originalBioPrice = LifeContract.getBioPrice();
        uint256 tokenId = LifeContract.totalSupply();

        LifeContract.mintBio{value: originalBioPrice}(bioDNA);
        LifeContract.safeTransferFrom(address(this), msg.sender, tokenId);

        LifeContract.withdraw();

        emit Mint(tokenId, msg.sender, bioDNA);
    }

    function transferLifeOwnership(address newOwner) external onlyOwner {
        LifeContract.transferOwnership(newOwner);
    }

    function withdraw() external onlyOwner {
        uint256 totalSupply = LifeContract.totalSupply();
        uint256 withdrawValue = address(this).balance;

        if (isEnabled && totalSupply != LifeContract.MAX_NFT_SUPPLY()) {
            withdrawValue = withdrawValue.sub(LifeContract.getBioPrice());
        }

        Address.sendValue(msg.sender, withdrawValue);
        emit Withdraw(withdrawValue);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}