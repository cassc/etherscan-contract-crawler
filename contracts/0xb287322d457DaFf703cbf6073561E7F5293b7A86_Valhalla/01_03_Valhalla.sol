//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/**
              (     )        (   (
 (   (     )  )\ ( /(     )  )\  )\    )
 )\  )\ ( /( ((_))\()) ( /( ((_)((_)( /(
((_)((_))(_)) _ ((_)\  )(_)) _   _  )(_))
\ \ / /((_)_ | || |(_)((_)_ | | | |((_)_
 \ V / / _` || || ' \ / _` || | | |/ _` |
  \_/  \__,_||_||_||_|\__,_||_| |_|\__,_|

powered by ctor.xyz

 */

import "@openzeppelin/contracts/access/Ownable.sol";

interface IShell {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract Valhalla is Ownable {
    IShell public immutable shell;

    bool public isLocked;

    error Locked();

    constructor(address shell_) {
        shell = IShell(shell_);
    }

    function transfer(address to, uint256 tokenId) external onlyOwner {
        if (isLocked) {
            revert Locked();
        }
        shell.transferFrom(address(this), to, tokenId);
    }

    function lock() external onlyOwner {
        isLocked = true;
    }
}