/**
            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@@@@@@@@@@@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@(           *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@@@@@@@@@   ,@,                          #@@@@@@@@@@@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@@@@@@&@@    @@   @@@@        *@@@@* *@,      %@@@@@@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@@@.   %@     @%   /&    %@@@(        @@          @@@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@,       @@    ,@#   /@@@/              @@      @     @@@@@@@.#@@@@
            @@@@@@@@@@@@          ,@(     @@@#                    ,@@    @       @@&   %@@@@
            @@@@@@@@@@    *@@@     (@*     @@                       [email protected]@      [email protected]@&      @@@@@
            @@@@@@@@              &@@@/     &@                        ,@@@@@&         @@@@@@
            @@@@@@@            @@&   *@%/%@@@                           &@.         %@@@@@@@
            @@@@@%          @@%                                          @@       @@@  *@@@@
            @@@@%        [email protected]@                                 #@@@@@@@@@&@%     @@& @@   /@@@
            @@@@        /@.                          /@@@@%.          [email protected](  &@@/   (@,    &@@
            @@@         /@.                     (@@@*                 @@@@,      @@       @@
            @@@   &@&    %@.                [email protected]@&     [email protected]@@@@@@@        @@      ,@@.        &@
            @@%           /@%             @@*     @@@   (@. [email protected]*        @&  %@@@           /@
            @@#             @@          @@     ,@@@@@&   @@ @@          @@%   @&    @@%   ,@
            @@%        @#    @@       @@,     @@@@@@@.  (@@@/            %@& @@           /@
            @@@        #,    *@*     @@       *@@@@@@@@@@,                 &@             &@
            @@@            &@@%%%%@@@                                     &@@             @@
            @@@@           &@      @                               @@@@@%                &@@
            @@@@%    @&    ,@@&  /@&                  *@#  ,@@@@@@,                     /@@@
            @@@@@%   @&     @@                       @@@@@*    @@               @@@    *@@@@
            @@@@@@@          @@* ,#@@@@@@%.    (@@@@@.        %@      @@,             &@@@@@
            @@@@@@@@            *%@@@@@@@@@@@@%*              @&                     @@@@@@@
            @@@@@@@@@@                     @@                [email protected]/                   &@@@@@@@@
            @@@@@@@@@@@@          (       %@                 /@.           %@@@( &@@@@@@@@@@
            @@@@@@@@@@@@@@,      %@&,     @&                 [email protected]@@@@@%,/@@&   [email protected]@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@@@            &@                   @@      @@    @@@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@@@@@@&        @@                   [email protected]%       %@@@@@@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@@@@@@@@@@@%   @@                     @@./@@@@@@@@@@@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%/.          *#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
**/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PMLToken is ERC20Burnable, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }

    /// @notice Since this token is only used to mint islands, the coin function should ensure that there are enough
    /// tokens to mint the islands, even if tokens are accidentally burned or locked.
    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender, amount);
    }
}