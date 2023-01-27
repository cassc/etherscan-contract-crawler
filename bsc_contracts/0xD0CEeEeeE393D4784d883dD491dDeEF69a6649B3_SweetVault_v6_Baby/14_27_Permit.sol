/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IPancakePair.sol";

library Permit {
    function approve(
        address _token,
        uint _inputTokenAmount,
        bytes calldata _signatureData
    ) internal {
        (uint8 v, bytes32 r, bytes32 s, uint deadline) = abi.decode(_signatureData, (uint8, bytes32, bytes32, uint));

        IPancakePair(_token).permit(
            msg.sender,
            address(this),
            _inputTokenAmount,
            deadline,
            v,
            r,
            s
        );
    }
}