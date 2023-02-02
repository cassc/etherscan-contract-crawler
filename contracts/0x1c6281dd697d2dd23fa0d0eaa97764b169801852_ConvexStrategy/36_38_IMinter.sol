// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

// See https://etherscan.io/address/0xd061D61a4d941c39E5453435B6345Dc261C2fcE0#code
/*  solhint-disable func-name-mixedcase, var-name-mixedcase */
interface IMinter {
    function mint(address gauge) external;
}

/*  solhint-disable func-name-mixedcase, var-name-mixedcase */