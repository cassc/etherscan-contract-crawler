// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseCollectionETHDenver.sol";

/**
 * @title JoshuaDavisETHDenver
 * .
 * @author @vtleonardo, @z-j-lin
 */
contract JoshDavisETHDenver is BaseCollectionETHDenver {
    // The expire date: March 5, 2023 00:00:00 PM MST
    uint256 public constant EXPIRE_DATE = 1678082400;

    bool internal _bypassExpireDate = false;

    constructor(
        address coaProxy_,
        address artist_
    )
        BaseCollectionETHDenver(
            "JoshDavisETHDenver",
            "JoshDavisETHDenver",
            1500,
            type(uint256).max,
            0 ether,
            coaProxy_,
            artist_
        )
    {}

    function setBypassExpireDate() public onlyOwner {
        _bypassExpireDate = !_bypassExpireDate;
    }

    function mint(address to_) public payable override onlyIfMintEnabled {
        require(_bypassExpireDate || block.timestamp < EXPIRE_DATE, "Minting has expired");
        uint32 tokenID = _tokenID + 1;
        _tokenID = tokenID;
        _mint(to_, tokenID);
    }
}