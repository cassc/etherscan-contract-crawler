// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/INftBank.sol";

contract NftBank is INftBank, AccessControl {
    using SafeMath for uint256;

    IERC20 public override token;

    address public override deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool public override paused = false;

    IERC20[] public override nft;
    mapping(address => uint256) public override multiplier;

    modifier isActive {
        require(!paused, "paused");
        _;
    }

    constructor(IERC20 _token) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        token = _token;
    }

    function totalSupplyNft() view public override returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < nftLength(); i++) {
            total = total.add(nft[i].totalSupply());
        }

        return total;
    }

    function burnedNft() view public override returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < nftLength(); i++) {
            total = total.add(nft[i].balanceOf(deadAddress));
        }

        return total;
    }

    function circulatingSupplyNft() view external override returns (uint256) {
        return totalSupplyNft().sub(burnedNft());
    }

    function nftLength() view public override returns (uint256) {
        return nft.length;
    }

    function allMultiplier() view public override returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < nftLength(); i++) {
            total = total.add(
                nft[i].totalSupply()
                .sub(nft[i].balanceOf(deadAddress))
                .mul(multiplier[address(nft[i])])
            );
        }

        return total;
    }

    function totalBank() view public override returns (uint256) {
        return token.balanceOf(address(this));
    }

    function price(address _nft) view public override returns (uint256) {
        return totalBank().div(allMultiplier()).mul(multiplier[_nft]);
    }

    function swap(address[] calldata _nfts, uint256[] calldata _values) external override isActive {
        require(_nfts.length == _values.length, "size");

        uint256 amount = 0;

        for (uint256 i = 0; i < _nfts.length; i++) {
            if (_values[i] > 0 && multiplier[_nfts[i]] > 0) {
                amount = amount.add(_values[i].mul(price(_nfts[i])));
                IERC20(_nfts[i]).transferFrom(msg.sender, deadAddress, _values[i]);
            }
        }

        if (amount > 0) {
            token.transfer(msg.sender, amount);
        }
    }

    function setNfts(address[] calldata _nft, uint256[] calldata _multipler) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_nft.length == _multipler.length, "size");

        for (uint256 i = 0; i < nft.length; i++) {
            multiplier[address(nft[i])] = 0;
        }

        delete nft;

        for (uint256 j = 0; j < _nft.length; j++) {
            nft.push(IERC20(_nft[j]));
            multiplier[_nft[j]] = _multipler[j];
        }
    }

    function setPaused(bool _paused) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = _paused;
    }

    function recoverTokens(address _address, uint256 _amount) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_address).transfer(_msgSender(), _amount);
    }

    function recoverTokensFor(address _address, uint256 _amount, address _to) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_address).transfer(_to, _amount);
    }

}